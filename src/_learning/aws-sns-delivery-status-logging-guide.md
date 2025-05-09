---
title: "AWS SNS 配信ステータスログの設定手順【初心者向け完全ガイド】"
date: 2025-05-24T15:35:00
mermaid: true
weight: 7
tags:
  - AWS
  - SNS
  - エラー対処
  - デバイストークン
  - GoLang
  - モバイル通知
description: "AWS SNS の配信ステータスログを CloudWatch に記録する設定手順を、初心者向けにわかりやすく解説します。成功・失敗ログの記録、IAM ロールの設定方法、実際のログ確認方法まで網羅しています。"
---



# AWS SNS 配信ステータスログの設定手順（初心者向け完全ガイド）

公式ドキュメントに書かれている[Configuring message delivery status attributes using the AWS Management Console](https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html)を事細かにまとめる。 AWSのコンソール画面を使って設定します。

---

## 🔰 前提条件

この手順を実行する前に、以下の準備が整っている必要があります：

* AWS アカウントにログインできる
* SNS のプラットフォームアプリケーション（例：FCM用）が作成済みである
* IAM ロール作成などの操作権限がある（"AdministratorAccess" 権限があればOK）

---

## ✅ 手順1：SNS コンソールへアクセスし、対象アプリを選ぶ

1. Sign in to the [Amazon SNS console](https://console.aws.amazon.com/sns/home).
3. 左のメニューから「**Mobile**」＞「**Push notifications**」をクリックします。
4. 表示された「**Platform applications**（プラットフォームアプリケーション）」の一覧から、設定対象のアプリをクリックします。

---

## ✅ 手順2：Delivery Status Logging タブを開く

1. 選択したPlatform applicationsの詳細画面が開いたら、右上のEditボタンをクリックします。
2. 「Delivery status logging - optional Info」のアコーディオンを開きます。
3. まだ設定されていない場合、"Success sample rate" や "IAM role for successful deliveries" や "IAM role for failed deliveries" の欄は空欄です。

---

## ✅ 手順3：CloudWatch Logs に出力するための IAM ロールを作成

1. 「**Create new roles**」ボタンをクリックします。
2. IAM ロール作成画面が表示されます。
3. デフォルトのロール名（`SNSSuccessFeedback`, `SNSFailureFeedback`）のままで OK です。
4. IAM ロールに割り当てられるポリシーは以下のようになります：

### SNSSuccessFeedback

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:PutMetricFilter",
                "logs:PutRetentionPolicy"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

### SNSFailureFeedback

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:PutMetricFilter",
                "logs:PutRetentionPolicy"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

5. 最後に画面右下の「**Create Roles**」ボタンをクリックしてロールを作成します。
6. これが完了するとPlatform applicationsのEdit画面に戻り"IAM role for successful deliveries" や "IAM role for failed deliveries"は作成したIAMのARNが設定されているはずです。
   1. うまく反映されていない場合は、IAMからARNをコピーして手動で設定してください。その際は「Use existing service role」のラジオボタンを選択してください。

---

## ✅ 手順4：成功ログのサンプリング設定

1. SNS の設定画面に戻ると、IAM ロールが選択された状態になっているはずです。
2. 「**Success sample rate**」という項目に `100` と入力します（これで**すべての成功メッセージ**がログに記録されます）。
3. 画面右下の「**Save changes**」をクリックして保存します。

---

## ✅ 手順5：CloudWatch Logs でログを確認する

1. AWS マネジメントコンソールのサービス検索で「CloudWatch」と検索し、CloudWatch を開きます。
2. 左のメニューから「**ロググループ**」をクリックします。
3. SNS プラットフォームアプリ用のロググループ（例：`sns/{region}/{accountid}/app/{PlatformType}/{Platform applications Name}`）を探してクリックします。
4. 一覧の中に「**ログストリーム**」が表示されているので、最新のものをクリックします。
5. ログイベントが JSON 形式で表示されます。

---

## ✅ 実際のログ例と意味

```json
{
  "notification": {
    "messageMD5Sum": "...",
    "messageId": "...",
    "timestamp": "2025-05-08 01:36:08.085"
  },
  "delivery": {
    "deliveryId": "...",
    "destination": "...",
    "providerResponse": "{\"name\": \"projects/...\"}",
    "dwellTimeMs": 89,
    "token": "...",
    "statusCode": 200
  },
  "status": "SUCCESS"
}
```

| 項目名                | 意味                       |
| ------------------ | ------------------------ |
| `status`           | 成功（SUCCESS）か失敗（FAILURE）か |
| `statusCode`       | HTTP レスポンスコード（200 = 成功）  |
| `dwellTimeMs`      | 配信にかかった時間（ミリ秒）           |
| `destination`      | 送信先エンドポイント（ARN）          |
| `providerResponse` | Firebase などの応答内容         |
