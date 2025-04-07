---
title: "KeycloakのJSONを使ってClientにService Roleを付与する"
date: 2024-07-29T08:10:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - Keycloak
description: "Keycloakでサービスロールを持つClientをJSONインポートで定義する方法を解説します。"
---

Keycloakの環境において、Realmを作成すると同時に、オリジナルのClientを含めた構成をJSONで定義し、そのJSONをインポートすることで環境構築を自動化しようと考えました。

その際、Service Roleを付与したClientを作成するために必要な設定が判明したため、備忘録として記録しておきます。

正直なところ、なぜその設定が必要なのかまでは理解できていません。KeycloakのExport機能を活用し、実際に動作する設定を抽出しただけなので、深い技術的背景の解説はできません。(公式ドキュメントには見当たらなかった。)

以下のJSONは、Realm `test-realm` を作成し、その中に `service-account-role-client` というClientを定義し、カスタムのRealm Role `option-custom-role-name` と、Keycloakにあらかじめ用意されている `manage-users` ロールを付与するものです。

ポイントは、ClientにService Roleを付与するには、**サービスアカウント用のユーザーを明示的に作成する必要がある**という点です。

```json
{
  "realm": "test-realm",
  "clients": [
    {
      "clientId": "service-account-role-client",
      "clientAuthenticatorType": "client-secret",
      "protocol": "openid-connect",
      "standardFlowEnabled": false,
      "implicitFlowEnabled": false,
      "directAccessGrantsEnabled": false,
      "serviceAccountsEnabled": true
    }
  ],
  "roles": {
    "realm": [
      {
        "name": "option-custom-role-name",
        "composite": false,
        "clientRole": false,
        "attributes": {}
      }
    ]
  },
  "users": [
    {
      "username": "service-account-service-account-role-client",
      "enabled": true,
      "totp": false,
      "emailVerified": false,
      "serviceAccountClientId": "service-account-role-client",
      "realmRoles": ["option-custom-role-name"],
      "clientRoles": {
        "realm-management": ["manage-users"]
      }
    }
  ]
}
```

この設定で重要なのは、`serviceAccountsEnabled: true` を指定することで、そのクライアントがサービスアカウントとして動作するように設定される点です。

ただし、JSONでインポートする場合、Keycloakは内部的に自動生成されるべきサービスアカウント用のユーザー（`service-account-<clientId>`）を作成してくれません。そのため、`users` セクションで手動で明示的に定義する必要があります。

そのユーザーに `serviceAccountClientId` を設定し、必要な `realmRoles` や `clientRoles` を付与することで、Clientに必要な権限を与えることができます。

公式ドキュメントにはこのような細かい内容は記載されていないため、実際に管理画面から設定を行い、Exportして得られるJSONを比較・分析することで把握するしかありません。

同じようにハマる人が減ることを願って、この知見を共有します。
