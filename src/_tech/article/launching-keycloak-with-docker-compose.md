---
title: "KeyCloakをDockerComposeで立ち上げる"
date: 2023-10-07T07:35:00
weight: 4
categories:
  - tech
  - docker
  - oauth
description: "Docker Composeを使用して、Keycloakを簡単に立ち上げる方法を紹介。設定ファイルとコマンド例を提供します。"
tags:
  - Keycloak
  - Docker
  - OAuth
  - セキュリティ
  - 認証
  - コンテナ
---

#### 1. docker-compose.yaml

```yaml
version : "3.9"

services:
  keycloak:
    image:
      quay.io/keycloak/keycloak:22.0.4
    command: 
      start-dev
    environment:
      - KEYCLOAK_ADMIN=admin
      - KEYCLOAK_ADMIN_PASSWORD=admin
    ports:
      - 8080:8080
    volumes:
      - ./data:/opt/keycloak/data

volumes:
  data:
```

#### 2. Excute

```bash
docker-compose up
```

#### 注意点

- [KeyCloakの公式ドキュメントGetting started Docker](https://www.keycloak.org/getting-started/getting-started-docker)をDocker-composeにしただけです。本番運用はできません。
- dataディレクトリはKeycloakのデータを永続化するためのものです。このディレクトリを削除すると、Keycloakのデータも失われるので注意してください。
