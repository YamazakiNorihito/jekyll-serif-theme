---
title: "OAuth 2.0承認フレームワークのシーケンス図"
date: 2023-10-08T10:00:00
weight: 4
mermaid: true
categories:
  - tech
  - oauth
description: ""
---

OAuth 2.0承認フレームワークのAuthorization Code Grant を使った、
サードパーティアプリケーションがアクセス制限されたリソース（保護されたリソース）へ
アクセスするまでの流れを図にします。

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
      Client-->>ResourceOwner: J. Return Requested Resource

```

※Refresh TokenのフローはステップFから始めます。Access Tokenが期限切れの場合、Clientは保存していたRefresh TokenをステップFでAuthorization ServerにRequestすることで、新しいAccess Tokenを取得することができます。

[RFC 6749 - The OAuth 2.0 Authorization Framework](https://tex2e.github.io/rfc-translater/html/rfc6749.html)
