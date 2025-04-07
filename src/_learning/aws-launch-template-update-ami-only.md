---
title: "AWS Launch Templateの設定を引き継いでImageだけ変更する方法"
date: 2025-03-03T15:00:00
mermaid: false
weight: 7
tags:
  - AWS
  - EC2
  - Launch Template
  - Infrastructure
  - Automation
description: "AWSのLaunch Templateを活用し、前回の設定を引き継ぎつつ、AMI IDのみ変更して新しいバージョンを作成する方法を解説します。"
---

## はじめに

AWSではEC2インスタンスの起動設定を簡単に管理できる**Launch Template**が提供されています。特に、新しいAMI（Amazon Machine Image）を適用したい場合、既存のLaunch Templateの設定をそのまま引き継ぎつつ、**AMI IDのみ変更した新しいバージョン**を作成すると便利です。

本記事では、その方法をシンプルなBashスクリプトを用いて解説します。

## 前提条件

本スクリプトを実行するには、以下の環境が整っている必要があります。

- AWS CLI がインストールされ、適切な認証情報が設定されている
- `jq` コマンドが利用可能である（JSONデータの加工に使用）
- 変更対象となる**Launch Template ID**と新しい**AMI ID**が分かっている

## スクリプトの処理概要

以下のステップで新しいLaunch Templateバージョンを作成します。

1. **最新バージョン番号の取得**
2. **現在のLaunch Templateの設定をJSONとして取得**
3. **JSONのImageIdを新しいAMI IDに変更**
4. **新しいバージョンの作成**

## Bashスクリプト

```bash
#!/bin/bash

# AWS 設定
REGION="ap-northeast-1"
PROFILE="default"  # AWS CLIのプロファイル名（適宜変更）
VERSION_DESC="新しいAMIを適用したバージョン"

# 変更対象のLaunch Template ID
LAUNCH_TEMPLATE_ID="lt-xxxxxxxxxxxxxxxxx"
# 新しいAMI ID
NEW_IMAGE_ID="ami-xxxxxxxxxxxxxxxxx"

echo "Launch Template ID: ${LAUNCH_TEMPLATE_ID} の最新バージョンを取得中..."

# 最新バージョンの取得
LATEST_VERSION=$(aws ec2 describe-launch-templates \
  --launch-template-id "$LAUNCH_TEMPLATE_ID" \
  --query 'LaunchTemplates[0].LatestVersionNumber' \
  --output text \
  --profile "$PROFILE" \
  --region "$REGION")

if [[ -z "$LATEST_VERSION" || "$LATEST_VERSION" == "None" ]]; then
  echo "エラー: Launch Templateの最新バージョンが取得できません。"
  exit 1
fi

echo "最新バージョン番号: ${LATEST_VERSION}"

# 現在のLaunch Template Dataを取得
aws ec2 describe-launch-template-versions \
  --launch-template-id "$LAUNCH_TEMPLATE_ID" \
  --versions "$LATEST_VERSION" \
  --query 'LaunchTemplateVersions[0].LaunchTemplateData' \
  --output json \
  --profile "$PROFILE" \
  --region "$REGION" > current-template.json

# ImageIdを新しいAMI IDに更新
jq --arg newImageId "$NEW_IMAGE_ID" '.ImageId = $newImageId' current-template.json > new-template.json

# 新しいバージョンの作成
aws ec2 create-launch-template-version \
  --launch-template-id "$LAUNCH_TEMPLATE_ID" \
  --launch-template-data file://new-template.json \
  --version-description "$VERSION_DESC" \
  --profile "$PROFILE" \
  --region "$REGION"

echo "Launch Templateの新しいバージョンが作成されました。"
```

## まとめ

このスクリプトを使うことで、**既存の設定を維持しながら、新しいAMI IDを適用したLaunch Templateのバージョンを作成**できます。

### メリット

- **設定の一貫性を保つ**: 既存の設定を変更せずに、AMI IDだけを更新
- **手動設定ミスを防ぐ**: JSONファイルを直接編集することでヒューマンエラーを削減
- **自動化が容易**: スクリプト化することでCI/CDにも組み込み可能

AWS環境でLaunch Templateを活用する際に、ぜひ参考にしてみてください！
