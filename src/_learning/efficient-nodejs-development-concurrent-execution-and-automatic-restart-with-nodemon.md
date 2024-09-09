---
title: "効率的なNode.js開発: concurrentlyでの同時実行とnodemonによる自動再起動"
date: 2023-10-09T06:27:00
#image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: "Ｎodejsで複数のアプリケーションを同時に実行する方法"
linkedinurl: ""
weight: 7
tags:
---

# Ｎodejsで複数のアプリケーションを同時に実行する方法

クライアント、認証サーバー、プロテクトサーバーを同時に動かす方法
[Git](https://github.com/oauthinaction/oauth-in-action-code/tree/master/exercises/ch-5-ex-3)

```bash
npm i concurrently
npm i nodemon
```

package.jsonのscriptsを追加する

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
  - ファイルの変更を監視し、変更が検出されたときに自動でNode.jsアプリケーションを再起動する
    - file編集したら反映してくれるので、必要であればInstallする
