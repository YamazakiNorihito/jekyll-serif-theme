---
title: "KeycloakでJSONインポートを用いて独自のAuthentication Flowを設定する方法"
date: 2024-12-04T10:35:00
mermaid: true
weight: 7
tags:
  - Keycloak
  - Authentication Flow
  - JSON Import
  - Configuration Management
  - Identity and Access Management
  - Realm Configuration
  - Web Security
  - Custom Login Flow
description: "KeycloakでカスタムAuthentication Flowを設定する方法を解説。JSONファイルを使用してアプリ停止せずに設定をインポートする手順を紹介します。"
---

## はじめに

Keycloakで複数のRealmを管理する際、共通のAuthentication Flowを適用する場合には、GUIで設定するよりもJSONファイルをインポート形式で利用する方法が効率的です。これにより、設定を再利用しやすくなり、運用コストが削減できます。ただし、[公式](https://www.keycloak.org/server/importExport)のkc.[sh|bat] importコマンドを利用すると、Keycloakを一時停止する必要があります。本記事では、アプリケーションを停止せずに管理コンソールからJSONファイルを使ってRealmを作成する方法を紹介します。

## 背景

Keycloakでユーザーのログイン体験をカスタマイズするために、ユーザー名とパスワードを別々のステップで入力させるAuthentication Flowを設定したいと考えました。このようなカスタムのAuthentication Flowを設定するためには、既存のFlowをコピーして編集するか、新たにFlowを作成する必要があります。

ただし、Keycloakの管理コンソールから部分的なインポート（Partial Import）を行う場合、Authentication Flowを含めることができません。そのため、JSONファイルを使用してRealm全体をインポートする方法を取ります。

## 手順

1. **管理コンソールへのログイン**

   Keycloakの管理コンソールにAdminユーザーでログインします。

2. **Realmの作成**

   左上の「Create realm」ボタンをクリックし、「Browse...」から事前に用意したJSONファイルを選択してインポートします。

3. **注意点**

   - 部分的なインポート（Realm Settings > Import）では、Authentication Flowをインポート・変更することはできません。インポート可能なのは以下の6種類のみです。

     - Users
     - Groups
     - Clients
     - Identity Providers
     - Roles (Realm Roles)
     - Roles (Client Roles)

     ソースコードは[こちら](https://github.com/keycloak/keycloak/blob/3111148fe766bbe21543b8e57f26c14a589fae52/js/apps/admin-ui/src/realm-settings/PartialImport.tsx#L351-L368)で確認できます。

   - JSONファイル内で設定したいFlowは`"browserFlow": "separate-browser-step"`です。関連するAuthentication Flowは以下の通りです。

     - `separate-browser-step`
     - `separate-browser-step Browser - Conditional OTP`
     - `separate-browser-step forms`

## JSONファイルのサンプル

以下に、インポート時に使用するJSONファイルのサンプルを示します。

<details><summary>JSONファイルを表示</summary>

```json
{
  "realm": "import-realm-v1", ## realmName適宜書き換え
  "enabled": true,
  "authenticationFlows": [
    {
      "id": "3d50274b-05a1-4f2e-ae23-da0f7e6d974a", ## UUID DB内でユニークである必要がある
      "alias": "Account verification options",
      "description": "Method with which to verity the existing account",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "idp-email-verification",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "ALTERNATIVE",
          "priority": 20,
          "autheticatorFlow": true,
          "flowAlias": "Verify Existing Account by Re-authentication",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "5200230f-9465-42f9-9748-26ec2afddb9c", ## UUID DB内でユニークである必要がある
      "alias": "Browser - Conditional OTP",
      "description": "Flow to determine if the OTP is required for the authentication",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "conditional-user-configured",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "auth-otp-form",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "86192052-fd70-40fc-8b3d-0cfc717cb418", ## UUID DB内でユニークである必要がある
      "alias": "Direct Grant - Conditional OTP",
      "description": "Flow to determine if the OTP is required for the authentication",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "conditional-user-configured",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "direct-grant-validate-otp",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "022835e2-ad89-4a96-ac30-468857c60b4a", ## UUID DB内でユニークである必要がある
      "alias": "First broker login - Conditional OTP",
      "description": "Flow to determine if the OTP is required for the authentication",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "conditional-user-configured",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "auth-otp-form",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "a4943d0b-d7ff-44cd-9cee-60f50e70da12", ## UUID DB内でユニークである必要がある
      "alias": "Handle Existing Account",
      "description": "Handle what to do if there is existing account with same email/username like authenticated identity provider",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "idp-confirm-link",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": true,
          "flowAlias": "Account verification options",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "778e7529-1021-46cf-8c58-c2a97f7cbb92", ## UUID DB内でユニークである必要がある
      "alias": "Reset - Conditional OTP",
      "description": "Flow to determine if the OTP should be reset or not. Set to REQUIRED to force.",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "conditional-user-configured",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "reset-otp",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "fda322a7-01d0-4635-a9a2-980636ca1fd4", ## UUID DB内でユニークである必要がある
      "alias": "User creation or linking",
      "description": "Flow for the existing/non-existing user alternatives",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticatorConfig": "create unique user config",
          "authenticator": "idp-create-user-if-unique",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "ALTERNATIVE",
          "priority": 20,
          "autheticatorFlow": true,
          "flowAlias": "Handle Existing Account",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "f6db95ab-14bd-41ea-b624-520c83c1297c", ## UUID DB内でユニークである必要がある
      "alias": "Verify Existing Account by Re-authentication",
      "description": "Reauthentication of existing account",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "idp-username-password-form",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "CONDITIONAL",
          "priority": 20,
          "autheticatorFlow": true,
          "flowAlias": "First broker login - Conditional OTP",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "2b6c2f3d-fffa-4d25-8201-97a71f9fd9e1", ## UUID DB内でユニークである必要がある
      "alias": "browser",
      "description": "browser based authentication",
      "providerId": "basic-flow",
      "topLevel": true,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "auth-cookie",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "auth-spnego",
          "authenticatorFlow": false,
          "requirement": "DISABLED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "identity-provider-redirector",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 25,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "ALTERNATIVE",
          "priority": 30,
          "autheticatorFlow": true,
          "flowAlias": "forms",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "40b248d1-efb4-40b5-bea2-30fc5c36e248", ## UUID DB内でユニークである必要がある
      "alias": "clients",
      "description": "Base authentication for clients",
      "providerId": "client-flow",
      "topLevel": true,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "client-secret",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "client-jwt",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "client-secret-jwt",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 30,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "client-x509",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 40,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "c574a4af-be52-40ed-a12c-6cd8ea8c1ec7", ## UUID DB内でユニークである必要がある
      "alias": "direct grant",
      "description": "OpenID Connect Resource Owner Grant",
      "providerId": "basic-flow",
      "topLevel": true,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "direct-grant-validate-username",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "direct-grant-validate-password",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "CONDITIONAL",
          "priority": 30,
          "autheticatorFlow": true,
          "flowAlias": "Direct Grant - Conditional OTP",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "84eec2af-1279-4f61-b1fd-59b0173b2ac8", ## UUID DB内でユニークである必要がある
      "alias": "docker auth",
      "description": "Used by Docker clients to authenticate against the IDP",
      "providerId": "basic-flow",
      "topLevel": true,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "docker-http-basic-authenticator",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "fcfe08ff-a0a5-48f4-bf0a-73873376d03d", ## UUID DB内でユニークである必要がある
      "alias": "forms",
      "description": "Username, password, otp and other auth forms.",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "auth-username-password-form",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "CONDITIONAL",
          "priority": 20,
          "autheticatorFlow": true,
          "flowAlias": "Browser - Conditional OTP",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "cabbc50c-2dc9-4123-bd73-b50509d6f7cf", ## UUID DB内でユニークである必要がある
      "alias": "separate-browser-step",
      "description": "browser based authentication",
      "providerId": "basic-flow",
      "topLevel": true,
      "builtIn": false,
      "authenticationExecutions": [
        {
          "authenticator": "auth-cookie",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "auth-spnego",
          "authenticatorFlow": false,
          "requirement": "DISABLED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "identity-provider-redirector",
          "authenticatorFlow": false,
          "requirement": "ALTERNATIVE",
          "priority": 25,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "ALTERNATIVE",
          "priority": 30,
          "autheticatorFlow": true,
          "flowAlias": "separate-browser-step forms",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "02dea47e-2a0c-4c64-a33a-d1f81805bd8d", ## UUID DB内でユニークである必要がある
      "alias": "separate-browser-step Browser - Conditional OTP",
      "description": "Flow to determine if the OTP is required for the authentication",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": false,
      "authenticationExecutions": [
        {
          "authenticator": "conditional-user-configured",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "auth-otp-form",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "432d1de5-e544-4f42-98be-261f3bd915b8", ## UUID DB内でユニークである必要がある
      "alias": "separate-browser-step forms",
      "description": "Username, password, otp and other auth forms.",
      "providerId": "basic-flow",
      "topLevel": false,
      "builtIn": false,
      "authenticationExecutions": [
        {
          "authenticator": "auth-username-form",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "auth-password-form",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 21,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "CONDITIONAL",
          "priority": 22,
          "autheticatorFlow": true,
          "flowAlias": "separate-browser-step Browser - Conditional OTP",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "c107b47b-e637-4b67-bd1e-54b7b92f82ff", ## UUID DB内でユニークである必要がある
      "alias": "registration",
      "description": "registration flow",
      "providerId": "basic-flow",
      "topLevel": true,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "registration-page-form",
          "authenticatorFlow": true,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": true,
          "flowAlias": "registration form",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "62b795d1-e8e8-445b-b11f-72ebe1cba55e", ## UUID DB内でユニークである必要がある
      "alias": "registration form",
      "description": "registration form",
      "providerId": "form-flow",
      "topLevel": false,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "registration-user-creation",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "registration-profile-action",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 40,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "registration-password-action",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 50,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "registration-recaptcha-action",
          "authenticatorFlow": false,
          "requirement": "DISABLED",
          "priority": 60,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "75ed89b5-c11b-422a-a49f-e411cf90b0cd", ## UUID DB内でユニークである必要がある
      "alias": "reset credentials",
      "description": "Reset credentials for a user if they forgot their password or something",
      "providerId": "basic-flow",
      "topLevel": true,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "reset-credentials-choose-user",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "reset-credential-email",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 20,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticator": "reset-password",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 30,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        },
        {
          "authenticatorFlow": true,
          "requirement": "CONDITIONAL",
          "priority": 40,
          "autheticatorFlow": true,
          "flowAlias": "Reset - Conditional OTP",
          "userSetupAllowed": false
        }
      ]
    },
    {
      "id": "9472706f-fe79-41c8-9c12-71e59eaebfa6", ## UUID DB内でユニークである必要がある
      "alias": "saml ecp",
      "description": "SAML ECP Profile Authentication Flow",
      "providerId": "basic-flow",
      "topLevel": true,
      "builtIn": true,
      "authenticationExecutions": [
        {
          "authenticator": "http-basic-authenticator",
          "authenticatorFlow": false,
          "requirement": "REQUIRED",
          "priority": 10,
          "autheticatorFlow": false,
          "userSetupAllowed": false
        }
      ]
    }
  ],
  "authenticatorConfig": [
    {
      "id": "36a8a30b-7e3a-4dfc-a1fe-fec543a97ae8", ## UUID DB内でユニークである必要がある
      "alias": "create unique user config",
      "config": {
        "require.password.update.after.registration": "false"
      }
    },
    {
      "id": "74d60b81-5864-4ca0-ab53-984116890960", ## UUID DB内でユニークである必要がある
      "alias": "review profile config",
      "config": {
        "update.profile.on.first.login": "missing"
      }
    }
  ],
  "browserFlow": "separate-browser-step", ## 適用したいFlow Name
  "registrationFlow": "registration",
  "directGrantFlow": "direct grant",
  "resetCredentialsFlow": "reset credentials",
  "clientAuthenticationFlow": "clients",
  "dockerAuthenticationFlow": "docker auth"
}
```

</details>

**注意点**

- `authenticationFlows`内の各Flowには一意の`id`（UUID）が必要です。他のRealmや既存のFlowと重複しないように注意してください。
- `authenticatorConfig`も同様に一意の`id`が必要です。

## 解説

JSONファイルでRealmをインポートする際、`authenticationFlows`セクションでカスタムのAuthentication Flowを定義できます。ここで指定したFlowを`browserFlow`などの設定で適用することで、ログインフローをカスタマイズできます。

`importAuthenticationFlows`メソッド（[ソースコード](https://github.com/keycloak/keycloak/blob/3111148fe766bbe21543b8e57f26c14a589fae52/model/legacy-private/src/main/java/org/keycloak/storage/datastore/LegacyExportImportManager.java#L1255)）が、インポート時にAuthentication Flowを処理しています。

## まとめ

KeycloakのRealmをJSONファイルでインポートすることで、アプリケーションを停止せずにカスタムのAuthentication Flowを設定できます。これにより、より柔軟なログインフローの構築が可能となります。

**ポイント**

- 管理コンソールからのRealm作成時にJSONファイルを使用する。
- `authenticationFlows`セクションで独自のFlowを定義する。
- `id`（UUID）は一意の値を使用する。
- 部分的なインポートではAuthentication Flowを変更できない。

## 参考情報

- [Keycloak Documentation - Importing and Exporting Realms](https://www.keycloak.org/server/importExport)
- [GitHub - PartialImport.tsx ソースコード](https://github.com/keycloak/keycloak/blob/3111148fe766bbe21543b8e57f26c14a589fae52/js/apps/admin-ui/src/realm-settings/PartialImport.tsx#L351-L368)
- [GitHub - LegacyExportImportManager.java ソースコード](https://github.com/keycloak/keycloak/blob/3111148fe766bbe21543b8e57f26c14a589fae52/model/legacy-private/src/main/java/org/keycloak/storage/datastore/LegacyExportImportManager.java#L1255)
