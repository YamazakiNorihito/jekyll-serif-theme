---
title: "Keycloak Custom REST Endpoint: Retrieve User Credentials"
date: 2024-10-17T14:57:00
mermaid: true
weight: 7
tags:
  - Keycloak
  - Custom REST API
  - Extension API
  - User Management
  - Credential Management
  - Java Development
  - Keycloak Customization
  - Web Security
description: "Learn how to create a custom REST endpoint in Keycloak using the Extension API to retrieve user credentials in JSON format."
---

KeycloakのExtension APIの実装について学びましたので、その内容をまとめます。今回の実装は、特定ユーザーのクレデンシャルデータを取得するためのカスタムREST APIの作成です。以下に、その具体的な手順とコードを紹介します。

## 実装概要

今回実装した内容は、ユーザーのクレデンシャルデータをJSON形式でレスポンスとして返すAPIです。サンプルコードは[こちらのGitHubリポジトリ](https://github.com/YamazakiNorihito/keycloak-custom-rest-endpoint/tree/main)に公開しています。

Keycloakのドキュメント「[Add custom REST endpoints](https://www.keycloak.org/docs/latest/server_development/index.html#_extensions_rest)」を参考にしながら、REST APIを拡張しました。

以下はプロジェクト構成です。

```plaintext
keycloak-extension-api
.
├── Dockerfile
├── MavenBuild.Dockerfile
├── compose.yml
├── custom-rest-api
│   ├── pom.xml
│   └── src
│       ├── main
│       │   ├── java
│       │   │   └── com
│       │   │       └── example
│       │   │           └── keycloak
│       │   │               └── rest
│       │   │                   ├── UserCredentialRestProvider.java
│       │   │                   ├── UserCredentialRestProviderFactory.java
│       │   │                   └── credential
│       │   │                       ├── SecretQuestionCredentialModel.java
│       │   │                       └── dto
│       │   │                           ├── SecretQuestionCredentialData.java
│       │   │                           └── SecretQuestionSecretData.java
│       │   └── resources
│       │       └── META-INF
│       │           ├── beans.xml
│       │           └── services
│       │               ├── org.keycloak.services.resource.RealmResourceProviderFactory
```

### 必要なファイル

実装に必要なファイルは以下の通りです。

- `keycloak/rest/UserCredentialRestProvider.java`
- `keycloak/rest/UserCredentialRestProviderFactory.java`
- `resources/META-INF/services/org.keycloak.services.resource.RealmResourceProviderFactory`
- `resources/META-INF/beans.xml` (内容は空のファイルです)

## 実装コード

以下に、各ファイルのコードを紹介します。

### UserCredentialRestProvider.java

```java
package com.example.keycloak.rest;

import java.util.List;
import java.util.stream.Collectors;
import org.jboss.logging.Logger;
import org.jboss.resteasy.spi.InternalServerErrorException;
import org.keycloak.credential.CredentialModel;
import org.keycloak.models.*;
import org.keycloak.services.resource.RealmResourceProvider;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.NotFoundException;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@jakarta.ws.rs.ext.Provider
public class UserCredentialRestProvider implements RealmResourceProvider {
    private static final Logger log = Logger.getLogger(UserCredentialRestProvider.class);
    private KeycloakSession session;

    public UserCredentialRestProvider(KeycloakSession session) {
        this.session = session;
    }

    @Override
    public Object getResource() {
        return this;
    }

    @GET
    @Path("users/{user-id}/credentials")
    @Produces(MediaType.APPLICATION_JSON)
    public List<CredentialModel> getUserCredentials(@PathParam("user-id") String userId) {
        log.infof("getUserCredentials() method called with user-id: %s", userId);

        try {
            final UserModel user =
                    session.users().getUserById(session.getContext().getRealm(), userId);
            if (user == null) {
                log.warnf("User with ID %s not found", userId);
                throw new NotFoundException("User not found");
            }

            final SubjectCredentialManager credentialStore = user.credentialManager();

            List<CredentialModel> credentials =
                    credentialStore.getStoredCredentialsStream().peek(cred -> {
                        // Optional: log each credential type for debugging
                        log.debugf("Credential ID: %s, Type: %s", cred.getId(), cred.getType());
                    }).collect(Collectors.toList());

            log.infof("Number of credentials retrieved for user-id %s: %d", userId,
                    credentials.size());
            return credentials;

        } catch (Exception e) {
            log.errorf("Error in getUserCredentials() method for user-id %s: %s", userId,
                    e.getMessage());
            throw new InternalServerErrorException(
                    "Error processing request for user-id " + userId);
        }
    }

    @Override
    public void close() {}
}
```

このコードは、指定されたユーザーIDに基づいてそのユーザーのクレデンシャルデータを取得し、JSON形式で返すためのRESTエンドポイントを提供します。

### UserCredentialRestProviderFactory.java

```java
package com.example.keycloak.rest;

import org.keycloak.Config.Scope;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.services.resource.RealmResourceProvider;
import org.keycloak.services.resource.RealmResourceProviderFactory;

public class UserCredentialRestProviderFactory implements RealmResourceProviderFactory {

    public static final String ID = "credential-api";

    @Override
    public RealmResourceProvider create(KeycloakSession session) {
        return new UserCredentialRestProvider(session);
    }

    @Override
    public String getId() {
        return ID;
    }

    @Override
    public void close() {}

    @Override
    public void init(Scope arg0) {}

    @Override
    public void postInit(KeycloakSessionFactory arg0) {}
}
```

このファクトリクラスは、`UserCredentialRestProvider`をKeycloakに登録するためのものです。`getId()`メソッドで指定するIDは、RESTエンドポイントにアクセスする際のURLパスに使用されます。

### META-INF設定

`META-INF/services/org.keycloak.services.resource.RealmResourceProviderFactory`には、`UserCredentialRestProviderFactory`のクラス名を記載します。

```java
com.example.keycloak.rest.UserCredentialRestProviderFactory
```

このファイルは、Keycloakが拡張ポイントを検出するために使用します。

## おわりに

以上のように、KeycloakのExtension APIを用いてカスタムRESTエンドポイントを実装し、特定のユーザーのクレデンシャルデータを取得するAPIを作成しました。この実装を行うことで、ユーザーに関連する情報をKeycloakの外部システムと連携させることが可能になります。

実装に関する詳細や、さらなるカスタマイズ方法については、[公式ドキュメント](https://www.keycloak.org/docs/latest/server_development/index.html)も参考にしてください。

ご質問やフィードバックがありましたら、[GitHubリポジトリ](https://github.com/YamazakiNorihito/keycloak-custom-rest-endpoint)にIssueを作成していただけると嬉しいです。
