---
title: "IdentityServerの紹介: OAuth 2.0 と OpenID Connectのサーバーの実装をサポート"
date: 2023-10-13T07:24:00
categories:
  - tech
  - oauth
  - csharp
  - dotnet
description: ""
---

最近、Duendeのドキュメントで[Add Support for External Authentication](https://docs.duendesoftware.com/identityserver/v6/quickstarts/2_interactive/#add-support-for-external-authentication)セクションを試していて、Googleの認証情報でのOAuth 2.0 クライアント IDの設定部分で困りました。具体的には、承認済みのリダイレクトURIにどの値を設定するべきかがわからなかったのです。

しかし、結論から言うと、このURIは `https://localhost:5001/signin-google` でした。この解決方法を見つけたのは、Google認証画面で「このアプリのリクエストは無効です」というエラーメッセージが表示された際のURLをチェックしたことでした。このURLにはRedirectURLの値が含まれており、それによって承認済みのリダイレクトURLを確認することができました。

```url
https://accounts.google.com/o/oauth2/v2/auth?response_type=code?&client_id={clientId}&redirect_uri=https://localhost:5001/signin-google&scope=openid profile email&state={stateHash}
```

後で気付いたのですが、[identityserver4.readthedocs.io](https://identityserver4.readthedocs.io/en/aspnetcore1/quickstarts/4_external_authentication.html) にも同じ内容が明確に記載されていました。

IdentityServerは多くの外部OAuthプロバイダと統合することができます。以下はいくつかの一般的なOAuthプロバイダと、それに関連するデフォルトのリダイレクトURLのリストです：

- **Google**: <http://localhost:5000/signin-google>
- **Facebook**: <http://localhost:5000/signin-facebook>
- **Twitter**: <http://localhost:5000/signin-twitter>
- **Microsoft (Azure AD)**: <http://localhost:5000/signin-microsoft>
- **GitHub**: <http://localhost:5000/signin-github>
