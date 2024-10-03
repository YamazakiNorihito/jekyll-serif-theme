---
title: "AWS CLIでIAM Identity Center認証を設定する手順まとめ"
date: 2024-10-03T07:15:00
mermaid: true
weight: 7
tags:
  - AWS
  - CLI
  - IAM
  - Identity Center
---

このブログ記事は、公式ドキュメント「[Configure the AWS CLI with IAM Identity Center authentication](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)」を参考にしています。基本的には公式を参照していただきたいのですが、特にユーザー作成の部分で分かりづらい点があったため、詳細にまとめました。自分自身の理解を深め、後で見返したときに分かりやすくするために、以下のように整形・整理しました。

## 目次

- [目次](#目次)
- [1. IAM Identity Centerの設定](#1-iam-identity-centerの設定)
  - [手順 1: IAM Identity Centerを有効にする](#手順-1-iam-identity-centerを有効にする)
  - [手順 2: ユーザーを追加する](#手順-2-ユーザーを追加する)
  - [手順 3: アクセス許可を設定する](#手順-3-アクセス許可を設定する)
  - [手順 4: AWS SSO URLを提供する](#手順-4-aws-sso-urlを提供する)
- [2. AWS CLIを設定して新しいユーザーに割り当てる](#2-aws-cliを設定して新しいユーザーに割り当てる)
  - [手順 1: AWS CLIのインストール](#手順-1-aws-cliのインストール)
  - [手順 2: AWS CLIでIAM Identity Centerを設定する](#手順-2-aws-cliでiam-identity-centerを設定する)
  - [手順 3: AWSリソースにアクセス](#手順-3-awsリソースにアクセス)
- [3. まとめ](#3-まとめ)
- [4. 追加情報: SSO Start URLとSSO Regionの確認方法](#4-追加情報-sso-start-urlとsso-regionの確認方法)
  - [SSO Start URLの確認方法](#sso-start-urlの確認方法)
  - [SSO Regionの設定について](#sso-regionの設定について)

## 1. IAM Identity Centerの設定

公式ドキュメントではユーザー作成の詳細が分かりにくかったため、以下に具体的な手順を示します。

### 手順 1: IAM Identity Centerを有効にする

1. AWS管理コンソールにサインイン
   - AWSの管理コンソールにサインインします。
2. IAM Identity Centerを探す
   - 検索バーに「IAM Identity Center」と入力し、サービスを開きます。

### 手順 2: ユーザーを追加する

1. ユーザーの追加ページに移動
   - IAM Identity Centerのメニューから「ユーザー」を選択し、「ユーザーの追加」をクリックします。
2. ユーザー情報を入力
   - **プライマリ情報**
     - ユーザー名: workday_worker
     - パスワード: 「パスワードの設定手順が記載されたEメールをこのユーザーに送信します」を選択
     - Eメールアドレス: <hogehoge@example.ne.jp>
     - 名: （任意で入力）
     - 姓: （任意で入力）
     - 表示名: （任意で入力）
3. グループを選択（オプション）
   - 必要に応じて、ユーザーを特定のグループに割り当てます（例: 管理者、開発者グループなど）。

### 手順 3: アクセス許可を設定する

1. アクセス許可セットを作成
   - 「マルチアカウントのアクセス許可 > 許可セット」で新しい許可セットを作成します。
     - 例: S3DynamoDBAccessというカスタム許可セットを作成。
   - ポリシーの詳細を定義する
     - AmazonDynamoDBFullAccess
       - タイプ: AWS マネージド
       - 説明: Amazon DynamoDBへのフルアクセスを提供
     - AmazonS3FullAccess
       - タイプ: AWS マネージド
       - 説明: すべてのS3バケットへのフルアクセスを提供
2. アクセス許可の確認と割り当て
   - 「マルチアカウントのアクセス許可 > AWSアカウント」で「ユーザーまたはグループを割り当て」をクリック。
   - 「ユーザー」タブから対象のユーザーを選択し、「次へ」をクリック。
   - 「許可セット」で先ほど作成した許可セットを選択し、「次へ」をクリック。
   - 送信して割り当てを完了します。

### 手順 4: AWS SSO URLを提供する

1. サインインリンクを共有
   - ユーザー作成後、IAM Identity Centerはサインイン用のURLを生成します。
   - このリンクをユーザーに共有し、AWS環境にサインインしてもらいます。
   - ユーザーは最初のサインイン時にパスワードを設定する必要があります。

## 2. AWS CLIを設定して新しいユーザーに割り当てる

### 手順 1: AWS CLIのインストール

1. AWS CLIをインストール
   - Mac/Linuxの場合:

     ```bash
     curl "<https://awscli.amazonaws.com/AWSCLIV2.pkg>" -o "AWSCLIV2.pkg"
     sudo installer -pkg AWSCLIV2.pkg -target /
     ```

   - Windowsの場合:
     - 公式ガイドに従ってインストールします。

### 手順 2: AWS CLIでIAM Identity Centerを設定する

1. AWS CLIの設定を開始

   ```bash
   aws configure sso
   ```

2. プロンプトに従って情報を入力

   ```plaintext
   SSO session name (Recommended): my-sso-session
   SSO start URL [None]: <https://d-xxxxxxxxxx.awsapps.com/start>
   SSO region [None]: ap-northeast-1
   SSO registration scopes [sso:account:access]:
   ```

   - SSO session name: 任意のセッション名を入力（例: my-sso-session）
   - SSO start URL: IAM Identity Centerの「AWS アクセスポータルのURL」を入力
   - SSO region: IAM Identity Centerが設定されているリージョンを入力（例: ap-northeast-1）
   - SSO registration scopes: デフォルトで問題なければそのままEnterキーを押す

3. ユーザーIDとパスワードの入力
   - ブラウザが自動的に開き、ユーザーの認証情報（Eメールとパスワード）を入力します。

### 手順 3: AWSリソースにアクセス

1. アクセス確認
   - 設定が完了したら、以下のコマンドでS3バケットの一覧を確認します。

   ```bash
   aws s3 ls
   ```

   - バケットのリストが表示されれば、設定は成功です。

## 3. まとめ

1. IAM Identity Centerを有効化し、新しいユーザーを作成
   - ユーザーに必要なアクセス権限を付与します。
2. AWS CLIを設定
   - ユーザーがAWS CLIでログインし、リソースにアクセスできるように設定します。

## 4. 追加情報: SSO Start URLとSSO Regionの確認方法

公式ドキュメントではこの部分が詳細に説明されていないため、補足します。

### SSO Start URLの確認方法

1. AWS管理コンソールにサインイン
   - 管理者権限でAWS管理コンソールにサインインします。
2. IAM Identity Centerのページに移動
   - 検索バーで「IAM Identity Center」と検索し、サービスを開きます。
3. SSOの開始URLを確認
   - IAM Identity Centerのダッシュボードにある「AWS アクセスポータルのURL」を確認します。
   - URL形式:

     ```plaintext
     https://d-xxxxxxxxxx.awsapps.com/start
     ```

4. CLIプロンプトに貼り付け
   - `aws configure sso`のプロンプトで、このURLを入力します。

### SSO Regionの設定について

1. SSOリージョンの確認
   - IAM Identity Centerが設定されているリージョンを確認します。
2. リージョンを入力
   - `aws configure sso`のプロンプトで、確認したリージョンコードを入力します。
   - 例:

     ```plaintext
     SSO region [None]: ap-northeast-1
     ```
