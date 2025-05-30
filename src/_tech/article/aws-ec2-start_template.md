---
title: "AWS EC2 Start Template"
date: 2023-10-18T07:00:00
weight: 4
categories:
  - aws
  - cloud-service
description: "AWS EC2の起動テンプレートを使用して、インスタンス起動時の設定情報を効率的に管理する方法を解説。"
tags:
  - AWS
  - EC2
  - クラウドサービス
  - 起動テンプレート
  - インスタンス管理
  - オートメーション
  - インフラストラクチャ
---

起動テンプレートとは、EC2インスタンス起動時に必要なAWSリソースの設定情報を予め定義するためのテンプレートです。
例えば

1. インスタンスタイプ
2. AMI (Amazon Machine Image)
3. キーペア
4. セキュリティグループ
5. サブネットとVPC
6. IAMロール
7. EBS
8. Elastic IPアドレス
9. などなど

起動テンプレートはバージョン管理が可能であり、インスタンス起動時に使用するバージョンを選択することができます。

起動テンプレートの利用により、毎回の起動で同じAWSリソース設定を指定する必要がなくなるため、
効率的にインスタンスを展開することが可能になります。
ただし、インスタンス内部のソフトウェアやアプリケーションの設定は、
起動テンプレートではなく、ユーザーデータスクリプトやその他の自動化ツールを通じて行う必要があります。

## 起動テンプレートの制限

- クォータ
  - 1つのリージョンあたり最大5,000の起動テンプレートが可能。
  - 1つの起動テンプレートあたり最大10,000のバージョンが可能。
- パラメータ
  - オプション
    - 起動テンプレートのパラメータは任意。
    - 必要なすべてのパラメータをテンプレートに含める必要がある。
  - 未検証
    - 起動テンプレート作成時にパラメータは完全には検証されない。
    - 誤った値やサポートされないパラメータの組み合わせはインスタンスの起動に失敗する。
- タグ
  - 起動テンプレートにはタグを付けることができるが、バージョンにはタグ付け不可。
- 変更不可能
  - 起動テンプレートは変更できない。変更するには新しいバージョンを作成する必要がある。
- バージョン番号
  - バージョン番号は作成された順に付けられる。
  - ユーザーがバージョン番号を自分で指定することはできない。

## 参考サイト

- [起動テンプレートからのインスタンスの起動](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/ec2-launch-templates.html)
