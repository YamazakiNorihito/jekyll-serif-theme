---
title: "OAuth徹底入門(4)"
date: 2023-10-17T17:04:00
##image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: "Keycloak RestAPI"
linkedinurl: ""
weight: 7
tags:
  - OAuth
  - Keycloak
  - REST API
  - Authentication
  - Authorization
  - Docker
  - Security
  - Access Token
description: ""
---

## KeycloakへRestしてみた

### 前提

- [KeyCloakをDockerComposeで立ち上げる](/tech/article/keycloak-docker-compose/) でKeyCloakを立ち上げていること
- VscodeのRestClientで実行する

### 実際に投げたRequest

```bash

@baseuri = http://localhost:8080/

@admin_username= admin
@admin_password=admin
@admin_client_id=admin-cli

##### get admin token
## @name admintoken
POST {{baseuri}}realms/master/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

username={{admin_username}}&password={{admin_password}}&grant_type=password&client_id={{admin_client_id}}

##### set admin token
@admin_access_token = {{admintoken.response.body.$.access_token}}
@admin_refresh_token = {{admintoken.response.body.$.refresh_token}}

##### refresh_token
## @name adminrefreshtoken
POST {{baseuri}}realms/master/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&client_id={{admin_client_id}}&refresh_token={{admin_refresh_token}}

##### refresh after set admin token
@admin_access_token = {{adminrefreshtoken.response.body.$.access_token}}
@admin_refresh_token = {{adminrefreshtoken.response.body.$.refresh_token}}

##### get realm

GET {{baseuri}}admin/realms
Authorization: Bearer {{admin_access_token}}
Content-Type: application/json

##### create realm

POST {{baseuri}}admin/realms
Authorization: Bearer {{admin_access_token}}
Content-Type: application/json

{"realm": "new-realm", "enabled": true}


##### get users
@target_reamlm = new-realm

GET {{baseuri}}admin/realms/{{target_reamlm}}/users
Authorization: Bearer {{admin_access_token}}

##### add user to realm
@target_realm = new-realm
POST {{baseuri}}admin/realms/{{target_realm}}/users
Authorization: Bearer {{admin_access_token}}
Content-Type: application/json

{
    "username" : "realmuser"
    , "enabled" : true
    , "totp": false
    , "emailVerified" : true
    , "firstName" : "rest"
    , "lastName" : "api"
    , "email": "email@example.co.jp"
    , "credentials" : [
        {
        "temporary": false
        , "type": "password"
        , "value" : "password"
    }]
    ,"access": {
      "manageGroupMembership": true,
      "view": true,
      "mapRoles": true,
      "impersonate": true,
      "manage": true
    }
}


##### get token from customer
## @name customertoken

@target_realm=new-realm
@client_id={作成したclient_id}
@client_secret={作成したclient_secret}
@authcode={authcodeはよしなに}
@redirect_uri=http://127.0.0.1:9090/callback
POST {{baseuri}}realms/{{target_realm}}/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

client_id={{client_id}}&client_secret={{client_secret}}&code={{authcode}}&redirect_uri={{redirect_uri}}&grant_type=authorization_code

##### set admin token
@customer_access_token = {{customertoken.response.body.$.access_token}}
@customer_refresh_token = {{customertoken.response.body.$.refresh_token}}

```
