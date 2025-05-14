---
title: "Amazon SNS モバイルプッシュ通知設定とトラブル対処メモ"
date: 2025-05-24T15:35:00
mermaid: true
weight: 7
tags:
  - AWS
  - SNS
  - エラー対処
  - デバイストークン
  - GoLang
  - モバイル通知
description: "仕事で必要になったため読んだ Amazon SNS のモバイルプッシュ通知関連ドキュメントの要点まとめ。通知フロー、エンドポイント管理、エラー対応などを実装例や推奨事項とともに整理。"
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
