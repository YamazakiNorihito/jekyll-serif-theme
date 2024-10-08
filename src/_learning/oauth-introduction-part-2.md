---
title: "OAuth徹底入門(2)"
date: 2023-10-06T20:23:00
#image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: "Keycloakの実践利用"
linkedinurl: ""
weight: 7
tags:
  - OAuth
  - Keycloak
  - IAM
  - Identity Management
  - Docker
  - SSO
  - Access Management
  - Security
description: ""
---

# Keycloakをローカルで試してみた: 実践記録

## Keycloakとは？

Keycloakは、オープンソースのアイデンティティとアクセス管理（IAM）ソリューションで、シングルサインオン（SSO）、アイデンティティブローカリング、およびアクセス管理の機能を提供します。

[Keycloakの公式サイト](https://www.keycloak.org/)

## 導入の経緯

職場でのプロジェクトにKeycloakが採用されていたため、私も利用することになりました。

### 実践利用

初めてのスタートは[Dockerを使用したKeycloakのセットアップガイド](https://www.keycloak.org/getting-started/getting-started-docker)を参考にしました。

後日、WebAPIを使って、Tokenの取得やRealmの追加、Userの追加などの詳細を記載します。  
まずは、このようなツールを使ってOAuthの流れをローカルで試すツールを作成しました。

## 他のIAMクラウドサービス

IAMのクラウドサービスとしては、  

- AWSの[Amazon Cognito](https://aws.amazon.com/jp/cognito/)
- Azureの[Azure Active Directory External Identities](https://azure.microsoft.com/ja-jp/products/active-directory-external-identities)  
などがあります。

## 感想

Keycloakをローカルで動かすことができるのは、非常に便利でした。初めての導入でも、手順がシンプルで理解しやすかったです。
