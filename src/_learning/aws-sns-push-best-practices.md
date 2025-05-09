---
title: "Amazon SNS モバイルプッシュ通知設定とトラブル対処メモ"
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
description: "仕事で必要になったため読んだ Amazon SNS のモバイルプッシュ通知関連ドキュメントの要点まとめ。通知フロー、エンドポイント管理、エラー対応などを実装例や推奨事項とともに整理。"
---

<https://docs.aws.amazon.com/sns/latest/dg/sns-mobile-application-as-subscriber.html>

仕事上読む必要が出てきたので、せっかくなので理解したことはまとめていく。

## [Sending mobile push notifications](https://docs.aws.amazon.com/sns/latest/dg/sns-mobile-application-as-subscriber.html)

Amazon SNSを使って、mobile devices および desktops に通知を送ることができる。  
以下のいずれかのサポートされているプッシュ通知サービスと連携する：

- Amazon Device Messaging (ADM)
- Apple Push Notification Service (APNs) for both iOS and Mac OS X
- Baidu Cloud Push (Baidu)
- Firebase Cloud Messaging (FCM)
- Microsoft Push Notification Service for Windows Phone (MPNS)
- Windows Push Notification Services (WNS)

**Direct Push 通知の流れ**

```txt
[1] アプリと端末が Push 通知サービスに登録
     ↓
[2] Push通知サービス（例: FCM, APNs）から Device Token を取得
     ↓
[3] Device Token を使って SNS に Mobile Endpoint を作成
     ↓
[4] SNS を使ってそのmobile endpointに Push 通知を送信
```

※ SNS が通知を送れるように、事前に Push通知サービスの `credentials`（認証情報）を  
Amazon SNS に登録しておく必要がある（あなたの代わりに SNS が通知するため）。

**Topic を使った Push 通知の流れ**

```txt
[1] アプリと端末が Push 通知サービスに登録
     ↓
[2] Push通知サービスから Device Token を取得
     ↓
[3] Device Token を使って SNS に Mobile Endpoint を作成
     ↓
[4] Mobile Endpoint を SNS Topic に subscribe（購読）させる
     ↓
[5] SNS Topic にメッセージを publish（発行）
     ↓
[6] SNS が、トピックに登録されたすべてのmobile endpointに Push 通知を送信
```

## [Setting up a mobile app](https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send.html)

### [Prerequisites](https://docs.aws.amazon.com/sns/latest/dg/sns-prerequisites-for-mobile-push-notifications.html)

Pushメッセージするために最低限事前に以下のもが必要

1. Push通知サービスのcredentials
2. デバイスのdevice tokenまたはregistration ID
3. Amazon SNSでmobile endpointの設定
4. Push通知サービスに登録＆設定されたモバイルアプリ

### [Creating a platform application](https://docs.aws.amazon.com/sns/latest/dg/mobile-push-send-register.html)

endpointを作成するためにまずはAmazon SNS platform applicationを作成する感じ

この部分は特に複雑ではないので、ドキュメントに従って作成すればOK。

### [Setting up a platform endpoint](https://docs.aws.amazon.com/sns/latest/dg/mobile-platform-endpoint.html)

#### device token とは？

- device token は、Push Notification Service（例：APNsやFCM）に登録されたモバイルデバイスを一意に識別するための識別子。
  - アプリがPush Notification Serviceに登録されると、そのアプリとデバイスに特化した device token が生成される。

#### Amazon SNS と device token の関係

- Amazon SNS は、この device token を使って、対応する platform application に紐づく platform endpoint を作成する。
- 作成された endpoint を通じて、Amazon SNS は Push Notification Service を介してモバイルデバイスにプッシュ通知を送信する。

#### CreatePlatformEndpoint アクションについて

- `CreatePlatformEndpoint` は endpoint を作成するための API であり、device token をパラメータとして受け取り、対応する Amazon Resource Name (ARN) を返す。
- この ARN に対して Push Message を送信することで、対象のデバイスに通知を届けることができる。

##### 振る舞い

1. device token に対する endpoint が既に存在する場合、endpoint を新たに作成せず、既存の ARN を返す。
2. 同じ device token に対して endpoint が存在するが、CustomUserData や属性の設定がリクエストと異なる場合、endpoint は作成されず、例外がスローされる。
3. device token に対する endpoint が存在しない場合、新しく endpoint を作成し、その ARN を返す。

##### 使用時の注意点

- 毎回無条件で `CreatePlatformEndpoint` を呼び出すのは推奨されない。

理由：

- トークンが変わるたびに新しい endpoint ARN が生成され、SNS 内に無効または重複した endpoint が増える。
- 古い endpoint が SNS 内に残存し、通知送信に失敗する原因となる可能性がある。
- endpoint の増加により SNS 側での管理が煩雑になり、パフォーマンスやコストに悪影響を及ぼす可能性がある。

##### 推奨される対応

- アプリとデバイスに対応するプラットフォーム・エンドポイントがあること
- プラットフォーム・エンドポイント内のデバイス・トークンが最新の有効なデバイス・トークンであること
- プラットフォーム・エンドポイントが有効で、使用可能であること。

疑似コード

```txt
retrieve the latest device token from the mobile operating system
if (the platform endpoint ARN is not stored)
  # this is a first-time registration
  call create platform endpoint
  store the returned platform endpoint ARN
endif

call get endpoint attributes on the platform endpoint ARN 

if (while getting the attributes a not-found exception is thrown)
  # the platform endpoint was deleted 
  call create platform endpoint with the latest device token
  store the returned platform endpoint ARN
else 
  if (the device token in the endpoint does not match the latest one) or 
      (GetEndpointAttributes shows the endpoint as disabled)
    call set endpoint attributes to set the latest device token and then enable the platform endpoint
  endif
endif

```

### Troubleshooting

**FCM**

- Amazon SNS は古い DeviceToken を新しい DeviceToken に置き換えてくれます。
  - ただし、それは FCM に依存しています。
  - FCM に古い DeviceToken と新しい DeviceToken のマッピング情報が残っている場合のみ、Amazon SNS は自動で更新できます。
    - FCM にそのマッピング情報が残っていない場合、Amazon SNS 側の DeviceToken は更新されず、該当のプラットフォームエンドポイントは自動的に無効化（Disabled）されます。
- 同じ device token を使って、同じ platform application 内に複数の platform endpoints を作成することが可能
- 同じ device token を使って何度も新しい platform endpoint を作ると、SNS に制限（クォータ）があって、やがてエラーになる
  - error message: "This endpoint is already registered with a different token."

### Re-enabling a platform endpoint associated with an invalid device token

- 無効なTokenを持つ無効なEndpointは、再有効化してもすぐにまた無効になる
- まず有効なDeviceTokenに更新しないと意味がない
- その上でEndpointを有効（Enabled: true）にすることで、配信が再開される

### [FCM endpoint management](https://docs.aws.amazon.com/sns/latest/dg/sns-fcm-endpoint-management.html)

device tokenの管理方法について説明している。

- 推奨される管理方針
  - すべての **device token**、対応する **Amazon SNS endpoint ARN**、および **更新日時（timestamp）** をアプリケーションサーバーまたは永続ストレージに保存する。
  - **古くなった device token**（使用されなくなったもの）は、  対応する **SNS endpoint ARN** ごと削除する。
    - ※ただし、そのトークンが将来的にも使われる可能性がないことが前提。
  - **新しい device token が発行された場合（アプリの再インストール、端末変更など）** は、
    - 可能な限り早く対応する SNS endpoint を **作成または更新** する。
  - すでに同じデバイス用の **SNS endpoint ARN** が存在する場合は、
    - **新規作成せずに、既存 endpoint の token を更新して再利用する**。

実装イメージは`推奨される対応`に書いてある疑似コードを参照するか[公式ドキュメント](https://docs.aws.amazon.com/sns/latest/dg/sns-fcm-endpoint-management.html#sns-device-token-pseudo-code)を見てほしい

#### Detecting invalid tokens

SNS->FCMにMessageを送信するときに、不正なFCMからのError Codeは下記のサイトを参照すると良い

Firebase公式ドキュメント:[rest/v1/ErrorCode](https://firebase.google.com/docs/reference/fcm/rest/v1/ErrorCode)

INVALID_ARGUMENTに関しては、デバイストークンまたはメッセージペイロードが無効なので、ペイロードが正しいか確認し問題なければ
デバイストークンが最新であるかを確認を確認する必要がある。

#### Removing stale tokens

stale token（無効なトークン）を持つエンドポイントには対応が必要。

メッセージ配信に失敗したトークンは、SNSによって自動的に無効化（`EndpointDisabled`）される。  
無効なエンドポイントにメッセージを送信すると、以下のエラーが返る：

- **イベント名**：`EventDeliveryFailure`  
- **FailureType**：`EndpointDisabled`  
- **FailureMessage**：`Endpoint is disabled`

#### 対処方法

1. `SetEndpointAttributes` を使ってトークンを更新し、Endpointを有効化する  
2. `DeleteEndpoint` を使って該当Endpointを削除する

### [Using Amazon SNS for mobile push notifications](https://docs.aws.amazon.com/sns/latest/dg/mobile-push-notifications.html)

send mobile push notificationsの方法は２つある

1. Publishing to a topic
2. Direct Amazon SNS mobile device messaging

設定方法はドキュメント読む

#### [Publishing Amazon SNS notifications with platform-specific payloads](https://docs.aws.amazon.com/sns/latest/dg/sns-send-custom-platform-specific-payloads-mobile-devices.html)

FCMを例にpayloadsはこんな感じ

```txt
{
"GCM": "{\"fcmV1Message\": {\"message\": {\"notification\": {\"title\": \"Hello\", \"body\": \"This is a test.\"}, \"data\": {\"dataKey\": \"example\"}}}}"
}
```

message以下の設定方法はFCMの[公式ドキュメント](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages)を参照

SNSを使ったFCMのFCM v1 payloadで送りたい場合のStructはこちらを[参照](https://docs.aws.amazon.com/sns/latest/dg/sns-fcm-v1-payloads.html#sending-messages-using-v1-payload)

### [Amazon SNS mobile app attributes](https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html)

Amazon SNSは、モバイル端末へのプッシュ通知の配信ステータスをCloudWatch Logsに記録できる。
これにより以下が可能になる：

- SNSからプッシュ通知サービスへの配信状況の把握
- プッシュ通知サービスからSNSへの応答の確認
- パブリッシュから送信直前までの滞留時間（dwell time）の計測

設定は、AWSコンソール、SDK、またはAPIで行える。

GUIを使った手順は”"AWS SNS 配信ステータスログの設定手順【初心者向け完全ガイド】"”のページを参照

### Mobile app events

platform endpointに対して作成、更新、削除、通知失敗の発生をEventとしてキャッチできます。

これらを**application events**と呼びます。

| Attribute name         | Notification trigger |
|------------------------|----------------------|
| EventEndpointCreated   | 新しいendpointが追加されたとき |
| EventEndpointDeleted   | endpointが削除されたとき       |
| EventEndpointUpdated   | endpointが変更されたとき       |
| EventDeliveryFailure   | SNS が通知を送ったが、相手（スマホ端末）に永続的に届かないと判断されたときに発生 |

---

### Sending mobile push notifications

application eventsを受け取って処理するには、**SNSのTopic機能**を使います。

application eventsはSNS Topicに流れ、そのTopicをSubscribeしている以下のようなエンドポイントで処理できます：

- Lambda関数（自動的にコード実行）
- SQS（メッセージキューイング）
- HTTP/HTTPSエンドポイント（外部通知）

## Mobile push API actions

必要な時に[公式ドキュメント](https://docs.aws.amazon.com/sns/latest/dg/mobile-push-api.html)を読む

## Common Amazon SNS mobile push API errors

必要な時に[公式ドキュメント](https://docs.aws.amazon.com/sns/latest/dg/mobile-push-api-error.html)を読む

## [Mobile push TTL](https://docs.aws.amazon.com/sns/latest/dg/sns-ttl.html)

**Firebase Cloud Messaging (FCM)** にフォーカスします。
※他のプラットフォームについては [公式ドキュメント](https://docs.aws.amazon.com/sns/latest/dg/sns-ttl.html#sns-ttl-msg-attrib) を参照してください。

#### TTLとは？

TTLとは、「この通知を **何秒以内に配信できなければ破棄してよいか**」という期限を示す属性です。
この値を超えても通知が配信されなかった場合、そのメッセージは送信されず破棄されます。

---

#### FCMでのTTL設定方法

AWS CLI を使って、TTL を `AWS.SNS.MOBILE.FCM.TTL` 属性で指定します。

```bash
$ aws sns publish \
  --region ap-northeast-1 \
  --profile dev-medcom.ne.jp \
  --target-arn "arn:aws:sns:ap-northeast-1:{account_id}:endpoint/GCM/{platform name}/{endpoint}" \
  --message-structure json \
  --message '{
    "GCM": "{\"notification\":{\"title\":\"Test Notification\",\"body\":\"This is a test\"}, \"priority\":\"high\"}"
  }' \
  --message-attributes '{"AWS.SNS.MOBILE.FCM.TTL":{"DataType":"String","StringValue":"3600"}}'

{
    "MessageId": "646c58e7-fef5-5b5f-aaa0-38709e553d82"
}
```

上記では TTL を **3600秒（1時間）** に設定しています。

---

#### CloudWatch Logs の例

```json
{
    "notification": {
        "messageId": "646c58e7-fef5-5b5f-aaa0-38709e553d82",
        "timestamp": "2025-05-09 01:46:08.963"
    },
    "delivery": {
        "deliveryId": "1a4d56c3-f582-5ba9-9200-3654952283bd",
        "destination": "arn:aws:sns:ap-northeast-1:{account_id}:endpoint/GCM/{platform name}/{endpoint}",
        "providerResponse": "{\n  \"name\": \"projects/{fcm projectname}/messages/{なんかの値}\"\n}\n",
        "dwellTimeMs": 78,
        "token": "{device token}",
        "statusCode": 200
    },
    "status": "SUCCESS"
}
```

ここでの `dwellTimeMs` は、**Amazon SNS 内部で処理された時間（ミリ秒）** を示しています。

---

#### 配信フローとTTLの関係

```
[送信元] →     [Amazon SNS]  →    [通知サービス（FCMなど）] → [ユーザーデバイス]
                   △                      △  
                   ｜                     ｜  
           ←-- dwell time --→    ←-    残りTTL時間     -→  
```

TTLは以下のように分解されます：

1. **SNS内の処理時間（dwell time）**
2. **通知サービスから端末までの残りTTL時間**

Amazon SNS は TTL から dwell time を差し引いた値を FCM に渡します。
この差し引き後のTTLが **0以下の場合、通知は破棄** されます。

---

#### 例

- 指定TTL：360秒
- SNSのdwell time：100秒
- → FCMへ渡るTTL：260秒
- → 260秒以内に通知が届かなければ破棄される

## [Amazon SNS mobile application supported Regions](https://docs.aws.amazon.com/sns/latest/dg/sns-mobile-push-supported-regions.html)

必要な時に[公式ドキュメント](https://docs.aws.amazon.com/sns/latest/dg/sns-mobile-push-supported-regions.html)を読む

in japanはサポートされている。

- Asia Pacific (Tokyo)
- Asia Pacific (Osaka)

## [Best practices for mobile push notifications](https://docs.aws.amazon.com/sns/latest/dg/mobile-push-notifications-best-practices.html)

1. Endpoint management
   1. [pseudo code](https://docs.aws.amazon.com/sns/latest/dg/mobile-platform-endpoint.html#mobile-platform-endpoint-pseudo-code)に従って、デバイスごとに適切な Endpoint を管理するべき
      1. 配信トラブルの主な原因には以下があります：
         1. アプリの再インストールなどにより device token が変更される
         2. 特定の iOS バージョンで 証明書が更新 される
      2. CreatePlatformEndpoint API は冪等であるため、通常は同じ device token に対して同じ Endpoint ARN が返されます。
         1. ただし以下のようなケースでは、同一デバイスに対して複数の Endpoint が作成される可能性があります：※best_practices_1
            1. 無効な token を使用している場合
            2. Endpoint 自体が無効（例：プロダクションとサンドボックス環境の不一致）
2. Delivery status logging
   1. Amazon SNS platform applicationのloggingを有効にするべき
      1. ログには、各プッシュプラットフォームサービス（APNs, FCMなど）から返されるレスポンスコードが記録されるため、配信失敗の原因を特定するのに役立ちます。
      2. 成功・失敗などの配信ステータスは **CloudWatch Logs** を通じて確認できます。
         1. Blog:[How do I access Amazon SNS topic delivery logs for push notifications?](https://docs.aws.amazon.com/sns/latest/dg/mobile-push-notifications-best-practices.html)
3. Event notifications
   1. Endpointの管理はEvent drivenが推奨される。
      1. SNS Topic を Subscriber（例：Lambda function）として設定しendpointのEvent `creation`,`deletion`,`updates`,`delivery failures`を適切に処理する。
         1. 例えば、endpointが無効になったらそのEndpointを削除するlambdaとか

<details markdown="1">
<summary>best_practices_1</summary>

## Endpoint が重複・無効になる代表的なケース

### ● 無効な token を使用している場合

- ユーザーがアプリをアンインストールすると、以前の `device token` は無効になる
- しかし、SNS 側ではその token に紐づいた Endpoint ARN が残り続ける
- 同じデバイスでアプリを再インストールすると、新しい token が発行される
- `CreatePlatformEndpoint` は冪等ではあるが、token が変わることで別の Endpoint が作成される

✅ **結果**：同一デバイスに複数の Endpoint ARN が存在  
⚠️ **問題**：無効な Endpoint に通知を送っても失敗し、リソースが無駄になる

---

### ● Endpoint 自体が無効（例：プロダクションとサンドボックス環境の不一致）

- iOS では APNs に **サンドボックス** と **プロダクション** の2種類の環境がある
- サンドボックスで発行された `device token` を、プロダクション証明書で使うと失敗する
- その結果、SNS 上の Endpoint は "Disabled" 状態になる

✅ **結果**：SNS には Endpoint が存在しても、実際には通知が届かない  
⚠️ **問題**：`CreatePlatformEndpoint` を再実行しても、別の Endpoint が作成される可能性がある

</details>
