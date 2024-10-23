---
title: "Node.jsとNode Configを使ったアプリケーション設定の管理"
date: 2024-04-22T08:56:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - Node.js
  - Configuration Management
  - Node Config
  - Environment Variables
  - TypeScript
  - Application Settings
  - Inversify
  - Database Configuration
description: ""
---

## Node.jsとNode Configを使ったアプリケーション設定の管理

Node Configは、Node.jsアプリケーションの設定を効率的に扱うためのライブラリで、環境に応じた設定を簡単に切り替えることができます。

#### Node Configのインストール

Node Configを使用するには、まずnpmを通じてインストールします。

```bash
npm install config

#### typescriptを使用している場合は下記も実行して下さい。
npm i @types/config --save-dev
```

`package.json`には以下のように記述されます。

```json
"dependencies": {
  "config": "^3.3.11"
}
```

#### 設定ファイルの作成

Node Configでは、configディレクトリ内に環境ごとの設定ファイルを作成します。以下のような構造になっています。

```bash
project_root/
├── config/               ## 環境ごとの設定ファイルを保管
│   ├── custom-environment-variables.json  ## 環境変数から設定を読み込むためのファイル
│   ├── development.json  ## 開発環境用の設定
│   ├── myhost.json       ## ローカル環境用の特別な設定
│   ├── production.json   ## 本番環境用の設定
│   └── staging.json      ## ステージング環境用の設定
```

各設定ファイルには、その環境に特有の設定をJSON形式で保存します。

config/myhost.json

```json
{
    "port": 3000,
    "db": {
        "contacts": {
            "host": "localhost",
            "user": "local-db-user",
            "password": "password",
            "database": "contacts",
            "port": 3306
        },
        "identity": {
            "host": "localhost",
            "user": "local-db-user",
            "password": "password",
            "database": "identityExtension",
            "port": 3306
        }
    },
    "redis": {
        "url": "redis://localhost:6379"
    },
    "backendIDP": "http://localhost:8080",
    "openidOverrides": {
        "userinfo_endpoint": "http://localhost:3000/api/v1/userInformation/enrich"
    }
}
```

config/custom-environment-variables.json

```json
{
    "port": "PORT",
    "db": {
        "contacts": {
            "host": "CONTACTS_DB_HOST",
            "user": "CONTACTS_DB_USER",
            "password": "CONTACTS_DB_PASSWORD",
            "database": "CONTACTS_DB_DATABASE",
            "port": "CONTACTS_DB_PORT"
        },
        "identity": {
            "host": "IDENTITY_DB_HOST",
            "user": "IDENTITY_DB_USER",
            "password": "IDENTITY_DB_PASSWORD",
            "database": "IDENTITY_DB_DATABASE",
            "port": "IDENTITY_DB_PORT"
        }
    },
    "redis": {
        "url": "REDIS_ENDPOINT"
    },
    "backendIDP": "BACKEND_IDP",
    "openidOverrides": {
        "userinfo_endpoint": "USERINFO_ENDPOINT_OVERRIDE"
    }    
}
```

#### 設定の使用

設定はアプリケーション内で簡単に取得できます。

```typescript
import config from 'config';

const dbHost = config.get<string>('db.contacts.host');
// 他の設定も同様に取得できます

```

#### 実際の例

```typescript
import { Container } from 'inversify';
import config from 'config';
import { MysqlContext } from './infrastructure/database/mysqlContext';

const container = new Container();

// Contactsデータベースの設定
container.bind<MysqlContext>('ContactsDbContext').toDynamicValue(() => {
  return new MysqlContext(
    config.get<string>('db.contacts.host'),
    config.get<string>('db.contacts.user'),
    config.get<string>('db.contacts.password'),
    config.get<string>('db.contacts.database'),
    config.get<number>('db.contacts.port')
  );
}).inSingletonScope();


```

#### 参考リンク

- [Node Config npm page](https://chat.openai.com/c/9cba7467-7141-454a-a429-908e166a869c##:~:text=Node%20Config%20npm%20page)
- [Node Config GitHub repository](https://github.com/node-config/node-config)
