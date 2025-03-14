---
title: "MacでUTMを使ってWindows ARM11を簡単にインストールする方法"
date: 2024-04-12T17:00:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 8
tags:
  - Mac
  - UTM
  - Windows ARM11
  - 仮想化
  - Apple Silicon
  - インストール
  - 技術解説
description: "Apple Silicon搭載のMacでUTMを使用してWindows ARM11をインストールする手順と注意点をわかりやすく紹介します。"
---

## MacでUTMを使ってWindows ARM11をインストールする方法

この記事では、Mac（Apple Silicon搭載）環境にUTMを用いてWindows ARM11を簡単にセットアップする方法をわかりやすく解説します。

### システム環境の確認

Terminalを開き、以下のコマンドを入力するとMacのシステム情報を確認できます。

```shell
~/Documents$ system_profiler SPHardwareDataType
```

実行結果の例:

```shell
Hardware:

    Hardware Overview:

      Model Name: MacBook Pro
      Model Identifier: Mac14,7
      Model Number: Z16T0004TJ/A
      Chip: Apple M2
      Total Number of Cores: 8 (4 performance and 4 efficiency)
      Memory: 16 GB
      System Firmware Version: 11881.81.4
      OS Loader Version: 11881.81.4
```

- MacBook Pro (macOS Sonoma)
- UTM 4.5.0
- Windows ARM11 ISOイメージ（公式より取得）

### インストール手順

#### 1. UTMをダウンロード

公式サイトからUTMをダウンロードしてインストールします。

[UTM公式サイト](https://mac.getutm.app/)

#### 2. Windows ARM11 ISOイメージを準備する

Microsoft公式ページよりWindows ARM11 ISOファイルをダウンロードします。
[Arm ベース PC 用 Windows 11 のダウンロード](https://www.microsoft.com/ja-jp/software-download/windows11arm64)

#### 3. 仮想マシンの作成

UTMを起動して以下の手順で仮想マシンを作成します。

- 「新しい仮想マシンを作成」をクリック
- 「仮想化」→「Windows」を選択
- ダウンロードしたISOファイルを選択
- ハードウェア設定（RAM・CPUなど）を指定します（ストレージは最低20GB必要）。

#### 3. 仮想マシン起動時の重要な注意点

仮想マシンを起動すると以下の画面が表示されます：

```shell
Press any key to boot from CD or DVD...
```

**この画面が表示されたらすぐにEnterキー（または任意のキー）を押します。**

キー入力が遅れると、UEFI Interactive Shell（手動モード）が表示され、インストールが進まなくなりますのでご注意ください。

#### 4. Windows ARM11のインストールを進める

画面の指示に従いインストールを進めます。インストールは非常に時間がかかりますので、時間の余裕を持ちましょう。

#### 5. 初回再起動後の注意点

インストールが終了し再起動が始まるタイミングで、UTMの仮想マシンを一旦停止します。

- UTMの設定でwindowsのISOファイルをクリア（取り外し）してください。
- ISOをクリアしないと、再度インストールの最初からやり直しになります。

#### 5. 仮想マシンの再起動

ISOファイルを取り外した後、仮想マシンを再度起動します。これでWindows ARM11が正常に起動します。

### 最後に

以上の手順でMac（Apple Silicon）上にUTMを使用し、Windows ARM11のセットアップが可能です。各手順の注意事項を確認しながら進めることで、トラブルを防ぐことができます。
