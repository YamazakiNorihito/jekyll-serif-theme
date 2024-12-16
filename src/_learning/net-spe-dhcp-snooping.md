---
title: "ネットワークスペシャリスト　DHCP Snooping"
date: 2024-02-14T15:25:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - DHCP Snooping
  - DHCP Spoofing
  - Network Security
  - Switch Security
  - Cybersecurity
  - IP Address Management
  - Trusted Ports
  - Untrusted Ports
  - Network Specialist
  - Attack Prevention
description: "DHCPスヌーピングを活用して、不正なDHCPサーバーからの攻撃を防ぐ方法を解説。trustedポートとuntrustedポートの役割を示し、DHCPスプーフィング攻撃の流れとその防止メカニズムを詳述します。"
---

## DHCP スヌーピングとは

DHCP スヌーピングは、ネットワークセキュリティを強化するための技術であり、不正な DHCP サーバからの攻撃を検出し、防止する機能です。この技術には、「trusted（信頼された）」ポートと「untrusted（信頼されていない）」ポートを区別する概念が含まれています。

#### Trusted ポートと Untrusted ポート

- **Trusted ポート**: これらのポートは、正規の DHCP サーバからの応答を許可するとマークされています。ネットワーク管理者は、実際の DHCP サーバに接続されているポートを trusted として設定することにより、正当な DHCP 通信のみがネットワーク内で行われるようにします。

- **Untrusted ポート**: 一方、untrusted ポートは、DHCP サーバからの応答を許可しないとマークされています。クライアントデバイスが接続されるポートは通常、untrusted として設定され、これにより不正な DHCP サーバがネットワーク内で応答することを防ぎます。

#### 主な機能と利点

- **不正な DHCP サーバの検出と防止**: untrusted ポートからの DHCP 応答をブロックすることで、不正な DHCP サーバによる攻撃を防ぎます。
- **DHCP スターベーション攻撃の防止**: untrusted ポートからの大量の DHCP リクエストを制御することで、IP アドレスプールの枯渇を防ぎます。
- **ネットワークセキュリティの向上**: trusted ポートのみが DHCP 応答を許可することにより、ネットワークのセキュリティが強化されます。
- **攻撃の検出と報告**: 不正な活動を検出し、管理者に報告することで、迅速な対応を可能にします。

## シーケンス図

**_DHCP Spoofing_**

```mermaid
sequenceDiagram
    participant PC as クライアントPC
    participant Switch as スイッチ
    participant DHCP as 正規DHCPサーバー
    participant Spoofer as スプーフィングサーバー

    PC->>Switch: DHCPディスカバリー
    Switch->>DHCP: DHCPディスカバリー
    Switch->>Spoofer: DHCPディスカバリー
    DHCP->>Switch: DHCPオファー
    Spoofer->>Switch: 偽のDHCPオファー
    Switch->>PC: 偽のDHCPオファー
    PC->>Switch: DHCPリクエスト(偽サーバー宛)
    Switch->>Spoofer: DHCPリクエスト
    Spoofer->>Switch: 偽のDHCPACK
    Switch->>PC: 偽のDHCPACK

    Note over PC,Spoofer: クライアントPCは偽のDHCPサーバーからIPアドレスを受け取る


```

**_DHCP Snooping_**

```mermaid
sequenceDiagram
    participant PC as クライアントPC
    participant Switch as スイッチ (DHCPスヌーピング有効)
    participant DHCP as 正規DHCPサーバー
    participant Spoofer as スプーフィングサーバー

    PC->>Switch: DHCPディスカバリー
    Switch->>DHCP: DHCPディスカバリー
    Switch->>Spoofer: DHCPディスカバリー
    DHCP->>Switch: DHCPオファー
    Spoofer->>Switch: 偽のDHCPオファー
    Switch-)Spoofer: 偽のDHCPオファーをブロック
    Switch->>PC: DHCPオファー
    PC->>Switch: DHCPリクエスト(正規サーバー宛)
    Switch->>DHCP: DHCPリクエスト
    DHCP->>Switch: DHCPACK
    Switch->>PC: DHCPACK

    Note over PC,DHCP: クライアントPCは正規DHCPサーバーからIPアドレスを受け取る
    Note over Switch,Spoofer: 不正なDHCP応答はスイッチによってブロックされる


```

## 参考サイト

- [DHCP Snooping](https://www.infraexpert.com/study/dhcp4.htm)
- [DHCP Spoofing](https://www.infraexpert.com/study/dhcpz5.html)
