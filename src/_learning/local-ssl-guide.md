---
title: "ローカル開発のための自己署名SSL証明書の作成方法"
date: 2024-7-19T15:52:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
---

# ローカル開発のための自己署名SSL証明書の作成方法

ローカルでの開発時、SSLを使って何かやるときに必要な時があると思います。
ローカルだけで使える自己署名SSL証明書の作成する方法を記述します。
以下、Dockerコンテナ内で動作するNginxサーバー用に自己署名SSL証明書を生成する手順を説明します。

## ステップ1: ディレクトリの設定

まず、SSL証明書と鍵を保存するディレクトリを作成します。構造化されたディレクトリを使用すると、プロジェクトが整理されます。以下のコマンドで設定できます：

```bash
mkdir -p /あなたのプロジェクトのパス/docker/nginx/ssl
```

`/あなたのプロジェクトのパス`をSSLファイルを保存したい実際のパスに置き換えてください。

## ステップ2: SSL証明書の生成

自己署名SSL証明書と鍵を生成するために、OpenSSLコマンドを使用します。以下のコマンドは、証明書と鍵を生成し、指定したディレクトリに保存します：

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /あなたのプロジェクトのパス/docker/nginx/ssl/server.key -out /あなたのプロジェクトのパス/docker/nginx/ssl/server.crt
```

このコマンドにより、有効期間365日の2048ビットRSA鍵を使用してSSL証明書が生成されます。次に表示されるプロンプトでは、国名、州または地域名、地域の市町村名、会社名、組織部門名、共通名（FQDNまたはあなたの名前）、電子メールアドレスなど、証明書に含める情報を入力します。

### 詳細情報入力例

- 国名 (2文字コード): JP
- 州・省名: Tokyo
- 市町村名: Chiyoda
- 会社名: MyCompany
- 部門名: IT
- 共通名: localhost
- メールアドレス: <admin@example.com>

## ステップ3: Diffie-Hellmanパラメータの生成

SSL通信の安全性を高めるために、Diffie-Hellmanグループのパラメータを生成することが推奨されます。これには以下のコマンドを使用します：

```bash
openssl dhparam -out /あなたのプロジェクトのパス/docker/nginx/ssl/dhparam 2048
```

### default.conf

```conf
upstream backend {
    server keycloak:8080 fail_timeout=2s;
}

server {
    listen 443 default_server ssl ;
    listen [::]:443 default_server ssl ;
    http2 on;

    server_name localhost;

    ssl_certificate /ssl/server.crt;
    ssl_certificate_key /ssl/server.key;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;
    ssl_session_tickets off;

    ssl_dhparam /ssl/dhparam;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;
    ssl_prefer_server_ciphers off;

    resolver 127.0.0.11 valid=1s;

    location / {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host $host;
        # proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Server $host;
        proxy_pass http://backend;
        proxy_redirect http:// https://;
        proxy_connect_timeout 2s;
    }
}

```

### docker compose YAML

```yaml
services:
  keycloak:
    build:
      context: ./keycloak
      dockerfile: Dockerfile
    environment:
      KC_DB_URL_HOST: host.docker.internal
      KC_DB_URL_DATABASE: keycloakdb
      KC_DB_USERNAME: hogehoge
      KC_DB_PASSWORD: hogehoge
      KC_HOSTNAME_URL:  http://localhost:4000/auth
      KC_HOSTNAME_ADMIN_URL:  http://localhost:4000/auth
      KC_HOSTNAME_STRICT: true
      KC_HOSTNAME_STRICT_BACKCHANNEL: true
      KC_PROXY: edge
      KC_HTTP_ENABLED: true
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: password
      TZ: Asia/Tokyo
    command:
      - "-v"
      - start
      - "--optimized"

  nginx:
    image: nginx:latest
    ports:
      - "8080:8080"
      - "443:443"
    volumes:
      - ./nginx/conf.d/staging.conf:/etc/nginx/conf.d/default.conf
      - ./nginx/ssl:/ssl
    depends_on:
      keycloak:
        condition: service_started

```
