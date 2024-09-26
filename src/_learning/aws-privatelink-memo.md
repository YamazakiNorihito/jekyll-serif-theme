---
title: ""
date: 2024-9-18T07:15:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - AWS
  - PrivateLink
  - VPC
  - Cloud Networking
  - Security
  - Interface Endpoints
  - Gateway Endpoints
  - AWS Architecture
---

PrivateLinkについてドキュメント読んだので自分用にメモ

PrivateLinkは、VPC間、オンプレミス環境からの接続、またはAWSサービスへのプライベート接続を提供します。これにより、パブリックインターネットを介さずに、安全にサービスにアクセスすることが可能です。

Service providers: サービスの所有者であり、そのサービスを提供する人 AWS自身、AWSパートナー、またはその他のAWSアカウントなどが該当します。
service consumers: サービスの利用者であり、エンドポイントサービスにアクセスする人やシステムのことです。

### VPCエンドポイントとエンドポイントサービスの違い

AWSのVPCには、2種類のサービスがあります：

- **エンドポイントサービス (Endpoint services)**  
  サービスプロバイダーが、サービスコンシューマに向けて提供するものです。

- **VPCエンドポイント (VPC endpoints)**  
  サービスコンシューマが、サービスプロバイダーの提供するサービスに接続するために使います。VPCエンドポイントには、次の3つの種類があります。

### VPCエンドポイントの種類

1. **インターフェースエンドポイント (Interface)**  
   エンドポイントサービスに向けてTCPトラフィックを流すためのものです。DNSを使用して、エンドポイントサービスの宛先を解決します。

2. **ゲートウェイロードバランサーエンドポイント (Gateway Load Balancer)**  
   プライベートIPアドレスを使い、レイヤー3またはレイヤー4で動作します。受信したトラフィックを複数のアベイラビリティーゾーン内のターゲットに送信し、負荷分散します。

3. **ゲートウェイエンドポイント (Gateway)**  
   Amazon S3やDynamoDBにトラフィックを流すために使います。ゲートウェイエンドポイントはAWS PrivateLinkを使用せず、ルートテーブルを介してトラフィックを送ります。

### エンドポイントネットワークインターフェース

エンドポイントネットワークインターフェースは、**リクエスターが管理**するネットワークインターフェースです。エンドポイントサービスへのトラフィックのエントリポイントとして機能し、以下の特徴があります。

- **IPv4/IPv6サポート**  
  IPv4アドレスとIPv6アドレスの両方をサポートしていますが、IPv6アドレスを持つ場合、`denyAllIgwTraffic`設定が自動的に有効になり、インターネットからのアクセスはできません。ただし、AWS内部ネットワーク内からのアクセスは可能です。

- **IPアドレスの固定**  
  一度設定されると、エンドポイントネットワークインターフェースのIPアドレスはエンドポイントのライフタイム中、変更されることはありません。

### AWS PrivateLink接続

AWS PrivateLinkは、VPCエンドポイント（サービスコンシューマ側）とエンドポイントサービス（サービスプロバイダー側）をプライベートに接続する仕組みです。VPCエンドポイントからエンドポイントサービスへのトラフィックはすべてAWSの内部ネットワークを通じて通信され、パブリックインターネットは経由しません。

- **パブリックホストゾーン**：パブリックホストゾーン内のレコードは、インターネット上でのトラフィックを制御します。
- **プライベートホストゾーン**：プライベートホストゾーン内のレコードは、特定のVPC内のみでトラフィックをルーティングします。

### スプリットホライズンDNS

スプリットホライズンDNSとは、同じドメイン名を使って、パブリックウェブサイトとプライベートなVPC内のエンドポイントサービスの両方に異なる解決結果を返す方法です。VPC内のDNSリクエストはVPCエンドポイントのプライベートIPアドレスに解決され、外部からのリクエストはパブリックエンドポイントに解決されます。この仕組みを使うことで、同じドメイン名でパブリックとプライベートのサービスを共存させることが可能です。

## 参考サイト

- [AWS PrivateLink concepts](https://docs.aws.amazon.com/vpc/latest/privatelink/concepts.html)