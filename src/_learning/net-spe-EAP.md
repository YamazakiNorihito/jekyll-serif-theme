---
title: "ネットワークスペシャリスト　EAP"
date: 2024-02-23T14:56:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - EAP
  - IEEE 802.1X
  - 認証方式
  - ネットワークセキュリティ
  - EAP-TLS
  - PEAP
  - 無線LAN
  - クライアント認証
  - Network Specialist
description: "EAPは柔軟な認証フレームワークで、無線LANや有線ネットワークのセキュリティを強化します。IEEE 802.1Xや主要な認証方式の概要と認証プロセスを解説します。"
---

## EAP についての概要

EAP（Extensible Authentication Protocol）は、様々な認証メカニズムをサポートするために設計されたフレームワークです。これは PPP（Point-to-Point Protocol）を拡張する形で開発され、無線 LAN や有線ネットワークでの認証に広く利用されています。

#### EAP が拡張したプロトコル

EAP は、2 点間の接続を確立するための PPP に対して認証機能を拡張しました。これにより、多様な認証メカニズムを PPP 上で提供することが可能となりました。

#### 認証方式

EAP は以下のような多様な認証方式をサポートしています。

- EAP-MD5
- EAP-TLS（Transport Layer Security）
- EAP-TTLS（Tunneled Transport Layer Security）
- PEAP（Protected EAP）
- EAP-SIM（Subscriber Identity Module）
- EAP-AKA（Authentication and Key Agreement）

| 認証方式 | 認証メカニズム                   | セキュリティレベル | 実装の複雑さ | 特徴                                                                             |
| -------- | -------------------------------- | ------------------ | ------------ | -------------------------------------------------------------------------------- |
| EAP-MD5  | ユーザー名とパスワード           | 低                 | 低           | 古い方式であり、暗号化されていないため、安全性が低いです。                       |
| EAP-TLS  | デジタル証明書                   | 高                 | 高           | クライアントとサーバーの両方が証明書を必要とし、高いセキュリティを提供します。   |
| EAP-TTLS | チュネルを使用した証明書         | 高                 | 中           | サーバーのみが証明書を必要とし、クライアント認証はチュネル内で行われます。       |
| PEAP     | チュネルを使用したパスワード認証 | 中                 | 中           | サーバーの証明書を使用してチュネルを確立し、その内部でパスワード認証を行います。 |
| EAP-SIM  | SIM カード                       | 中                 | 低           | モバイルネットワークの SIM カードを使用した認証方式です。                        |
| EAP-AKA  | SIM カードの派生                 | 高                 | 中           | 強化されたセキュリティ機能を持つ SIM カードを使用した認証方式です。              |

**_覚え方_**

- EAP-TLS: 「全員証明書」
  - EAP-TLS は、クライアントとサーバーの両方がデジタル証明書を使用することが特徴です。この方式を「全員証明書」と覚えることで、双方が証明書を持っていることを思い出しやすくなります。
- PEAP: 「パスワードの保護層」
  - PEAP（Protected EAP）は、セキュリティで保護されたトンネルを確立してからパスワード認証を行う方式です。この特徴を「パスワードの保護層」と考えることで、PEAP が提供するセキュリティ層を通じてパスワードが保護されることを覚えられます。
- EAP-SIM: 「モバイル認証」
  - EAP-SIM は、モバイルネットワークの SIM カードを使用して認証を行う方法です。この方式を簡単に「モバイル認証」と覚えることで、SIM カードを利用する認証方法として記憶に残ります。

#### IEEE 802.1X との関係

IEEE 802.1X は、特に有線 LAN や無線 LAN で利用されるネットワークアクセス制御プロトコルです。EAP は IEEE 802.1X の認証フレームワークとして機能し、端末がネットワークへのアクセスを試みる際に前もって認証を行う仕組みを提供します。これにより、IEEE 802.1X プロトコルの実現が可能となります。

## IEEE 802.1X 認証フレームワークのコンポーネント

IEEE 802.1X 認証フレームワークでは、以下の 3 つの主要コンポーネントが連携してネットワーク認証を行います。

1. **Supplicant (サプリカント)**: ネットワークにアクセスしようとするクライアントデバイスです。認証情報を提供する責任があります。
2. **Authenticator (オーセンティケータ)**: ネットワークアクセスポイントのことで、クライアントデバイスと認証サーバ間の中間者として機能します。
3. **Authentication Server (認証サーバ)**: 認証情報の検証を担当するサーバです。通常は RADIUS サーバがこの役割を果たします。

#### 認証プロセスのシーケンス

以下は、これらのコンポーネント間での基本的な認証プロセスの Mermaid シーケンス図です。

```mermaid
sequenceDiagram
    participant S as Supplicant
    participant A as Authenticator
    participant AS as Authentication Server

    S->>+A: EAP-Start (認証開始)
    A->>+AS: EAP-Message (サプリカントからのメッセージ転送)
    AS-->>-A: EAP-Request Identity (身元確認要求)
    A-->>-S: EAP-Request Identity (身元確認要求)
    S->>+A: EAP-Response Identity (身元情報応答)
    A->>+AS: EAP-Response Identity (身元情報応答転送)
    AS->>A: EAP-Success or EAP-Failure (認証結果)
    A->>S: EAP-Success or EAP-Failure (認証結果)
```

#### EAP-TLS 認証プロセス

EAP-TLS を使用した認証プロセスでは、サプリカント（Supplicant）、オーセンティケータ（Authenticator）、および認証サーバー（Authentication Server）間で証明書が交換され、相互認証が行われます。以下はそのプロセスを示したシーケンス図です。

```mermaid
sequenceDiagram
    participant S as Supplicant
    participant A as Authenticator
    participant AS as Authentication Server

    S->>+A: EAP-Start (認証開始)
    A->>+AS: EAP-Message (サプリかんとからのメッセージ転送)
    AS-->>-A: EAP-Request Identity (身元確認要求)
    A-->>-S: EAP-Request Identity (身元確認要求)
    S->>+A: EAP-Response Identity (身元情報応答)
    A->>+AS: EAP-Response Identity (身元情報応答転送)
    AS->>A: EAP-Request TLS (TLS認証開始要求)
    A->>S: EAP-Request TLS (TLS認証開始要求)
    S->>A: EAP-Response TLS (クライアント証明書提供)
    A->>AS: EAP-Response TLS (クライアント証明書提供)
    AS->>A: EAP-Request TLS (サーバー証明書提供)
    A->>S: EAP-Request TLS (サーバー証明書提供)
    S->>A: EAP-TLS Exchange (TLSハンドシェイク続行)
    A->>AS: EAP-TLS Exchange (TLSハンドシェイク続行)
    AS->>A: EAP-Success or EAP-Failure (認証結果)
    A->>S: EAP-Success or EAP-Failure (認証結果)
```

1. EAP-Start: サプリカントが認証開始を知らせます。
1. EAP-Request Identity: 認証サーバーが身元確認要求をします。
1. EAP-Response Identity: サプリカントが身元情報を応答します。
1. EAP-Request TLS: TLS 認証の開始が要求されます。
1. EAP-Response TLS (クライアント証明書提供): サプリカントがクライアント証明書を提供します。
1. EAP-Request TLS (サーバー証明書提供): 認証サーバーがサーバー証明書を提供します。
1. EAP-TLS Exchange: TLS ハンドシェイクが続行され、相互認証とセキュアな通信チャネルの確立が行われます。
1. EAP-Success or EAP-Failure: 認証結果がサプリカントに通知されます。
