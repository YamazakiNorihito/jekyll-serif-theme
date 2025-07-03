---
title: "AWS Lambda 基本概念メモ"
date: 2025-6-30T15:00:00
mermaid: false
weight: 7
tags:
  - AWS
  - Lambda
  - サーバーレス
  - イベント駆動アーキテクチャ
  - ベストプラクティス
description: "AWS Lambdaの基本的な仕組み、実行モデル、ライフサイクル、イベント駆動アーキテクチャの概念とベストプラクティスをまとめたノート。"
---


<https://docs.aws.amazon.com/lambda/latest/dg/welcome.html>

### Lambdaとは

AWS Lambdaは、サーバーの用意や管理なしでコードを実行できるサービスです。コードを「関数（Lambda関数）」として登録し、必要なときだけ自動的に実行・スケール。

### How Lambda works

Lambda関数を書くために必要な、4つの重要な要素

1. Lambda functions and function handlers
   1. functions
      1. イベントに応じて自動で実行される、小さな独立したプログラム
      2. イベント駆動
      3. コードは自己完結、特定の処理を1つだけ担当する（単一責任）
      4. 実行が終わると自動的に停止する
      5. 関数コードと依存関係は「デプロイパッケージ」としてまとめる
         1. .zip アーカイブ形式 または コンテナイメージ形式が使える
   2. function handlers
      1. eventsを処理するmethod
      2. Lambda が関数を実行する際に呼び出される
      3. イベントに関するデータが引数として渡される
      4. Lambda関数ごとに1つのハンドラーのみ定義できる
2. Lambda execution environment and runtimes
   1. execution environment
      1. 独立しており、secure（安全）な環境で動作する
      2. function の実行に必要な processes や resources を管理する
      3. 初回実行時に新しい実行環境を作成する
      4. 実行終了後もすぐには環境を破棄せず、一時的に保持する
      5. 再実行時には、既存の実行環境を再利用（re-use）する可能性がある
   2. runtime
      1. 実行環境に含まれる、言語ごとのランタイム環境
      2. Lambda 本体と関数コードの間で、イベントの受け渡しとレスポンスの中継を行う
      3. [Supported runtimes](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html#runtimes-supported)
      4. マネージド runtime 使用時は、Lambda がセキュリティアップデートやパッチを自動適用する
3. Events and triggers
   1. Events
      1. Lambda 関数は event によって起動される
      2. Event は、他の AWS サービスから発生する特定のアクション
      3. Lambda は event data を JSON document として受け取り、runtime がそれをオブジェクトに変換して handler に渡す
   2. Triggers
      1. Trigger は function と event source を connect する仕組み
      2. Lambda 関数には複数の triggers を設定可能
      3. 一部のサービス（例：Amazon Kinesis、Amazon SQS）は trigger ではなく event source mapping を使用する
         1. Polling によってデータを取得し、batch 化して関数を呼び出す
4. Lambda permissions and roles
   1. permissionsは２種類ある
      1. Lambda function が他の AWS サービスを使うための permissions
         1. Lambda service principal`lambda.amazonaws.com`に対して、trusted することで Lambda がその IAM ロール（実行ロール）を`sts:AssumeRole`できるようにする必要がある
            1. 公式[Defining Lambda function permissions with an execution role](https://docs.aws.amazon.com/lambda/latest/dg/lambda-intro-execution-role.html)
            2. 関数のコード中でわざわざ sts.assumeRole() を書くなという意味
      2. 他のユーザーや AWS サービスが Lambda を呼び出すための permissions
         1. AWSの他のServiceからLambda 関数に対して、何かしら操作したい場合は、リソースベースポリシーを設定する必要がある
            1. 公式[Viewing resource-based IAM policies in Lambda](https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html)
            2. 例えば、lambdaを実行させたい場合は、`"Action": "lambda:InvokeFunction"`を宣言する必要がある

### Running code

#### The Lambda execution model

| フェーズ名             | 内容             | 詳細説明 |
|------------------------|------------------|----------|
| **1. Initialization** （初期化） | 実行環境の準備 | - Lambdaが実行環境を作成<br>- ランタイムのセットアップ<br>- コードの読み込み<br>- スタートアップコードの実行（例：グローバル領域でのDB接続など） |
| **2. Invocation** （呼び出し）   | 関数の実行       | - イベントを受け取るとこの環境で関数を実行<br>- 複数のイベントを**同じ環境で順番に処理**可能<br>- イベント数が増えると環境を**追加作成**<br>- 減れば不要な環境を**停止** |
| **3. Shutdown** （終了）        | 後片付けと終了処理 | - Lambdaが環境を削除する前に、**残りの処理を片付ける時間（チャンス）**が与えられる<br>- 例：一時ファイルの削除、接続のクローズなど |

- **メモリと `/tmp` ストレージ**  
  - 関数には設定したメモリと、512MBの一時保存領域（`/tmp`）が提供される。

- **リソースの再利用**  
  - DB接続やクライアントなどを、**関数呼び出し間で使い回せる**（同じ環境が再利用されるため）。

- **Provisioned Concurrency（事前起動）**  
  - リクエストに即時応答するために、**実行環境を事前に起動しておく機能**。

#### programming model

- Lambda関数のエントリーポイントは **ハンドラー関数** として指定される。イベント情報とコンテキスト（リクエストIDなど）が引数として渡される。
- ハンドラーの**外側（モジュールスコープやクラスのstatic・インスタンスフィールド）で初期化された変数やオブジェクトは、実行環境が再利用される限り保持される**。
- 初期化処理の中で、**AWS SDKクライアントなどのリソースを生成しておくと、後の呼び出しで高速に再利用できる**。
- `/tmp` ディレクトリは512MBの一時ストレージとして使用でき、複数の呼び出し間で使える可能性がある。
- Lambdaはイベントを**順不同または並列で処理する可能性があるため、関数インスタンスの永続性に依存しない設計が必要**。

#### Lambda execution environment lifecycle

Lambdaの実行環境は、「Runtime + Function」と「Extension」で構成されており、それぞれが専用のAPI（Runtime API / Extensions API / Telemetry API）を使ってLambdaと通信します。

![Architecture diagram of the execution environment.](https://docs.aws.amazon.com/images/lambda/latest/dg/images/telemetry-api-concept-diagram.png)

##### lifecycle

![Lambda lifecycle phases: Init, Invoke, Shutdown](https://docs.aws.amazon.com/images/lambda/latest/dg/images/Overview-Successful-Invokes.png)

phaseは３つが存在する。

1. INIT
2. INVOKE
3. SHUTDOWN

**詳しく入る前に知っておきたいこと**

各PhaseはLambdaからruntimeと全てのextensionに各種event(INIT、INVOKE、SHUTDOWN)を送信します。
runtimeやextensionはそのeventの処理が完了したらそれぞれのAPIに対して`Next API request`してeventの処理が完了したことを通知します。
runtimeと各extensionが完了し、かつ保留中のイベントがない場合、Lambdaは実行環境をフリーズし、次のフェーズ（INVOKE か SHUTDOWN）のEventが来るまで待機状態に入ります。

#### Init phase

Init phaseでは以下のタスクが実行されます。

1. Start all extensions (Extension init)
2. Bootstrap the runtime (Runtime init)
3. Run the function's static code (Function init)
4. Run any before-checkpoint runtime hooks (Lambda SnapStart のみ)

まとめ

- **Initフェーズのタイムアウト (通常)**:
  - Initフェーズは、上記タスク（SnapStartでない場合は3つ）を**10秒以内**に完了させる必要があります。
  - 10秒以内に完了しなかった場合、Lambdaは最初の関数呼び出し時に **Initフェーズを再試行**します。この**再試行されるInitフェーズと、それに続くInvokeフェーズ**が、設定された関数のタイムアウト時間内で実行される必要があります。
    - （修正前：「Init+INVOKE合わせて、function timeoutで設定した時間以内で実行します。」）
- **Initフェーズのタイムアウト (Provisioned Concurrency または SnapStart の場合)**:
  - Provisioned Concurrency または SnapStart を使用する関数の場合、Initフェーズの10秒タイムアウトは適用されません。
  - 初期化コードは最大15分間実行できます。具体的なタイムアウトは、**130秒**または**設定された関数タイムアウト（最大900秒）のいずれか高い方**となります。
- **Lambda SnapStart を使うと**:
  - Initフェーズは、関数バージョンを**発行する時**に実行されます。Lambda は初期化された実行環境のメモリとディスク状態のスナップショットを保存し、暗号化して永続化、低レイテンシアクセスのためにキャッシュします。
  - `before-checkpoint` [runtime hook](https://docs.aws.amazon.com/lambda/latest/dg/snapstart-runtime-hooks.html) があれば、Initフェーズの最後に実行されます。
  - **Restore phase (Lambda SnapStart のみ)**:
    - 関数が初めて呼び出されたりスケールアップしたりする際には、Lambda は新しい実行環境を最初から初期化するのではなく、**永続化されたスナップショットから復元**します。
    - `after-restore runtime hook` があれば、Restoreフェーズの最後に実行されます。
    - この `after-restore runtime hook` の実行時間は課金対象になります。
    - ランタイムのロードと `after-restore runtime hook` の実行は、**合計10秒以内**に完了する必要があります。
    - 間に合わない場合は、`SnapStartTimeoutException` がスローされ、リクエストが失敗します。
    - Restoreフェーズが完了すると、次は **Invokeフェーズ** に進みます。
- **Provisioned Concurrency (PC) を使うと**:
  - コールドスタートをほぼ完全に排除することができます。LambdaはPC設定時に実行環境を初期化し、呼び出しに備えて常に利用可能な状態を維持します。
  - 初期化済みの環境であっても、初回呼び出し時にランタイムやメモリ設定に応じて可変のレイテンシ（遅延）が発生する可能性があります。
  - 関数呼び出しと初期化フェーズの間に時間的なギャップが見られることがあります。

> 💡 **runtime hook (Lambda SnapStart の場合)** とは：
> Lambda SnapStart のライフサイクルにおいて、開発者が特定のポイント（チェックポイント作成前やスナップショット復元後）で任意の処理（コード）を挿入できる仕組みです。
> （修正前：「Lambda が関数を実行する前後に、開発者が任意の処理（コード）を挿入できる仕組みです。」これは一般的な説明であり、SnapStartの文脈に合わせて具体化しました。）

#### Invoke phase

まとめ

- function's timeoutはInvoke phas全体に対して適用されます。
- 後処理（post-invoke）は存在しない。
- duration time = runtime time + extensions time　で求められる

#### Shutdown phase

まとめ

- **Duration limit（シャットダウン処理の制限時間）:**
  - 拡張機能（Extensions）の登録状況によって、シャットダウンに与えられる時間が異なります。
    - 拡張機能なし: **0ms** (即時破棄)
    - 内部拡張機能あり: **500ms**
    - 外部拡張機能あり: **2000ms** (2秒)
  - この制限時間内に処理が完了しない場合、Lambdaは `SIGKILL` シグナルを使ってプロセスを強制終了させます。
- **定期的な実行環境の終了:**
  - ランタイムのアップデートやメンテナンスのため、Lambdaの実行環境は数時間ごとに終了されます 。
  - これは、継続的に呼び出されているLambda関数であっても同様です。

### Cold starts and latency

![perf optimize figure 1](https://docs.aws.amazon.com/images/lambda/latest/dg/images/perf-optimize-figure-1.png)

Lambda関数を実行する際には、実行までに以下の4つのステップがある。

1. Download your code  
2. Start new execution environment  
3. Execute initialization code(Init phase)
4. Execute handler code(Invoke phase)

Step1と2が「Cold Start」と呼ばれる準備時間  
Step3と4が実際の関数の実行時間（Invocation）

- Cold Start（コールドスタート）  
  - Lambda関数の初回実行時や、長時間使用されていなかった関数の再実行時に発生する。  
  - コードのダウンロードや実行環境のセットアップに時間がかかる。  
  - この準備時間は課金対象外だが、**呼び出し全体の遅延（レイテンシ）**を引き起こす。  
  - Cold Startの所要時間は、通常100ミリ秒未満から1秒以上に及ぶこともある。

- Warm Start（ウォームスタート）  
  - すでに初期化済みのLambda実行環境が再利用される状態。  
  - 実行環境がすでに構築されているため、次のリクエスト処理は高速に完了する。  
  - 初回実行後、Lambdaは実行環境を一時的に保持・凍結し、後続のリクエストで再利用することで発生する。

### Optimizing static initialization

- 静的初期化は、`lambda_handler`コードが関数内で実行を開始する**前**に起こります。
  - `lambda_handler`のスコープ外で定義されたコード（静的初期化コード）は、新しい実行環境が作成される際（コールドスタート時）に一度だけ実行されます。ウォームスタート時には再実行されません。
- initialization codeは、関数実行**前**(init phase)のレイテンシにおける最大の要因となります。
- initialization codeのレイテンシに影響を与える要素：
  - Lambdaレイヤーを含む、インポートされるライブラリや依存関係の観点から見た関数パッケージのサイズ。
  - コードの量と初期化処理の作業量。
  - 接続やその他のリソースをセットアップする際の、ライブラリや他のサービスのパフォーマンス。
- なるべく関数の役割は小さく、コード量を減らす
  - または**Lazy Load（遅延ロード）**使って、init phaseを短くすることもできる。考えて使って
  - 必要なライブラリのみをインポートする（例: aws-sdk/clients/dynamodbのように特定のクライアントだけを読み込む）
  - 呼び出しごとにリセットされるようなコンテキスト固有の情報はグローバル変数に置かない

## Creating event-driven architectures with Lambda

Lambdaの実行には２つの方法がある。

|型|説明|例|
|-----|-----|-----|
|Push|AWSサービスが**イベントを直接送信（push）**してLambdaを起動する|API Gateway、S3、EventBridge|
|Pull|Lambdaが**自分で定期的にチェック（polling）**してイベントがあれば処理する|SQS、DynamoDB Streams、Kinesis|

functionにpassされるeventはJson形式のデータです。Jsonの構造は依存するServiceに依存する。
invoke phaseは最大１５分まで実行できるけど、Lambdaは1秒以下invoke phase（handler関数の実行時間）終了することがベスト

### eventsを使うことのメリット

**Polling / Webhook の課題**

- Polling
  - 新しいデータ取得にラグがある
  - 無駄なリクエストが多く非効率（CPU・帯域を浪費）
- Webhook
  - 他マイクロサービスが対応していないケースあり
  - 認証・認可の仕組みが必要になることが多い
- 共通の課題
  - オンデマンドスケーリングが難しい
  - スケール対応には開発者による追加実装が必要

**イベント駆動アーキテクチャの利点**

- イベントによる置き換え
  - Polling / Webhook を使わずにイベントで処理を通知
  - イベントはフィルタ・ルーティング・プッシュが可能
- 効率性・コスト削減
  - 帯域とCPU使用量を抑えられる可能性
  - 結果としてコスト削減も見込める
- 構成の簡素化
  - 各機能が小さく、コード量も少ない
- ニアリアルタイム対応
  - アプリケーションの状態が変化するとすぐにイベントが生成される
  - バッチ処理への依存を減らせます
- スケーラビリティ
  - カスタムコードを変えずにLambdaによりスケールはサービス側で自動対応

### Improving scalability and extensibility

- マイクロサービスは、Amazon SNS や Amazon SQS にイベントを発行する。
  - これらは「弾力的なバッファ」として機能し、トラフィック増加時のスケーラビリティを向上させる。
- Amazon EventBridge により、イベントの内容に基づいてフィルタリングおよびルーティングが可能。
  - ルールに基づいた柔軟なメッセージ制御が実現される。
- 【スケーラビリティの利点】
  - イベントベースのアーキテクチャは、モノリスに比べてスケーラブル。
  - 各サービスが疎結合のため、冗長性や耐障害性が高まる。
- 【拡張性の利点】
  - 他チームが既存サービスに影響を与えず機能追加可能。
  - EventBridge により、将来的なイベントコンシューマーも容易に統合可能。
- 【疎結合のメリット】
  - イベントの送信元は、受信側の存在や実装を意識する必要がない。
  - マイクロサービスごとのロジックが単純になり、保守・運用が容易になる。

### Trade-offs of event-driven architectures

#### Variable latency

- モノリシックアプリケーションは、同一メモリ空間内で処理されるため、レイテンシーが低く一貫性のあるパフォーマンスが期待できる。。
- イベント駆動アーキテクチャはネットワーク越しに通信するため、可変レイテンシー（Variable latency）が発生する。
- レイテンシー最小化の工夫は可能だが、モノリスの方が低レイテンシーに最適化しやすい。
  - ただし、その分スケーラビリティと可用性は制限されやすい。
- 常に低レイテンシーが求められる処理（例：高頻度取引、ロボティクス自動化）には、イベント駆動は不向き。

### Eventual consistency

- イベントは「状態の変化」を表す
- 多数のイベントが並行して処理されるため、結果整合性となるケースが多い
- → トランザクション処理や重複排除、全体状態の把握が難しくなる

【強整合性と結果整合性の例】

- 結果整合性：1時間あたりの注文総数
- 強整合性：現在の在庫数

【強整合性を実現するアーキテクチャ例】

- DynamoDB：
  - 強整合性リード可能（高レイテンシー・高スループットになる可能性あり）
  - トランザクション対応でデータ整合性を保つ
- RDS：
  - ACID特性が必要な処理に向いている
  - スケーラビリティはNoSQLより劣る
  - RDS Proxy で Lambda などからの接続制御が可能

【バッチ処理 vs イベント処理】

- イベントベースは1件ずつ処理する設計が一般的
- サーバーレスではバッチよりリアルタイム処理が好まれる
- 小さな更新の積み重ねで処理することで可用性・スケーラビリティが向上
- 反面、イベント同士の関連性を追うのが難しくなる

### Returning values to callers

- イベントベースのアプリケーションは非同期的であり、呼び出し元サービスは処理完了を待たずに他の作業を続行する
- 非同期性はスケーラビリティと柔軟性を実現するイベント駆動アーキテクチャの核心的特徴
- 同期処理に比べ、ワークフローの結果や戻り値を伝搬する仕組みは複雑になる
- 本番環境の多くの Lambda 呼び出しは Amazon S3 や Amazon SQS などのイベントトリガーによる非同期実行
- 非同期実行では「戻り値」を返すよりも、イベント処理の成功／失敗を適切に捉えることが重要
- Lambda のデッドレターキュー（DLQ）機能を使えば、失敗したイベントを特定して再試行でき、呼び出し元への通知は不要で耐障害性を高められる

### Debugging across services and functions

- イベント駆動システムでは、複数サービスの状態を一度に記録・再現することが難しく、エラー発生時の原因追跡が複雑になる
- 各サービス／関数呼び出しが個別のログを持つため、特定のイベントで何が起きたかを把握しにくい

デバッグ手法構築の３要件

- 堅牢なログ収集：Amazon CloudWatch を活用し、全サービス・Lambda 関数のログを一元的に取得・保存
- トランザクション識別子の付与：全イベントに一意のトランザクション ID を付け、処理の各ステップでログに出力
- ログ解析の自動化：AWS X-Ray などのデバッグ・モニタリングサービスを使い、複数 Lambda 呼び出しやサービス横断でログを集約・解析し、根本原因の特定を容易化

## Anti-patterns in Lambda-based event-driven applications

- [The Lambda monolith](https://docs.aws.amazon.com/lambda/latest/dg/concepts-event-driven-architectures.html#monolith)
  - 1つのLambdaでAPIを全部捌こうとする考え
- Recursive patterns that cause run-away Lambda functions
  - Eventによる再起処理が走ってしまう考慮不足？
    - これ面白い
    - S3をTriggerでFunctionが動くけど、そのFunction内でS3を更新するからまた自身のFunctionが呼び出されるという無限ループ
      - バケットを分けるやら、フォルダをイベント発行用と書き込み用に分けるやらして対処するのがいいのかな、
    - SQS／SNSも同様のパターンがあるらしい、Exponential Backoff以外、自分自身を呼び出すことはないと思うけどね
- [Lambda functions calling Lambda functions](https://docs.aws.amazon.com/lambda/latest/dg/concepts-event-driven-architectures.html#functions-calling-functions)
  - Lambdaから別のLambdaを呼びまくる考え
    - SNS,SQSを通じて呼び出すが吉
- [Synchronous waiting within a single Lambda function](https://docs.aws.amazon.com/lambda/latest/dg/concepts-event-driven-architectures.html#synchronous-waiting)
  - 他のサービスを1つのFunction内でそれぞれ呼ぶこと
    - 例えば、S3へのPutとDynamoDBへのWrite処理
      - 「S3への書き込みとDynamoDBへの書き込みを分離する」というアーキテクチャは、処理が完全に独立している場合にのみ有効な理想論な気がする

----

- [Best practices for working with AWS Lambda functions](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [Code best practices for Go Lambda functions](https://docs.aws.amazon.com/lambda/latest/dg/golang-handler.html#go-best-practices)

### [Reuse connections with keep-alive](https://docs.aws.amazon.com/sdk-for-javascript/v3/developer-guide/node-reusing-connections.html)

- TCPコネクションを再利用（keep-alive）することで、毎回の新規接続にかかるコスト（latency, CPU）を削減できる。
- 毎回新しくTCPコネクションを張るのはオーバーヘッドが大きく、レイテンシ悪化の原因になる。
- しかし、AWS Lambdaはアイドル状態のときにコネクションを自動でクローズするため、再利用前提でコードを書いていると例外が発生することがある。
- そのため、明示的にkeep-alive有効のHTTPエージェントを設定する必要がある。

```js
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { NodeHttpHandler } from "@smithy/node-http-handler";
import { Agent } from "https";

const dynamodbClient = new DynamoDBClient({
    requestHandler: new NodeHttpHandler({
        httpsAgent: new Agent({ keepAlive: true })
    })
});
```

### Performance testing your Lambda function

cloudwatchでfunctionが使用したmemoryを確認できる。`Max Memory Used`

```bash
REPORT RequestId: 3604209a-e9a3-11e6-939a-754dd98c7be3 Duration: 12.34 ms Billed Duration: 100 ms Memory Size: 128 MB Max Memory Used: 18 MB
```

### Be familiar with Lambda quotas

1. 実行時間（Execution Timeout）
   - 最大 15 分（900 秒）/ 1 回の関数実行
2. メモリ（Memory）
   - 最小: 128 MB
   - 最大: 10,240 MB（10 GB）
3. ペイロードサイズ（Payload Size）
   - 同期リクエスト／レスポンス：各 6 MB
   - ストリームレスポンス：最大 20 MB
   - 非同期呼び出し：256 KB
   - リクエスト行 + ヘッダー：合計 1 MB
4. ファイルディスクリプタ（File Descriptors）
   - OSがファイル・ソケットを識別するための番号
   - Lambda 実行環境では 1 プロセスあたり最大 1,024 個
5. /tmp ストレージ
   - 最低 512 MB、最大 10,240 MB（10 GB）

公式ドキュメントリンク

- [Compute and storage](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html#compute-and-storage)
- [Function configuration and execution](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html#function-configuration-deployment-and-execution)
- [Lambda API requests](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html#api-requests)

### If you are using Amazon Simple Queue Service

SQS をイベントソースとして使う場合は、Lambda の実行時間（Timeout）が SQS の Visibility Timeout を超えないように設定してね」
