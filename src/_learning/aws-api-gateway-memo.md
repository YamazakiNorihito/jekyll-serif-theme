---
title: "Amazon API Gateway メモ：REST, HTTP, WebSocket APIの機能と使い分け"
date: 2025-6-3T07:00:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - AWS
  - API Gateway
  - REST API
  - HTTP API
  - WebSocket
  - サーバーレス
description: "Amazon API Gatewayの概要、主要機能、ユースケース、APIタイプ（REST, HTTP, WebSocket）の違い、execute-apiとapigatewayの使い分けを整理した技術メモです。"
---

API  Gatewayの[ドキュメント](https://docs.aws.amazon.com/apigateway/latest/developerguide/welcome.html)を読んでいく

## API Gateway とは

AWS 上で REST・HTTP・WebSocket API  を簡単に作って公開・管理できるサービス

## API Gateway の主な機能

- HTTP、REST（ステートレス）および WebSocket（ステートフル）API に対応
- 認証機能が豊富（IAMポリシー、Lambdaオーソライザー、Cognitoユーザープール）
- Canary release deploymentsに対応（段階的なデプロイ）
- CloudTrail によるAPIの操作履歴ログ
- CloudWatch によるアクセスログ、実行ログ、アラーム設定
- CloudFormation テンプレートによるAPI構築の自動化
- カスタムドメイン名の利用が可能
- AWS WAF と連携してWeb攻撃から保護
- AWS X-Ray と連携してAPIパフォーマンスの可視化

## API Gateway use cases

- REST APIs
  - リソース（resources）とメソッド（methods）で構成される
    - 例：`/incomes`（リソース）＋ `POST`（メソッド）＝ `POST /incomes`
  - クライアントからのリクエストは method request として処理され、バックエンドのレスポンスは method response にマッピングされる
  - integration request / response を使ってバックエンドと連携する
    - 例：DynamoDB をバックエンドに指定し、DynamoDB アクション・IAM ロール・入力データの変換などを設定可能
  - schema / model を定義して、リクエスト／レスポンスの構造を明確にできる
    - body mapping template によりバックエンドとフロントエンドのデータ形式の変換が可能
  - OpenAPI 拡張による SDK の生成や API ドキュメント作成に対応している
  - HTTP リクエストに対するスロットリングなどの管理機能を提供している
- HTTP APIs
  - RESTful API を低レイテンシかつ低コストで作成できる
  - クライアントからのリクエストを AWS Lambda 関数や外部 HTTP エンドポイントに転送できる
    - 例：API Gateway が Lambda 関数と統合され、関数のレスポンスをクライアントに返す
  - OpenID Connect や OAuth 2.0 による認可をサポートしている
  - クロスオリジンリソース共有（CORS）に対応している
  - 自動デプロイ機能に対応している
- WebSocket APIs
  - クライアントとサーバーが双方向にメッセージを送受信できるリアルタイム通信向けAPI
    - バックエンドからクライアントへのプッシュ通知が可能で、複雑なポーリング処理は不要
  - メッセージ内容に応じて Lambda、Kinesis、HTTP エンドポイントなどのバックエンドを呼び出せる
    - 例：チャットアプリでユーザーやグループへのメッセージ送信を制御
  - サーバーのプロビジョニングや接続管理なしにリアルタイム通信アプリケーションを構築可能
    - 例：チャットアプリ、株価ダッシュボード、リアルタイム通知
  - WebSocket 接続とメッセージのモニタリングおよびスロットリングに対応している
  - AWS X-Ray によるメッセージのトレーシングが可能
  - HTTP / HTTPS エンドポイントとの連携も容易に設定できる

## Calling an API Gateway API - `execute-api` と `apigateway` の違い

### `execute-api` とは？

- API Gateway で作成した API を呼び出すときに使われるサービス名
- 実行用のエンドポイントとして機能する
- URL や IAM ポリシー、Service Principal などで使用される

例: API の URL に含まれる

```
https://abcd1234.execute-api.ap-northeast-1.amazonaws.com/prod/hello
```

例: IAM ポリシーでの使用

```json
{
  "Effect": "Allow",
  "Action": "execute-api:Invoke",
  "Resource": "arn:aws:execute-api:ap-northeast-1:123456789012:abcd1234/prod/GET/hello"
}
```

### `apigateway` とは？

- API Gateway の API を作成・設定・デプロイするためのサービス名
- 管理者や開発者が API を設計・構築する際に使う
- AWS CLI、SDK、IAMポリシーなどで使用される

例: AWS CLI での使用

```bash
aws apigateway get-rest-apis
```

### 用途の比較

| 目的         | サービス名         | 説明                           |
| ---------- | ------------- | ---------------------------- |
| API を作成・管理 | `apigateway`  | 開発者が API を設計・設定・デプロイするためのもの  |
| API を呼び出す  | `execute-api` | アプリ・ユーザーが API を実行（利用）するためのもの |

### ポイントまとめ

- `apigateway` = API を「作る」側
- `execute-api` = API を「使う」側

## [Amazon API Gateway concepts](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-basic-concept.html)

API Gatewayでよく出てくる「用語」や「構成要素」の意味がまとまっている

## Choose between REST APIs and HTTP APIs

| Category               | REST APIs                                                                                         | HTTP APIs                                                              |
|------------------------|----------------------------------------------------------------------------------------------------|------------------------------------------------------------------------|
| **Overview**           | Feature-rich                                                                                      | Minimal features                                                       |
| **Pricing**            | Higher                                                                                            | Lower                                                                  |
| **Best use cases**     | When you need:<br>- API keys<br>- Per-client throttling<br>- Request validation<br>- AWS WAF integration<br>- Private endpoints | シンプルな用途                    |
| **Endpoint types**     | - Edge-optimized ✅<br>- Regional ✅<br>- Private ✅                                                 | - Edge-optimized ❌<br>- Regional ✅<br>- Private ❌                    |
| **Security features**  | - Mutual TLS authentication ✅<br>- Certificates for backend authentication ✅<br>- AWS WAF ✅        | - Mutual TLS authentication ✅<br>- Certificates for backend authentication ❌<br>- AWS WAF ❌ |
| **Authorization options** | - IAM ✅<br>- Resource policies ✅<br>- Amazon Cognito ✅<br>- Lambda authorizer ✅                  | - IAM ✅<br>- Amazon Cognito ✅<br>- Lambda authorizer ✅<br>- JWT ✅     |
| **API management**     | - Custom domain names ✅<br>- API keys ✅<br>- Per-client rate limiting ✅<br>- Per-client usage throttling ✅ | - Custom domain names ✅<br>- API keys ❌<br>- Per-client rate limiting ❌<br>- Per-client usage throttling ❌ |
| **Development**        | - CORS configuration ✅<br>- Test invocations ✅<br>- Caching ✅<br>- Manual deployments ✅<br>- Automatic deployments ❌<br>- Custom gateway responses ✅<br>- Canary release deployments ✅<br>- Request validation ✅<br>- Request parameter transformation ✅<br>- Request body transformation ✅ | - CORS configuration ✅<br>- Test invocations ❌<br>- Caching ❌<br>- Manual deployments ✅<br>- Automatic deployments ✅<br>- Custom gateway responses ❌<br>- Canary release deployments ❌<br>- Request validation ❌<br>- Request parameter transformation ✅<br>- Request body transformation ❌ |
| **Monitoring**         | - CloudWatch metrics ✅<br>- Access logs to CloudWatch Logs ✅<br>- Access logs to Amazon Kinesis Data Firehose ✅<br>- Execution logs ✅<br>- AWS X-Ray tracing ✅ | - CloudWatch metrics ✅<br>- Access logs to CloudWatch Logs ✅<br>- Access logs to Amazon Kinesis Data Firehose ❌<br>- Execution logs ❌<br>- AWS X-Ray tracing ❌ |
| **Integrations**       | - Public HTTP endpoints ✅<br>- AWS services ✅<br>- AWS Lambda ✅<br>- Private integrations with NLB ✅<br>- Private integrations with ALB ❌<br>- AWS Cloud Map ❌<br>- Mock integrations ✅ | - Public HTTP endpoints ✅<br>- AWS services ✅<br>- AWS Lambda ✅<br>- Private integrations with NLB ✅<br>- Private integrations with ALB ✅<br>- AWS Cloud Map ✅<br>- Mock integrations ❌ |

---
