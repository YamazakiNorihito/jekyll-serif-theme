---
title: "TypeScriptで作成したプロジェクトをDockerイメージにする方法"
date: 2024-4-4T14:18:00
weight: 4
categories:
  - javascript
  - nodejs
  - typescript
  - docker
---

# TypeScriptで作成したプロジェクトをDockerイメージにする方法

Jestを使用したユニットテストの実行も含め、全体のプロセスを段階的に説明していきます。

```docker
FROM node:20.12.0-alpine AS builder

WORKDIR /app

COPY package*.json ./
COPY src/ src/
COPY config/ config/
COPY test/ test/
COPY tsconfig.json .
COPY jest.config.js .

RUN npm install

RUN npm run compile
# テストの実行
RUN npx jest

# ----------------------------------
FROM node:20.12.0-alpine AS production

WORKDIR /app

COPY --from=builder /app/package*.json ./
RUN npm install --only=production --ignore-scripts

COPY --from=builder /app/build ./build
COPY --from=builder /app/config ./config

ENV NODE_ENV=myhost

CMD ["node", "build/index.js"]
```


### Dockerfileの解説
二段階のビルドプロセスを使用しています。これにより、最終的なイメージのサイズを最小限に抑えることができます。

1. **ビルドステージ**: このステージでは、アプリケーションのコードと依存関係をコピーし、プロジェクトをコンパイルします。その後、Jestを使ってユニットテストを実行します。このステージで発生する可能性のあるいかなるエラーも、イメージのビルドが中断される原因となります。
2. **プロダクションステージ**: ここでは、ビルドステージからコンパイルされたコードと必要な実行時依存関係のみをコピーします。これにより、開発に関連する余分なファイルや依存関係が最終イメージに含まれることがありません。


## 参考までに

このDockerfileでは、パッケージのscriptsを直接使用せずに、アプリケーションのビルドとテストを行います。
特に、gts関連のスクリプトは、ソースコードの特定の構成に依存するため、直接使用せずに回避しています。
必要なソースコードと設定ファイルのみをDockerイメージ内にコピーし、`npx jest`を使用してテストを直接実行します。

### package.json
```json
{
  "name": "app",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "jest",
    "start": "node build/index.js",
    "lint": "gts lint",
    "clean": "gts clean",
    "compile": "tsc",
    "fix": "gts fix",
    "prepare": "npm run compile",
    "pretest": "npm run compile",
    "posttest": "npm run lint"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "engines": {
    "node": "20.x"
  },
  "devDependencies": {
    "@types/config": "^3.3.4",
    "@types/express": "^4.17.21",
    "@types/jest": "^29.5.12",
    "@types/node": "20.8.2",
    "@types/prettyjson": "^0.0.33",
    "@types/uuid": "^9.0.8",
    "gts": "^5.2.0",
    "jest": "^29.7.0",
    "jest-mock-extended": "^3.0.5",
    "nodemon": "^3.1.0",
    "ts-jest": "^29.1.2",
    "typescript": "~5.1.6"
  },
  "dependencies": {
    "axios": "^1.6.7",
    "config": "^3.3.11",
    "dayjs": "^1.11.10",
    "express": "^4.19.2",
    "inversify": "^6.0.2",
    "inversify-express-utils": "^6.4.6",
    "jose": "^5.2.3",
    "mysql2": "^3.9.2",
    "prettyjson": "^1.2.5",
    "redis": "^4.6.13",
    "reflect-metadata": "^0.2.1",
    "uuid": "^9.0.1"
  }
}
```