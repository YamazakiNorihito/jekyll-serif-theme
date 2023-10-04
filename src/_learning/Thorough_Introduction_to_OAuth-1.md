---
title: "OAuth徹底入門(1)"
date: 2023-10-05T08:19:00+09:00
#image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: "Client Callbackのredirect_uriの役割"
linkedinurl: ""
weight: 7
---

##### 学習教材
# 学習教材

- **日本語**: [OAuth徹底入門](https://www.amazon.co.jp/OAuth%E5%BE%B9%E5%BA%95%E5%85%A5%E9%96%80-%E3%82%BB%E3%82%AD%E3%83%A5%E3%82%A2%E3%81%AA%E8%AA%8D%E5%8F%AF%E3%82%B7%E3%82%B9%E3%83%86%E3%83%A0%E3%82%92%E9%81%A9%E7%94%A8%E3%81%99%E3%82%8B%E3%81%9F%E3%82%81%E3%81%AE%E5%8E%9F%E5%89%87%E3%81%A8%E5%AE%9F%E8%B7%B5-Justin-Richer/dp/4798159298)
- **英語**: [OAuth 2 in Action](https://www.manning.com/books/oauth-2-in-action)

##### コードのコメント

`3.2.2. Processing the authorization response`のセクションに関するコメント：

```javascript
var form_data = qs.stringify({
  grant_type: 'authorization_code',
  code: code,
  redirect_uri: client.redirect_uris[0]
});
```

> As an aside, why do we include the redirect_uri in this call? We’re not redirecting anything, after all. According to the OAuth specification, if the redirect URI is specified in the authorization request, that same URI must also be included in the token request. This practice prevents an attacker from using a compromised redirect URI with an otherwise well-meaning client by injecting an authorization code from one session into another. We’ll look at the server-side implementation of this check in chapter 9.
> 
> We also need to send a few headers to tell the server that this is an HTTP form-encoded request, as well as authenticate our client using HTTP Basic. The Authorization header in HTTP Basic is a base64 encoded string made by concatenating the username and password together, separated by a single colon (:) character. OAuth 2.0 tells us to use the client ID as the username and the client secret as the password, but with each of these being URL encoded first.[1] We’ve given you a simple utility function to handle the details of the HTTP Basic encoding.

##### 調査内容

###### redirect_uriの役割

リダイレクトURIをこの呼び出しに含める理由は、OAuthの仕様に基づくものです。認可リクエストでリダイレクトURIが指定されている場合、トークンリクエストにもその同じURIを含める必要があります。この方法は、攻撃者が意図的なクライアントとともに危険なリダイレクトURIを使用して、あるセッションから別のセッションに認可コードを注入するのを防ぐためのものです。

###### HTTPヘッダーの送信

サーバーにHTTPフォームエンコードリクエストであることを伝えるためのヘッダーを送信する必要があります。さらに、HTTP Basicを使用してクライアントを認証する必要があります。OAuth 2.0は、クライアントIDをユーザー名として、クライアントシークレットをパスワードとして使用するように指示していますが、これらのそれぞれを最初にURLエンコードする必要があります。

###### redirect_uriの役割とは？

OAuth 2.0の認証フローにおいて、`redirect_uri`は「認証が完了した後にユーザーをどこに戻すか」を指定するためのURLです。しかし、トークンリクエストの際にも`redirect_uri`を再度指定する理由は、セキュリティ上のものです。これにより、攻撃者が不正なコードやトークンを注入するのを防ぐことができます。
