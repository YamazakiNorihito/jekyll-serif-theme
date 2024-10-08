---
title: "ALB経由でPrivate API GatewayにリクエストするためのCloudFormationメモ"
date: 2024-8-23T07:00:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - AWS
  - API Gateway
  - Application Load Balancer (ALB)
  - VPC
  - CloudFormation
  - REST API
  - VPCエンドポイント
  - プライベートAPI
  - ALBリスナールール
  - インフラ構成
  - ネットワークセキュリティ
  - AWSベストプラクティス
description: ""
---

この記事では、ALB（Application Load Balancer）を経由して、プライベートなAPI Gatewayにリクエストを送信する構成についてまとめています。ALB、VPCエンドポイント、プライベートAPI Gateway、およびListenerRuleを活用して構築しました。背景として、リクエストのエントリーポイントをALBにする必要があったため、このような設計を採用しました。

以下に、構成を実現するためのCloudFormationテンプレートを紹介します。

## vpc-endpoint-template.yaml

最初に、プライベートAPI GatewayにアクセスするためのVPCエンドポイントを設定します。

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: CloudFormation template to create an interface VPC endpoint for private access to API Gateway

Parameters:
  VpcId:
    Type: String
    Description: The ID of the VPC
  PublicSubnets:
    Type: CommaDelimitedList
  AlbSecurityGroupId:
    Type: String
    Description: The ID of the security group associated with the Application Load Balancer (ALB)

Resources:
  ApiGatewayVPCEndpoint:
    Type: 'AWS::EC2::VPCEndpoint'
    Properties:
      VpcId: !Ref VpcId
      ServiceName: !Sub com.amazonaws.${AWS::Region}.execute-api
      SubnetIds: !Ref PublicSubnets
      PrivateDnsEnabled: true
      VpcEndpointType: Interface
      SecurityGroupIds:
        - !Ref AlbSecurityGroupId

Outputs:
  ApiGatewayVPCEndpointId:
    Description: The ID of the VPC endpoint for API Gateway
    Value: !Ref ApiGatewayVPCEndpoint
```

## private-api-gateway-template.yaml

次に、プライベートAPI Gatewayを構成します。VPCエンドポイントを利用してアクセスするための設定を行います。

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: CloudFormation template for a private REST API using an interface VPC endpoint

Parameters:
  VpcEndpointIds:
    Type: CommaDelimitedList
    Description: The first VPC Endpoint ID to be used for the API Gateway.

Resources:
  PrivateRestApi:
    Type: AWS::ApiGateway::RestApi
    Properties: 
      Name: PrivateHelloApi
      Description: Private API Gateway that returns "hello" without using Lambda.
      EndpointConfiguration:
        Types:
          - PRIVATE
        VpcEndpointIds: !Ref VpcEndpointIds
      Policy:
        Version: '2012-10-17'
        Statement:
          - Effect: Deny
            Principal: '*'
            Action: 'execute-api:Invoke'
            Resource: !Sub 'arn:aws:execute-api:${AWS::Region}:*:*/*/*/*'
            Condition:
              StringNotEquals:
                aws:SourceVpce: !Ref VpcEndpointIds
          - Effect: Allow
            Principal: '*'
            Action: 'execute-api:Invoke'
            Resource: !Sub 'arn:aws:execute-api:${AWS::Region}:*:*/*/*/*'

  HelloResource:
    Type: AWS::ApiGateway::Resource
    Properties:
      ParentId: !GetAtt PrivateRestApi.RootResourceId
      PathPart: hello
      RestApiId: !Ref PrivateRestApi

  GetHelloMethod:
    Type: AWS::ApiGateway::Method
    Properties:
      AuthorizationType: NONE
      HttpMethod: GET
      RestApiId: !Ref PrivateRestApi
      ResourceId: !Ref HelloResource
      Integration:
        Type: MOCK
        IntegrationResponses:
          - StatusCode: "200"
            ResponseParameters:
              method.response.header.Access-Control-Allow-Origin: "'*'"
              method.response.header.Access-Control-Allow-Headers: "'content-type,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
              method.response.header.Access-Control-Allow-Methods: "'OPTIONS,GET'"
            ResponseTemplates:
              application/json: "{\"message\": \"OK\"}"
          - StatusCode: "500"
            ResponseTemplates:
              application/json: "{\"message\": \"Internal Server Error\"}"
        RequestTemplates:
          application/json: "{\"statusCode\": 200}"
      MethodResponses:
        - StatusCode: "200"
          ResponseParameters:
            method.response.header.Access-Control-Allow-Origin: true
            method.response.header.Access-Control-Allow-Headers: true
            method.response.header.Access-Control-Allow-Methods: true
        - StatusCode: "500"

  OptionsHelloMethod:
    Type: AWS::ApiGateway::Method
    Properties:
      RestApiId: !Ref PrivateRestApi
      ResourceId: !Ref HelloResource
      HttpMethod: "OPTIONS"
      AuthorizationType: NONE
      Integration:
        Type: MOCK
        RequestTemplates:
          application/json: "{\"statusCode\": 200}"
        IntegrationResponses:
          - StatusCode: 200
            ResponseParameters:
              method.response.header.Access-Control-Allow-Origin: "'*'"
              method.response.header.Access-Control-Allow-Headers: "'content-type,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
              method.response.header.Access-Control-Allow-Methods: "'OPTIONS,GET'"
            ResponseTemplates:
              application/json: ""
      MethodResponses:
        - StatusCode: 200
          ResponseParameters:
            method.response.header.Access-Control-Allow-Origin: true
            method.response.header.Access-Control-Allow-Headers: true
            method.response.header.Access-Control-Allow-Methods: true

  HelloApiModel:
    Type: AWS::ApiGateway::Model
    Properties:
      ContentType: 'application/json'
      RestApiId: !Ref PrivateRestApi
      Schema: {}

  ApiGatewayDeployment:
    Type: AWS::ApiGateway::Deployment
    DependsOn: GetHelloMethod
    Properties:
      RestApiId: !Ref PrivateRestApi
      StageName: dev

Outputs:
  PrivateApiUrl:
    Description: "Invoke URL for the Private API"
    Value: 
      Fn::Sub: "https://${PrivateRestApi}.execute-api.${AWS::Region}.amazonaws.com/dev/hello"
```

## alb-attach-template.yaml

最後に、ALBとターゲットグループを設定し、ALBからAPI Gatewayへのトラフィックを転送します。

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Parameters:
  VpcId:
    Type: String
    Description: The ID of the VPC
  TargetIps:
    Type: CommaDelimitedList
    Description: The IP address
  AlbListenerArn:
    Type: String
    Description: The ARN of the Application Load Balancer (ALB) listener

Resources:
  HelloApiTargetGroup:
    Type: 'AWS::ElasticLoadBalancingV2::TargetGroup'
    Properties: 
      Name: 'HelloApiTargetGroup'
      TargetType: 'ip'
      Protocol: 'HTTPS'
      Port: 443
      VpcId: !Ref VpcId
      HealthCheckProtocol: 'HTTPS'
      HealthCheckPort: '443'
      HealthCheckPath: '/200,403'
      HealthCheckIntervalSeconds: 30
      HealthCheckTimeoutSeconds: 5
      HealthyThresholdCount: 5
      UnhealthyThresholdCount: 2
      Matcher:
        HttpCode: '200,403'
      Targets:
        - Id: !Select [0, !Ref TargetIps]
          Port: 443
        - Id: !Select [1, !Ref TargetIps]
          Port: 443

  HelloApiListenerRule:
    Type: 'AWS::ElasticLoadBalancingV2::ListenerRule'
    Properties:
      Actions:
        - Type: 'forward'
          TargetGroupArn: !Ref HelloApiTargetGroup
      Conditions:
        - Field: 'path-pattern'
          Values:
            - '/dev/*'
      ListenerArn: !Ref AlbListenerArn
      Priority: 30
```

## 参考にしたサイト

- [Rest API](https://docs.aws.amazon.com/ja_jp/whitepapers/latest/best-practices-api-gateway-private-apis-integration/rest-api.html)
- [How Amazon VPC works](https://docs.aws.amazon.com/vpc/latest/userguide/how-it-works.html)
- [プライベートエンドポイントと Application Load Balancer を使用して、Amazon API Gateway API を内部 Web サイトにデプロイする](https://docs.aws.amazon.com/ja_jp/prescriptive-guidance/latest/patterns/deploy-an-amazon-api-gateway-api-on-an-internal-website-using-private-endpoints-and-an-application-load-balancer.html)
- [API Gateway のプライベート REST API](https://docs.aws.amazon.com/ja_jp/apigateway/latest/developerguide/apigateway-private-apis.html)
- [プライベート API の呼び出し](https://docs.aws.amazon.com/ja_jp/apigateway/latest/developerguide/apigateway-private-api-test-invoke-url.html)
