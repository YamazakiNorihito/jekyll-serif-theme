---
title: "効率的なNode.js開発: concurrentlyでの同時実行とnodemonによる自動再起動"
date: 2023-10-09T06:27:00
weight: 7
tags:
  - Node.js
  - Development Tools
  - Concurrently
  - Nodemon
  - Automation
  - JavaScript
  - Code Hot Reloading
  - Multi-process Management
  - Web Development
description: "Node.jsでの効率的な開発手法として、複数のアプリケーションを同時実行するためのconcurrentlyと、コード変更時に自動でアプリケーションを再起動するnodemonの設定方法を紹介します。OAuthサーバー構成の例を用い、クライアント、認証サーバー、保護リソースを簡単に管理する方法を具体的に解説します。"
---

## Ｎ odejs で複数のアプリケーションを同時に実行する方法

クライアント、認証サーバー、プロテクトサーバーを同時に動かす方法
[Git](https://github.com/oauthinaction/oauth-in-action-code/tree/master/exercises/ch-5-ex-3)

```bash
npm i concurrently
npm i nodemon
```

package.json の scripts を追加する

```json
{
  "dependencies": {
    "body-parser": "^1.13.2",
    "consolidate": "^0.13.1",
    "cors": "^2.7.1",
    "express": "^4.13.1",
    "nosql": "^6.1.0",
    "qs": "^6.9.3",
    "randomstring": "^1.0.7",
    "sync-request": "^2.0.1",
    "underscore": "^1.8.3",
    "underscore.string": "^3.1.1"
  },
  "scripts": {
    "start": "concurrently \"nodemon authorizationServer.js\" \"nodemon protectedResource.js\" \"nodemon client.js\""
  },
  "devDependencies": {
    "concurrently": "^8.2.1",
    "nodemon": "^3.0.1"
  }
}
```

- [concurrently](https://www.npmjs.com/package/concurrently)
  - 複数のコマンドを同時に実行します
- [nodemon](https://www.npmjs.com/package/nodemon)
  - ファイルの変更を監視し、変更が検出されたときに自動で Node.js アプリケーションを再起動する
    - file 編集したら反映してくれるので、必要であれば Install する
