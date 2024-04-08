---
title: "ネットワークスペシャリスト　CSMA/CD と CSMA/CA の概要と覚え方"
date: 2024-02-23T14:56:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
---

# CSMA/CD と CSMA/CA の概要と覚え方

## CSMA/CD（Collision Detection）

- **定義**: 「Carrier Sense Multiple Access with Collision Detection」の略で、データ通信ネットワークで使用されるメディアアクセス制御（MAC）方法。特にイーサネットネットワークで使用される。
- **動作原理**:
  1. キャリア感知: デバイスがデータを送信する前に、通信チャネルが使用中か確認。
  2. 多重アクセス: 複数デバイスがチャネルを監視し、空いている時にデータ送信。
  3. 衝突検出: 衝突が発生した場合、検出し再送信を試みる。
- **覚え方**: CD = 「Car Detect」。車（Car）がぶつかる（Detect）ことをイメージ。

## CSMA/CA（Collision Avoidance）

- **定義**: 「Carrier Sense Multiple Access with Collision Avoidance」の略で、無線LAN（Wi-Fi）で使用される技術。
- **動作原理**:
  1. 聞く: 他のデバイスがデータを送っているか確認。
  2. 待つ: 通信チャネルが空いているのを待つ。
  3. 話す: 空いたら、データ送信を開始する前に信号を送る。
  4. 確認する: データ送信後、受信確認を待つ。
- **覚え方**: CA = 「Careful Action」。事前に気をつけて行動することをイメージ。

## 覚えやすい方法

- **CSMA/CD**: CDプレイヤー。物理的なディスク（有線ケーブルを使うイーサネット）を連想。
- **CSMA/CA**: CAフェ。友達とのんびりとカフェで会うように、無線で通信するイメージ。
