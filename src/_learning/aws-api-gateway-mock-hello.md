---
title: "API Gatewayでモックレスポンスを返すAPIの作成方法"
date: 2024-9-12T14:46:00
mermaid: true
weight: 7
tags:
  - AWS
  - API Gateway
  - CloudFormation
  - Mock Integration
  - Infrastructure as Code
description: "AWS API Gatewayを使用し、モック統合機能で静的レスポンスを返すAPIをCloudFormationで作成する方法を解説。簡単なステップでAPI構築可能。"
---

## API GatewayでMockを使って"hello"を返すAPIの作成

AWS API Gatewayは、Lambda関数や他のバックエンドを必要とせずに、APIリクエストに対して静的なレスポンスを返す「モック」機能を使って、
単純に"hello"メッセージを返すAPIをCloudFormationテンプレートで作成する方法を紹介します。

### CloudFormationテンプレート

このAPIを作成するためのCloudFormationテンプレートです。このテンプレートを使用することで、API Gatewayがモックレスポンスを返す設定が自動的に作成されます。

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  RestApi:
    Type: AWS::ApiGateway::RestApi
    Properties: 
      Name: HelloApi
      Description: API Gateway returning "hello" without using Lambda
      EndpointConfiguration:
        Types:
          - EDGE

  ApiResource:
    Type: AWS::ApiGateway::Resource
    Properties:
      ParentId: !GetAtt RestApi.RootResourceId
      PathPart: hello
      RestApiId: !Ref RestApi

  ApiGatewayMethod:
    Type: AWS::ApiGateway::Method
    Properties:
      AuthorizationType: NONE
      HttpMethod: GET
      RestApiId: !Ref RestApi
      ResourceId: !Ref ApiResource
      Integration:
        Type: MOCK
        IntegrationResponses:
          - StatusCode: "200"
            ResponseTemplates:
              application/json: "{\"message\": \"OK\"}"
          - StatusCode: "500"
            ResponseTemplates:
              application/json: "{\"message\": \"Internal Server Error\"}"
        RequestTemplates:
          application/json: "{\"statusCode\": 200}"
      MethodResponses:
        - StatusCode: "200"
        - StatusCode: "500"

  ApiGatewayModel:
    Type: AWS::ApiGateway::Model
    Properties:
      ContentType: 'application/json'
      RestApiId: !Ref RestApi
      Schema: {}

  ApiGatewayDeployment:
    Type: AWS::ApiGateway::Deployment
    DependsOn: ApiGatewayMethod
    Properties:
      RestApiId: !Ref RestApi
      StageName: dev

Outputs:
  ApiUrl:
    Description: "Invoke URL for the API"
    Value: 
      Fn::Sub: "https://${RestApi}.execute-api.${AWS::Region}.amazonaws.com/dev/hello"
```
