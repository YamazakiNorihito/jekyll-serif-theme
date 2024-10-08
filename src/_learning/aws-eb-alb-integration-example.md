---
title: "AWS Elastic BeanstalkとApplication Load Balancerを連携するCloudFormationテンプレート"
date: 2024-8-8T13:35:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - AWS
  - Elastic Beanstalk
  - Application Load Balancer
  - CloudFormation
  - Docker
  - EC2
  - Auto Scaling
  - Infrastructure as Code
description: ""
---

# AWS Elastic BeanstalkとApplication Load Balancerを連携するCloudFormationテンプレート

今回はAWS Elastic Beanstalk（以下EB）とApplication Load Balancer（以下ALB）を連携して、Dockerコンテナを利用したアプリケーションをデプロイするためのCloudFormationテンプレートを紹介します。このテンプレートは、ALBを使用してトラフィックを管理し、必要に応じてAuto Scalingグループを利用することでスケーラビリティを確保します。

## CloudFormationテンプレートの概要

以下にテンプレートの内容を示します。このテンプレートは、必要なパラメータとリソースを定義し、EBとALBを設定します。

### パラメータ

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Parameters:
  TemplateBucket:
    Type: String
    Description: "The S3 bucket where the templates are stored"
  ENV:
    Type: String
    Description: "The environment for the application."
    AllowedValues:
      - develop
      - staging
      - production
  # https://docs.aws.amazon.com/ja_jp/elasticbeanstalk/latest/platforms/platforms-supported.html#platforms-supported.docker
  SolutionStackName:
    Type: String
    Description: "The name of the solution stack used by Elastic Beanstalk, such as '64bit Amazon Linux 2023 v4.3.5 running Docker'."
  # https://aws.amazon.com/jp/ec2/instance-types/
  InstanceType:
    Type: String
    Description: "The EC2 instance type, e.g., 't3.micro'."
  EBRoleArn:
    Type: String
    Description: "The ARN of the Elastic Beanstalk service role. This role requires the following managed policies: AmazonSSMManagedInstanceCore, AmazonS3FullAccess, AWSElasticBeanstalkEnhancedHealth, AWSElasticBeanstalkService."
  EC2RoleArn:
    Type: String
    Description: "The ARN of the EC2 instance profile. This profile requires the following managed policies: AmazonSSMManagedInstanceCore, AWSElasticBeanstalkMulticontainerDocker, AWSElasticBeanstalkWebTier, AWSElasticBeanstalkWorkerTier, CloudWatchLogsFullAccess, AmazonS3ReadOnlyAccess, AmazonEC2ContainerRegistryReadOnly."
  VPCId:
    Type: String
    Description: "The ID of the VPC in which the Elastic Beanstalk environment will be launched."
  Subnets:
    Type: String
    Description: "A comma-separated list of subnet IDs within the specified VPC."
  EC2KeyName:
    Type: String
    Description: "The name of the EC2 key pair to enable SSH access to the instances."
  ElasticacheSecurityGroupId:
    Type: String
    Description: "The security group ID for the ElastiCache cluster used by the application."
  SharedLoadBalancerArn:
    Type: String
    Description: "The ARN of the shared Application Load Balancer."
  ALBSecurityGroupId:
    Type: String
    Description: "The security group ID associated with the Application Load Balancer."
  HostHeaders:
    Type: String
    Description: "A comma-separated list of host headers for routing traffic to the application."

Resources:
  Application:
    Type: "AWS::ElasticBeanstalk::Application"
    Properties:
      ApplicationName: !Sub "app-server-${ENV}"

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
  
  IdentityServerSecurityGroupInboundRule:
    Type: "AWS::EC2::SecurityGroupIngress"
    Properties:
      GroupId: !GetAtt SecurityGroup.GroupId
      IpProtocol: tcp
      FromPort: 80
      ToPort: 80
      SourceSecurityGroupId: !Ref ALBSecurityGroupId
      Description: "security group for ALB"
  
  ElasticacheSecurityGroupInboundRule:
    Type: "AWS::EC2::SecurityGroupIngress"
    Properties:
      GroupId: !Ref ElasticacheSecurityGroupId
      IpProtocol: tcp
      FromPort: 6379
      ToPort: 6379
      SourceSecurityGroupId: !GetAtt SecurityGroup.GroupId
      Description: "security group for app-server"

  Environment:
    Type: "AWS::ElasticBeanstalk::Environment"
    Properties:
      EnvironmentName: !Sub "${Application}"
      CNAMEPrefix: !Sub "${Application}-app-com"
      ApplicationName: !Ref Application
      VersionLabel: !Ref ApplicationVersion
       # https://docs.aws.amazon.com/ja_jp/elasticbeanstalk/latest/platforms/platforms-supported.html#platforms-supported.docker
      SolutionStackName: !Ref SolutionStackName
      # https://docs.aws.amazon.com/ja_jp/elasticbeanstalk/latest/dg/command-options.html
      OptionSettings:
        # リクエストを直接受けるかLBを挟むかの設定
        - Namespace: "aws:elasticbeanstalk:environment"
          OptionName: "EnvironmentType"
          Value: "LoadBalanced"
        - Namespace: "aws:elasticbeanstalk:environment"
          OptionName: "ServiceRole"
          Value: !Ref EBRoleArn
        - Namespace: "aws:elasticbeanstalk:environment"
          OptionName: "LoadBalancerType"
          Value: "application"
        # 共有または専有どちらのLBに接続するのか設定
        # https://docs.aws.amazon.com/ja_jp/elasticbeanstalk/latest/dg/command-options-general.html#command-options-general-elasticbeanstalkenvironment
        - Namespace: "aws:elasticbeanstalk:environment"
          OptionName: "LoadBalancerIsShared"
          Value: "true"
        - Namespace: "aws:autoscaling:launchconfiguration"
          OptionName: "InstanceType"
          Value: !Ref InstanceType
        - Namespace: "aws:autoscaling:launchconfiguration"
          OptionName: "EC2KeyName"
          Value: !Ref EC2KeyName
        - Namespace: "aws:autoscaling:launchconfiguration"
          OptionName: "IamInstanceProfile"
          Value: !Ref EC2RoleArn
        # セキュリティグループはデフォルトでEBのものが作成されます。
        # 追加でACLを操作したい場合は、別途セキュリティグループを作成してアタッチする
        - Namespace: "aws:autoscaling:launchconfiguration"
          OptionName: "SecurityGroups"
          Value: !Ref SecurityGroup
        - Namespace: "aws:ec2:vpc"
          OptionName: "VPCId"
          Value: !Ref VPCId
        - Namespace: "aws:ec2:vpc"
          OptionName: "Subnets"
          Value: !Ref Subnets
        # Auto Scaling グループのインスタンスにパブリック IP アドレスを割り当てるためのオプション
        # https://docs.aws.amazon.com/ja_jp/elasticbeanstalk/latest/dg/command-options-general.html#command-options-general-ec2vpc
        - Namespace: "aws:ec2:vpc"
          OptionName: "AssociatePublicIpAddress"
          Value: "true"
        - Namespace: "aws:elbv2:loadbalancer"
          OptionName: "SharedLoadBalancer"
          Value: !Ref SharedLoadBalancerArn
        - Namespace: "aws:autoscaling:asg"
          OptionName: "MinSize"
          Value: "1"
        - Namespace: "aws:autoscaling:asg"
          OptionName: "MaxSize"
          Value: "4"
        - Namespace: "aws:autoscaling:asg"
          OptionName: "Cooldown"
          Value: "300" # 5 min
        - Namespace: "aws:autoscaling:trigger"
          OptionName: "MeasureName"
          Value: "CPUUtilization"
        - Namespace: "aws:autoscaling:trigger"
          OptionName: "Statistic"
          Value: "Average"
        - Namespace: "aws:autoscaling:trigger"
          OptionName: "Unit"
          Value: "Percent"
        - Namespace: "aws:autoscaling:trigger"
          OptionName: "Period"
          Value: "3" # 3 min
        - Namespace: "aws:autoscaling:trigger"
          OptionName: "EvaluationPeriods"
          Value: "3"
        - Namespace: "aws:autoscaling:trigger"
          OptionName: "UpperThreshold"
          Value: "80" # 80%
        - Namespace: "aws:autoscaling:trigger"
          OptionName: "UpperBreachScaleIncrement"
          Value: "1"
        - Namespace: "aws:autoscaling:trigger"
          OptionName: "LowerThreshold"
          Value: "20" # 20%
        - Namespace: "aws:autoscaling:trigger"
          OptionName: "LowerBreachScaleIncrement"
          Value: "-1"
        - Namespace: "aws:autoscaling:updatepolicy:rollingupdate"
          OptionName: "RollingUpdateEnabled"
          Value: "true"
        - Namespace: "aws:autoScaling:updatepolicy:rollingupdate"
          OptionName: "MaxBatchSize"
          Value: "1"
        - Namespace: "aws:autoScaling:updatepolicy:rollingupdate"
          OptionName: "MinInstancesInService"
          Value: "1"
        - Namespace: "aws:autoScaling:updatepolicy:rollingupdate"
          OptionName: "RollingUpdateType"
          Value: "Health"
        - Namespace: "aws:autoScaling:updatepolicy:rollingupdate"
          OptionName: "pauseTime"
          Value: "PT3M"

        # アプリケーションコードのデプロイポリシーを設定
        - Namespace: "aws:elasticbeanstalk:command"
          OptionName: "DeploymentPolicy"
          Value: "Rolling"
        - Namespace: "aws:elasticbeanstalk:command"
          OptionName: "Timeout"
          Value: "600" # Unit: seconds
        - Namespace: "aws:elasticbeanstalk:command"
          OptionName: "BatchSizeType"
          Value: "Fixed"
        - Namespace: "aws:elasticbeanstalk:command"
          OptionName: "BatchSize"
          Value: "1"
        - Namespace: "aws:elasticbeanstalk:command"
          OptionName: "IgnoreHealthCheck"
          Value: "false"
        # リクエストの流れ client -> (https) -> Application Load balancer -> (http) -> EC2(application)
        - Namespace: "aws:elasticbeanstalk:environment:process:default"
          OptionName: "Port"
          Value: "80"
        - Namespace: "aws:elasticbeanstalk:environment:process:default"
          OptionName: "Protocol"
          Value: "HTTP"
        - Namespace: "aws:elasticbeanstalk:environment:process:default"
          OptionName: "HealthCheckPath"
          Value: "/auth/health"
        - Namespace: "aws:elasticbeanstalk:environment:process:default"
          OptionName: "HealthCheckInterval"
          Value: "30" # ヘルスチェックの実行間隔（秒）
        - Namespace: "aws:elasticbeanstalk:environment:process:default"
          OptionName: "HealthCheckTimeout"
          Value: "5" # ヘルスチェックのタイムアウト（秒）
        - Namespace: "aws:elasticbeanstalk:environment:process:default"
          OptionName: "HealthyThresholdCount"
          Value: "5" # 正常とみなすまでの連続成功回数
        - Namespace: "aws:elasticbeanstalk:environment:process:default"
          OptionName: "UnhealthyThresholdCount"
          Value: "2" # 異常とみなすまでの連続失敗回数
        # アプリケーションのインスタンスログストリーミングを設定
        - Namespace: "aws:elasticbeanstalk:cloudwatch:logs"
          OptionName: "StreamLogs"
          Value: "true"
        - Namespace: "aws:elasticbeanstalk:cloudwatch:logs"
          OptionName: "DeleteOnTerminate"
          Value: "true"
        - Namespace: "aws:elasticbeanstalk:cloudwatch:logs"
          OptionName: "RetentionInDays"
          Value: "5"
        
        # リスナールールの設定
        # 下記を参考にした
        # https://docs.aws.amazon.com/ja_jp/elasticbeanstalk/latest/dg/environments-cfg-alb-shared.html#environments-cfg-alb-shared-ebcli
        # リスナールールはルートとPathPatternsの２つのルールが作成される
        - Namespace: "aws:elbv2:listener:443"
          OptionName: "Rules"
          Value: "default,apprule" # defaultは必須で設定しないとエラーになる。

        - Namespace: "aws:elbv2:listenerrule:apprule"
          OptionName: "PathPatterns"
          Value: "/auth/*"
        # https://docs.aws.amazon.com/ja_jp/elasticbeanstalk/latest/dg/environments-cfg-alb-shared.html#environments-cfg-alb-shared-intro
        # > Elastic Beanstalk は、ロードバランサーを共有する環境間でルールの優先順位設定を相対的なものとして扱い、作成時に絶対的な優先順位にマッピングします。
        #   と書いてある通り、設定通りの優先順位になるわけではない。
        - Namespace: "aws:elbv2:listenerrule:apprule"
          OptionName: "Priority"
          Value: "32"
        - Namespace: "aws:elbv2:listenerrule:apprule"
          OptionName: "HostHeaders"
          Value: !Ref HostHeaders
        - Namespace: "aws:elbv2:listenerrule:apprule"
          OptionName: "Process"
          Value: "default"
        
        # アプリケーションの環境変数を設定
        - Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: "KC_DB_URL_HOST"
          Value: !Ref KcDbURLHost
        - Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: "KC_DB_URL_DATABASE"
          Value: "keycloak"
        - Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: "KC_DB_USERNAME"
          Value: !Ref KcDbUsername
        - Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: "KC_DB_PASSWORD"
          Value: !Ref KcDbPassword
        - Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: "KC_HOSTNAME_URL"
          Value: !Sub "${LoadBalancerURL}/auth"
        - Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: "KC_HOSTNAME_ADMIN_URL"
          Value: !Sub "${LoadBalancerURL}/auth"
        - Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: "KC_HOSTNAME_STRICT"
          Value: "true"
        - Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: "KC_HOSTNAME_STRICT_BACKCHANNEL"
          Value: "true"
        - Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: "KC_PROXY"
          Value: "edge"
        - Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: "KC_PROXY_HEADERS"
          Value: "xforwarded"
        - Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: "KC_HTTP_ENABLED"
          Value: "true"
        - Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: "KEYCLOAK_ADMIN"
          Value: !Ref KeycloakAdmin
        - Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: "KEYCLOAK_ADMIN_PASSWORD"
          Value: !Ref KeycloakAdminPassword
        - Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: "TZ"
          Value: "Asia/Tokyo"
        - Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: "JGROUPS_DISCOVERY_PROTOCOL"
          Value: "JDBC_PING"
        - Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: "KC_CACHE"
          Value: "ispn"
        - Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: "KC_LOG_LEVEL"
          Value: "info"

Outputs:
  ApplicationName:
    Value: !Ref Application
  EnvironmentName:
    Value: !Ref Environment
```
