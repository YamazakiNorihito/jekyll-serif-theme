---
title: "MacでUTMを使ってUbuntu仮想マシンを構築する方法【初心者向け完全ガイド】"
date: 2023-10-25T06:14:00
#image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: ""
linkedinurl: ""
weight: 7
tags:
  - Mac
  - Ubuntu
  - 仮想マシン
  - UTM
  - Linuxインストール
  - MacでLinux
  - 初心者向け
  - 技術解説
description: "Macユーザー向けに、UTMを使ってUbuntuの仮想マシンを構築する方法をわかりやすく解説します。ISOの取得から仮想マシンの設定、インストール後の作業まで、初心者にも安心のステップバイステップガイドです。"
---


## UT インストール

```bash
brew install --cask utm

/$ ls Applications | grep UTM
UTM.app
```

## UbuntuのISOファイル

- ARM版Ubuntuをダウンロード
  - [Ubuntu Desktop](https://ubuntu.com/download/desktop)
    - GUIが必要な場合におすすめ（初心者向け）。
  - [Ubuntu Server](https://ubuntu.com/download/server)
    - CLIベースで軽量（必要に応じて後からGUIをインストール可能）。

## UTM SetUp

 1. UTMを起動
 2. - Create a New Virtual Machine
 3. PreConfigured
    1. Linuxを選択
 4. Linuxの設定
    1. Use Apple Virtualization: OFF
    2. Boot from kernel image: チェックしない。
    3. Boot ISO Image: ダウンロードしたUbuntuのISOイメージを指定。
 5. Hardware(設定値は適当)
    1. Memory
       1. 4096MB（4GB）
    2. CPU Cores
       1. 3コア
    3. OpenGL
       1. 無効
 6. Storage
    1. 40GB

## ISOイメージをアンマウント

仮想マシンが再起動すると、再度インストーラーが起動するのでISOイメージをアンマウントする。

ISOイメージのアンマウント手順

 1. UTMの設定画面を開く
    1. 仮想マシンが停止している状態で、該当の仮想マシンを選択します。
    2. **「Edit（編集）」**ボタンをクリックします。
 2. Drives（ドライブ）の設定に移動
    1. 左側のメニューから「Drives」または「USB Drive」セクションを選択します。
    2. 現在マウントされているISOイメージ（例: ubuntu-24.04.1-live-server-arm64.iso）が表示されているはずです。
 3. ISOイメージをクリア
    1. 「Path」の右側にある「Clear」ボタンをクリックします。
    2. これによりISOイメージがアンマウントされます。
 4. 設定を保存
    1. 画面右下の「Save」ボタンをクリックして設定を保存します。
 5. 仮想マシンを再起動
    1. 設定が完了したら仮想マシンを再起動してみてください。

- 注意
  - ISOイメージがアンマウントされることで、仮想マシンはインストール済みのシステム（HDDや仮想ディスク）から起動します。
  - 再起動後、仮想マシンが正常に起動しない場合は、GRUB設定やストレージ構成を確認してください。
