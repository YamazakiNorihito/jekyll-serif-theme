---
title: "Amazon Elastic Container Serviceの基礎知識のメモ"
date: 2024-10-7T07:15:00
tags:
  - AWS
  - DynamoDB
  - NoSQL
description: "自分用のメモとして、ECSについて整理。設計に役立つベストプラクティスも含む"
---

[What is Amazon Elastic Container Service?](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html)を順番に読んでいく

## Amazon Elastic Container Service

Amazon Elastic Container Service (Amazon ECS) は、AWSが提供するコンテナ管理サービス。
コンテナアプリケーションのdeploy, manage, scale を簡単に行えるよう設計されており、
AWSの各種サービスやサードパーティツール（ECRやDocker）とも統合されています。

そのため、環境構築から運用までの作業をECSに任せることができ、開発者はアプリケーション開発に集中できるのが特徴です。

## ECS components

Amazon ECSは３つのlayerで構成される

1. **Capacity**: コンテナを実行するために必ず設定が必要なインフラストラクチャ
   1. 設定する選択肢（以下の3つのいずれか）
      1. Amazon EC2 instances
      2. AWS Fargate
      3. On-premises
2. **Controller**:ECS上で動作するアプリケーションの配置や管理を行うソフトウェア
3. **Provisioning**:ECSのリソースをセットアップ・管理できる手段
   1. AWS Management Console
   2. [AWS Command Line Interface (AWS CLI)](https://aws.amazon.com/cli/)
   3. [AWS SDKs](https://aws.amazon.com/developer/tools/#SDKs)
   4. [Copilot](https://github.com/aws/copilot-cli)
   5. [AWS CDK](https://docs.aws.amazon.com/ja_jp/cdk/v2/guide/home.html)

## Application lifecycle

![ECS Lifecycle](https://docs.aws.amazon.com/images/AmazonECS/latest/developerguide/images/ecs-lifecycle.png)

### 1. イメージのビルドと登録

1. **Dockerfile**: 各アプリケーション用にDockerfileを作成します。これには、必要なコード、ライブラリ、ツールが含まれます。
2. **Build Image**: Dockerfileをもとにコンテナイメージをビルドします。
3. **Amazon ECR**: 作成したイメージをAmazon ECRなどのコンテナレジストリに保存します。これにより、必要なときにイメージをダウンロードしてデプロイできます。

### 2. タスク定義

**ECS Task Definition**は、コンテナアプリケーションの設計図です。JSON形式のファイルで、アプリケーションを構成する1つ以上のコンテナとその設定を指定します。主な設定項目には以下が含まれます。

- **Image**: Amazon ECRなどのレジストリに保存されたコンテナイメージ。
- **Ports**: 開放するポートを指定します。
- **Data Volumes**: データの永続化やコンテナ間で共有するストレージを指定します。

### 3. クラスターにServiceまたはTaskとしてデプロイ

1. **Task**:
   - クラスター内で実行されるタスク定義のインスタンスです。
   - スタンドアロンで実行することも、サービスの一部として実行することも可能です。
   - タスクは一度実行されると完了するタイプと、常時稼働するタイプがあります。

2. **Service**:
   - クラスター内で指定した数のタスクを常に稼働させたい場合に使用します。
   - **Service Scheduler**がタスク数を維持するよう管理しており、タスクが失敗や停止した場合、タスク定義に基づいて新しいタスクを起動し、指定したタスク数を保ちます。

3. **Cluster**:
   - **Capacity Infrastructure**（例: EC2やFargate）上で実行されるTaskやServiceの論理的なグループです。

4. **Container Agent**:
   - Amazon ECSクラスター内の各**Container Instance**上で稼働します。
   - 実行中のタスクの状態やリソース使用量をAmazon ECSに送信します。
   - Amazon ECSからのリクエストに基づいてタスクの開始や停止を行います。

## getting-started

Amazon ECSを使ってコンテナのデプロイを試してみました。今回は、Amazon ECRにコンテナイメージを登録し、
それを使用してAmazon ECS上で実行するまでの手順をまとめました。

### Amazon ECRにコンテナイメージを登録

[create-container-image](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-container-image.html)

```bash
# create Dockerfile
touch Dockerfile # File content reference `ecs/Dockerfile`
docker build -t hello-world .
docker run -t -i -p 80:80 hello-world

# For cross-platform builds targeting Linux x86_64 (amd64) for Fargate
docker buildx build --platform linux/amd64 -t hello-world .

# create private repository
## aws ecr create-repository --repository-name hello-repository --region {region}
aws ecr create-repository --repository-name hello-repository --region ap-northeast-1 --profile workday

## Example output
###{
###    "repository": {
###        "repositoryArn": "arn:aws:ecr:ap-northeast-1:[aws_account_id]:repository/hello-repository",
###        "registryId": "[aws_account_id]",
###        "repositoryName": "hello-repository",
###        "repositoryUri": "[aws_account_id].dkr.ecr.ap-northeast-1.amazonaws.com/hello-repository",
###        "createdAt": "2024-11-12T06:39:19.706000+09:00",
###        "imageTagMutability": "MUTABLE",
###        "imageScanningConfiguration": {
###            "scanOnPush": false
###        },
###        "encryptionConfiguration": {
###            "encryptionType": "AES256"
###        }
###    }
###}

# To create a public repository
## aws ecr-public create-repository --repository-name hello-repository --region us-east-1 --profile workday

# image push
## docker tag hello-world {aws_account_id}.dkr.ecr.{region}.amazonaws.com/hello-repository
docker tag hello-world [aws_account_id].dkr.ecr.ap-northeast-1.amazonaws.com/hello-repository

## aws ecr get-login-password --region {region} | docker login --username AWS --password-stdin {aws_account_id}.dkr.ecr.{region}.amazonaws.com
aws ecr get-login-password --region ap-northeast-1 --profile workday | docker login --username AWS --password-stdin [aws_account_id].dkr.ecr.ap-northeast-1.amazonaws.com

## Expected output
### Login Succeeded

## docker push {aws_account_id}.dkr.ecr.{region}.amazonaws.com/hello-repository
docker push [aws_account_id].dkr.ecr.ap-northeast-1.amazonaws.com/hello-repository

```

### Amazon ECSにデプロイする

```bash
aws cloudformation create-stack --stack-name ecs-stack --template-body file://template.yaml --parameters file://parameters.json --region ap-northeast-1 --profile workday --capabilities CAPABILITY_NAMED_IAM
```

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: ECS Fargate Sample Template (without ALB, uses default VPC)

Parameters:
  VPCId:
    Type: AWS::EC2::VPC::Id
    Description: VPC ID to use (default VPC)
    Default: default
  SubnetIds:
    Type: List<AWS::EC2::Subnet::Id>
    Description: List of subnet IDs (comma-separated)
  AssignPublicIp:
    Type: String
    Default: ENABLED
    AllowedValues:
      - ENABLED
      - DISABLED
    Description: Assign public IP to ECS task

Resources:
  ECSCluster:
    Type: AWS::ECS::Cluster
    Properties:
      ClusterName: !Sub '${AWS::StackName}-cluster'

  ECSTaskExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Sub '${AWS::StackName}-ecsTaskExecutionRole'
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - ecs-tasks.amazonaws.com
            Action:
              - sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

  TaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: !Sub '${AWS::StackName}-task'
      Cpu: '256'
      Memory: '512'
      NetworkMode: awsvpc
      RequiresCompatibilities:
        - FARGATE
      RuntimePlatform:
        OperatingSystemFamily: LINUX
      ExecutionRoleArn: !GetAtt ECSTaskExecutionRole.Arn
      ContainerDefinitions:
        - Name: hello-container
          Image: [aws_account_id].dkr.ecr.ap-northeast-1.amazonaws.com/hello-repository
          Essential: true
          PortMappings:
            - ContainerPort: 80
              Protocol: tcp

  ECSSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: "ECS Task Security Group"
      VpcId: !Ref VPCId
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0

  Service:
    Type: AWS::ECS::Service
    Properties:
      Cluster: !Ref ECSCluster
      ServiceName: !Sub '${AWS::StackName}-service'
      TaskDefinition: !Ref TaskDefinition
      LaunchType: FARGATE
      DesiredCount: 1
      NetworkConfiguration:
        AwsvpcConfiguration:
          AssignPublicIp: !Ref AssignPublicIp
          SecurityGroups:
            - !Ref ECSSecurityGroup
          Subnets: !Ref SubnetIds
```

parameters.json

```json
[
  {
    "ParameterKey": "VPCId",
    "ParameterValue": "vpc-xxxxxxxxxxxxxxxxx"
  },
  {
    "ParameterKey": "SubnetIds",
    "ParameterValue": "subnet-xxxxxxxxxxxxxxxxx"
  },
  {
    "ParameterKey": "AssignPublicIp",
    "ParameterValue": "ENABLED"
  }
]

```
