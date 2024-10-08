---
title: "AWS Elastic BeanstalkでDocker環境を構築するためのCloudFormationテンプレート"
date: 2024-7-31T15:00:00
weight: 4
categories:
  - aws
  - cloud-service
description: ""
---

AWS Elastic BeanstalkでDocker環境を構築するためのCloudFormationテンプレートのサンプルを紹介します。
このテンプレートでは、Dockerコンテナを使用したアプリケーションのデプロイをサポートしています。
また、テンプレートファイルをネストして、各種リソースの定義を分割して管理する構成になっています。

## ファイル構成

以下は、サンプルプロジェクトのファイル構成です。

```bash
$ tree 
.
├── Dockerrun.aws.json
├── deploy.sh
├── eb
│   └── template.yaml
├── iam
│   ├── eb.yaml
│   ├── ec2.yaml
└── template.yaml
```

## eb/template.yaml

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Parameters:
  TemplateBucket:
    Type: String
  ENV:
    Type: String
    AllowedValues:
      - develop
      - staging
      - production
  SolutionStackName:
    Type: String
  InstanceType:
    Type: String
  EBRoleArn:
    Type: String
  EC2RoleArn:
    Type: String
  VPCId:
    Type: String
  Subnets:
    Type: String
  EC2KeyName:
    Type: String

Resources:
  Application:
    Type: "AWS::ElasticBeanstalk::Application"
    Properties:
      ApplicationName: !Sub "identity-server-${ENV}"

  ApplicationVersion:
    Type: "AWS::ElasticBeanstalk::ApplicationVersion"
    Properties:
      ApplicationName: !Ref Application
      SourceBundle:
        S3Bucket: !Ref TemplateBucket
        S3Key: "Dockerrun.aws.json"

  SecurityGroup:
    Type: "AWS::EC2::SecurityGroup"
    Properties:
      GroupName: !Sub "${Application}-sg"
      GroupDescription: "Security group for the Elastic Beanstalk environment"
      VpcId: !Ref VPCId
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: "0.0.0.0/0"
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: "0.0.0.0/0"
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: "0.0.0.0/0"

  Environment:
    Type: "AWS::ElasticBeanstalk::Environment"
    Properties:
      EnvironmentName: !Sub "${Application}"
      CNAMEPrefix: !Sub "${Application}"
      ApplicationName: !Ref Application
      VersionLabel: !Ref ApplicationVersion
       # https://docs.aws.amazon.com/ja_jp/elasticbeanstalk/latest/platforms/platforms-supported.html#platforms-supported.docker
      SolutionStackName: !Ref SolutionStackName
      # https://docs.aws.amazon.com/ja_jp/elasticbeanstalk/latest/dg/command-options.html
      OptionSettings:
        - Namespace: "aws:elasticbeanstalk:environment"
          OptionName: "EnvironmentType"
          Value: "SingleInstance"
        - Namespace: "aws:elasticbeanstalk:environment"
          OptionName: "ServiceRole"
          Value: !Ref EBRoleArn
        - Namespace: "aws:autoscaling:launchconfiguration"
          OptionName: "InstanceType"
          Value: !Ref InstanceType
        - Namespace: "aws:autoscaling:launchconfiguration"
          OptionName: "EC2KeyName"
          Value: !Ref EC2KeyName
        - Namespace: "aws:ec2:vpc"
          OptionName: "VPCId"
          Value: !Ref VPCId
        - Namespace: "aws:ec2:vpc"
          OptionName: "Subnets"
          Value: !Ref Subnets
        - Namespace: "aws:autoscaling:launchconfiguration"
          OptionName: "IamInstanceProfile"
          Value: !Ref EC2RoleArn
        - Namespace: "aws:autoscaling:launchconfiguration"
          OptionName: "SecurityGroups"
          Value: !Ref SecurityGroup

Outputs:
  ApplicationName:
    Value: !Ref Application
  EnvironmentName:
    Value: !Ref Environment
```

## iam

### eb.yaml

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Parameters:
  ENV:
    Type: String
Resources:
  Role:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Sub "identity-server-${ENV}-eb"
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: "Allow"
            Principal: 
              Service: "elasticbeanstalk.amazonaws.com"
            Action: "sts:AssumeRole"
      Path: '/'
      ManagedPolicyArns: 
        - "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        - "arn:aws:iam::aws:policy/AmazonS3FullAccess"
        - "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
        - "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
Outputs:
  Name:
    Value: !Ref 'Role'
  Arn:
    Value: !GetAtt 'Role.Arn'
```

### ec2.yaml

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Parameters:
  ENV:
    Type: String
Resources:
  Role:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Sub "identity-server-${ENV}-ec2"
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: "Allow"
            Principal: 
              Service: "ec2.amazonaws.com"
            Action: "sts:AssumeRole"
      Path: '/'
      ManagedPolicyArns:
        - "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        - "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
        - "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
        - "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
        - "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
        - "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
        - "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  InstanceProfile:
    Type: AWS::IAM::InstanceProfile
    Properties: 
      Roles:
        - !Ref Role
Outputs:
  Name:
    Value: !Ref  'Role'
  Arn:
    Value: !GetAtt 'Role.Arn'
  Profile:
    Value: !GetAtt 'InstanceProfile.Arn'
```

## めも

- [Docker 公式イメージが Amazon Elastic Container Registry Public で利用可能になりました](https://aws.amazon.com/jp/blogs/news/docker-official-images-now-available-on-amazon-elastic-container-registry-public/)
- [CloudFormation のパラメータを JSON ファイルで簡単に渡す方法](https://agaroot-itp.com/blog/706/)
