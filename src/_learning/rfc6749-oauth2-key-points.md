---
# 70文字以内
title: "RFC 6749 OAuth2 の主要なところを読んでみた。"
date: 2024-12-18T13:34:00
linkedinurl: ""
weight: 7
tags:
  - RFC 6749
# 20文字から160文字以内
description: ""
---

## grant types defined

忘れてはいけない、どの方法も全て最終的にAccess Tokenを取得することを

- [Authorization Code Grant](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1)
- [Implicit Grant](https://datatracker.ietf.org/doc/html/rfc6749#section-4.2)
- [Resource Owner Password Credentials Grant](https://datatracker.ietf.org/doc/html/rfc6749#section-4.3)
- [Client Credentials Grant](https://datatracker.ietf.org/doc/html/rfc6749#section-4.4)
- Implicit Grant

## Access Token

- Protected Resources（保護されたリソース）へのアクセスを制御するための文字列。
- Authorization Server によってclientに発行される。
- clientにとってAccess Tokenの文字列の内容が不明瞭（opaque）。
- 認可（Authorization）のスコープと有効期限を表す
- 認可構造の**抽象化**
  - 抽象化により、リソースサーバーはトークンのみを理解すればよく、認可の具体的な実装（例: 認証方法やユーザー情報の形式）に依存しない設計を実現する。
  - あらゆる認可手段（例: ユーザー名とパスワード）を単一のトークンに置き換える。
  - リソースサーバー側の実装を簡素化（多様な認証方法を理解する必要がなくなる）。

## Refresh Token

- authorization servers に対してのみ使われる
- Resource Servers には送信されることはない
- 主にアクセストークンの再発行に使用される
- clientにとって内容が不明瞭（opaque）
  - リフレッシュトークンの文字列は、clientにはその詳細がわからない形で設計されている
- Access Token と同時に発行される
  - Authorization Server がリフレッシュトークンを発行する場合、アクセストークン発行時に同時に付与される
- 発行の判断は Authorization Server の裁量
  - Authorization Server がリフレッシュトークンを発行するかどうかは任意であり、仕様に必須ではない
- 使用されるシチュエーション
  1. Access Token の期限切れ
  2. Access Token の無効化
  3. Resource Owner による権限範囲の変更
     - 例: 同じスコープでの再発行、またはより狭いスコープのアクセストークンを取得する場合

## Client

### Client Types

1. confidential
   1. credential（認証情報）を安全に保管できるclient。
   2. 例
      1. サーバーサイドで動作するウェブアプリケーションのバックエンド
      2. APIを呼び出す専用のバックエンドプロセス。
2. public
   1. credential（認証情報）を安全に保管できないclient。
   2. 例
      1. スマートフォンアプリ（ネイティブアプリ）
      2. シングルページアプリケーション（SPA）

### Client Identifier

- Authorization Server 内でclientに割り振る一意の文字列。
- 秘密ではなく、単独でclient認証に使用してはならない。
- サイズは未定義だが、実装時には明記するべき。

### Client Authentication

- **対象**: Confidential clientのみclient認証が可能。
- **認証方式**:
  1. **HTTP Basic 認証方式**（推奨）:
     - clientIDとシークレットを Base64 エンコードし、ヘッダーに送信。
     - 例: `Authorization: Basic base64(client_id:client_secret)`
  2. **リクエストボディ方式**（非推奨）:
     - client_idとclient_secretをリクエストボディに含める。
       - HTTP Basic 認証方式を直接利用できないclientのみ利用することを推奨
     - 例:

       ```bash
        client_id=client123&client_secret=secret456
       ```

- **注意事項**:
  - TLS（HTTPS）必須。
  - リクエストボディ方式はセキュリティリスクがあるため非推奨。
  - ブルートフォース攻撃対策を実施。

## Protocol Endpoints

- Authorization endpoint
  - clientがリソース所有者の認可を取得するために使用  
    （例: <https://example.com/authorize?response_type=code&client_id=123）>
  - Authorization Server はリソース所有者の身元を検証する必要がある  
    （認証方式は任意: ユーザー名とパスワード、セッションクッキーなど）
  - URIにフラグメント (#fragment) を含めてはいけない
  - 同一のパラメータ名を1つのリクエストやレスポンス内に複数回設定してはいけない
  - response_type パラメータは必須  
    （code や token など、どのフローを利用するかを伝える）
  - エンドポイントのコンテンツ（特にリダイレクト先のHTML）を直接レンダリングする場合は、URIに含まれるトークン情報がスクリプトから取得されるリスクがある
    - 広告やSNSプラグインなどの第三者スクリプトは必要最小限にとどめる
    - トークンを受け取ったら、すぐにURIから除去して別ページへリダイレクトする実装が推奨される
- Token endpoint
  - clientが認可グラントをaccess tokenと交換するために使用。
    - POSTメソッドを必ず使用。
    - HTTPリクエスト/レスポンスで平文の資格情報が送信されるため、TLSの使用が必須。
  - Client認証は必須（MUST）
    - Token Endpointでは、ClientId と ClientSecret を使って認証する必要がある。
  - refresh tokens と authorization codes の関連付け
    - トークンやコードが意図しないclientで使用されるリスクを防ぐため、Clientとの関連付けが重要。
  - 侵害されたclientへの対応
    - clientが侵害された場合、次の方法で対応：
      - clientを無効化する。
      - 資格情報（ClientId や ClientSecret）を変更し、悪用を防ぐ。
  - 資格情報の定期的なローテーション
    - セキュリティ強化のため、資格情報は定期的に更新する（ベストプラクティス）。
- Redirection endpoint
  - 必ずauthorization serverに登録必須項目
  - 認可サーバーがauthorization credentialsをclientにresponse type is "code" or "token"を返すために使用。
  - redirection endpoint URIは絶対URLであるべき
    - URIにフラグメント (#fragment) を含めてはいけない
    - TLSの使用が必須
  - 認可サーバーは、clientが完全なリダイレクトURIを指定することを推奨
    - 完全なリダイレクトURI例: <https://example.com/callback?client_id=1234&state=abc>
    - 完全なURI登録が不可能な場合(QueryParamをDynamicに設定したい場合は)：
      - URI scheme、ホスト（authority）、およびpathを登録し、クエリパラメータのみ動的に変更可能とするべき。
        - 例:
          - 登録URI: <https://example.com/callback>
          - 実際のリダイレクトURI: <https://example.com/callback?state=xyz>
  - 複数のリダイレクトURIが登録されている場合、または部分的なURIのみが登録されている場合、またはURIが登録されていない場合
    - clientは、認可リクエストでredirect_uriリクエストパラメータを必ず含める
  - 認可リクエストにリダイレクトURIが含まれている場合
    - 認可サーバーは、受信したURIを登録されたリダイレクトURIと比較・照合する必要がある
- Access Token Scope
  - Scopeの指定
    - AuthorizationエンドポイントとTokenエンドポイントでは、clientがアクセス要求のスコープを指定するためにscopeリクエストパラメータを使用できます。
    - 発行されたaccess tokenのスコープは、authorization serverがscopeレスポンスパラメータを使用してclientに通知します。
  - Scopeの形式
    - scopeパラメータの値は、スペースで区切られた大小文字区別の文字列リストで表されます。
    - 各文字列はauthorization serverによって定義され、順序は無関係です。
    - ABNF形式

        ```txt

  scope       = scope-token *( SP scope-token )
  scope-token = 1*( %x21 / %x23-5B / %x5D-7E )
        ```

      - 各トークンは、少なくとも 1 文字以上の文字列から成ります (1*)。
      - トークン内で使える文字は、以下の範囲に含まれます：
        - %x21: ! (ASCII コード 33)
        - %x23-5B: # から [ までの文字
        - %x5D-7E: ] から ~ までの文字
      - 例
        - `read write user:manage`

## Obtaining Authorization

access tokenを取得するまでのFlow
図解はRFCを[見て](https://datatracker.ietf.org/doc/html/rfc6749#section-4)

1. Authorization Code Grant
   1. access tokens and refresh tokens 両方を取得できる
   2. Step
      1. (A) clientがAuthorizationリクエストを開始  
         1. clientはリソースオーナーのUser-Agent（例: ブラウザ）をauthorization serverにリダイレクトする。  
         2. clientID、Scope、State、Redirection URIを含める。
         3. Requestの内容は[4.1.1.  Authorization Request](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.1)を見て
      2. (B) authorization serverがリソースオーナーを認証  
         1. サーバーはユーザーを認証し、アクセス要求を許可するか拒否するかを判断する。
      3. (C) authorization serverがAuthorization Codeを発行  
         1. アクセスが許可された場合、サーバーはUser-Agentを指定されたRedirection URIにリダイレクトする。  
         2. リダイレクトにはAuthorization CodeとStateが含まれる。
         3. authorization serverからのResponseの内容は[4.1.2.  Authorization Response](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.2)を見て
      4. (D) clientがAccess Tokenを要求  
         1. clientはAuthorization Codeを使用して、authorization serverのTokenエンドポイントにAccess Tokenをリクエストする。  
         2. このとき、Redirection URIも送信され、検証が行われる。
         3. authorization serverへのAccess Token Requestの内容は[4.1.3.  Access Token Request](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.3)を見て
      5. (E) サーバーがAccess Tokenを発行  
         1. サーバーはclient、Authorization Code、Redirection URIを検証する。  
         2. 検証が成功した場合、Access Tokenと必要に応じてRefresh Tokenをclientに発行する。
2. Implicit Grant
   1. Access Token のみを取得可能（Refresh Tokenは発行されない）。
   2. Client認証を含まず、リソースオーナーの存在とRedirection URIの登録に依存する。
   3. Access TokenがURIフラグメントに含まれるため、リソースオーナーや同じデバイス上の他アプリケーションに露出する可能性がある。
   4. Step
      1. (A) クライアントがリクエストを開始
         1. クライアントはリソースオーナーのユーザーエージェント（例: ブラウザ）をAuthorizationエンドポイントにリダイレクトする。
         2. Requestの内容は[4.2.1.  Authorization Request](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.2)を見て
      2. (B) Authorization Serverがリソースオーナーを認証
         1. リソースオーナーを認証し、アクセス要求を許可または拒否する。
      3. (C) Authorization ServerがAccess Tokenを発行
         1. アクセスが許可された場合、Authorization ServerはRedirection URIにリソースオーナーのUser-Agentをリダイレクトする。
         2. Redirection URIにはAccess TokenがURIフラグメントとして含まれる。
         3. authorization serverへのAccess Token Requestの内容は[4.2.2.  Access Token Response](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.2)を見て
      4. (D) ユーザーエージェントがリダイレクトをフォロー  
         1. ユーザーエージェントはフラグメント情報をローカルに保持しながら、Webホストされたクライアントリソースにリクエストを送る。
      5. (E) クライアントリソースがスクリプトを提供  
         1. クライアントリソースはリダイレクトされたフラグメント情報を含むHTMLページ（スクリプト埋め込み）を返す。
      6. (F) スクリプトがフラグメントを解析  
         1. ユーザーエージェントがスクリプトを実行し、フラグメント内のAccess Tokenを抽出する。
      7. (G) Access Tokenがクライアントに渡される  
         1. ユーザーエージェントがクライアントにAccess Tokenを渡す。
3. Resource Owner Password Credentials Grant
   1. リソースオーナーがクライアントと信頼関係を持っている場合に適用される（例: デバイスのOSや特権の高いアプリケーション）。
   2. クライアントがリソースオーナーの資格情報（ユーザー名とパスワード）を取得可能な場合に適している。
   3. クライアントはAccess Tokenを取得した後、リソースオーナーの資格情報（ユーザー名とパスワード）を破棄しなければならない
   4. Step
      1. (A) リソースオーナーが資格情報を提供
         1. リソースオーナーがクライアントにユーザー名とパスワードを提供する。
      2. (B) クライアントがAccess Tokenをリクエスト
         1. クライアントは、リソースオーナーから受け取った資格情報を使用して、Authorization ServerのTokenエンドポイントにAccess Tokenをリクエストする。
         2. このリクエスト時に、クライアントはAuthorization Serverに対して認証を行う。
         3. authorization serverへのAccess Token Requestの内容は[4.3.2.  Access Token Request](https://datatracker.ietf.org/doc/html/rfc6749#section-4.3.2)を見て
      3. (C) Authorization Serverが認証とトークン発行
         1. Authorization Serverはクライアントの認証を行い、リソースオーナーの資格情報を検証する。
         2. 資格情報が有効であれば、Access Tokenを発行する。
4. Client Credentials Grant
   1. クライアントが自分の管理下にあるリソース、または事前に合意された他のリソースオーナーの保護リソースにアクセスする際に使用される。
   2. クライアント資格情報のみを使用してアクセスをリクエストする。
   3. Step
      1. (A) クライアントが認証およびトークンのリクエストを実行
         1. クライアントはAuthorization Serverに認証を行い、TokenエンドポイントからAccess Tokenをリクエストする。
         2. authorization serverへのAccess Token Requestの内容は[4.4.2.  Access Token Request](https://datatracker.ietf.org/doc/html/rfc6749#section-4.4.2)を見て
      2. (B) Authorization Serverがクライアントを認証し、トークンを発行  
         - Authorization Serverはクライアントを認証し、認証が成功した場合にAccess Tokenを発行する。

## Error Response

認可フロー中にリクエストが失敗した場合、

- リダイレクトURIが欠落・無効・不一致、またはクライアントIDが無効/欠落の場合:
  - 認可サーバーはユーザーにエラーを通知すべき（SHOULD）。
  - 不正なリダイレクトURIにはリダイレクトしてはならない（MUST NOT）。

- それ以外の理由で失敗（例: ユーザーが拒否）:
  - 認可サーバーはリダイレクトURIにエラー情報を付加してクライアントに通知。
  -

| パラメータ | 必須条件         | 説明     | 例           |
|-------------|-------------|-------------|-------------|
| `error` | 必須          | エラーの種類を表すASCII文字列のコード。    | `invalid_request`, `unauthorized_client`   |
| `error_description` | 任意          | エラーに関する追加情報を提供する、人間が読める形式のASCIIテキスト。クライアント開発者がエラーを理解するのに役立つ情報を提供。             | "Invalid parameter value"        |
| `error_uri`       | 任意          | エラーの詳細情報が記載された人間が読めるウェブページへのリンクを示すURI。    | `https://example.com/error-info` |
| `state` | リクエストに含まれる場合必須 | クライアント認可リクエストで受け取った`state`パラメータの正確な値を返す。レスポンスの整合性を確保するため。  | `xyz`        |

### `error`コード一覧

| コード           | 説明         |
|-------------|-------------|
| `invalid_request`        | 必須パラメータが不足している、パラメータ値が無効、パラメータが重複している、またはリクエストが不正な形式である。|
| `unauthorized_client`    | クライアントがこのメソッドを使用して認可コードを要求する権限を持っていない。           |
| `access_denied`          | リソースオーナーまたは認可サーバーがリクエストを拒否した。              |
| `unsupported_response_type` | 認可サーバーが要求されたレスポンス型をサポートしていない。           |
| `invalid_scope`          | 要求されたスコープが無効、不明、または不正な形式である。              |
| `server_error` | 認可サーバーで予期しないエラーが発生した。  |
| `temporarily_unavailable`| サーバーが一時的に過負荷やメンテナンスによりリクエストを処理できない。             |

## Accessing Protected Resources

protected resource serverは、access tokenを検証し、有効期限が切れていないこと、リクエストされたリソースをカバーするスコープを持っていることを確認しなければなりません。

### Access Token Types

1. Access Token の種類
   1. Bearer トークン: トークン文字列をそのままリクエストに含める簡単な方式。
   2. MAC トークン: トークンと一緒に発行されるMACキーでリクエストを署名するセキュアな方式。
2. token_typeの役割
   1. アクセストークンがどのタイプかを示すもの。（例: "token_type": "Bearer"）
   2. クライアントはこの情報を基にトークンを正しく使用する必要がある。
3. クライアントがすべきこと
   1. token_typeをレスポンスから読み取り、トークンタイプを理解する。
   2. リソースサーバーへのリクエスト時に、対応するフォーマットを使用する。
