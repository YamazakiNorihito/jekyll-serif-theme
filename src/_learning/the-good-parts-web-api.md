---
title: "Web API: The Good Partsからの学び"
date: 2024-5-9T06:43:00
#image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: "Graphic Designer"
linkedinurl: ""
weight: 7
tags:
  - API Design
  - Web API
  - RESTful API
  - HTTP Methods
  - Error Handling
  - Security
  - Versioning
  - JSON
  - Best Practices
description: ""
---



## エンドポイントの設計

覚えやすく、どんな機能を持つのURIなのか一目でわかる

**Point**

- 短く入力しやすい
- 人間が読んで理解できる
  - 無闇に文字を省略しない（ただしISO639など公に認知されているものは除く）
  - 英単語を使用する
  - 単語を繋げる必要がある場合はハイフンを利用する
- 大文字小文字が混在していない
- 改造しやすい(hackableな)
- サーバ側のアーキテクチャが反映されていない
- ルールが統一されている

**URIとHTTPメソッドの関係**

HTTPメソッドは「動詞」のようなもので、何をするか（例：取得、更新、削除）を示し、URIは「名詞」のようなもので、どのリソースに対して操作を行うかを指定します。つまり、URIが「どこに」という質問に答え、HTTPメソッドが「何を」という質問に答える。

**HTTPメソッドの種類**

| HTTPメソッド | 役割                                         |
|--------------|--------------------------------------------|
| GET          | リソースの取得。サーバーから情報を取得するために使用します。 |
| POST         | リソースの作成。サーバーにデータを送信し、新たなリソースを作成します。 |
| PUT          | リソースの更新。指定したURIのリソースを新しいデータで完全に置き換えます。 |
| DELETE       | リソースの削除。指定したURIのリソースを削除します。           |
| PATCH        | リソースの部分的更新。リソースの一部のみを更新するために使用します。|
| HEAD         | ヘッダ情報の取得。GETと似ていますが、ボディは返されません。        |
| OPTIONS      | 使用可能なHTTPメソッドの確認。特定のURIに対してどのHTTPメソッドが許可されているかを調べます。|

**URIのパスとクエリパラメータの使い分け基準**

- パスの使用
  - **リソースの識別**: リソースを階層的に表現し、一意に識別する場合に使用。
  - **例**: `/users/12345`（特定のユーザー）

- クエリパラメータの使用
  - **条件付けやフィルタリング**: 検索条件や特定の属性でリソースをフィルタリングする場合に使用。
  - **例**: `/search?q=キーワード`（キーワードで検索）、`/users?status=active`（ステータスでユーザーをフィルタリング）。

## APIレスポンスデータ設計

**基本方針**

- APIコールの最小化: 必要なデータを取得するためのAPIコールを最少に保つ。
- データ量の削減: レスポンスデータの量を可能な限り減らす。

**サポートするデータフォーマット**

- SON
  - 現在の主流。基本的にJSONフォーマットのサポートを推奨。
- XML
  - 使用者は少数だが、特定の用途では依然として有用。

**レスポンスデータのフィールド名設計指針**

- 一般的な用語の使用: APIフィールド名には、一般的で理解しやすい単語を使用する。
- 単語数の最小化: フィールド名はなるべく少ない単語数で表現する。
- 単語の連結規則の統一: 複数の単語を連結する場合、API全体を通して同じ連結方法を採用する。
  - snake_caseまたはcamelCaseを利用することが多い
- 省略語の使用を避ける: 不自然な省略は避け、フィールド名を明確に保つ。
- 単数形と複数形の正確な使用: データの内容に応じて単数形や複数形を正しく使用する。

**日付フォーマット**

| フォーマット名   | 例                                       |
|------------------|--------------------------------------------|
| RFC 3339         | `2023-05-10T15:30:00Z` または `2023-05-10T15:30:00+09:00` |
| RFC 822          | `Wed, 10 May 2023 15:30:00 +0000`          |
| RFC 850          | `Wednesday, 10-May-23 15:30:00 GMT`        |
| UNIXタイムスタンプ | `1683808200`                               |

一般的なAPI利用においては、**RFC 3339** 形式を推奨。
特定の言語に依存した表記(Wed,May)を含まない。また日本語のように年月日の順で表示されているためわかりやすい。

**HTTPレスポンスステータスコード**

HTTPステータスコードのカテゴリー

- **100系 (Informational)**: クライアントのリクエストを受け取ったことを示し、プロセスが継続している状態。
- **200系 (Successful)**: クライアントのリクエストが正常に処理され、目的の操作が成功したことを示す。
- **300系 (Redirection)**: 完了のために追加のアクションが必要であることを示し、リクエストされたリソースが別の場所に移動したことを通知する。
- **400系 (Client Error)**: クライアントのリクエストにエラーがあることを示し、リクエストが正しく処理できなかったことを意味する。
- **500系 (Server Error)**: サーバ側に問題があることを示し、リクエストがサーバによって処理できなかったことを意味する。

よく見るStatusコード（[一覧](https://developer.mozilla.org/ja/docs/Web/HTTP/Status)）

| ステータスコード | 説明                                                                                     |
|------------------|------------------------------------------------------------------------------------------|
| 200              | OK - リクエストが成功し、レスポンスとともにデータが返される。通常のGETリクエストなどで使用される。 |
| 201              | Created - リクエストが成功し、新しいリソースが作成されたことを示す。POSTリクエストで新規作成が完了した際に使用。 |
| 204              | No Content - リクエストが成功したが、レスポンスとして返すべきコンテンツが何もない。PUTやDELETEなど、操作後に特に表示するデータがない場合に使用。 |
| 400              | Bad Request - リクエストが不正または誤りがあり、処理できない。|
| 401              | Unauthorized - 認証が必要なリクエストで認証がない場合。     |
| 403              | Forbidden - サーバがリクエストを理解したが、承認を拒否した。 |
| 404              | Not Found - リクエストされたリソースが見つからない。         |
| 500              | Internal Server Error - サーバ内部でエラーが発生した。       |
| 502              | Bad Gateway - 不適切なレスポンスを受け取ったプロキシサーバ。 |
| 503              | Service Unavailable - サービスが一時的に使えない状態。       |

### エラーレスポンス設計

**有名どころのエラーレスポンスBody**

[Google API](https://developers.google.com/search/apis/indexing-api/v3/core-errors?hl=ja)

```json
{
 "error": {
  "errors": [
   {
    "domain": "global",
    "reason": "invalidParameter",
    "message": "Invalid string value: 'asdf'. Allowed values: [mostpopular]",
    "locationType": "parameter",
    "location": "chart"
   }
  ],
  "code": 400,
  "message": "Invalid string value: 'asdf'. Allowed values: [mostpopular]"
 }
}
```

[Microsoft Graph API](https://learn.microsoft.com/ja-jp/graph/errors#http-status-codes)

```json
{
  "error": {
    "code": "badRequest",
    "message": "Uploaded fragment overlaps with existing data.",
    "innerError": {
      "code": "invalidRange",
      "request-id": "request-id",
      "date": "date-time"
    }
  }
}
```

[Facebook API](https://developers.facebook.com/docs/graph-api/guides/error-handling?locale=ja_JP)

```json
{
  "error": {
    "message": "Message describing the error", 
    "type": "OAuthException", 
    "code": 190,
    "error_subcode": 460,
    "error_user_title": "A title",
    "error_user_msg": "A message",
    "fbtrace_id": "EJplcsCHuLu"
  }
}
```

#### RFC 9457

[RFC 9457](https://www.rfc-editor.org/rfc/rfc9457.html)でHTTP APIで発生する問題の詳細を表現するための標準形式を定義しています。

```json
{
    "type":"https://problems-registry.smartbear.com/missing-body-property",
    "status":400,
    "title":"Missing body property",
    "detail":"The request is missing an expected body property.",
    "code":"400-09",
    "instance":"/logs/regisrations/d24b2953-ce05-488e-bf31-67de50d3d085",
    "errors":[
       {
          "detail":"The body property {name} is required",
          "pointer":"/name"
       }
    ]
 }
```

| フィールド    | 型         | 概要                                                         |
|---------------|------------|--------------------------------------------------------------|
| **type**([必須](https://www.rfc-editor.org/rfc/rfc9457.html#name-defining-new-problem-types))      | JSON文字列 | エラーの種類を識別するURI。解決可能なURIや非解決可能なURI、単純なエラーコードが使用される。 |
| **status**  ([必須](https://www.rfc-editor.org/rfc/rfc9457.html#name-defining-new-problem-types))   | JSON数値   | オリジン サーバーによって生成された HTTP ステータス コード                           |
| **title**([必須](https://www.rfc-editor.org/rfc/rfc9457.html#name-defining-new-problem-types))     | JSON文字列 | エラーの種類を簡潔に説明する人間が読みやすいテキスト。 題が発生するたびに変更すべきではありません。         |
| **detail**    | JSON文字列 | エラー発生の具体的な詳細を説明するテキスト。タイトルとは異なり、このフィールドの内容は出現ごとに異なる場合があります。                    |
| **instance**  | JSON文字列 | 特定のエラー事象を識別するURI。エラー事象の詳細情報へのリンクや一意の識別子として機能することがある。 |
| **extension** |            | 特定の問題タイプに固有の追加メンバー。例として、             |
|               |            | - **balance** (JSON数値): 利用可能な残高を表示します。           |
|               |            | - **accounts** (JSON配列): 関連するアカウントのリストを提供します。|
|               |            | - **errors** (JSONオブジェクト): バリデーションエラーのリストを含み、各エラーの詳細と位置を指摘します。 |

>New problem type definitions MUST document:
>
>1. a type URI (typically, with the "http" or "https" scheme)
>2. a title that appropriately describes it (think short)
>3. the HTTP status code for it to be used with

参考

- [swagger Problem Details (RFC 9457): Doing API Errors Well](https://swagger.io/blog/problem-details-rfc9457-doing-api-errors-well/)
- [.NETでRFC 9457準拠のクラスProblemDetails Class](https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.mvc.problemdetails?view=aspnetcore-8.0)
- [RFC 9457](https://tex2e.github.io/rfc-translater/html/rfc9457.html)

## API Version Management

**目的**

APIのversion管理を導入する主な目的は、新しいversionのAPIがリリースされても、古いversionを使用しているクライアントが引き続き機能するようにすることです。これにより、安定性と互換性を保ちつつ、新機能の導入やセキュリティの改善が可能となります。

 **推奨されるURI構造**

version管理をURIに反映させる一般的な方法は、以下のような形式です：

```bash
https://{FQDN}/v{version-number}/users

```

- `v{version-number}`: version番号を明示するために `v` を前置します。これにより、どのversionのAPIを呼び出しているかが一目で明確になります。
- `{version-number}`: 通常はメジャーversionの整数を使用します。セマンティックバージョニングを採用することもありますが、URLでの利用にはメジャーversionが最も適しています。

**クエリパラメータによるversion指定**
クエリパラメータを使用してAPIのversionを指定する方法もありますが、次の理由で私は推奨されません：

- 省略時の挙動: クエリパラメータが省略された場合、自動的に最新のversionのAPIが呼び出されるため、仕様が変更された際にクライアントアプリケーションが予期せず壊れるリスクがあります。
- 冗長性: クエリが冗長的に見え、URLの構造が複雑になるため、管理が煩雑になりがちです。

**バージョンを変更する方針**

APIのバージョンを更新する主な理由は、後方互換性を保持できなくなったときです。

たとえば:

- **APIのエンドポイントの入力パラメータや返却値の変更**: 既存のAPIエンドポイントに新しい入力パラメータを追加する場合や、返却するデータ形式を変更する場合、これらの変更が既存のクライアントに影響を与える可能性があるため、新バージョンをリリースします。
- **機能の削除**: 使われなくなった機能や非効率なエンドポイントをAPIから削除する場合、後方互換性が失われるため、バージョンを上げる必要があります。

## セキュリティ

APIを設計する際には、以下のセキュリティ対策を講じることが重要です。

- HTTPSを使用しよう: すべての通信をHTTPSを通じて行うことで、データの傍受や改ざんを防ぎます。

- XSS（クロスサイトスクリプティング）対策:
  - レスポンスでの対策: `Content-Type: application/json`と明示することで、ブラウザがレスポンスをJSONとして解釈し、スクリプトとして実行されるリスクを減らします。
  - 入力の検証とエスケープ: ユーザーからの入力を適切に検証し、HTMLエスケープ処理を行うことで、悪意のあるスクリプトが埋め込まれることを防ぎます。

- XSRF（クロスサイトリクエストフォージェリ）対策:
  - XSRFトークンの使用: フォームやAJAXリクエストに対して、サーバーから提供される一時的なトークンを使用し、リクエストが正当なものであるかを検証します。

## 公開されているAPIをまとめたサイト

- [RapidAPI](https://rapidapi.com/)
