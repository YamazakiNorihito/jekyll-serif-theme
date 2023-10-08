---
title: "OAuth認証フローのシーケンス図"
date: 2023-10-08T10:00:00
weight: 4
mermaid: true
categories:
  - tech
  - oauth
---

OAuth 2.0承認フレームワークを使って、
サードパーティアプリケーションがHTTPサービスへの制限付きアクセスするまでの
流れを図にします。

Webサイト（以下、Client）の特定の機能を利用する際に、
Salesforce API（以下、Resource Server）からAccountのレコードを安全に取得する方法について説明します。
OAuth 2.0承認フレームワークを使用すると、
Salesforceの連携ユーザー（以下、ResourceOwner）のログインIDとパスワードをClientに共有せずに、
どのようにデータを取得するかに焦点を当てています。


```mermaid

  sequenceDiagram
      participant ResourceOwner as Resource Owner
      participant Client as Client
      participant AuthServer as Authorization Server
      participant ResourceServer as Resource Server
      
      ResourceOwner->>Client: A. Access Client
      Client->>AuthServer: B. Redirect to Authorization Server
      AuthServer-->>ResourceOwner: C. Prompt for Authentication
      ResourceOwner->>AuthServer: D. Authenticate & Authorize Client
      AuthServer-->>Client: E. Authorization Grant
      Client->>AuthServer: F. Present Authorization Grant
      AuthServer-->>Client: G. Issue Access Token
      Client->>ResourceServer: H. Request to Protected Resource with Access Token
      ResourceServer-->>Client: I. Validate Access Token & Accept Request
      Client-->>ResourceOwner: J. Return Salesforce Account Records

```

[RFC 6749 - The OAuth 2.0 Authorization Framework](https://tex2e.github.io/rfc-translater/html/rfc6749.html)