---
title: "HTML FormからDELETEやPUTメソッドを使ってリクエストを送る方法"
date: 2023-11-04T07:42:00
weight: 4
categories:
  - javascript
  - nodejs
  - typescript
description: ""
---

## 目的や背景

HTMLのフォームは、基本的にGETまたはPOSTメソッドしかサポートしていません。
そのためDELETEやPUTと同じ振る舞いをするURIをPOSTまたはGETでActionを用意する必要があります。
しかし、~~URIを考えるのがめんどくさくて~~なんとかWebAPI風にURIを構築し、 URIを考える時間をなくしたいと
思い、そこでmethod-overrideというライブラリを使います。

使うライブラリーは[method-override](https://github.com/expressjs/method-override#method-override)

### headerのmethodを書き換える設定をする

```typescript
// app.ts
// ↓下記の設定をする
// override with the X-HTTP-Method-Override header in the request
// https://github.com/expressjs/method-override
app.use(methodOverride('_method'))

app.listen(3000, () => {
    console.log('Server is running on port 3000');
});

export default app;
```

### delete methodの Actionを設定

```typescript
// routes.ts
const router = express.Router();

const freeeController = container.resolve(FreeeController);
router.delete('/freee/work-records', asyncHandler((req, res) => freeeController.deleteWorkRecords(req, res)));

export default router;
```

### HTML FormでDeleteを指定する

methodOverride関数にクエリストリングのキーを文字列として指定することで、クエリストリングの値を使用してHTTPメソッドを上書きできます。

```html

    <div id="attendance-input">
        <h2>勤怠削除</h2>
        <form id="attendance-form" action="/freee/work-records?_method=DELETE" method="POST">
            <div class="day-group">
                <!-- 勤務日のFromとToの入力 -->
                <div class="input-group">
                    <label for="work-from-date">勤務日:</label>
                    <input type="date" id="work-from-date" name="workFromDate" required />

                    <label for="work-to-date">〜</label>
                    <input type="date" id="work-to-date" name="workToDate" required />
                </div>
            </div>
            <button type="submit">登録</button>
        </form>
    </div>

```

### 環境情報

```json
// package.json
{
  "name": "workday",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "start": "ts-node ./src/app.ts",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "@types/express": "^4.17.20",
    "@types/node": "^20.8.9",
    "axios": "^1.6.0",
    "dotenv": "^16.3.1",
    "ejs": "^3.1.9",
    "express": "^4.18.2",
    "express-validator": "^7.0.1",
    "method-override": "^3.0.0",
    "polly-js": "^1.8.3",
    "redis": "^4.6.10",
    "reflect-metadata": "^0.1.13",
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

```json
// tsconfig.json
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
