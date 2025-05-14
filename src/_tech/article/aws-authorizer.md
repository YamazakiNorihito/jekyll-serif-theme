---

title: "API Gateway Lambda Authorizerによるカスタム認証の導入"
date: 2025-5-13T07:00:00
weight: 4
categories:
  - aws
  - cloud-service
  - api-gateway
description: "API Gateway の Lambda Authorizer を使って、ヘッダーに含まれるトークンを検証し、細かい認可制御を実現する方法を解説。"
tags:
  - AWS
  - API Gateway
  - Lambda Authorizer
  - 認証
  - セキュリティ
  - インフラストラクチャ
  - オートメーション
---

## はじめに

AWS API Gateway のカスタム認証機能である **Lambda Authorizer**（は、リクエストヘッダーやクエリ文字列、ステージ変数などに含まれる情報をもとに、細かい認可ロジックを自分で実装できる強力な仕組みです。
本記事では、公式 blueprints の [Go サンプル](https://github.com/awslabs/aws-apigateway-lambda-authorizer-blueprints/blob/master/blueprints/go/main.go)をベースに、CloudFormation テンプレートを使って Lambda Authorizer をデプロイし、API Gateway の各メソッドに紐づけるまでの流れをまとめます。

---

## 全体構成イメージ

1. **Lambda Authorizer（認証用関数）** を用意
2. CloudFormation テンプレートで **Authorizer リソース** を作成
3. API Gateway の各メソッドに **CUSTOM** タイプの認証を設定
4. デプロイ＆テスト

---

## 1. Lambda Authorizer の準備

まずは、AWS Labs が提供する Go のサンプルコードをベースに、簡易的なトークン検証ロジックを持つ Lambda 関数を用意します。

* リポジトリ：[awslabs/aws-apigateway-lambda-authorizer-blueprints/blueprints/go/main.go](https://github.com/awslabs/aws-apigateway-lambda-authorizer-blueprints/blob/master/blueprints/go/main.go)
* 動作：リクエストヘッダーの `Authorization`（もしくは `x-access-token`）に適当な文字列を入れて “allow” を返すだけのシンプルな実装

この Lambda 関数をデプロイし、**ARN**（実行のための識別子）を控えておきます。

---

## 2. `AWS::ApiGateway::Authorizer` リソースの作成

以下の CloudFormation テンプレートを参考に、`Authorizer` リソースを定義します。
`AuthorizerUri` には先ほど控えた Lambda 関数の ARN を指定し、`IdentitySource` でトークン取得先のヘッダー名を設定します。

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Parameters:
  LambdaAuthorizerArn:
    Type: String
  RestApiId:
    Type: String

Resources:
  Authorizer:
    Type: AWS::ApiGateway::Authorizer
    Properties:
      AuthorizerResultTtlInSeconds: 300
      AuthorizerUri: !Sub "arn:${AWS::Partition}:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${LambdaAuthorizerArn}/invocations"
      IdentitySource: method.request.header.Authorization
      #IdentityValidationExpression: '^Bearer [-0-9a-zA-Z\.]*$'
      Name: First_Token_Custom_Authorizer
      RestApiId: !Ref RestApiId
      Type: TOKEN
  AlarmAuthorizerLambdaInvokePermission:
    Type: AWS::Lambda::Permission
    Properties:
      FunctionName: !Ref LambdaAuthorizerArn
      Action: lambda:InvokeFunction
      Principal: apigateway.amazonaws.com
      SourceArn: !Sub "arn:aws:execute-api:${AWS::Region}:${AWS::AccountId}:${RestApiId}/authorizers/${Authorizer}"

Outputs:
  AuthorizerId:
    Value: !Ref Authorizer
```

---

## 3. API Gateway メソッドへの組み込み

次に、REST API の各メソッドに対して、先ほど作成した Authorizer を紐づけます。AuthorizationType は `CUSTOM`、AuthorizerId には出力された ID を指定します。

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Parameters:
  HttpMethod:
    Type: String
    AllowedValues:
      - "GET"
      - "POST"
      - "PUT"
      - "PATCH"
      - "DELETE"
  RestApiId:
    Type: String
  ResourceId:
    Type: String
  LambdaArn:
    Type: String
  RequestParametersLocation:
    Type: String
    Default: AWS::NoValue
  AuthorizerId:
    Type: String


Resources:
  Method:
    Type: AWS::ApiGateway::Method
    Properties:
      RestApiId: !Ref RestApiId
      ResourceId: !Ref ResourceId
      HttpMethod: !Ref HttpMethod
      AuthorizationType: CUSTOM
      AuthorizerId: !Ref AuthorizerId
      RequestParameters:
        Fn::Transform:
          Name: 'AWS::Include'
          Parameters:
            Location: !Ref RequestParametersLocation
      Integration:
        Type: AWS_PROXY
        IntegrationHttpMethod: POST
        Uri: !Sub "arn:${AWS::Partition}:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${LambdaArn}/invocations"
        PassthroughBehavior: WHEN_NO_MATCH
        RequestTemplates:
          application/json: "{\"statusCode\": 200}"
        IntegrationResponses:
          - StatusCode: 200
            ResponseTemplates:
              application/json: ""
            ResponseParameters:
              method.response.header.Access-Control-Allow-Headers: "'*'"
      MethodResponses:
        - StatusCode: 200
          ResponseModels:
            application/json: "Empty"
          ResponseParameters:
            method.response.header.Access-Control-Allow-Origin: true
            method.response.header.Access-Control-Allow-Headers: true
            method.response.header.Access-Control-Allow-Methods: true
  AlarmLambdaInvokePermission:
    Type: "AWS::Lambda::Permission"
    Properties:
      FunctionName: !Ref LambdaArn
      Action: "lambda:InvokeFunction"
      Principal: "apigateway.amazonaws.com"
```
