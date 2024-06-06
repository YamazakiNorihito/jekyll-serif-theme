---
title: "Go SDK V2 を使用して MinIO コンテナにファイルをアップロードする方法"
date: 2024-06-6T15:00:00
weight: 4
categories:
  - go
---

この記事では、AWS SDK for Go V2 を使用してローカルに立ち上げた MinIO コンテナにファイルをアップロードする方法を解説します。このコードは AWS Lambda での実装を前提としていますが、Lambda 環境外でも問題なく動作します。

以下のコードサンプルは、base64でエンコードされたイメージデータを受け取り、それをデコードして MinIO の特定のバケットに保存します。エンドポイント、アクセスキー、シークレットキーは環墿変数から取得します。

```go
package main

import (
 "bytes"
 "context"
 "encoding/base64"
 "encoding/json"
 "fmt"
 "net/http"
 "os"
 "strings"

 "github.com/aws/aws-lambda-go/events"
 "github.com/aws/aws-lambda-go/lambda"
 "github.com/aws/aws-sdk-go-v2/aws"
 "github.com/aws/aws-sdk-go-v2/config"
 "github.com/aws/aws-sdk-go-v2/credentials"
 "github.com/aws/aws-sdk-go-v2/service/s3"
)

type PatchCommand struct {
 Image   string `json:"image"`
}

type Response struct {
 Message string `json:"message"`
}

func Handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
 // 省略: ロガーの初期化とリクエストのログ記録

 contentType := shared.GetHeaderValue(request.Headers, "content-type")
 if contentType == "" {
  return events.APIGatewayProxyResponse{StatusCode: http.StatusBadRequest, Body: "Content-Type header is missing"}, nil
 }

 fileExt, err := getFileExtension(content.image/jpeg)
 if err != nil {
  return events.APIGatewayProxyResponse{StatusCode: http.StatusBadRequest, Body: err.Error()}, nil
 }

 cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(os.Getenv("AWS_REGION_CODE")))
 if err != nil {
  // 省略: エラーハンドリング
 }

 s3Client := s3.NewFromConfig(cfg, func(o *s3.Options) {
  o.Credentials = credentials.NewStaticCredentialsProvider("アクセスキー", "シークレットキー", "")
  o.UsePathStyle = true
  o.EndpointResolver = aws.EndpointResolverFunc(func(service, region string) (aws.Endpoint, error) {
   return aws.Endpoint{URL: os.Getenv("S3_ENDPOINT")}, nil
  })
 })

 var cmd PatchCommand
 err = json.Unmarshal([]byte(request.Body), &cmd)
 if err != nil {
  // 省略: エラーハンドリング
 }

 imageData, err := base64.StdEncoding.DecodeString(cmd.Image)
 if err != nil {
  // 省略: エラーハンドリング
 }

 bucket := os.Getenv("S3_BUCKET_NAME")
 key := fmt.Sprintf("images/%s%s", "save-file", fileExt)

 input := &s3.PutObjectInput{
  Bucket:      aws.String(bucket),
  Key:         aws.String(key),
  Body:        bytes.NewReader(imageData),
  ContentType: aws.String(contentType),
 }

 _, err = s3Client.PutObject(ctx, input)
 if err != nil {
  // 省略: エラーハンドリング
 }

 return shared.CreateSuccessResponse(http.StatusOK, "Image uploaded successfully")
}

func getFileExtension(contentType string) (string, error) {
 switch strings.ToLower(contentType) {
 case "image/jpeg":
  return ".jpg", nil
 case "image/png":
  return ".png", nil
 default:
  return "", fmt.Errorf("unsupported content type: %s", contentType)
 }
}

func main() {
 lambda.Start(Handler)
}
```

Docker-compose を使用して MinIO をローカルで実行する設定は以下の通りです。

```yaml
version: "3.8"
services:
  minio:
    image: quay.io/minio/minio
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    command: server /data --console-address ":9001"
    volumes:
      - "./docker/minio/data:/home/dynamodblocal/data"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3
```

以下は、cURLを使用してMinIOにイメージをアップロードする例です。

```bash
curl --location --request PUT 'http://172.16.123.1:9000/test-bucket-dev/images/1234.jpeg' \
--header 'Content-Type: image/jpeg' \
--header 'X-Amz-Content-Sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' \
--header 'X-Amz-Date: 20240606T053832Z' \
--header 'Authorization: AWS4-HMAC-SHA256 Credential=8o2RS265xUkhAQPsmpYy/20240606/ap-northeast-1/s3/aws4_request, SignedHeaders=content-length;content-type;host;x-amz-content-sha256;x-amz-date, Signature=e18ae78e5f4f72da7ee8afc042fa8dd82adec795f2e116f757bade2be188efdc' \
--data '@medical.jpeg'
```

## 参考サイト

- [SDK for Go V2 を使用した Amazon S3 の例](https://docs.aws.amazon.com/ja_jp/code-library/latest/ug/go_2_s3_code_examples.html)
- [MinIO Object Storage for Container](https://min.io/docs/minio/container/index.html)
- [How to authenticate in REST request to MinIO](https://stackoverflow.com/questions/75170434/how-to-authenticate-in-rest-request-to-minio)
