---
title: "Android アプリの基礎(1)"
date: 2023-10-18T07:00:00
weight: 4
categories:
  - tech
  - android
description: "Android アプリ開発の基本的なコンポーネントやセキュリティ機能、アプリ間のデータ共有についてまとめた記事。"
tags:
  - Android
  - アプリ開発
  - Kotlin
  - セキュリティ
  - SDK
  - Androidコンポーネント
  - APK
---

Android デベロッパーの[アプリの基礎](https://developer.android.com/guide/components/fundamentals?hl=ja)をつらつらと自分なりにまとめていく。

## 開発言語

- Kotlin
- Java
- C++

## Android SDK ツール

- コードやデータやリソースファイルと一緒にAPKにコンパイルして`.apk` のアーカイブファイルで出力される

## APK（Androidパッケージ）

- １つのAPK ファイルにAndroidアプリの全てのコンテンツが含まれる
- Android端末のアプリインストールにAPKファイルを使用する

## Android のセキュリティ機能

- **セキュリティサンドボックス**: 各アプリは独自のセキュリティサンドボックス内で動作します。
- **マルチユーザーLinuxシステム**: AndroidはマルチユーザーLinuxシステムを採用しています。
- **一意のLinuxユーザーID**: 各アプリには一意のLinuxユーザーIDが割り当てられ、アクセス制御が行われます。
- **独自の仮想マシン**: 各プロセスは独自の仮想マシン（VM）上で実行され、アプリ間でコードが隔離されます。
- **プロセス管理**: アプリの`Activities`、`Services`、`Broadcast receivers`、`Content providers`コンポーネントによりプロセスが開始され、不要になるまたは他のアプリ用にメモリを回復させる必要があるときにシステムによりプロセスがシャットダウンされます。

## 最小権限の原則

- 各アプリにコンポーネントの動作に必要な分だけのアクセス権が与えられている

## アプリが他のアプリとデータを共有したり、システムのサービスにアクセスしたりするための方法

- **2つのアプリで同一の`Linux ユーザー ID`を共有した場合**:
  - この場合、アプリは同じ証明書で署名される必要があり、同じLinuxプロセスとVMを共有できます
- **ユーザーが`明示的に付与する`場合**:
  - 詳細については、[システム パーミッションの使用](https://developer.android.com/guide/topics/permissions/overview?hl=ja)をご覧ください。

## アプリを定義するコア フレームワーク コンポーネント

- Activities
- Services
- Broadcast receivers
- Content providers

## Activities

- ユーザーとやり取りするためのエントリ ポイント
- Activitiesは [Activityクラス](https://developer.android.com/reference/android/app/Activity?hl=ja)を継承して実装し、ユーザーが見る・操作することができる一つの画面（ユーザーインタフェース）を提供します。
- Activitiesは独立していて、[インテント](https://e-words.jp/w/インテント.html#:~:text=インテント%20【intent】,を指すことが多い%E3%80%82)を通じて他のアプリから開始することができます（例えば、メールアプリが許可している場合）。
- システムとアプリ間における重要なインタラクション:
  - アクティビティをホストしているプロセスを継続的に実行するために、ユーザーの現在の操作内容（画面の表示）を追跡。
  - 以前に使用されたプロセス（停止されたアクティビティ）のうち、ユーザーが再度アクセスする可能性があるものを検知し、それらの優先順位を上げてプロセスを維持。
  - アプリのプロセスがシステムによって強制終了された場合でも、システムはアクティビティの状態を保存し
