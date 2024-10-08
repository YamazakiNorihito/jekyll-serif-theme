---
title: "IdentityResource-vs-ApiResource-vs-ApiScope"
date: 2023-11-10T08:15:00
weight: 4
mermaid: true
categories:
  - tech
  - oauth
  - csharp
  - dotnet
description: ""
---

IdentityResource/ApiResource/ApiScope それぞれの役割がわからなくなったので
自分なりの整理をしてみた。
下記の記事を参考にしています。
[IdentityServer – IdentityResource vs. ApiResource vs. ApiScope](https://nestenius.se/2023/02/02/identityserver-identityresource-vs-apiresource-vs-apiscope/)

- Identity Scopes
  - 主にユーザーのアイデンティティ情報（例えば、ユーザー名、メールアドレス）に関連しています。
  - スコープが要求されると、要求されたクレームはIDトークンに含まれます。
  - IDトークンは、ユーザーのアイデンティティを表すために使用されます。
- Access Scopes
  - クライアントアプリケーションがアクセスを要求するAPIの機能やデータへのアクセスを制御します。
  - スコープが要求されると、要求されたクレームはアクセストークンに含まれます。
- API Resources
  - IdentityServerにおける特定のAPIやサービスを表します。
  - アクセススコープと関連付けられ、アクセストークンのaud（オーディエンス）クレームを通じて、そのトークンが特定のAPIに対して有効であることを指定します。
  - トークンが特定のAPIに対してのみ使用されることを保証し、セキュリティを強化します。
