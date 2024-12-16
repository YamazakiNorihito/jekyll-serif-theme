---
title: "GoでAmazon SNS モバイルPushエンドポイント登録サービスを実装"
date: 2024-06-5T5:00:00
weight: 4
categories:
  - go
description: "Goを使ってAmazon SNSでモバイルPush通知のエンドポイントを登録・更新するサービスを実装。ユーザー情報とデバイストークンに基づいてエンドポイントを管理します。"
tags:
  - Go
  - Amazon SNS
  - Push Notifications
  - AWS SDK
  - Goサービス
  - モバイル通知
---

## はじめに

特にリアルタイムデータや通知を必要とするアプリケーションにおいて、Amazon Simple Notification Service（Amazon SNS）の統合が不可欠です。
このブログ投稿では、Goを使用してSNSエンドポイントを管理するサービスの実装方法について説明します。
これにより、アプリケーションが動的にデバイスを登録または更新するためのプッシュ通知を可能にします。

## サービス

このサービスクラスは、Amazon SNSへの登録および更新を行うためのものです。主にRegisterOrUpdateEndpointメソッドを公開しています。

```go
package service

import (
 "context"

 "github.com/aws/aws-sdk-go-v2/service/sns"
 "github.com/example/alarm-api/internal/domain"
)

type SNSNotificationEndpointService struct {
 client                 *sns.Client
 platformApplicationArn string
}

func NewSNSNotificationEndpointService(client *sns.Client, platformApplicationArn string) *SNSNotificationEndpointService {
 return &SNSNotificationEndpointService{
  client:                 client,
  platformApplicationArn: platformApplicationArn,
 }
}

func (s *SNSNotificationEndpointService) RegisterOrUpdateEndpoint(ctx context.Context, user domain.UserMeta, deviceToken string) error {
 endpointArn, err := s.findEndpoint(ctx, user)
 if err != nil {
  return err
 }

 if endpointArn == "" {
  return s.createEndpoint(ctx, user, deviceToken)
 }
 return s.updateEndpoint(ctx, endpointArn, deviceToken)
}

func (s *SNSNotificationEndpointService) findEndpoint(ctx context.Context, user domain.UserMeta) (string, error) {
 input := sns.ListEndpointsByPlatformApplicationInput{
  PlatformApplicationArn: &s.platformApplicationArn,
 }

 paginator := sns.NewListEndpointsByPlatformApplicationPaginator(s.client, &input)
 customUserData := formatUserKey(user)

 for paginator.HasMorePages() {
  page, err := paginator.NextPage(ctx)
  if err != nil {
   return "", err
  }

  for _, endpoint := range page.Endpoints {
   if endpoint.Attributes["CustomUserData"] == customUserData {
    return *endpoint.EndpointArn, nil
   }
  }
 }

 return "", nil
}

func (s *SNSNotificationEndpointService) createEndpoint(ctx context.Context, user domain.UserMeta, deviceToken string) error {
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

func (s *SNSNotificationEndpointService) updateEndpoint(ctx context.Context, endpointArn, deviceToken string) error {
 input := sns.SetEndpointAttributesInput{
  EndpointArn: &endpointArn,
  Attributes: map[string]string{
   "Token":   deviceToken,
   "Enabled": "true",
  },
 }

 _, err := s.client.SetEndpointAttributes(ctx, &input)
 return err
}

func formatUserKey(user domain.UserMeta) string {
 return "UserID" + user.UserId
}


```

## 使い方

以下は、このサービスを使用する例です：

```go
cfg, _ := config.LoadDefaultConfig(ctx)
snsClient := sns.NewFromConfig(cfg)

service := service.NewSNSNotificationEndpointService(s.snsClient, "arn:aws:sns:region:account-id:app/platform")

user := domain.UserMeta{
  UserId:       "endpoint-user-id",
  UserName:     "endpoint-user-name",
}
token := "deviceTokenExample"
snsService.RegisterOrUpdateEndpoint(ctx, user, token)

```

このコードスニペットは、設定をロードしてSNSクライアントを初期化し、ユーザー情報とデバイストークンを使用して、エンドポイントを登録または更新します。これにより、アプリケーションはSNSを通じてプッシュ通知を送信することができます。
