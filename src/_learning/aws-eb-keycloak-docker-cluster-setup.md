---
title: "DockerでKeycloakをクラスタ運用する話"
date: 2024-08-19T07:00:00
jobtitle: ""
linkedinurl: ""
weight: 7
tags:
  - Docker
  - Keycloak
  - Clustering
  - AWS
  - Elastic Beanstalk
  - Infinispan
  - EC2
---

### DockerでKeycloakをクラスタ運用する話

プロジェクトで、Dockerコンテナ使ってKeycloakを運用することになったんだ。Elastic Beanstalkを使って環境とデプロイを簡単にするのが狙い。EC2に直接Keycloakをインストールするのって、正直めんどくさいし、コンテナにしちゃえば、Keycloakのマイグレーションも楽だし、いいんじゃないかって話。

#### トラブル発生：トークンが共有されない問題

そこで、EC2インスタンス2台を使ってクラスタ構成を試してみたんだけど、JWTを使った`userinfo`リクエストで200と401のステータスが交互に返ってくるっていう謎の現象が発生。要するに、各Keycloakインスタンス間でトークンが共有されてなかったわけ。

Keycloakでは、トークン情報を[Infinispan](https://infinispan.org/)っていう分散キャッシュで管理してるんだけど、各インスタンスが独自にInfinispanを持ってるせいで、トークンの共有がうまくいってなかったんだ。

#### 解決策：Infinispanの同期

Infinispanをどうやって同期するかって話なんだけど、方法は二つある。

1. **別にInfinispanを立ち上げて、全インスタンスが同じInfinispanを参照する**
2. **各インスタンスが自分のInfinispanを同期させる**

今回は、既存システムとの兼ね合いもあって、2番目の「各インスタンスが自分のInfinispanを同期させる」方法を選んだよ。

#### アーキテクチャの問題発覚

アーキテクチャはこんな感じで組んでたんだ。

```text
LB ------> auto scaling group -----------|
          |----ec2-1----------------------|
          |          docker -------------|
          |              nginx           |
          |                keycloak      |
          |----ec2-2---------------------|
          |          docker -------------|
          |              nginx           |
          |                keycloak      |
          --------------------------------
```

でも、Dockerのデフォルトのブリッジ・ネットワークを使ってたら、Keycloakのログに`172.17.0.2`みたいな内部IPアドレスが表示されちゃって、各インスタンス間で通信できず、クラスタ構成がうまく機能しなかったんだよね。

#### 解決策：`network_mode`を`host`に設定

で、最終的に思い切って`network_mode`を`host`に設定してみたら、EC2インスタンスのIPアドレスが物理アドレスとしてちゃんと表示されて、クラスタ構成がうまくいったってわけ。以下はその設定例ね。

```yaml
services:
  keycloak:
    image: {ecr_url}/keycloak:0.0.1
    environment:
      - KC_DB_URL_HOST=${KC_DB_URL_HOST}
      - KC_DB_URL_DATABASE=${KC_DB_URL_DATABASE}
      - KC_DB_USERNAME=${KC_DB_USERNAME}
      - KC_DB_PASSWORD=${KC_DB_PASSWORD}
      - KC_HOSTNAME_URL=${KC_HOSTNAME_URL}
      - KC_HOSTNAME_ADMIN_URL=${KC_HOSTNAME_ADMIN_URL}
      - KC_HOSTNAME_STRICT=true
      - KC_HOSTNAME_STRICT_BACKCHANNEL=true
      - KC_PROXY=edge
      - KC_PROXY_HEADERS=xforwarded
      - KC_HTTP_ENABLED=true
      - KEYCLOAK_ADMIN=${KEYCLOAK_ADMIN}
      - KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD}
      - TZ=Asia/Tokyo
      - KC_CACHE=${KC_CACHE}
      - JGROUPS_DISCOVERY_PROTOCOL=${JGROUPS_DISCOVERY_PROTOCOL}
      - KC_LOG_LEVEL=${KC_LOG_LEVEL}
      - KC_HEALTH_ENABLED=true
    command:
      - "-v"
      - start
      - "--optimized"
    logging:
      driver: awslogs
      options:
        awslogs-region: us-east-1
        awslogs-group: idp/keycloak
        awslogs-create-group: "true"
    network_mode: "host" 

  nginx:
    image: public.ecr.aws/docker/library/nginx:stable-alpine3.19-slim
    volumes:
      - /home/ec2-user/nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      keycloak:
        condition: service_started
      app:
        condition: service_started
    logging:
      driver: awslogs
      options:
        awslogs-region: us-east-1
        awslogs-group: idp/nginx
        awslogs-create-group: "true"
    network_mode: "host" 
```

今のところ、この方法でプロジェクト進めてるけど、他にも良い方法があるかもね。でも、これでうまくいってるし、まあいいかなって感じ。

### おまけ

cache-ispn-jdbc-ping-mysql.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<infinispan
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="urn:infinispan:config:14.0 http://www.infinispan.org/schemas/infinispan-config-14.0.xsd"
    xmlns="urn:infinispan:config:14.0">

    
    <!-- custom stack goes into the jgroups element -->
    <jgroups>
        <stack name="jdbc-ping-tcp" extends="tcp">
            <JDBC_PING connection_driver="com.mysql.cj.jdbc.Driver"
                connection_username="${env.KC_DB_USERNAME}"
                connection_password="${env.KC_DB_PASSWORD}"
                connection_url="jdbc:mysql://${env.KC_DB_URL_HOST}:${env.KC_DB_URL_PORT:3306}/${env.KC_DB_URL_DATABASE}${env.KC_DB_URL_PROPERTIES:}"
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

Dockerfile

```dockerfile
ARG dbflavor=mysql
ARG kcversion=22.0.3

FROM quay.io/keycloak/keycloak:${kcversion} AS builder

ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

ARG dbflavor
ENV KC_DB=${dbflavor}

COPY ./cache-ispn-jdbc-ping-${dbflavor}.xml /opt/keycloak/conf/cache-ispn-jdbc-ping.xml
# RUN /opt/keycloak/bin/kc.sh build --http-relative-path=/auth
RUN /opt/keycloak/bin/kc.sh build --cache-config-file=cache-ispn-jdbc-ping.xml --http-relative-path=/auth --cache=ispn

FROM quay.io/keycloak/keycloak:${kcversion}
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT [ "/opt/keycloak/bin/kc.sh" ]

```
