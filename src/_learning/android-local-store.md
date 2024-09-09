---
title: "アプリ DataStore を使用して設定をローカルに保存"
date: 2024-4-24T09:29:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
---


# [DataStore](https://developer.android.com/topic/libraries/architecture/datastore?hl=ja)

DataStore には、Preferences DataStore と Proto DataStore の 2 種類の実装があります。

- Preferences DataStore は Key-Value ペアを格納します。値は、String、Boolean、Integer などの Kotlin の基本データ型にできます。複雑なデータセットは保存されません。定義済みのスキーマは必要ありません。Preferences Datastore の主なユースケースは、ユーザー設定をデバイスに保存することです。
- Proto DataStore はカスタムデータ型を格納します。proto 定義をオブジェクト構造にマッピングする事前定義スキーマが必要です。
