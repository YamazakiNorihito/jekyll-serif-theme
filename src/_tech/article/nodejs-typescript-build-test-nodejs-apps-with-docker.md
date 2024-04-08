---

title: "Dockerを使用してNode.jsアプリケーションをビルドとテストする方法"
date: 2024-3-29T08:51:00
weight: 4
categories:
  - javascript
  - nodejs
  - typescript
  - docker

---

# Dockerを使用してNode.jsアプリケーションをビルドとテストする方法

Dockerは、アプリケーションの開発、配布、実行を簡単かつ一貫性のある方法で行うための強力なツールです。特にNode.jsアプリケーションにおいて、Dockerを利用することで開発環境から本番環境への移行をスムーズに行うことが可能になります。この記事では、Node.jsアプリケーションのビルドとテストをDocker化するプロセスについて詳しく説明します。

```dockerfile
# このDockerfileでは、パッケージのscriptsを直接使用せずに、アプリケーションのビルドとテストを行います。
# 特に、gts関連のスクリプトは、ソースコードの特定の構成に依存するため、直接使用せずに回避しています。
# 必要なソースコードと設定ファイルのみをDockerイメージ内にコピーし、`npx jest`を使用してテストを直接実行します。
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

### package.json

```json
{
  "name": "myapp",
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

## マルチステージビルドの採用

マルチステージビルドを採用することで、一つのDockerfile内で複数のステージを定義し、ビルド、テスト、プロダクションイメージの作成を効率的に行うことができます。このアプローチにより、開発依存関係を含むビルドステージから最終的なプロダクションイメージには必要最低限のファイルのみを含めることができ、イメージのサイズを小さく保つことが可能になります。

## ビルドステージ

ビルドステージでは、ソースコードと必要な設定ファイルをイメージ内にコピーし、依存関係のインストール、ソースコードのコンパイル、そしてテストの実行を行います。特に、テストには`npx jest`を用いて直接実行し、外部スクリプトに依存しない純粋なテスト環境を構築します。

## プロダクションステージ

プロダクションステージでは、ビルドステージで生成された成果物のみを新しいイメージにコピーします。ここでは、プロダクション環境に必要な依存関係のみをインストールし、アプリケーションの実行に不要な開発ツールやテストファイルは含めません。これにより、セキュリティが強化され、実行速度が向上した軽量なプロダクションイメージが得られます。

# Docker Imageのビルド手順

このドキュメントでは、Dockerfileを使用してDockerイメージをビルドする手順を説明します。

### Dockerイメージのビルド

Dockerfileを使用してイメージをビルドするには、以下のコマンドを実行します。-tオプションでイメージの名前とタグを指定できます。この例では、イメージの名前をapp、タグをffとしています。

```bash
docker build -t app:1 -f docker/app/Dockerfile .
```

## まとめ

Dockerを利用したNode.jsアプリケーションのビルドとテストプロセスは、開発の効率化はもちろん、セキュリティとパフォーマンスの観点からも多くのメリットを提供します。マルチステージビルドの採用により、一つのDockerfileで開発から本番環境までの一連の流れをシームレスに管理できるようになります。これは、現代のアプリケーション開発において非常に価値のあるアプローチと言えるでしょう。
