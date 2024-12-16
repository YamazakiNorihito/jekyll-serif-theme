---
title: "DockerでHTTPS対応を実現する方法"
date: 2023-12-13T09:00:00
weight: 7
tags:
  - Docker
  - HTTPS
  - Nginx
  - Docker Compose
  - Web Security
  - SSL/TLS
  - Reverse Proxy
  - Redis
  - Node.js
description: "Dockerを使用して簡単にHTTPS対応を実現する手順を紹介。steveltn/https-portal Dockerイメージを使用し、NginxベースのリバースプロキシでHTTPS化。Node.jsアプリケーションとRedisを含むdocker-compose構成を例に、SSL/TLSセキュリティと基本的なWebサーバー構成について学べる内容です。"
---

[steveltn/https-portal:1](https://github.com/SteveLTN/https-portal) の DockerImage を使うと簡単に Https 化ができる
nginx を使っているので、nginx の知識があれば、チューニングもできる。

## docker-compose

```yaml
version: "3.8"
services:
  https-portal:
    image: steveltn/https-portal:1
    ports:
      - "80:80"
      - "443:443"
    restart: always
    environment:
      DOMAINS: "workday.ap-northeast-1.elasticbeanstalk.com -> http://app:3000"
      STAGE: "production"
    volumes:
      - https-portal-data:/var/lib/https-portal
    depends_on:
      - app

  app:
    build:
      context: .
      dockerfile: Dockerfile-node
    environment:
      - DOMAIN
      - NODE_ENV=production
      - FREE_CLIENT_ID
      - FREE_CLIENT_SECRET
      - REDIS_URL
      - SLACK_TOKEN
      - COGNITO_DOMAIN
      - COGNITO_USER_POOL_URL
      - COGNITO_CLIENT_ID
      - COGNITO_CLIENT_SECRET
    depends_on:
      - redis

  redis:
    build:
      context: .
      dockerfile: Dockerfile-redis
    volumes:
      - redis-data:/data

volumes:
  redis-data:
  https-portal-data:
```

## dockerfile

- Dockerfile-node

```bash
# ビルドステージ
FROM node:18 as builder

# アプリケーションディレクトリを作成
WORKDIR /app

# package.json と package-lock.json をコピー
COPY package*.json ./

# 依存関係のインストール
RUN npm install

# ソースコードのコピー
COPY src/ src/
COPY tsconfig.json .

# TypeScriptのコンパイル
RUN npm run build

# 実行ステージ
FROM node:18-slim

# アプリケーションディレクトリを作成
WORKDIR /app

# ビルドステージからコンパイルされたファイルと node_modules をコピー
COPY --from=builder /app/dist /app/dist
COPY --from=builder /app/node_modules /app/node_modules

EXPOSE 3000

# アプリケーションの起動
CMD ["node", "dist/app.js"]

```

- Dockerfile-redis

```bash
# ベースイメージを指定
FROM redis/redis-stack-server:7.2.0-v4

# ホストシステムからコンテナに設定ファイルをコピー
COPY redis.conf /redis-stack.conf
COPY users.acl /users.acl

# Redisデータ用のボリュームを指定（オプション）
VOLUME /data

# Redisサーバーを実行
CMD ["redis-stack-server", "redis-stack.conf"]

```

- redis.conf

```text
# 認証のためのパスワードを設定
requirepass password

# 保護モードを有効にする
protected-mode yes
# AOFの永続化を有効
appendonly yes

aclfile /users.acl
```

- users.scl

```text
user admin on >adminpass +@all ~*
user read_only on >readonlypass +@read ~*
user execute_user on >executeuserpass +@all -@dangerous ~*

```
