---
title: "Keycloakのメモリ設定の変化について (v23以前とv24以降)"
date: 2024-9-6T09:34:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - Keycloak
  - JVM
  - Memory Management
  - Docker
  - Configuration
  - Java
  - Performance Tuning
  - Identity Management
description: "Keycloakのメモリ設定がv23以前とv24以降でどのように変わったかを解説します。v23以前はJAVA_OPTSを使用してヒープサイズを調整していましたが、v24以降では専用のJAVA_OPTS_KC_HEAP環境変数が導入されました。Docker Compose設定例を含め、ヒープメモリ管理の最適化について説明します。"
---

## Keycloak のメモリ設定の変化について (v23 以前と v24 以降)

Keycloak は Java ベースのアプリケーションであり、JVM (Java Virtual Machine) オプションを調整することで、メモリ管理の動作に影響を与えることができます。Keycloak のバージョンによって、JVM のメモリ設定の方法に違いがあります。特に、**v24 以降とそれ以前のバージョン**では、`JAVA_OPTS_KC_HEAP`の使い方が異なります。

### v23 以前の設定方法

Keycloak v23 以前のバージョンでは、JVM オプションを直接`JAVA_OPTS`に設定していました。たとえば、以下のようにコンテナの総メモリに対する割合でヒープ領域を動的に調整できます。

```yaml
# v23以前のKeycloakのJVM設定
environment:
  JAVA_OPTS: "-XX:InitialRAMPercentage=50 -XX:MaxRAMPercentage=70"
```

これにより、コンテナのメモリ制限に基づいて、初期ヒープサイズと最大ヒープサイズが自動的に調整されます。`InitialRAMPercentage=50`は、コンテナの 50%のメモリを初期ヒープサイズとして割り当て、`MaxRAMPercentage=70`は最大でコンテナメモリの 70%までヒープメモリを拡張する設定です。

### v24 以降の設定方法

Keycloak v24 以降では、`JAVA_OPTS_KC_HEAP`という専用の環境変数が導入され、この変数を通じてヒープメモリ関連のオプションを設定することが推奨されるようになりました。

```yaml
# v24以降のKeycloakのJVM設定
environment:
  JAVA_OPTS_KC_HEAP: "-XX:InitialRAMPercentage=50 -XX:MaxRAMPercentage=70"
```

このバージョンからは、`JAVA_OPTS_KC_HEAP`を使用することで、Keycloak のメモリ管理を効率化し、他の JVM オプションと区別することができます。

### Docker Compose 設定例

```yaml
services:
  keycloak:
    ports:
      - "8080:8080"
    image: quay.io/keycloak/keycloak:23.0
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
      KC_DB: mysql
      KC_DB_URL_HOST: mysql
      KC_DB_URL_DATABASE: keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: password
      KC_PROXY: edge
      KC_PROXY_HEADERS: "xforwarded"
      KC_HTTP_ENABLED: true
      TZ: Asia/Tokyo
      # keycloak v24 and later
      #JAVA_OPTS_KC_HEAP: "-XX:InitialRAMPercentage=50 -XX:MaxRAMPercentage=70"

      # keycloak v23 and earlier
      JAVA_OPTS: "-XX:InitialRAMPercentage=50 -XX:MaxRAMPercentage=70"
    command:
      - start-dev
    depends_on:
      mysql:
        condition: service_healthy
    volumes:
      - idp_keycloak_data:/opt/keycloak/data
    deploy:
      resources:
        limits:
          memory: 1G

volumes:
  idp_keycloak_data:
  idp_mysql_data:
```

### 参考リンク

- [Keycloak 公式メモリ設定ドキュメント](https://www.keycloak.org/server/containers#_specifying_different_memory_settings)
- [Increase jvm on container in AWS ECS](https://keycloak.discourse.group/t/increase-jvm-on-container-in-aws-ecs/25428)
