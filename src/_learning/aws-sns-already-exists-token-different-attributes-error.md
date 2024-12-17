---
title: "Amazon SNS: Tokenが同じだが属性が異なるエラーの原因"
date: 2024-09-24T15:35:00
mermaid: true
weight: 7
tags:
  - AWS
  - SNS
  - エラー対処
  - デバイストークン
  - GoLang
  - モバイル通知
description: "Amazon SNS の CreatePlatformEndpoint API で発生する「already exists with the same Token, but different attributes」エラーの原因と解決方法を解説。GoLang を使った実装例も紹介。"
---

## はじめに

GoLang で Amazon SNS の`CreatePlatformEndpoint` API を使って、プラットフォームエンドポイントを作成しようとした際に、以下のようなエラーに遭遇しました。今回は、そのエラーの原因と対処法について解説します。

```bash
"error": "operation error SNS: CreatePlatformEndpoint, https response error StatusCode: 400, RequestID: 31859cc5-5e31-5416-9df5-c3a9036654ee, InvalidParameter: Invalid parameter: Token Reason: Endpoint arn:aws:sns:ap-northeast-1:******:endpoint/GCM/******/830d456e-dbea-304f-a2af-e2e9e666cd70 already exists with the same Token, but different attributes."
```

エラーが示す通り、同じデバイストークンで異なる属性を持つエンドポイントが既に存在していると、このエラーが発生します。具体的な原因とその理解について、私が学んだことを書いておきます。

## 該当コード

アプリケーションでは、デバイストークンを使って SNS のエンドポイントを作成しようとしています。また、CustomUserData を使ってデバイストークンの所有者情報を登録しています。

```go
func (s *SNSEndpointService) createEndpoint(ctx context.Context, user domain.UserMeta, deviceToken string) error {
    customUserData := formatUserKey(user)
    input := sns.CreatePlatformEndpointInput{
        PlatformApplicationArn: &s.platformApplicationArn,
        Token:                  &deviceToken,
        Attributes: map[string]string{
            "Enabled": "true",
        },
        CustomUserData: &customUserData,
    }

    _, err := s.client.CreatePlatformEndpoint(ctx, &input)
    return err
}
```

この実装では、デバイストークンを使って新しいエンドポイントを作成しようとしていますが、`CustomUserData`に異なるデータが含まれている場合、上記のエラーが発生します。

## 背景

モバイル端末 1 台を複数のユーザーで共有しているため、同じデバイストークンでも、その時々で所有者が変わるケースがあります。そのため、`CustomUserData`を更新する必要がありました。`CreatePlatformEndpoint`メソッドを使ってエンドポイントを作成し、既存のエンドポイントがある場合は ARN を取得し、その ARN を使って`CustomUserData`を更新するつもりでした。

しかし、これがエラーの原因となりました。

## エラーの原因

Amazon SNS の`CreatePlatformEndpoint`は、デバイストークンが同じであっても、他の属性（例: `CustomUserData`）が異なると、既存のエンドポイントを返さずにエラーを返す仕様になっています。このことは、[AWS の公式ブログ](https://aws.amazon.com/jp/blogs/mobile/mobile-token-management-with-amazon-sns/)でも確認できます。

> If a PlatformEndpoint with the same token, but different attributes already exists, doesn’t create anything; also does not return anything but throws an exception.

## 参考リンク

同様の問題に関して、参考になる情報はこちらです。

[Stack Overflow - How do I check whether a mobile device has already been registered?](https://stackoverflow.com/questions/19551067/how-do-i-check-whether-a-mobile-device-has-already-been-registered)
