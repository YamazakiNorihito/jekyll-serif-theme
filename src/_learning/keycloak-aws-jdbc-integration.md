---
title: "KeycloakのJDBCドライバーをAWS Advanced JDBC Wrapperに変更する方法"
date: 2024-8-29T16:34:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - Keycloak
  - JDBC
  - AWS
  - Docker
  - Database
  - MySQL
  - Configuration
  - Identity Management
description: "KeycloakのJDBCドライバーをAWS Advanced JDBC Wrapperに変更する手順を解説します。Dockerを使ったローカル環境での設定方法やサンプルのDockerfile、環境変数、Docker Compose設定などを紹介し、MySQL接続の構成についても詳しく説明します。"
---

# Keycloak の JDBC ドライバーを AWS Advanced JDBC Wrapper に変更する方法

このガイドでは、Keycloak の JDBC ドライバーを[aws-advanced-jdbc-wrapper](https://github.com/aws/aws-advanced-jdbc-wrapper)に変更して使用する方法を説明します。ローカル環境で Docker を使用した設定手順と、サンプルの環境変数について解説します。

## Dockerfile の設定

まず、Keycloak の Docker イメージをカスタマイズするために、以下の Dockerfile を作成します。これは、aws-advanced-jdbc-wrapper を Keycloak に組み込むためのサンプルです。

```dockerfile
ARG dbflavor=mysql
ARG kcversion=22.0.3

FROM quay.io/keycloak/keycloak:${kcversion} AS builder

ADD --chmod=0666 https://github.com/awslabs/aws-advanced-jdbc-wrapper/releases/download/2.3.9/aws-advanced-jdbc-wrapper-2.3.9.jar /opt/keycloak/providers/aws-advanced-jdbc-wrapper.jar

ARG dbflavor

COPY ./cache-ispn-jdbc-ping-${dbflavor}.xml /opt/keycloak/conf/cache-ispn-jdbc-ping.xml
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:${kcversion}
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT [ "/opt/keycloak/bin/kc.sh" ]
```

### cache-ispn-jdbc-ping-mysql.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<infinispan
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="urn:infinispan:config:14.0 http://www.infinispan.org/schemas/infinispan-config-14.0.xsd"
    xmlns="urn:infinispan:config:14.0">

    <jgroups>
        <stack name="jdbc-ping-tcp" extends="tcp">
            <JDBC_PING connection_driver="com.mysql.cj.jdbc.Driver"
                connection_username="${env.KC_DB_USERNAME}"
                connection_password="${env.KC_DB_PASSWORD}"
                connection_url="${env.KC_DB_URL}"
                initialize_sql="CREATE TABLE IF NOT EXISTS JGROUPSPING (own_addr varchar(200) NOT NULL, cluster_name varchar(200) NOT NULL, ping_data BYTEA, constraint PK_JGROUPSPING PRIMARY KEY (own_addr, cluster_name));"
                info_writer_sleep_time="500"
                remove_all_data_on_view_change="false"
                stack.combine="REPLACE"
                stack.position="MPING" />
        </stack>
    </jgroups>

    <cache-container name="keycloak">
        <transport lock-timeout="60000" stack="jdbc-ping-tcp" />
        <local-cache name="realms">
            <encoding>
                <key media-type="application/x-java-object" />
                <value media-type="application/x-java-object" />
            </encoding>
            <memory max-count="10000" />
        </local-cache>
        <local-cache name="users">
            <encoding>
                <key media-type="application/x-java-object" />
                <value media-type="application/x-java-object" />
            </encoding>
            <memory max-count="10000" />
        </local-cache>
        <distributed-cache name="sessions" owners="2">
            <expiration lifespan="-1" />
        </distributed-cache>
        <distributed-cache name="authenticationSessions" owners="2">
            <expiration lifespan="-1" />
        </distributed-cache>
        <distributed-cache name="offlineSessions" owners="2">
            <expiration lifespan="-1" />
        </distributed-cache>
        <distributed-cache name="clientSessions" owners="2">
            <expiration lifespan="-1" />
        </distributed-cache>
        <distributed-cache name="offlineClientSessions" owners="2">
            <expiration lifespan="-1" />
        </distributed-cache>
        <distributed-cache name="loginFailures" owners="2">
            <expiration lifespan="-1" />
        </distributed-cache>
        <local-cache name="authorization">
            <encoding>
                <key media-type="application/x-java-object" />
                <value media-type="application/x-java-object" />
            </encoding>
            <memory max-count="10000" />
        </local-cache>
        <replicated-cache name="work">
            <expiration lifespan="-1" />
        </replicated-cache>
        <local-cache name="keys">
            <encoding>
                <key media-type="application/x-java-object" />
                <value media-type="application/x-java-object" />
            </encoding>
            <expiration max-idle="3600000" />
            <memory max-count="1000" />
        </local-cache>
        <distributed-cache name="actionTokens" owners="2">
            <encoding>
                <key media-type="application/x-java-object" />
                <value media-type="application/x-java-object" />
            </encoding>
            <expiration max-idle="-1" lifespan="-1" interval="300000" />
            <memory max-count="-1" />
        </distributed-cache>
    </cache-container>
</infinispan>
```

この Dockerfile は、AWS Advanced JDBC Wrapper を Keycloak に追加し、ビルドプロセスを実行してカスタムイメージを作成します。

## Docker Compose の設定

次に、Docker Compose を使用して、Keycloak と MySQL のコンテナを設定します。以下に必要な環境変数と設定を含む Docker Compose ファイルを示します。

```yaml
services:
  keycloak:
    build:
      context: ./keycloak
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
      KC_DB: mysql
      KC_DB_URL: jdbc:aws-wrapper:mysql://mysql:3306/keycloak
      KC_DB_DRIVER: software.amazon.jdbc.Driver
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: password
      KC_HOSTNAME_URL: "https://localhost:8081/auth"
      KC_HOSTNAME_ADMIN_URL: "https://localhost:8081/auth"
      KC_HOSTNAME_STRICT: true
      KC_HOSTNAME_STRICT_BACKCHANNEL: true
      KC_PROXY: edge
      KC_PROXY_HEADERS: "xforwarded"
      KC_HTTP_ENABLED: true
      TZ: Asia/Tokyo
      KC_TRANSACTION_XA_ENABLED: false
      KC_HEALTH_ENABLED: true
      KC_METRICS_ENABLED: true
      KC_CACHE_CONFIG_FILE: cache-ispn-jdbc-ping.xml
      KC_HTTP_RELATIVE_PATH: /auth
    command:
      - "-v"
      - start
    depends_on:
      mysql:
        condition: service_healthy
    restart: on-failure:1
    volumes:
      - idp_keycloak_data:/opt/keycloak/data

  nginx:
    image: nginx:latest
    ports:
      - "8081:443"
    volumes:
      - ./nginx/conf.d/myhost.conf:/etc/nginx/conf.d/default.conf
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on:
      app:
        condition: service_started
      keycloak:
        condition: service_started

  mysql:
    image: mysql:8.3
    platform: linux/amd64
    expose:
      - 3306
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: keycloak
      MYSQL_USER: keycloak
      MYSQL_PASSWORD: password
    healthcheck:
      test:
        ["CMD", "mysqladmin", "ping", "-h", "localhost", "-uroot", "-ppassword"]
      interval: 10s
      timeout: 5s
      retries: 5
    volumes:
      - idp_mysql_data:/var/lib/mysql
      - "./mysql/initdb.d/keycloak/schema.sql:/docker-entrypoint-initdb.d/4.sql"

volumes:
  idp_keycloak_data:
  idp_mysql_data:
```

### schema.sql

```sql
-- 使用するデータベースを選択
USE keycloak;

GRANT ALL PRIVILEGES ON keycloak.* TO 'keycloak'@'%';
FLUSH PRIVILEGES;

-- テーブルが存在しない場合、`JGROUPSPING` テーブルを作成
CREATE TABLE IF NOT EXISTS JGROUPSPING (
    own_addr VARCHAR(200) NOT NULL,
    cluster_name VARCHAR(200) NOT NULL,
    ping_data BLOB,
    CONSTRAINT PK_JGROUPSPING PRIMARY KEY (own_addr, cluster_name)
);
```

### docker/nginx/conf.d/default.conf

```conf
upstream backend {
    server keycloak:8080 fail_timeout=2s;
}

server {
    listen 443 ssl http2;
    server_name localhost;

    include mime.types;

    ssl_certificate /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m; # about 40000 sessions
    ssl_session_tickets off;

    ssl_dhparam /etc/nginx/ssl/dhparam;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;
    ssl_prefer_server_ciphers off;

    resolver 127.0.0.11 valid=1s;

    location / {
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }

        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Server $host;
        proxy_redirect off;
        proxy_connect_timeout 2s;
    }
}
```

この設定により、Keycloak が aws-advanced-jdbc-wrapper を使用して MySQL に接続するように構成されます。

## `--optimized` オプションの使用について

Keycloak を start コマンドで実行する際に、`--optimized`オプションは設定しないでください。このオプションは Keycloak のスタートアップ時間を短縮し、メモリ使用量を最適化しますが、以下の問題が報告されています:  
[Keycloak Issue #15898](https://github.com/keycloak/keycloak/issues/15898)

### `--optimized` の役割

1. **ビルドプロセスのスキップ**: 起動時にビルドステップをスキップし、既にビルド済みの状態で起動を開始します。
2. **スタートアップ時間の短縮**: ビルドプロセスのスキップにより、起動時間が短縮されます。
3. **メモリ使用量の削減**: 不要なビルドステップのスキップにより、メモリ使用量が削減されます。

## 参考サイト

この設定を行う際に参考にしたサイト：

- [Amazon Aurora PostgreSQL の準備](https://www.keycloak.org/server/db#preparing-keycloak-for-amazon-aurora-postgresql)
- [7.7. Amazon Aurora PostgreSQL の準備](https://docs.redhat.com/ja/documentation/red_hat_build_of_keycloak/24.0/html/server_guide/db-preparing-keycloak-for-amazon-aurora-postgresql)
- [aws-advanced-jdbc-wrapper](https://github.com/aws/aws-advanced-jdbc-wrapper)
