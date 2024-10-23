---
title: "ASP.NET Core: UseAuthentication と UseAuthorization の順序の重要性"
date: 2023-10-12T07:27:00
weight: 4
categories:
  - tech
  - oauth
  - dotnet
description: ""
---

## ASP.NET Core: `UseAuthentication` と `UseAuthorization` の順序の重要性

ASP.NET Coreにおいて、ミドルウェアの順序は特に重要です。中でも、`UseAuthentication`
と `UseAuthorization` の順序は、セキュリティ上の理由から正確に配置する必要があります。

#### なぜこの順序が重要なのか？

1. **UseAuthentication**: このミドルウェアは、HTTPリクエストから資格情報を読み取り、
2. それを現在のユーザーとして認識します。このプロセスの後、ユーザーの情報やクレームはユーザーのコンテキストとして利用可能になります。
3. **UseAuthorization**: このミドルウェアは、先に識別されたユーザーの情報を基に、特定のリソースやエンドポイントへのアクセスを許可または拒否します。

この順序を逆にすると、認可の際にユーザー情報がまだ読み取られていない可能性があります。そのため、認可プロセスが正しく機能しなくなる可能性があります。

#### 実体験

Identity Serverのチュートリアルを進めている際、私は`UseAuthentication`と`UseAuthorization`の順序を誤って逆にしてしまいました。結果として、TokenやScopeは正常に発行されていたにも関わらず、Protected APIへのアクセス時に`Unauthorized`エラーが発生しました。このエラーには少し手間取りましたが、この順序の重要性を改めて認識する良い機会となりました。

#### まとめ

認証は「誰か」を特定するプロセスであり、認可はその特定された「誰か」が何をしていいのかを判断するプロセスです。したがって、まずユーザーを特定する必要があり、次にそのユーザーの許可されたアクションを判断します。この順序を逆にすると、認可の判断が正しく行えなくなる可能性があります。

#### 参考リンク

- [MSドキュメント][ASP.NET Core のミドルウェア](https://learn.microsoft.com/ja-jp/aspnet/core/fundamentals/middleware)
