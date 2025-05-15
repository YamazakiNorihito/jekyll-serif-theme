---
title: "AWS API Gateway Lambda Authorizer 実践メモ：仕組み・構成・ベストプラクティス"
date: 2025-05-24T15:35:00
mermaid: true
weight: 7
tags:
  - AWS
  - APIGateway
  - Lambda
  - CustomAuthorizer
  - JWT
  - IAM
  - ServerlessSecurity
  - Authorization
description: "AWS API Gateway の Lambda Authorizer について、自分の理解を深めるためにドキュメントを精読し、実装・構成・挙動・ベストプラクティスを整理。"
---


公式ドキュメント[[Use API Gateway Lambda authorizers](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html)]

## Lambda Authorizerとは

API GatewayでAPIへのアクセス制御を行うためのLambda関数です。  
クライアントがAPIにリクエストすると、API GatewayはLambda Authorizerを呼び出します。

- **入力（Input）**: リクエストに含まれる情報（ヘッダー、クエリ文字列、トークンなど）を元に呼び出し元の「identity（誰か）」を判定  
- **出力（Output）**: IAMポリシーを返して、そのリクエストを許可するかどうかを制御

カスタム認証スキームを実装でき、以下のような方法を使用可能です：

- リクエストパラメータからidentityを判別  

## Authorization Workflow

1. クライアントが、Bearerトークンやリクエストパラメータを含めて、API Gatewayのメソッドを呼び出す。
2. API Gatewayは、そのメソッドにLambda Authorizerが設定されているかをチェックする。
3. Lambda Authorizerが設定されている場合：
   - API GatewayはLambda Authorizer関数を呼び出す。
   - Lambda関数は以下のいずれかの方法で呼び出し元を認証する：
     - OAuthプロバイダーに問い合わせてアクセストークンを確認
     - SAMLプロバイダーに問い合わせてSAMLアサーションを確認
     - リクエストパラメータを元にIAMポリシーを生成
     - データベースから資格情報（クレデンシャル）を取得して確認
   - Lambda関数は以下を返す：
     - IAMポリシー
     - プリンシパルID（識別子）
     - ※ これらを返さない場合は、認証失敗（失敗として扱われる）
4. API Gatewayは返されたIAMポリシーを評価する。
   - 許可されていない場合：HTTPステータスコード `403 ACCESS_DENIED` を返す
   - 許可されている場合：APIメソッドを実行する
5. 認可キャッシュ（Authorization Caching）が有効な場合：
   - 同じ認証情報を使用する後続リクエストでは、Lambda Authorizerは再度呼び出されない（キャッシュが使用される）

> ※ `403 ACCESS_DENIED` や `401 UNAUTHORIZED` のレスポンスはカスタマイズ可能です。

## type

Lambda authorizersは２種類ある

- Request parameter-based Lambda authorizer  
  - `REQUEST` authorizer と表記する  
  - headers や query string parameters を使って「identity（誰か）」を判定する  
  - API Gateway は `REQUEST` authorizer で必要な identity sources がリクエストに含まれるかを検証する  
    - もし null または empty の場合は `401 Unauthorized` を返す  
      - Lambda authorizer は呼び出されない  
  - キャッシュキーの一部が変更され、API が redeploy された場合、cached policy は破棄され新たに生成される  
  - authorization cachingがturn onの場合
    - 指定された identity source の「すべての値の組み合わせ」がキャッシュキーになる
  - authorization caching を off の場合は
    - リクエストは直接 Lambda authorizer に渡される  
- Token-based Lambda authorizer  
  - `TOKEN` authorizer と表記する  
  - bearer token、JSON Web Token (JWT)、OAuth token を使って「identity（誰か）」を判定する  
  - authorization caching が on の場合  
    - 指定された header name に含まれる token がキャッシュキーになる  
  - Additionally  
    - 正規表現（RegEx）を使って token の初期検証ができる  
      - API Gateway が token を検証し、条件を満たす場合のみ Lambda Authorizer を呼び出す  
      - これにより不要な Lambda 呼び出しを減らせる  
  - `IdentityValidationExpression` プロパティは `TOKEN` authorizer のみに対応している  

## Example REQUEST or TOKEN authorizer Lambda function

[実装例はドキュメントをみてほしい](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-use-lambda-authorizer.html)

大事なことは、
以下の**2つを必ず設定する必要**がある：

- principalId（呼び出し元ユーザーの識別子）
- policyDocument（許可または拒否するポリシー）

policyDocument では、**Allow** の場合に以下のように許可する apiGatewayArn に対して Allow を返す。
Action は "execute-api:Invoke" を指定する。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "execute-api:Invoke",
      "Effect": "Allow",
      "Resource": "arn:aws:execute-api:us-east-1:123456789012:ivdtdhp7b5/ESTestInvoke-stage/GET/"
    }
  ]
}
```

optionで`context`にたいを設定すると後続のlambdaで伝播できる。

## AWSから提供されているサンプルコード

1. サンプルアプリケーション
   1. API GatewayとFAPI準拠の外部OIDCプロバイダー、およびLambdaオーソライザーを使って、APIアクセスを保護・認可する方法をデモンストレーション
   2. [Open Banking Brazil - Authorization Samples](https://github.com/aws-samples/openbanking-brazilian-auth-samples)
2. Custom Authorizer Blueprints
   1. [aws-apigateway-lambda-authorizer-blueprints](https://github.com/awslabs/aws-apigateway-lambda-authorizer-blueprints)

## Configure an API Gateway Lambda authorizer

設定手順については、[公式ドキュメント](https://docs.aws.amazon.com/apigateway/latest/developerguide/configure-api-gateway-lambda-authorization.html)を参照してください。

注意：Lambda関数に対する実行権限（Permission）と、API Gatewayのエンドポイントに対するAuthorizerの設定を忘れずに行ってください。
詳しくは[こちら](https://docs.aws.amazon.com/apigateway/latest/developerguide/configure-api-gateway-lambda-authorization.html#configure-api-gateway-lambda-authorization-method-cli)を参照してください。

## [Input to an API Gateway Lambda authorizer](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-lambda-authorizer-input.html)

`TOKEN`と`REQUEST`　authorizer　それぞれで、eventのinput formatのがそれぞれ異なる

### `TOKEN`

```json
{
    "type":"TOKEN",
    "authorizationToken":"{caller-supplied-token}",
    "methodArn":"arn:aws:execute-api:{regionId}:{accountId}:{apiId}/{stage}/{httpVerb}/[{resource}/[{child-resources}]]"
}
```

### `REQUEST`

```json
{
  "type": "REQUEST",
  "methodArn": "arn:aws:execute-api:us-east-1:123456789012:abcdef123/test/GET/request",
  "resource": "/request",
  "path": "/request",
  "httpMethod": "GET",
  "headers": {
    "X-AMZ-Date": "20170718T062915Z",
    "Accept": "*/*",
    "HeaderAuth1": "headerValue1",
    "CloudFront-Viewer-Country": "US",
    "CloudFront-Forwarded-Proto": "https",
    "CloudFront-Is-Tablet-Viewer": "false",
    "CloudFront-Is-Mobile-Viewer": "false",
    "User-Agent": "..."
  },
  "queryStringParameters": {
    "QueryString1": "queryValue1"
  },
  "pathParameters": {},
  "stageVariables": {
    "StageVar1": "stageValue1"
  },
  "requestContext": {
    "path": "/request",
    "accountId": "123456789012",
    "resourceId": "05c7jb",
    "stage": "test",
    "requestId": "...",
    "identity": {
      "apiKey": "...",
      "sourceIp": "...",
      "clientCert": {
        "clientCertPem": "CERT_CONTENT",
        "subjectDN": "www.example.com",
        "issuerDN": "Example issuer",
        "serialNumber": "a1:a1:a1:a1:a1:a1:a1:a1:a1:a1:a1:a1:a1:a1:a1:a1",
        "validity": {
          "notBefore": "May 28 12:30:02 2019 GMT",
          "notAfter": "Aug  5 09:36:04 2021 GMT"
        }
      }
    },
    "resourcePath": "/request",
    "httpMethod": "GET",
    "apiId": "abcdef123"
  }
}
```

## [Output from an API Gateway Lambda Authorizer](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-lambda-authorizer-output.html)

Lambda authorizerの出力は、`principalId`と`policyDocument`を含むJSON形式で返す必要がある。

1. principalId

   1. principal identifier
2. policyDocument

   1. policy document
   2. policy statementsは配列

sample

```json
{
  "principalId": "yyyyyyyy", // The principal user identification associated with the token sent by the client.
  "policyDocument": {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "execute-api:Invoke",
        "Effect": "Allow|Deny",
        "Resource": "arn:aws:execute-api:{regionId}:{accountId}:{apiId}/{stage}/{httpVerb}/[{resource}/[{child-resources}]]"
      }
    ]
  },
  "context": {
    "stringKey": "value",
    "numberKey": "1",
    "booleanKey": "true"
  },
  "usageIdentifierKey": "{api-key}"
}
```

`context`は任意の文字列Key-Valueペアを指定でき、後続のLambdaに伝播される。オブジェクトや配列は使用不可。
Lambdaでは`$event.requestContext.authorizer.{key}`で参照可能（例: `stringKey` → "value"）。

`usageIdentifierKey`は[Usage Plans](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-api-usage-plans.html)を用いる際、対象ユーザーのAPI Keyを指定する。

`Resource`の長さは最大1600バイト。超過するとクライアントに`414 Request URI too long`が返る。これは実行時にのみ判定され、デプロイ前の検出は不可。

## Call an API with an API Gateway Lambda authorizer

確認手順については、[公式ドキュメント](https://docs.aws.amazon.com/apigateway/latest/developerguide/call-api-with-api-gateway-lambda-authorization.html)を参照してください。

## [Configure a cross-account API Gateway Lambda authorizer](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-lambda-authorizer-cross-account-lambda-authorizer.html)

今のところやる予定ないから[Skip](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-lambda-authorizer-cross-account-lambda-authorizer.html)

## [Control access based on an identity’s attributes with Verified Permissions](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-lambda-authorizer-verified-permissions.html)

[What is Amazon Verified Permissions?](https://docs.aws.amazon.com/verifiedpermissions/latest/userguide/what-is-avp.html)から始めないとようわからん、今度のTODOとしておく
