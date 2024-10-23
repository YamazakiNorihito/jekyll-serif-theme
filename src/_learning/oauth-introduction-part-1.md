---
title: "OAuth徹底入門(1)"
date: 2023-10-05T08:19:00
##image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: "Client Callbackのredirect_uriの役割"
linkedinurl: ""
weight: 7
tags:
  - OAuth
  - Security
  - redirect_uri
  - Authorization
  - Authentication
  - Access Token
  - Identity Management
  - Learning Resources
description: ""
---

## `3.2.2. Processing the authorization response`における`redirect_uri`の理解

初めてこのセクションを読んだ際、`redirect_uri`に関するコメントの意味が理解できませんでした。ので、ちょっと調べてみました。

本文中のコメント：
> As an aside, why do we include the redirect_uri in this call? We’re not redirecting anything, after all. According to the OAuth specification, if the redirect URI is specified in the authorization request, that same URI must also be included in the token request. This practice prevents an attacker from using a compromised redirect URI with an otherwise well-meaning client by injecting an authorization code from one session into another. We’ll look at the server-side implementation of this check in chapter 9.

```javascript
var form_data = qs.stringify({
  grant_type: 'authorization_code',
  code: code,
  redirect_uri: client.redirect_uris[0]
});
```

#### 調査内容

###### redirect_uriの役割

リダイレクトURIをこの呼び出しに含める理由は、OAuthの仕様に基づくものです。認可リクエストでリダイレクトURIが指定されている場合、トークンリクエストにも同じURIを指定する必要があります。この手段は、攻撃者が意図的なクライアントと共に危険なリダイレクトURIを使用し、あるセッションから別のセッションへ認可コードを注入するのを防ぐためのものです。

###### redirect_uriの本質

OAuth 2.0の認証フローにおいて、`redirect_uri`は認証完了後のユーザーのリダイレクト先を指定するURLです。しかし、なぜトークンリクエストで`redirect_uri`を再度指定するのかというと、それはセキュリティ上の理由からです。この手順により、攻撃者が不正なコードやトークンを注入することを防ぎます。

#### 学習教材

- **日本語**: [OAuth徹底入門](https://www.amazon.co.jp/OAuth%E5%BE%B9%E5%BA%95%E5%85%A5%E9%96%80-%E3%82%BB%E3%82%AD%E3%83%A5%E3%82%A2%E3%81%AA%E8%AA%8D%E5%8F%AF%E3%82%B7%E3%82%B9%E3%83%86%E3%83%A0%E3%82%92%E9%81%A9%E7%94%A8%E3%81%99%E3%82%8B%E3%81%9F%E3%82%81%E3%81%AE%E5%8E%9F%E5%89%87%E3%81%A8%E5%AE%9F%E8%B7%B5-Justin-Richer/dp/4798159298)
- **英語**: [OAuth 2 in Action](https://www.manning.com/books/oauth-2-in-action)
