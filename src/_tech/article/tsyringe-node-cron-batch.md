---
title: "tsyringe×node-cron で定義実行バッチを作成してみた"
date: 2023-11-04T07:00:00
weight: 4
categories:
  - javascript
  - nodejs
  - typescript
description: ""
---


## この記事

tsyringe×node-cron で定義実行バッチを作成を作成したので紹介します。

紹介するコードは、node-cronライブラリを使用して定期的にRSSフィードを取得します。
tsyringeを使った依存性注入でモジュール性とテスタビリティを高めます。
[node-cron](https://www.npmjs.com/package/node-cron)ライブラリ

## 重要なコードスニペット

### app.ts

```typescript
import 'reflect-metadata';
import { container } from 'tsyringe';
import express from 'express';
import { NewsScheduler } from './schedulers/newsScheduler';

/*実装一部省略*/

// ここでTimerをOnにする
const newsScheduler = container.resolve(NewsScheduler);
newsScheduler.start();


export default router;
```

### schedulers/newsScheduler.ts

```typescript
import { CronJob } from 'cron';
import { inject, singleton } from 'tsyringe';

@singleton()
export class NewsScheduler {
    private fetchJob: CronJob;
    private notificationJob: CronJob;

    // ここてTimerの設定
    constructor(@inject(RSSFeedService) private readonly _rssFeedService: RSSFeedService,
        @inject(PostMessageService) private readonly _postMessageService: PostMessageService) {
        this.fetchJob = new CronJob(
            '*/5 * * * *',
            () => {
                console.log('Starting to fetch all feeds...');
                this.fetchAllFeeds();
            },
            null,
            false,
            'Asia/Tokyo'
        );
        this.notificationJob = new CronJob(
            '0 * * * *',
            () => {
                console.log('Starting to fetch all feeds...');
                this.notificationAllFeeds();
            },
            null,
            false,
            'Asia/Tokyo'
        );
    }

    // 外からCronJobをStartできるようにする
    start() {
        console.log('NewsScheduler started.');
        this.fetchJob.start();
        this.notificationJob.start();
    }

    private async fetchAllFeeds() {
      /*実装は省略*/
    }

    private async notificationAllFeeds() {
      /*実装は省略*/
    }
}
```

### 開発環境設定

参考までに

### tsconfig.json

```json
{
    "compilerOptions": {
      "target": "ES2022",
      "module": "commonjs",
      "outDir": "./dist",
      "rootDir": "./src",
      "strict": true,
      "esModuleInterop": true,
      "noImplicitAny" : true,
      "sourceMap": true,
      "emitDecoratorMetadata": true,
      "experimentalDecorators": true,
    }
}
```

### package.json

```json
{
  "name": "workday",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "start": "concurrently \"nodemon ./src/app.ts\"",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "@types/express": "^4.17.20",
    "@types/node": "^20.8.9",
    "axios": "^1.6.0",
    "concurrently": "^8.2.2",
    "cron": "^3.1.6",
    "dotenv": "^16.3.1",
    "ejs": "^3.1.9",
    "express": "^4.18.2",
    "express-validator": "^7.0.1",
    "method-override": "^3.0.0",
    "nodemon": "^3.0.1",
    "polly-js": "^1.8.3",
    "redis": "^4.6.10",
    "reflect-metadata": "^0.1.13",
    "rss-parser": "^3.13.0",
    "sequelize": "^6.33.0",
    "sqlite3": "^5.1.6",
    "ts-node": "^10.9.1",
    "tsyringe": "^4.8.0",
    "typescript": "^5.2.2"
  },
  "devDependencies": {
    "@types/ejs": "^3.1.4",
    "@types/method-override": "^0.0.34"
  }
}
```
