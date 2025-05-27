---
title: "実務メモ：AWS VPC Peering接続の勘所と注意点"
date: 2025-05-26T07:15:00
mermaid: true
weight: 7
tags:
  - AWS
  - VPC Peering
  - ネットワーク設計
  - セキュリティ設計
  - Transit Gateway
  - VPN接続
  - クラウドインフラ
  - ネットワークベストプラクティス
  - 実践ノウハウ
  - フルメッシュ構成
description: "実務でVPC間接続に迷ったときのための個人用メモ。Peeringの仕様、制限、コスト、設定の詰まりポイントを整理。教科書では拾えない“実際どうするか”の判断材料として残しておく。
"
---

<https://docs.aws.amazon.com/vpc/latest/peering/what-is-vpc-peering.html>

## What is VPC peering?

A VPC peeringとは、2つのVPC間で、プライベートIPv4またはIPv6アドレスを使用して通信できるようにする接続

- 特徴
  - 接続可能な範囲
    - 同一アカウント内のVPC
    - 別のAWSアカウントのVPC
    - 異なるリージョン間のVPC（inter-Region VPC peering）
  - 技術的な特性
    - ゲートウェイ・VPN・ネットワークアプライアンス不要
    - 物理ハードウェアに依存しない
    - 単一障害点（Single Point of Failure）なし
    - 帯域ボトルネックなし
  - 通信のセキュリティと経路
    - トラフィックは常にAWSのグローバルバックボーンネットワーク上を流れる
    - インターネットを経由しない
    - 通信はすべて暗号化されている
    - DDoS攻撃や一般的な脅威から保護されやすい

## Pricing for a VPC peering connection

- 無料（Free）
  - VPC peering connectionを作るだけなら無料
  - 同一アベイラビリティゾーン (AZ) 内でのデータ転送
    - たとえ異なるAWSアカウント間でも、同一AZ内なら通信コストは無料
- 課金されるケース
  - 異なるアベイラビリティゾーン (AZ) 間の通信
    - 例：東京リージョンの ap-northeast-1a と ap-northeast-1c 間
  - 異なるリージョン 間の通信（Inter-Region VPC Peering）
    - 東京リージョン ap-northeast-1 と大阪リージョン ap-northeast-3

## How VPC peering connections work

設定の流れは[公式ドキュメント](https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-basics.html)を参考にする

ドキュメントで重要そうなこと

1. VPC A ↔ VPC B が ピアリング接続されていて、かつ同じリージョンにあるとき、
   1. VPC A のセキュリティグループの設定で、「通信を許可する相手」として、VPC B 内のセキュリティグループを直接指定できる。
2. Public DNS ホスト名（例：ec2-xx-xx-xx-xx.compute.amazonaws.com）で相手を指定すると、その名前は Public IP アドレスに解決される
   1. よって、VPC ピアリング経由ではなく、インターネット経由になる可能性がある。
   2. DNS hostname resolutionを有効にすることで
      1. Public DNS ホスト名からPrivate IPアドレスに解決されVPC ピアリング経由になる。

<details markdown="1">
<summary>手動で設定してみた感じ</summary>

前提として繋げたいVPC（VPC-A, VPC-B）はすでに存在するものとします。

1. EC2 > [Peering Connections](https://ap-northeast-1.console.aws.amazon.com/vpcconsole/home?region=ap-northeast-1#PeeringConnections:) に移動
2. [Create Peering Connection]ボタンを押す
   1. 必要な項目（Requester、Accepter、VPC IDなど）を設定して作成
   2. Accepter VPC側は、Peering Connectionsページで該当リクエストの [Actions] → [Accept Request] を実行して承認
3. Route Tablesの設定
   1. VPC-A 側のルートテーブルにレコード追加
      - Destination: VPC-BのCIDR
      - Target: 作成した Peering Connection（`pcx-xxxxxxx`）を選択
   2. VPC-B 側も同様に設定
      - Destination: VPC-AのCIDR
      - Target: Peering Connection
4. 必要な設定は以上です。
   - 通信できない場合は、各EC2のSecurity Groupが相手VPCのCIDRからのトラフィックを許可しているか確認してください。

</details>

## VPC peering connection lifecycle

各ステータスは[ドキュメント読む](https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-basics.html#vpc-peering-lifecycle)

- Pending-acceptance
  - 7日間アクション待ち（7日過ぎるとExpiredになる）
- Expired
  - その後2日間表示され続ける
- Rejected
  - 原則**2日間（リクエスター）／2時間（アクセプター）**表示される
- Failed
  - **2時間（リクエスターに）**表示される
- Deleted →
  - 削除した側に2時間表示される
  - 削除していない側に2日間表示される

![VPC Peering Lifecycle](https://docs.aws.amazon.com/images/vpc/latest/peering/images/peering-lifecycle-diagram.png)

## Multiple VPC peering connections

- VPCピアリングは1対1の関係（2つのVPC間だけの接続）
- 1つのVPCに複数のピアリング接続は可能
- transit point（中継）な通信は不可
  - 例えば：
    - A ↔ B
    - A ↔ C
    - でも B ↔ C は通信できない
  - BとCの通信をしたいなら、直接BとCの間にもピアリング接続を作る必要がある

## VPC peering limitations

### Connections

1. VPC peering connection には、1VPCあたり[Default](https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-connection-quotas.html)で 50 の上限があり、最大で 125 まで引き上げ可能です。
2. VPC peering connectionは、VPCの組み合わせで１つしか作れません。
   1. 同じペア（VPC A ↔ VPC B）間には、1本まで。
3. VPC peering connectionに付与したTagは自分にしか見えない
4. peeringしているVPCのCIDRブロック（IP範囲）が[RFC 1918](http://www.faqs.org/rfcs/rfc1918.html)で定義されたプライベートIPアドレスの範囲外だったら、そのVPCのプライベートDNSホスト名（例：ip-10-0-1-10.ec2.internal）を使っても、プライベートIPアドレスに変換（名前解決）できない
   1. Enable DNS resolution supportを有効にしていれば解決できる
   2. private internets
      1. 10.0.0.0        -   10.255.255.255  (10/8 prefix)
      2. 172.16.0.0      -   172.31.255.255  (172.16/12 prefix)
      3. 192.168.0.0     -   192.168.255.255 (192.168/16 prefix)

例えば、

- Elastic Load BalancingでInternet-facingに関しては、Peering越しにアクセスはできないけど、internalならアクセスできる。

### Overlapping CIDR blocks

1. CIDRが重複してるとpeering不可。

### Edge to edge routing through a gateway or private connection

Peering越しに以下のサービスは使えない。

- Internet Gateway (IGW)
- NAT Gateway / NAT Instance
- VPN接続
- AWS Direct Connect
- Gateway Endpoint (例: Amazon S3)

### Shared VPCs and subnets

VPC 所有者のみがピアリング接続を操作（説明、作成、承認、拒否、変更、削除）できます。参加者はピアリング接続を操作できません。
