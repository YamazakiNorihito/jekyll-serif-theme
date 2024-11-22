---
title: "GitHubからAWS CloudFormationをデプロイするチャレンジ"
date: 2024-11-22T16:03:00
mermaid: true
weight: 7
tags:
  - AWS
  - CLI
  - IAM
  - GitHub
description: ""
---

[GitHubからのAWS CloudFormationデプロイ自動化](https://aws.amazon.com/jp/blogs/news/automate-safe-aws-cloudformation-deployments-from-github-jp/) を見て、実際に試してみました。そこで学んだことやつまずいた点を書いてみます。

## 試してみてわかったこと

GitHubからCloudFormationをDeployしたかったので、記事の内容に基づいてそのまま試してみましたが、何点かでつまずいたのでその経験を下記します。

基本的にはドキュメント通りで問題ないのですが、Deployするときに必要なRoleが2つあります。それは、[Git 同期](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/git-sync-prereq.html)および[CloudFormationがスタックをデプロイ](https://aws.amazon.com/jp/blogs/news/automate-safe-aws-cloudformation-deployments-from-github-jp/#:~:text=Git%20%E5%90%8C%E6%9C%9F%E3%81%AE%E6%9C%89%E5%8A%B9%E5%8C%96) するための権限を付与されたRoleです。

その他にも、AWS CodePipelineで[GitHub connections](https://docs.aws.amazon.com/codepipeline/latest/userguide/connections-github.html) を事前に作成しておく必要があります。

## CloudFormation Roleの構築

ここでは、CloudFormationをDeployするためのRoleを定義しています。

### cloudformation-deployment-role.yaml

```yaml
## aws cloudformation deploy --stack-name "deploy-role-stack" --template-file ./sandbox-teamc-cloudformation-deployment-role.yaml --capabilities CAPABILITY_NAMED_IAM --region "us-east-1"

AWSTemplateFormatVersion: '2010-09-09'
Description: Create IAM Role with specified permissions

Resources:
  DeploymentRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: sandbox-teamc-cloudformation-deployment-role
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - cloudformation.amazonaws.com
            Action: 'sts:AssumeRole'
      Policies:
        - PolicyName: SandboxTeamCPolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - 'ec2:CreateVpc'
                  - 'ec2:CreateSubnet'
                  - 'ec2:DescribeVpcs'
                  - 'ec2:DescribeSubnets'
                  - 'ec2:DeleteVpc'
                  - 'ec2:DeleteSubnet'
                  - 'ec2:ModifySubnetAttribute'
                  - 'ec2:ModifyVpcAttribute'
                  - "ec2:DescribeSecurityGroups"
                  - ec2:DescribeNetworkAcls
                Resource: '*'
                Condition:
                  ForAnyValue:StringEquals:
                    aws:CalledVia:
                      - cloudformation.amazonaws.com
  GitSyncRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: sandbox-teamc-git-sync-role
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - cloudformation.sync.codeconnections.amazonaws.com
            Action: 'sts:AssumeRole'
      Policies:
        - PolicyName: GitSyncPolicy
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Sid: SyncToCloudFormation
                Effect: Allow
                Action:
                  - "cloudformation:CreateChangeSet"
                  - "cloudformation:DeleteChangeSet"
                  - "cloudformation:DescribeChangeSet"
                  - "cloudformation:DescribeStackEvents"
                  - "cloudformation:DescribeStacks"
                  - "cloudformation:ExecuteChangeSet"
                  - "cloudformation:GetTemplate"
                  - "cloudformation:ListChangeSets"
                  - "cloudformation:ListStacks"
                  - "cloudformation:ValidateTemplate"
                  - "codestar-connections:UseConnection"
                Resource: "*"
              - Sid: PolicyForManagedRules
                Effect: Allow
                Action:
                  - "events:PutRule"
                  - "events:PutTargets"
                Resource: "*"
                Condition:
                  StringEquals:
                    events:ManagedBy: "cloudformation.sync.codeconnections.amazonaws.com"
              - Sid: PolicyForDescribingRule
                Effect: Allow
                Action: "events:DescribeRule"
                Resource: "*"
```

## Pull Request Workflowのサンプル

GitHub Actionsを使ってYAMLファイルをデプロイするワークフローを設定しました。

### .github/workflows/pull-request.yaml

```yaml
name: Pull Request workflow

on:
  - pull_request

jobs:
  cloudformation-linter:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Install cfn-lint
        run: |
          pip install cfn-lint

      - name: Lint specified YAML files
        run: |
          # List of files to check
          files=(
            "./vpc.yaml"
            "./sandbox-teamc-cloudformation-deployment-role.yaml"
          )

          # Lint each file
          for file in "${files[@]}"; do
            if [ -f "$file" ]; then
              echo "Linting $file"
              cfn-lint -t "$file" || exit 1
            else
              echo "File not found: $file"
              exit 1
            fi
          done
```

## VPCのテンプレート

### vpc.yaml

```yaml
AWSTemplateFormatVersion: '2010-09-09'

Parameters:
  EnvironmentName:
    Type: String
    Default: dev
  VpcCIDR:
    Type: String
    Default: 10.0.0.0/16

Resources:
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCIDR
      EnableDnsHostnames: true
      EnableDnsSupport: true
      InstanceTenancy: default
      Tags: 
        - Key: "Name"
          Value:  !Sub "vpc-${EnvironmentName}"
  Subnet:
    Type: AWS::EC2::Subnet 
    Properties:
      VpcId: !Ref VPC 
      CidrBlock: 10.0.0.2/16 

Outputs:
  VpcId:
    Description: The ID of the VPC
    Value: !Ref VPC

  VpcCidrBlock:
    Description: The primary IPv4 CIDR block for the VPC
    Value: !GetAtt VPC.CidrBlock

  VpcCidrBlockAssociations:
    Description: The association IDs of the IPv4 CIDR blocks for the VPC
    Value: !Join [",", !GetAtt VPC.CidrBlockAssociations]

  DefaultNetworkAcl:
    Description: The ID of the default network ACL for the VPC
    Value: !GetAtt VPC.DefaultNetworkAcl

  DefaultSecurityGroup:
    Description: The ID of the default security group for the VPC
    Value: !GetAtt VPC.DefaultSecurityGroup
```

## deployment-file

### deployment-file.yaml

```yaml
template-file-path: ./vpc.yaml 
```

## 学び

`vpc.yaml`のOutPutで`!GetAtt VPC.DefaultNetworkAcl`を使っていますが、DefaultNetworkAclを参照するには`ec2:DescribeNetworkAcls`のPolicyが必要です。そこで、その他のアトリビュートの値を取得するときにも、CloudFormationをDeployするRoleに対して、都度必要なPolicyを適用していく必要があることを学びました。今まではローカルからAdmin権限でDeployしていたので、このような詳細な権限については気づきませんでした。良い学びとなりました。
