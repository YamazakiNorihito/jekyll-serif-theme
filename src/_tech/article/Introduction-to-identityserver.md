---
title: "IdentitySeverの紹介(OAuth 2.0およびOpenID Connectのサーバーの実装をサポート)"
date: 2023-10-12T06:34:00
weight: 4
categories:
  - tech
  - oauth
  - csharp
---

# IdentityServerの紹介

IdentityServerは、現代のWebアプリケーションやAPIのセキュリティを
担保するための強力なフレームワークです。
主に.NET環境でのOAuth 2.0およびOpenID Connectのサーバーの
実装をサポートしています。

## 特徴:

1. **モダンなプロトコル**: OAuth 2.0, OpenID Connect, JWTなどの現代のセキュリティプロトコルを完全にサポート。
2. **統合と拡張性**: ASP.NET Coreとの深い統合を持ちながら、多くのカスタマイズポイントを提供。ユーザーストアの変更、トークンの生成方法、認証手段など、多岐にわたる拡張が可能です。
3. **APIの保護**: APIのエンドポイント保護と、適切なトークンに基づくアクセス制御が容易。

## 使用シナリオ:

- **Single Sign-On/Single Sign-Out**: 複数のアプリケーション間での一度のログインやログアウトを実現。
- **APIの認証・認可**: アクセスを制御し、認証されたクライアントやユーザーのみがAPIを利用できるように。
- **外部認証**: GoogleやFacebookなどの外部認証プロバイダとの統合も可能。

## カスタマイズの柔軟性:

IdentityServerはその設計から高いカスタマイズ性を持っています。例えば、独自のユーザーストアの統合、
特定の認証方法のカスタマイズ、UIのデザイン変更など、
さまざまなニーズに応じてIdentityServerをカスタマイズすることができます。

## ライセンスについて:

- **Community Edition**: Enterprise Editionと同等の機能を持ちつつ、標準的な開発者サポートのみを提供。自社のインフラやクラウドでのホスティングに適していますが、再配布や第三者向けのソフトウェア開発には使用できません。そのような場合は別のライセンス取得が必要となります。
- **ライセンス不要なケース**:
  - 営利企業や個人で、予想される年間の総収益が1M USD以下、または資本設備へのアクセスが3M USD以下の場合。
  - 年間予算が1M USD以下の非営利組織。
  - 公に登録されている慈善団体。
  - 評価、開発、テスト環境、または個人プロジェクトのためにはライセンスは不要。起動時の警告メッセージは無視しても良い。

## 参考リンク

- [MSドキュメント][クラウドネイティブ アプリケーション用の IdentityServer](https://learn.microsoft.com/ja-jp/dotnet/architecture/cloud-native/identity-server)
- [duende公式サイト][IdentityServer](https://duendesoftware.com/products/identityserver)
- [duende公式サイト][IdentityServer communityedition](https://duendesoftware.com/products/communityedition)
- [Identityドキュメント][IdentityServer4](https://identityserver4-ja.readthedocs.io/ja/latest/)
