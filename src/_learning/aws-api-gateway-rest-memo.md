---
title: "API Gateway REST APIsのメモ"
date: 2025-6-9T07:00:00
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
description: ""
---

API Gateway REST APIsの[ドキュメント](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-rest-api.html)を読んでいく

## [API endpoint types](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-api-endpoint-types.html)

3種類のEndpoint Typeがある。

1. Edge-optimized API endpoints
   1. デフォルトのエンドポイントタイプ
   2. CloudFront Point of Presence (POP) を利用することで、世界中からのアクセスにも高速に応答できる
      1. CloudFront（CDN）からAPI Gatewayまでの通信は、AWSの内部ネットワークを通るため、高速・安定・安全です。
   3. HTTPヘッダー名が大文字始まりの形式に変換される
      1. 元のヘッダー名: cookie
      2. Edge-optimizedでの変換後: Cookie
   4. リクエスト中のHTTP Cookieを、クッキー名で自然順（アルファベット順）に並べ替えてから、オリジン(Lambdaとか)に転送
2. Regional API endpoints
   1. API とクライアントが同じリージョンにあり、通信のオーバーヘッドを減らしたい場合に使う
   2. 各リージョンに独立してデプロイされるため、同じカスタムドメイン名を複数リージョンに設定することが可能（ただし、Route 53 でルーティング制御が必要）[図regional_multi]
   3. Regional API + 自前 CloudFront を使えば、Edge-optimized のような世界中対応の構成が実現可能
      1. CloudFront のキャッシュ設定、WAF、オリジン設定などを細かくカスタマイズできる
      2. Edge-optimized のように AWS 管理の CloudFront に依存しないため、自由度が高く、要件に応じた設計が可能
3. Private API endpoints
   1. VPC 内からのみアクセス可能な API を作るためのエンドポイントタイプ
   2. Interface VPC endpoint（タイプ：com.amazonaws.<region>.execute-api） を使って、自分の VPC 内からアクセスできるようにする
   3. HTTP ヘッダー名はそのまま（as-is）でオリジンに渡される（Edge-optimized のような変換はなし

**図regional_multi**

```txt
                +------------------------+
  api.example.com —► Route 53 (ルーティング設定)
                +------------------------+
                      |            |
           ┌──────────┘            └──────────┐
           ▼                                   ▼
Tokyo Regional API                Virginia Regional API
(api.example.com)                 (api.example.com)
```

### [Change a public or private API endpoint type in API Gateway](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-api-migration.html)

必要な時に読む

### [Methods for REST APIs in API Gateway](https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-method-settings.html)

API メソッドは「method request（入力）」と「method response（出力）」から構成される。

non-proxy integrations のケースにおいて、以下を明示的に設定する必要がある：

- クライアントのリクエストに対応する **method request**
- バックエンドのレスポンスをクライアントに返すための **method response**
  - ステータスコード（例：200, 400, 500）
  - 必要に応じてレスポンスヘッダーやボディのマッピング先

### [Control and manage access to REST APIs in API Gateway](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-control-access-to-api.html)

制御は以下のやり方があるらしい、必要な時に読む

- Resource policies
- Standard AWS IAM roles and policies
- IAM tags
- Endpoint policies for interface VPC endpoints
- Lambda authorizers
- Amazon Cognito user pools

### [Integrations for REST APIs in API Gateway](https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-integration-settings.html)

以下について取り上げれている。詳細は必要な時に読む

- Integration request
- Integration response
- Lambda integration
- HTTP integration
- Private integration
- Mock integration

API Gateway Integration Types

- **Lambda 統合**
  - `AWS_PROXY`: Lambda Proxy 統合  
    - API Gateway がリクエスト全体をそのまま Lambda Function に渡す。
    - 統合がシンプルになるが、Request / Response の形式は制御しにくい。
  - `AWS`: Lambda カスタム統合  
    - Integration Request / Response Template を使って手動でマッピングを行う。

- **HTTP 統合**
  - `HTTP_PROXY`: HTTP Proxy 統合  
    - API Gateway がリクエストをそのまま HTTP Backend に転送する。
  - `HTTP`: HTTP カスタム統合  
    - Request / Response のマッピングテンプレートを自分で定義する。

- **AWS 統合**
  - `AWS`: AWS Service 統合（Proxy ではない）  
    - S3 や DynamoDB などの AWS Service Action を呼び出すために使用。
    - Request / Response Mapping Template が必要。

- **Mock 統合**
  - `MOCK`: バックエンドなしの統合  
    - API Gateway 自体が固定レスポンス（Mock Response）を返す。
    - テストやスタブ用に便利。

| タイプ         | 説明 |
|----------------|------|
| `AWS`          | **AWS service action** と連携する統合。<br>**Integration Request** と **Integration Response** の設定が必要。 |
| `AWS_PROXY`    | **Lambda function** を呼び出す専用の統合（Lambda proxy統合）。<br>**Integration Request** と **Integration Response** の設定は不要。 |
| `HTTP`         | 任意の **HTTP backend** と連携するカスタム統合。<br>**Integration Request** と **Integration Response** の設定が必要。 |
| `HTTP_PROXY`   | **HTTP backend** にそのままリクエストを渡す **proxy integration**。<br>**Integration Request** と **Integration Response** の設定は不要。 |
| `MOCK`         | バックエンドなしで **固定レスポンス（static response）** を返す統合。<br>テストやモックAPIに便利で、料金もかからない。 |

#### Lambda proxy integrations

- クライアントが API リクエストを送信したときに、API Gateway は Lambda 関数に `event` オブジェクトを渡す
- ただし、リクエストパラメータの **順序は保持されない**
- The `event` object includes: ([format](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format))
  - Request **headers**
  - **Query string parameters**
  - **Path parameters**
  - **Body** (payload)
  - API configuration data:
    - Current **deployment stage name**
    - **Stage variables**
    - **User identity**
    - **Authorization context** (if any)
- レスポンスのフォーマットは [こちら](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-output-format) に従う：
  - CORSを有効にするには、`Access-Control-Allow-Origin` ヘッダーを `headers` に含める
  - `body` がバイナリのとき：
    - `isBase64Encoded` を `true` に設定する
    - API Gateway の設定で `*/*` を Binary Media Type に追加（任意の content-type でも可）

      ```json
      {
          "isBase64Encoded": true|false,
          "statusCode": httpStatusCode,
          "headers": {
              "headerName": "headerValue",
              "Access-Control-Allow-Origin": "{domain-name | *}"
              // ... 他のヘッダー
          },
          "multiValueHeaders": {
              "headerName": ["headerValue", "headerValue2", ...]
              // ... 必要に応じて使用
          },
          "body": "..."
      }
      ```

  - API Gateway 側で `ANY` を設定していても、Lambda に渡される `event.httpMethod` は実際の HTTP メソッドになる
- **Generic Proxy Resource** とは：
  - Amazon API Gateway において、`{proxy+}` という特別なパス変数と `ANY` メソッドを組み合わせて使用することで、
    任意のパス・任意のHTTPメソッドを一括で受け付けるエンドポイントを作成できる
  - 例：`/{proxy+}` は `/a` や `/a/b/c` のようなすべてのパスにマッチする

#### asynchronous invocation of the backend Lambda function

AWS公式ドキュメントはこちら → [Set up asynchronous invocation of a Lambda function](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-integration-async.html)
サンプルコードはこちら → [GitHub リポジトリ](https://github.com/YamazakiNorihito/AWS-CloudFormation/tree/main/api-gateway-async)

API Gateway から Lambda を非同期に呼び出すには、「Lambda non-proxy（custom）統合」を使う必要があります。これは、バッチ処理や長時間かかる処理（long-latency operations）に適しています。

非同期呼び出しの特徴は、API Gateway を境界に処理の同期/非同期が分かれることです：

クライアント → API Gateway：同期
API Gateway → Lambda：非同期

処理の流れ

 1. クライアントが API Gateway にリクエストを送信する（同期）。
 2. API Gateway は、すぐに HTTP ステータス 202 Accepted を返す（クライアントとの通信はこの時点で終了）。
 3. その後、API Gateway がバックエンドの Lambda を非同期で実行する。

つまり、クライアントは Lambda の処理結果を受け取らない構成です。SQS にメッセージを送るような動きに近く、Lambda 側の完了通知や結果を知るには、別途ステータス確認用のエンドポイントを実装する必要があります。

レスポンス例（API Gateway → クライアント）

HTTP/1.1 202 Accepted
Content-Type: application/json
Content-Length: 0
Connection: close
...

### Handle Lambda errors in API Gateway

Lambda のカスタム統合を使用している場合、Lambda 関数内でエラーが発生しても、デフォルトでは API Gateway は HTTP ステータスコード `200 OK` を返します。これはクライアントにとって直感的ではなく、適切に処理するには **Lambda のエラーを HTTP エラーとして正しくマッピング**する必要がある。

- **Lambda 標準エラーの処理**
  API Gateway の「Integration Response」で `selectionPattern` に正規表現を指定し、対応する HTTP ステータスコードにマッピング

  例：

  ```sh
  aws apigateway put-integration-response \
    --rest-api-id abc123 \
    --resource-id xyz456 \
    --http-method GET \
    --status-code 400 \
    --selection-pattern "Malformed.*" \
    --region ap-northeast-1
  ```

- **Lambda カスタムエラーの処理**
  エラーオブジェクトを JSON 文字列として返し、Mapping Template を使って整形、もしくはレスポンスヘッダーへ展開

  Lambda 関数の例（Node.js）：

  ```javascript
  export const handler = (event, context, callback) => {
    const error = {
      errorType: "InternalServerError",
      httpStatus: 500,
      requestId: context.awsRequestId,
      trace: {
        function: "abc()",
        line: 123,
        file: "abc.js"
      }
    };
    callback(JSON.stringify(error));
  };
  ```

  Mapping Template の例（500エラー用）：

  ```json
  {
    "errorMessage": $input.path('$.errorMessage')
  }
  ```

詳しくはドキュメントを必要な時に[読む](https://docs.aws.amazon.com/apigateway/latest/developerguide/handle-errors-in-lambda-integration.html)

### HTTP integrations for REST APIs in API Gateway

必要な時に[読む](https://docs.aws.amazon.com/apigateway/latest/developerguide/setup-http-integrations.html)

API Gateway の HTTP proxy 統合は、nginx のようなリバースプロキシをマネージドで提供するサービス。
そのままレスポンスを流すこともできるし、必要ならラップして加工もできる。

### Private integrations for REST APIs in API Gateway

必要な時に[読む](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-private-integration.html)

`API Gateway ->(VPC境界)->NLB->(service in VPC)`
API Gateway を使って VPC 内のサービスを外部に公開 したいときの構成。
この構成は Private Integration と呼ばれ、NLB（Network Load Balancer）と VPC Link を使って、VPC 内の HTTP/HTTPS エンドポイントにリクエストを中継する。

### Mock integrations

必要な時に[読む](https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-mock-integration.html)
