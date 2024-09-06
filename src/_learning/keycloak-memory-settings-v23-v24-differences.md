---
title: "Keycloakのメモリ設定の変化について (v23以前とv24以降)"
date: 2024-9-6T09:34:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
---

## Keycloakのメモリ設定の変化について (v23以前とv24以降)

KeycloakはJavaベースのアプリケーションであり、JVM (Java Virtual Machine) オプションを調整することで、メモリ管理の動作に影響を与えることができます。Keycloakのバージョンによって、JVMのメモリ設定の方法に違いがあります。特に、**v24以降とそれ以前のバージョン**では、`JAVA_OPTS_KC_HEAP`の使い方が異なります。

### v23以前の設定方法

Keycloak v23以前のバージョンでは、JVMオプションを直接`JAVA_OPTS`に設定していました。たとえば、以下のようにコンテナの総メモリに対する割合でヒープ領域を動的に調整できます。

```yaml
# v23以前のKeycloakのJVM設定
environment:
  JAVA_OPTS: "-XX:InitialRAMPercentage=50 -XX:MaxRAMPercentage=70"
```

これにより、コンテナのメモリ制限に基づいて、初期ヒープサイズと最大ヒープサイズが自動的に調整されます。`InitialRAMPercentage=50`は、コンテナの50%のメモリを初期ヒープサイズとして割り当て、`MaxRAMPercentage=70`は最大でコンテナメモリの70%までヒープメモリを拡張する設定です。

### v24以降の設定方法

Keycloak v24以降では、`JAVA_OPTS_KC_HEAP`という専用の環境変数が導入され、この変数を通じてヒープメモリ関連のオプションを設定することが推奨されるようになりました。

```yaml
# v24以降のKeycloakのJVM設定
environment:
  JAVA_OPTS_KC_HEAP: "-XX:InitialRAMPercentage=50 -XX:MaxRAMPercentage=70"
```

このバージョンからは、`JAVA_OPTS_KC_HEAP`を使用することで、Keycloakのメモリ管理を効率化し、他のJVMオプションと区別することができます。

### Docker Compose設定例

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

- [Keycloak公式メモリ設定ドキュメント](https://www.keycloak.org/server/containers#_specifying_different_memory_settings)
- [Keycloak 19から22へのアップグレード後の問題に関するディスカッション](https://keycloak.discourse.group/t/high-cpu-utilization-and-frequent-restarts-after-upgrading-from-keycloak-19-to-keycloak-22/26298) [oai_citation:1,How-to Optimize Memory Consumption for Java Containers Running in Kubernetes - Ralph's Open Source Blog](https://ralph.blog.imixs.com/2020/10/22/how-to-optimize-memory-consumption-for-wildfly-running-in-kubernetes/)
