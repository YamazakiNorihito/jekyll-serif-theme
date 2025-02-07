---
title: "OAuth徹底入門(3)"
date: 2023-10-09T7:00:00
jobtitle: "OAuthのコンポーネントの役割"
linkedinurl: "/tech/article/OAuth-%20Sequence_Diagram/"
weight: 7
tags:
  - OAuth 2.0
  - Authentication
  - Authorization Server
  - Security Best Practices
  - Access Token Management
  - Identity Management
  - API Security
  - OAuth Components
description: "OAuthの主要コンポーネント（Client, Authorization Server, Protected Resource）の役割とそれぞれの役割を理解し、OAuth認証フローを正しく実装するための基本を学びます。"
---

## OAuthのコンポーネントの役割

### 1. Client（クライアント）

**主な役割**:

- リソースオーナーに代わって、保護されたリソースにアクセスするためのトークンを要求します。

**やるべきこと**:

- リソースオーナーからの明確な同意を取得する。
- AuthServerにリダイレクトして、認可コードまたはトークンを取得する。
- 認可コードを使用してアクセストークンを取得する際には、クライアントの認証を行う。
- アクセストークンを使用して、保護されたリソースにアクセスする。

---

### 2. Authorization Server (AuthServer)

**主な役割**:

- 認証および認可の両方のプロセスを管理し、適切なトークンをクライアントに発行する。

**やるべきこと**:

- リソースオーナーの認証を行う。
- リソースオーナーからクライアントへのアクセスの承認を得る。
- 認可コードやアクセストークンをクライアントに発行する。
- クライアントの認証を行う（特に認可コードフローにおいて）。
- トークンの有効期限や範囲を管理する。

---

### 3. Protected Resource（保護されたリソース）

**主な役割**:

- 適切なアクセストークンを持つクライアントのみにリソースへのアクセスを許可する。

**やるべきこと**:

- クライアントからのリクエストに添付されたアクセストークンの検証。
- トークンが有効であれば、要求されたリソースを提供する。
- トークンが無効または期限切れであれば、アクセスを拒否し、適切なエラーレスポンスを返す。

## 学習教材

- **日本語**: [OAuth徹底入門](https://www.amazon.co.jp/OAuth%E5%BE%B9%E5%BA%95%E5%85%A5%E9%96%80-%E3%82%BB%E3%82%AD%E3%83%A5%E3%82%A2%E3%81%AA%E8%AA%8D%E5%8F%AF%E3%82%B7%E3%82%B9%E3%83%86%E3%83%A0%E3%82%92%E9%81%A9%E7%94%A8%E3%81%99%E3%82%8B%E3%81%9F%E3%82%81%E3%81%AE%E5%8E%9F%E5%89%87%E3%81%A8%E5%AE%9F%E8%B7%B5-Justin-Richer/dp/4798159298)
- **英語**: [OAuth 2 in Action](https://www.manning.com/books/oauth-2-in-action)
