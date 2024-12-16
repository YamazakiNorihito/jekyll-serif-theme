---
title: "Keycloak Migration Guide: 16.0.0 to 17.0.0"
date: 2024-07-29T08:10:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - Keycloak
  - Migration
  - Quarkus
  - Identity Management
  - Upgrade Guide
  - Database Schema
  - Configuration
  - Security
description: "Keycloakのバージョン16.0.0から17.0.0への移行手順を徹底解説。Quarkusディストリビューションへの変更、カスタムプロバイダーの配置方法、新しい設定手法、データベーススキーマ更新など、移行に必要な情報を網羅しています。"
---

こちらは、Keycloak のバージョン 16.0.0 から 17.0.0 への移行に関するブログ投稿のドラフトです：

## Keycloak 16.0.0 への移行

### 主な変更点

1. **レガシーセキュリティサブシステムの廃止**
   - `standalone.xml`または`host.xml`ファイルの`security-realm`要素が削除されました。
     - データベースを使用せずに、プロパティファイルを使ってユーザーを定義できます。
2. **プロキシ設定**
   - リクエストとレスポンスが同じプロキシを経由するようになりました。
3. **Keycloak Operator の変更**
   - Metrics 拡張を含む Keycloak Operator が削除されました。

詳細なアップグレード手順については、[公式アップグレードガイド](https://www.keycloak.org/docs/latest/upgrading/index.html#migrating-to-16-0-0)を参照してください。

## Keycloak 17.0.0 への移行

### 主な変更点

1. **デフォルトディストリビューションの変更: WildFly から Quarkus へ**

   - 旧ディストリビューションを使用するには、`legacy`または`17.0.0-legacy`タグを使用します。
   - Quarkus ではデフォルトでコンテキストパスから`/auth`が削除されています。これを維持するには、以下のコマンドでサーバーを起動します：

     ```sh
     bin/kc.[sh|bat] start-dev --http-relative-path /auth
     ```

2. **クライアントスコープ条件**

   - クライアントスコープ条件の JSON ドキュメント内の`scope`フィールド名が`scopes`に変更されました。

3. **設定の変更**

   - 新しい Quarkus CLI コマンドが WildFly CLI の代わりになります。詳細は[サーバーガイド](https://www.keycloak.org/guides#server)を参照してください。

4. **管理者ユーザーの設定**

   - 初回起動時に`KEYCLOAK_ADMIN`と`KEYCLOAK_ADMIN_PASSWORD`環境変数を設定します。追加のユーザーは`kcadm.sh`または`kcadm.bat`を使用して追加できます。

5. **カスタムプロバイダーの移行**

   - カスタムプロバイダーは`standalone/deployments`ではなく`providers`ディレクトリに配置します。
   - EAR パッケージ形式と`jboss-deployment-structure.xml`はサポートされなくなりました。

6. **ヘッダー処理の変更**
   - `X-Forwarded-Port`ヘッダーが`X-Forwarded-Host`に含まれるポートよりも優先されます。

### データベーススキーマの更新

- インデックス`IDX_USER_SERVICE_ACCOUNT`が追加されました。
- スキーマバージョンを確認するには、以下の SQL を実行します：

  ```sql
  SELECT * FROM DATABASECHANGELOG;
  ```

詳細は、[データベーススキーマの更新ドキュメント](https://github.com/keycloak/keycloak/blob/17.0.0/docs/updating-database-schema.md)を参照してください。

### 参考資料

- [Quarkus ディストリビューションへの移行](https://www.keycloak.org/migration/migrating-to-quarkus)
- [Keycloak 17.0.0 GitHub リポジトリ](https://github.com/keycloak/keycloak/tree/17.0.0)
