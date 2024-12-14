---
title: "Best Practices for Deploying Applications on Public or Private Subnets in Amazon ECS"
date: 2024-11-14T14:57:00
mermaid: true
weight: 7
tags:
  - AWS
  - Amazon ECS
  - Public Subnet
  - Private Subnet
  - Networking
  - NAT Gateway
  - Best Practices
description: "Amazon ECSでアプリをPublicまたはPrivate Subnetに配置する際のベストプラクティスを解説。セキュリティ、帯域幅、レイテンシを考慮した設計を紹介。"
---


ECSの[Connect Amazon ECS applications to the internet](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/networking-outbound.html)を読んで
public subnetとprivate subnetのどちらにアプリケーションを配置すべきかBestプラクティスがあったのでまとめる。

## Public subnet and internet gateway

public subnetにアプリケーションを配置し、internet gatewayを通じて「public subnet ↔ internet」双方向の通信を実現するアーキテクチャです。このアーキテクチャではアプリケーションがインターネットからアクセス可能であるため、Security Groupやファイアウォールルールの設定には特に注意を払う必要があります。

このアーキテクチャが適しているのは、以下の要件を満たすアプリケーションの場合です。

1. **Large amounts of bandwidth**（高帯域幅）
2. **Minimal latency**（低レイテンシ）

これらの要件に合致する代表的なアプリケーションには、ビデオストリーミングやゲームサービスがあります。

---

**Minimal latency**が求められる理由：  
Public subnetのリソースはインターネットに直接アクセスできるため、NAT Gatewayを介するPrivate subnetよりも通信経路が短く、レイテンシーが低くなります。特にリアルタイム性が重要なアプリケーションでは、低レイテンシによる直接アクセスが重要です。

**Large amounts of bandwidth**が求められる理由：  
NAT Gatewayを使用すると、複数のインスタンスが帯域幅を共有し、競合する可能性があります。この競合により通信の遅延やタイムアウトが発生することもあるため、Public subnetを利用して直接アクセスすることで高い帯域幅を確保し、より安定した通信が可能になります。

## Private subnet and NAT gateway

Private subnetにアプリケーションを配置し、NAT Gatewayを利用することで「private subnet -> NAT Gateway -> Internet」という一方向の通信を実現するアーキテクチャです。この構成により、インターネットからの直接アクセスが不可能となり、セキュリティが向上します。

- NAT Gatewayの配置: NAT GatewayはPublic subnetに置く必要があり、作成時から課金が発生します（時間単位の使用料金とデータ処理量に基づく料金）。
- 冗長化の推奨: 可用性を確保するため、各Availability ZoneにNAT Gatewayを配置することで、特定のゾーンが利用不可になっても外部接続が継続されるようにします。
