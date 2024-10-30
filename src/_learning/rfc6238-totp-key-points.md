---
title: "RFC 6238 TOTP の主要なところを読んでみた。"
date: 2024-10-29T10:34:00
##image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: "Graphic Designer"
linkedinurl: ""
weight: 7
tags:
  - TOTP
  - HMAC
  - OTP
  - セキュリティ
  - 認証
  - RFC 6238
  - ワンタイムパスワード
description: "RFC 6238で定義されたTOTPの主要な仕組みとアルゴリズム要件についてのポイントを整理。"
---

RFC 6238 - TOTP: Time-Based One-Time Password Algorithmの主要なところを読んでみた。

## [3.  Algorithm Requirements](https://datatracker.ietf.org/doc/html/rfc6238#section-3)

1. 現在のUnix時間が必要: 認証者と検証者は、OTP生成のために現在のUnix時間を知っている必要があります。
2. shared secret: 認証者と検証者は、同じ秘密情報またはその変換情報を共有する必要があります。
3. HOTPの利用: HOTPアルゴリズムが基盤として使われなければなりません。
4. 同じタイムステップの使用: 認証者と検証者は同じ時間間隔（タイムステップ）を使用する必要があります。
5. 個別の秘密鍵: 各認証者には一意の秘密鍵が必要です。
6. ランダム生成の鍵: 鍵はランダムに生成するか、鍵派生アルゴリズムを用いるべきです。
7. 鍵の保護: 鍵は改ざん防止デバイスに保管され、不正アクセスから保護されるべきです。

## [4. TOTP Algorithm](https://datatracker.ietf.org/doc/html/rfc6238#section-4)

TOTPアルゴリズムは、HOTPアルゴリズムの応用で、**カウンターの代わりに時間を利用して**ワンタイムパスワード（OTP）を生成します。

### 4.1. Notations

- **X**: タイムステップの長さ（秒）。通常、30秒ごとに新しいOTPが生成されるように設定されます。
- **T0**: カウントの開始点（Unixエポック: 1970年1月1日 0:00 UTC）。

XとT0は**システムパラメータ**として設定されます。

### 4.2. Description

TOTPは以下のように定義されます。

```math
TOTP = HOTP(K, T)
```

ここで、`T` はintegerで、**初期カウンター時間（T0）と現在のUnix時間の間の時間ステップの数**を示します。2038年以降のサポートには、32ビットから64ビットに拡張する必要があります。

#### Tの計算方法

```math
T = \frac{{\text{{Current Unix time}} - T0}}{{X}}
```

この式は、`Current Unix time`（現在のUnix時間）から`T0`（初期時間）を引き、X（タイムステップの秒数）で割った結果を表します。計算には切り捨て（floor）関数が使用されます。

#### 例

- **例1**: Unix時間が59秒の場合

    ```math
    T = \frac{{59 - 0}}{{30}} = 1
    ```

- **例2**: Unix時間が60秒の場合

    ```math
    T = \frac{{60 - 0}}{{30}} = 2
    ```

このように、Unix時間がタイムステップXの倍数に達するごとに、Tの値が1ずつ増加します。

### プロビジョニングについて

XとT0の値は**プロビジョニング時に設定され、認証者（prover）と検証者（verifier）間で共有されます**。プロビジョニングの詳細は[[RFC6030](https://datatracker.ietf.org/doc/html/rfc6030)]をご参照ください。

## [5. Security Considerations](https://datatracker.ietf.org/doc/html/rfc6238#section-5)

### 5.1.  General

HOTPの標準的なセキュリティ対策を踏襲

### 5.2. Validation and Time-Step Size

- 同じタイムステップ内で生成されたOTPは同一になります。
  - 検証システムは一般的に、OTPの受信時刻を使用してOTPを比較します。
  - 受け入れ可能なOTP伝送遅延ウィンドウに対するポリシーを設定する必要があります。
    - ネットワーク遅延により、OTP生成と受信の間に時間差が生じる可能性があります。
    - OTPが生成されたタイムステップウィンドウと同じウィンドウ内に収まらないことがあります。
      - OTPが時間ステップウィンドウの終わりに生成された場合、受信時間が次の時間ステップウィンドウに入る可能性が高くなります。
- 過去のタイムスタンプの考慮:
  - 検証システムは、許容される送信遅延ウィンドウ内の過去のタイムスタンプも考慮する必要があります。
  - 許容遅延ウィンドウが大きいほど攻撃のリスクが高まります。
  - 推奨される最大送信遅延: 1タイムステップ。
- セキュリティとユーザビリティ:
  - タイムステップサイズが大きいほど、有効なウィンドウが広がり、攻撃に対して脆弱になります。
    - 第三者がOTPを利用する時間が長くなります。
  - 推奨されるデフォルトのタイムステップサイズ: 30秒。
    - セキュリティとユーザビリティのバランスを取る。
- 次のOTP生成までの待ち時間への影響:
  - ユーザーはOTPを生成した後、次のタイムステップウィンドウまで待つ必要があります。
  - タイムステップウィンドウが大きいほど、次のOTPを生成するまでの待ち時間も長くなります。
  - 非常に長いタイムステップ（例：10分）は、一般的なインターネットログインには不適切です。
- タイムステップウィンドウ内でのOTPの再利用:
  - 検証者は、最初の検証成功後のOTPの再送を拒否しなければなりません。
    - OTPの一度限りの使用を保証します。

## 6. Resynchronization

clientとvalidation server間で発生する時間のずれ（clock drift）により、同期が取れない状態（"out of sync"）になる可能性があります。これに対応するために、validation server側で許容されるタイムステップのズレ数を設定し、許容範囲内のズレであれば認証を続行することで同期の問題を修正します。

clientからOTPを受信した際に、validation serverは現在のタイムステップを基準に、設定されたズレ数の範囲内でOTPの有効性を検証します。この範囲は、タイムステップが前後（forward and backward）にずれる場合の許容数で設定可能です。

検証が成功した場合、検出されたタイムステップのズレ（clock drift）が記録され、次回のOTP受信時には、記録されたズレを考慮したタイムステップでの検証が行われます。

ただし、proverが長期間OTPを送信しなかった場合、proverとvalidation server間のclock driftが大きくなる可能性があり、自動でのresynchronizationが行えなくなる場合があります。その際は、追加の認証手段が必要です。

### 追加の認証手段の例

- 管理者コンソールでの手動再同期
  - [HID Global](https://docs.hidglobal.com/activid-as-v8.4/Procedures/device-management/device-sync.htm#DeviceSynchronizationMethods)
  - [Duo](https://help.duo.com/s/article/2240?language=en_US)
- ネットワークタイムプロトコル（NTP）を使用
  - [Deepnet Security](https://wiki.deepnetsecurity.com/display/SafeID/How+to+resolve+time+drift+in+a+TOTP+token)

このような追加手段を使用して認証者と検証者のクロックのズレを明示的に再同期することが求められます。

- このセクションでの用語
  - token: OTPを発行する機器（デバイス）と捉える
