---
title: "KeycloakのJDBCドライバーをAWS Advanced JDBC Wrapperに変更する方法"
date: 2024-8-29T16:34:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
---

# KeycloakのJDBCドライバーをAWS Advanced JDBC Wrapperに変更する方法

KeycloakのJDBCドライバーを[aws-advanced-jdbc-wrapper](https://github.com/aws/aws-advanced-jdbc-wrapper)に変更して利用する方法を紹介します。この記事では、ローカル環境でDockerを使用して設定する手順と、環境変数のサンプルを中心に解説します。

## Dockerfileの設定

まず、KeycloakのDockerイメージをカスタマイズするためのDockerfileを作成します。以下は、aws-advanced-jdbc-wrapperをKeycloakに組み込むためのサンプルDockerfileです。

```dockerfile
ARG kcversion=22.0.3

FROM quay.io/keycloak/keycloak:${kcversion} AS builder

ADD --chmod=0666 https://github.com/awslabs/aws-advanced-jdbc-wrapper/releases/download/2.3.9/aws-advanced-jdbc-wrapper-2.3.9.jar /opt/keycloak/providers/aws-advanced-jdbc-wrapper.jar

ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

ARG dbflavor

COPY ./cache-ispn-jdbc-ping-${dbflavor}.xml /opt/keycloak/conf/cache-ispn-jdbc-ping.xml
RUN /opt/keycloak/bin/kc.sh build --cache-config-file=cache-ispn-jdbc-ping.xml --http-relative-path=/auth

FROM quay.io/keycloak/keycloak:${kcversion}
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT [ "/opt/keycloak/bin/kc.sh" ]
```

このDockerfileは、AWS Advanced JDBC WrapperをKeycloakに追加し、ビルドプロセスを実行してカスタムイメージを作成します。

## Docker Composeの設定

次に、Docker Composeを使用して、KeycloakとMySQLのコンテナを設定します。以下は、必要な環境変数と設定を含むDocker Composeファイルの例です。

```yaml
services:
  keycloak:
    ports:
      - "8080:8080"
    build:
      context: ./keycloak
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
      KC_DB : mysql
      KC_DB_URL: jdbc:aws-wrapper:mysql://mysql:3306/keycloak
      KC_DB_DRIVER: software.amazon.jdbc.Driver
      KC_DB_URL_DATABASE: keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: password
      KC_PROXY: edge
      KC_PROXY_HEADERS: "xforwarded"
      KC_HTTP_ENABLED: true
      TZ: Asia/Tokyo
      KC_TRANSACTION_XA_ENABLED: false
    command:
      - start-dev
    depends_on:
      mysql:
        condition: service_healthy
    volumes:
      - idp_keycloak_data:/opt/keycloak/data

  mysql:
    image: mysql:8.3
    platform: linux/amd64
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: keycloak
      MYSQL_USER: keycloak
      MYSQL_PASSWORD: password
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-uroot", "-ppassword"]
      interval: 10s
      timeout: 5s
      retries: 5
    ports:
      - "3306:3306"
    volumes:
      - idp_mysql_data:/var/lib/mysql

volumes:
  idp_keycloak_data:
  idp_mysql_data:
```

この設定により、Keycloakがaws-advanced-jdbc-wrapperを使用してMySQLに接続するようになります。

以上で、KeycloakをAWS Advanced JDBC Wrapperで動作させるための基本的なセットアップは完了です。環境によっては追加の調整が必要になることがありますが、この手順を参考にして進めてください。

## 参考サイト

この設定を行うにあたり、以下のサイトを参考にしました。

- [Amazon Aurora PostgreSQL の準備](https://www.keycloak.org/server/db#preparing-keycloak-for-amazon-aurora-postgresql)
- [7.7. Amazon Aurora PostgreSQL の準備](https://docs.redhat.com/ja/documentation/red_hat_build_of_keycloak/24.0/html/server_guide/db-preparing-keycloak-for-amazon-aurora-postgresql)
- [aws-advanced-jdbc-wrapper](https://github.com/aws/aws-advanced-jdbc-wrapper)
