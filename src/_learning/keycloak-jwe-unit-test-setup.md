---
title: "Keycloak JWE の単体テスト時の事前準備メモ"
date: 2024-12-11T11:32:00
mermaid: true
weight: 7
tags:
  - Keycloak
  - JWE
  - UnitTest
  - BouncyCastle
  - Java
description: "KeycloakのJWE機能を使用した単体テスト実行時に必要な事前準備について、BouncyCastleProviderの登録方法やCryptoIntegrationの有効化手順を解説します。"
---

誰のために役に立つのかわからないが、 KeycloakのJWEに関してUT（ユニットテスト）で使う時に、  
何を事前準備しないといけないのか学んだので書き残す。

ここでは Keycloak API をExtensionするためのSPIやWeb APIの詳細な仕様、実行方法は省略する。  
あくまでも KeycloakのJWEでEncode/Decodeを行うUT実行時に必要な準備についてのみ残す。

ポイントは以下の2点:

1. `SecurityProvider` に `BouncyCastleProvider` を追加すること
2. `CryptoIntegration` でBouncyCastleProviderを有効化すること

実際の実装例は以下を参照してください。

## pom.xml

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example.keycloak</groupId>
  <artifactId>custom-rest-api</artifactId>
  <packaging>jar</packaging>
  <version>1.0-SNAPSHOT</version>
  <name>custom-rest-api</name>
  <url>http://maven.apache.org</url>

  <properties>
    <keycloak.version>22.0.0</keycloak.version>
    <maven.compiler.source>17</maven.compiler.source>
    <maven.compiler.target>17</maven.compiler.target>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.keycloak</groupId>
      <artifactId>keycloak-core</artifactId>
      <version>${keycloak.version}</version>
      <scope>provided</scope>
    </dependency>
    <dependency>
      <groupId>org.keycloak</groupId>
      <artifactId>keycloak-server-spi</artifactId>
      <version>${keycloak.version}</version>
      <scope>provided</scope>
    </dependency>
    <dependency>
      <groupId>org.keycloak</groupId>
      <artifactId>keycloak-services</artifactId>
      <version>${keycloak.version}</version>
      <scope>provided</scope>
    </dependency>
    <dependency>
      <groupId>org.keycloak</groupId>
      <artifactId>keycloak-model-jpa</artifactId>
      <version>${keycloak.version}</version>
      <scope>provided</scope>
    </dependency>
    <dependency>
      <groupId>jakarta.ws.rs</groupId>
      <artifactId>jakarta.ws.rs-api</artifactId>
      <version>4.0.0</version>
    </dependency>
    <dependency>
      <groupId>org.mockito</groupId>
      <artifactId>mockito-core</artifactId>
      <version>5.14.2</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-api</artifactId>
      <version>5.11.3</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-params</artifactId>
      <version>5.11.3</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-engine</artifactId>
      <version>5.11.3</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.bouncycastle</groupId> <!--必須-->
      <artifactId>bcprov-jdk18on</artifactId>
      <version>1.76</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.keycloak</groupId> <!--必須-->
      <artifactId>keycloak-crypto-default</artifactId>
      <version>${keycloak.version}</version>
      <scope>test</scope>
    </dependency>
  </dependencies>
  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>3.0.0-M7</version>
        <configuration>
          <includes>
            <include>**/*Test.java</include>
          </includes>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
```

## DecryptResourceTest

```java
package jp.ne.medcom.keycloak.rest;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import java.security.*;
import org.junit.jupiter.api.*;
import org.keycloak.crypto.*;
import org.keycloak.jose.jwe.*;
import org.keycloak.models.*;
import org.keycloak.services.managers.AuthenticationManager;
import jakarta.ws.rs.core.Response;
import java.util.stream.Stream;
import java.nio.charset.StandardCharsets;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.keycloak.common.crypto.CryptoIntegration;

class DecryptResourceTest {
    protected static final String PAYLOAD =
            "Hello world! How are you man? I hope you are fine. This is some quite a long text, which is much longer than just simple 'Hello World'";

    private KeycloakSession session;
    private AuthenticationManager.AuthResult auth;
    private RealmModel realm;

    private KeyManager keyManager;
    private KeyPair keyPair;

    @BeforeEach
    public void setUp() throws NoSuchAlgorithmException {

        // BouncyCastleProviderを登録
        // https://github.com/bcgit/bc-java/blob/d95afbf5c329d51c2a92099e8db84f7fc2028602/prov/src/main/java/org/bouncycastle/jce/provider/BouncyCastleProvider.java#L81
        if (Security.getProvider("BC") == null) {
            Security.addProvider(new BouncyCastleProvider());
        }
        // CryptoIntegrationの初期化
        CryptoIntegration.dumpSecurityProperties();

        // DefaultCryptoProviderは、BouncyCastleProviderが利用している
        // https://github.com/keycloak/keycloak/blob/0e1a62fa60166940eb2065fd7cb91862918f36eb/crypto/default/src/main/java/org/keycloak/crypto/def/DefaultCryptoProvider.java#L56
        // https://github.com/keycloak/keycloak/blob/0e1a62fa60166940eb2065fd7cb91862918f36eb/authz/client/src/main/resources/META-INF/services/org.keycloak.common.crypto.CryptoProvider#L20
        CryptoIntegration.init(Thread.currentThread().getContextClassLoader());

        session = mock(KeycloakSession.class);
        auth = mock(AuthenticationManager.AuthResult.class);
        realm = mock(RealmModel.class);
        keyManager = mock(KeyManager.class);

        KeyPairGenerator keyGen = KeyPairGenerator.getInstance("RSA");
        keyGen.initialize(2048);
        keyPair = keyGen.generateKeyPair();

        var clientModel = mock(ClientModel.class);
        when(auth.getClient()).thenReturn(clientModel);
        when(clientModel.getRealm()).thenReturn(realm);
        when(session.keys()).thenReturn(keyManager);
    }

    @Test
    void Should_success_decrypt() throws Exception {
        // Arrange
        var keyId = "test-keyId";
        when(session.keys().getKeysStream(realm)).thenAnswer(invocation -> {
            KeyWrapper keyWrapper = new KeyWrapper();
            keyWrapper.setKid(keyId);
            keyWrapper.setStatus(KeyStatus.ACTIVE);
            keyWrapper.setPrivateKey(keyPair.getPrivate());
            return Stream.of(keyWrapper);
        });

        // Act
        var response =
                (new DecryptResource(session, auth)).decrypt(encode(keyPair.getPublic(), keyId));

        // Assert
        assertEquals(Response.Status.OK.getStatusCode(), response.getStatus());
        assertEquals(PAYLOAD, response.getEntity());
    }

    private String encode(PublicKey aesKey, String keyId) throws JWEException {
        JWEHeader jweHeader =
                new JWEHeader(JWEConstants.RSA_OAEP_256, JWEConstants.A128CBC_HS256, null, keyId);

        JWE jwe = new JWE().header(jweHeader).content(PAYLOAD.getBytes(StandardCharsets.UTF_8));
        jwe.getKeyStorage().setEncryptionKey(aesKey);
        return jwe.encodeJwe();
    }
}

```

## DecryptResource

```java
package jp.ne.medcom.keycloak.rest;

import org.eclipse.microprofile.openapi.annotations.responses.APIResponse;
import org.keycloak.jose.JOSEParser;
import org.keycloak.jose.jwe.*;
import org.keycloak.models.KeycloakSession;
import org.keycloak.services.managers.AuthenticationManager;
import org.keycloak.util.TokenUtil;

import java.security.Key;
import java.util.Objects;

import org.keycloak.crypto.KeyWrapper;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.*;

@jakarta.ws.rs.ext.Provider
public class DecryptResource {
    protected final KeycloakSession session;
    private final AuthenticationManager.AuthResult auth;

    public DecryptResource(KeycloakSession session, AuthenticationManager.AuthResult auth) {
        this.session = Objects.requireNonNull(session, "session cannot be null");
        this.auth = Objects.requireNonNull(auth, "auth result cannot be null");
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Path("/")
    @APIResponse(responseCode = "200", description = "Successfully decrypted and returned token")
    public Response decrypt(String jweStr) throws JWEException {
        var header = (JWEHeader) ((JWE) JOSEParser.parse(jweStr)).getHeader();
        var key = getKey(header).getPrivateKey();
        return Response.ok(decodeString(key, jweStr)).build();
    }

    private String decodeString(Key key, String jweStr) throws JWEException {
        byte[] decodedString = TokenUtil.jweKeyEncryptionVerifyAndDecode(key, jweStr);
        return new String(decodedString, java.nio.charset.StandardCharsets.UTF_8);
    }

    private KeyWrapper getKey(JWEHeader jweHeader) {
        return session.keys().getKeysStream(this.auth.getClient().getRealm()).filter(
                key -> key.getStatus().isActive() && key.getKid().equals(jweHeader.getKeyId()))
                .findFirst().orElse(null);
    }
}

```
