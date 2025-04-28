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

本記事では、Go言語を用いてAmazon SNSのモバイルPush通知のエンドポイント登録サービスを実装する方法について紹介します。  
Amazon SNSのモバイルプラットフォームエンドポイントに関する詳細は、公式ドキュメントをご参照ください。  
[AWS SNS モバイルプラットフォームエンドポイントドキュメント](https://docs.aws.amazon.com/ja_jp/sns/latest/dg/mobile-platform-endpoint.html)

モバイルPush通知を適切に管理するために、ユーザーのデバイストークンをどのように管理し、更新するかがポイントとなります。  
思いついたシンプルな実装モデルを共有します。

## 課題：DeviceToken管理の問題点

モバイルPush通知を送るには、ユーザーごとにSNSのエンドポイントARNを管理し、トークンが変わった場合や無効になった場合に適切に更新する必要があります。  
しかし、これを適切に管理しないと、無効なエンドポイントに送信したり、トークンの不整合が発生したりしてしまいます。  
そのため、トークンの更新ロジックやエンドポイントの作成・更新処理をきちんとモデル化し、サービスとして切り出すことが望まれます。

## 提案するアプローチ

私が考えたのは、ユーザーのDeviceTokenを表すモデルと、SNSエンドポイントを操作するサービスを分離し、  
DeviceTokenモデルが自分で更新処理を持つ形です。  
これにより、トークンの更新やエンドポイントの作成・更新のロジックをUserDeviceTokenのRefreshメソッドに集約でき、呼び出し側はシンプルに扱えます。

## 実装例

次に示すのはDeviceToken管理のためのModelです。

```go
type DeviceType string

const (
 DeviceTypeAndroid DeviceType = "Android"
)

type UserDeviceToken struct {
 UserId         string     `dynamodbav:"userId"`
 DeviceType     DeviceType `dynamodbav:"deviceType"`
 Token          string     `dynamodbav:"token"`
 SnsEndpointArn string     `dynamodbav:"snsEndpointArn"`
}

func NewDeviceToken(user User) (*UserDeviceToken, error) {
 if user.Id == "" {
  return nil, errors.New("user is required")
 }
 return UserDeviceToken{
  UserId:       user.Id,
  DeviceType:   DeviceTypeAndroid,
 }, nil
}

func (d *UserDeviceToken) Refresh(ctx context.Context, newToken string, snsEndpointService service.ISNSEndpointService) error {
 createNewEndpoint := func() error {
  endpointArn, err := snsEndpointService.CreatePlatformEndpoint(ctx, newToken)
  if err != nil {
   return err
  }
  d.SnsEndpointArn = endpointArn
  d.Token = newToken
  return nil
 }

 if d.SnsEndpointArn == "" {
  return createNewEndpoint()
 }

 attrs, err := snsEndpointService.GetEndpointAttributes(ctx, d.SnsEndpointArn)
 if err != nil {
  return err
 }

 if attrs.Token == "" {
  return createNewEndpoint()
 }

 if attrs.Token != newToken || attrs.Enabled == false {
  if err := snsEndpointService.UpdateTokenAndEnable(ctx, d.SnsEndpointArn, newToken); err != nil {
   return err
  }
  d.Token = newToken
  return nil
 }
 return nil
}
```

続いて、SNSエンドポイントを操作するサービスの実装例です。  
ここでは、エンドポイントの作成、属性取得、更新、そしてPush通知の送信処理を持っています。

```go
type SNSEndpointService struct {
 client                 *sns.Client
 platformApplicationArn string
}

type EndpointAttributes struct {
 CustomUserData string
 Enabled        bool
 Token          string
}

type notification struct {
 Title string `json:"title,omitempty"`
 Body  string `json:"body,omitempty"`
}

type message struct {
 Notification notification      `json:"notification,omitempty"`
 Data         map[string]string `json:"data,omitempty"`
}

type fcmV1Message struct {
 Message message `json:"message"`
}

type fcm struct {
 FCMv1Message fcmV1Message `json:"fcmV1Message"`
}

type mobileMessage struct {
 GCM string `json:"GCM"`
}

type ISNSEndpointService interface {
 CreatePlatformEndpoint(ctx context.Context, deviceToken string) (endpointArn string, err error)
 MobilePush(ctx context.Context, pushMessageEndPoint string, title string, data map[string]string, logger infrastructure.Logger) error
 GetEndpointAttributes(ctx context.Context, endpointArn string) (EndpointAttributes, error)
 UpdateTokenAndEnable(ctx context.Context, endpointArn, deviceToken string) error
}

func NewSNSEndpointService(client *sns.Client, platformApplicationArn string) *SNSEndpointService {
 return &SNSEndpointService{
  client:                 client,
  platformApplicationArn: platformApplicationArn,
 }
}

func (s *SNSEndpointService) CreatePlatformEndpoint(ctx context.Context, deviceToken string) (endpointArn string, err error) {
 if deviceToken == "" {
  return "", errors.New("deviceToken cannot be empty")
 }

 input := sns.CreatePlatformEndpointInput{
  PlatformApplicationArn: &s.platformApplicationArn,
  Token:                  &deviceToken,
 }

 output, err := s.client.CreatePlatformEndpoint(ctx, &input)
 if err != nil {
  return "", err
 }
 return *output.EndpointArn, nil
}

func (s *SNSEndpointService) MobilePush(ctx context.Context, pushMessageEndPoint string, title string, data map[string]string, logger infrastructure.Logger) error {
 fcmMessage := fcm{}
 fcmMessage.FCMv1Message.Message.Data = data

 fcmJSON, err := json.Marshal(fcmMessage)
 if err != nil {
  return err
 }

 message := mobileMessage{
  GCM: string(fcmJSON),
 }

 messageJSON, err := json.Marshal(message)
 if err != nil {
  return err
 }

 input := &sns.PublishInput{
  Message:          aws.String(string(messageJSON)),
  MessageStructure: aws.String("json"),
  TargetArn:        aws.String(pushMessageEndPoint),
 }

 logger.Info("Attempted to send message", string(messageJSON))

 _, err = s.client.Publish(ctx, input)
 if err != nil {
  logger.Error("Error publishing to SNS", err)
  return err
 }

 return nil
}

func (s *SNSEndpointService) GetEndpointAttributes(ctx context.Context, endpointArn string) (EndpointAttributes, error) {
 input := &sns.GetEndpointAttributesInput{
  EndpointArn: aws.String(endpointArn),
 }

 output, err := s.client.GetEndpointAttributes(ctx, input)
 if err != nil {
  return EndpointAttributes{}, err
 }

 attrs := output.Attributes
 return EndpointAttributes{
  CustomUserData: attrs["CustomUserData"],
  Enabled:        attrs["Enabled"] == "true",
  Token:          attrs["Token"],
 }, nil
}

func (s *SNSEndpointService) UpdateTokenAndEnable(ctx context.Context, endpointArn, deviceToken string) error {
 attrs := map[string]string{
  "Token":   deviceToken,
  "Enabled": "true",
 }

 input := &sns.SetEndpointAttributesInput{
  EndpointArn: aws.String(endpointArn),
  Attributes:  attrs,
 }

 _, err := s.client.SetEndpointAttributes(ctx, input)
 return err
}
```

## 使い方

最後に、このサービスを使って実際にユーザーのDeviceTokenを更新する例を示します。  

```go
cfg, _ := config.LoadDefaultConfig(ctx)
snsClient := sns.NewFromConfig(cfg)

service := service.NewSNSNotificationEndpointService(s.snsClient, "arn:aws:sns:region:account-id:app/platform")

userDeviceToken, _ = domain.NewDeviceToken(user)
token := "deviceTokenExample"
 err = userDeviceToken.Refresh(ctx, token, snsEndpointService)
 if err != nil {
  logger.Error("failed to refresh user device token", err)
  return err
 }
```

上記のように、`NewDeviceToken`でモデルを生成し、`Refresh`メソッドに新しいトークンとSNSエンドポイントサービスを渡すだけで、  
必要に応じてエンドポイントの作成や更新が行われます。  
この設計により、呼び出し側はトークンの管理に煩わされることなく、シンプルに利用できます。
