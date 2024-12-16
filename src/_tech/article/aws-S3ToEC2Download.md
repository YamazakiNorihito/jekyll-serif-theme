---
title: "AWS S3からEC2インスタンスへのファイルダウンロードのやり方"
date: 2023-10-18T07:00:00
weight: 4
categories:
  - aws
  - cloud-service
description: "AWS S3からEC2インスタンスにファイルをダウンロードする方法をIAMロール設定からCloudFormationまでの手順を解説します。"
tags:
  - AWS
  - EC2
  - S3
  - ファイルダウンロード
  - IAMロール
  - CloudFormation
  - 自動化
---

## AWS S3からEC2インスタンスへのファイルダウンロードのやり方

このガイドでは、AWS S3バケットからEC2インスタンスにファイルをダウンロードする手順を説明します。

#### 1. IAMロールの作成

- **目的**: EC2インスタンスがS3バケットにアクセスするための権限を設定します。
- **手順**:
  1. AWS管理コンソールにログインします。
  2. IAMコンソールを開き、「ロール」セクションへ移動します。
  3. 「ロールの作成」をクリックし、EC2をサービスとして選択します。
  4. 適切なポリシー（例: AmazonS3ReadOnlyAccess）を添付します。
- **設定内容**:

許可ポリシー:AmazonS3ReadOnlyAccess

```json
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "s3:Get*",
                  "s3:List*",
                  "s3:Describe*",
                  "s3-object-lambda:Get*",
                  "s3-object-lambda:List*"
              ],
              "Resource": "*"
          }
      ]
  }
```

信頼ポリシー

```json
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
```

#### 2. EC2インスタンス起動時のUserDataの実行

- **目的**: EC2インスタンス起動時に自動でファイルダウンロードスクリプトを実行します。
- **実行方法**:
  - EC2インスタンスを起動する際、UserDataセクションにダウンロードスクリプトを追加します。
- **設定内容**:

```bash
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/cloud-config; charset="us-ascii"

##cloud-config
cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"

##!/bin/bash
mkdir -p /{任意のディレクトリ}
cd /{任意のディレクトリ}
aws s3 cp s3://{S3bucket}/{任意のファイル}.json /{任意の}/

aws s3 cp s3://{S3bucket}/{任意の}.json /{任意のディレクトリ}/
--//--
```

※ちなみにCopyしたファイルの権限についてみてみた

```bash
[ec2-user@ip-{ip-address} my]$ whoami
ec2-user
[ec2-user@ip-{ip-address} my]$ ls -l
total 4
-rw-r--r--. 1 root root 2379 Feb  9 03:32 test.json
```

ファイルの所有者はroot です。読み取り権限は、他のユーザーにあるみたいです。

#### 3. ログの確認方法

- **目的**: スクリプトの実行結果を確認します。
- **手順**:
  1. EC2インスタンスにSSH接続します。
  2. `/var/log/cloud-init-output.log` ファイルを確認します。
- **実行内容**:

```bash
cat /var/log/cloud-init-output.log
```

#### 4. CloudFormationを使用した自動化

- **目的**: プロセスを自動化し、エラーの可能性を減らします。
- **方法**: CloudFormationテンプレートを使用して、上記手順を自動化します。
- **設定内容**:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: EC2 instance with custom UserData.
Metadata:
  AWS::Region: ap-northeast-1
Resources:
  S3ToEC2DownloadCloudformation:
    Type: AWS::EC2::Instance
    Metadata:
      AWS::CloudFormation::Init:
        config:
          commands:
            01_create_dir:
              command: "mkdir -p /{任意のディレクトリ}"
            02_copy_file:
              command: "aws s3 cp s3://{任意のファイル名}/{任意のファイル}.json /{任意のディレクトリ}/{任意のファイル}.json"
    Properties:
      InstanceType: t2.micro
      ImageId: ami-0b5c74e235ed808b9  ## 適切なAMI IDに置き換えてください。
      KeyName: workdayKeyPeir2
      IamInstanceProfile: "S3ToEC2DownloadRole2"
      SecurityGroupIds: 
        - sg-08054815e2b4cc74c  ## 既存のセキュリティグループID
      Tags:
        - Key: Name
          Value: s3ec2testioc
      UserData:
        Fn::Base64: !Sub |
          MIME-Version: 1.0
          Content-Type: multipart/mixed; boundary="//"

          --//
          Content-Type: text/cloud-config; charset="us-ascii"

          ##cloud-config
          cloud_final_modules:
          - [scripts-user, always]

          --//
          Content-Type: text/x-shellscript; charset="us-ascii"

          ##!/bin/bash
          ## Install the files and packages from the metadata
          ## https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cfn-init.html
          /opt/aws/bin/  -v --stack ${AWS::StackName} --resource S3ToEC2DownloadCloudformation --region ${AWS::Region}
          --//--
```

※1. "2. インスタンス起動毎UserDataを実行する"の内容をCloudFormationテンプレートに書くとEC 2インスタンスが再構築されます。
※2. CloudFormationテンプレートメタデータを手動実行するときのコマンド（SSHでEC 2インスタンスへ接続して下さい。）

```bash
/opt/aws/bin/cfn-init -v --stack S3ToEC2DownloadCloudformation --resource S3ToEC2DownloadCloudformation --region {リージョン}
```

#### セキュリティ上の注意点

- 必要最低限の権限をIAMロールに付与し、プリンシパルに対するアクセスを制限してください。
- S3バケットの公開設定を確認し、不要な公開アクセスがないようにします。

#### トラブルシューティング

- **一般的なエラー**:
  - IAMロールの権限不足
  - スクリプトの実行エラー
- **解決策**:
  - IAMポリシーを確認し、必要な権限が含まれているか再確認してください。
  - `/var/log/cloud-init-output.log` をチェックし、スクリプトのエラーメッセージを確認します。

#### 参考サイト

- [EC2用にIAMロールを作ったのに、EC2へ割り当てられない！](https://dev.classmethod.jp/articles/how-to-create-iam-instance-profile-using-amc/)
- [Amazon EC2 Linux インスタンスを再起動するたびに、ユーザーデータを利用してスクリプトを自動的に実行するにはどうすればよいですか?](https://repost.aws/ja/knowledge-center/execute-user-data-ec2)
- [スタックのリソースの更新動作](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-update-behaviors.html)
  - 詳しくは調べてないけど、EC 2のリソースで置換が必要なプロパティを追加または削除削除するとEC 2インスタンスを再構築（停止→削除→新しくインスタンス作成）するみたい
- [cfn-init](https://docs.aws.amazon.com/ja_jp/AWSCloudFormation/latest/UserGuide/cfn-init.html)
