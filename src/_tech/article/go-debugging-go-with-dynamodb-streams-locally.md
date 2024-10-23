---
title: "Debugging Go with Local DynamoDB Streams"
date: 2024-06-4T7:00:00
weight: 4
categories:
  - go
description: ""
---

## ローカルでDynamoDB Streamsを使ってGoプログラムをデバッグする方法

以下はDynamoDBのStreamイベントを使って、ローカルでGoプログラムをデバッグするためのステップバイステップガイドです。

#### コードの準備

```go
package main

import (
 "context"
 "fmt"
 "log"
 "os"
 "time"

 "github.com/aws/aws-lambda-go/events"
 "github.com/aws/aws-lambda-go/lambda"
 "github.com/aws/aws-sdk-go-v2/config"
 "github.com/aws/aws-sdk-go-v2/service/dynamodbstreams"
 "github.com/aws/aws-sdk-go-v2/service/dynamodbstreams/types"
 "github.com/aws/aws-sdk-go/aws"
)

/*
AWS CLI コマンドを利用してDynamoDBのストリームを有効化、確認、無効化:
-- ストリームを有効化
aws dynamodb update-table --table-name User --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES --endpoint-url http://localhost:8000 --region us-west-2

-- ストリーム確認
aws dynamodb describe-table --table-name User --endpoint-url http://localhost:8000 --region us-west-2


-- ストリームを無効化
aws dynamodb update-table --table-name User --stream-specification StreamEnabled=false --endpoint-url http://localhost:8000 --region us-west-2
*/
// https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/with-ddb-example.html
// DynamoDBイベントを処理
func handle(ctx context.Context, e events.DynamoDBEvent) error {
 logger := shared.NewZapWrappedLogger()
 defer logger.Sync()

 for _, record := range e.Records {
  logger.Info("Processing record", record)
 }
 return nil
}

// ストリームをポーリングしてハンドラを呼び出す

func PollStreamAndInvokeHandler(ctx context.Context, streamArn string, debugHandle func(ctx context.Context, e events.DynamoDBEvent) error) {
 cfg, err := config.LoadDefaultConfig(ctx)
 if err != nil {
  log.Fatalf("unable to load SDK config, %v", err)
 }

 client := dynamodbstreams.NewFromConfig(cfg, func(o *dynamodbstreams.Options) {
  o.BaseEndpoint = aws.String("http://localhost:8000")
 })

 describeStreamOutput, err := client.DescribeStream(ctx, &dynamodbstreams.DescribeStreamInput{
  StreamArn: &streamArn,
 })
 if err != nil {
  log.Fatalf("failed to describe stream, %v", err)
 }

 shardIteratorType := types.ShardIteratorTypeTrimHorizon
 shardIteratorOutput, err := client.GetShardIterator(ctx, &dynamodbstreams.GetShardIteratorInput{
  StreamArn:         &streamArn,
  ShardId:           describeStreamOutput.StreamDescription.Shards[0].ShardId,
  ShardIteratorType: shardIteratorType,
 })
 if err != nil {
  log.Fatalf("failed to get shard iterator, %v", err)
 }

 shardIterator := shardIteratorOutput.ShardIterator
 for {

  output, err := client.GetRecords(ctx, &dynamodbstreams.GetRecordsInput{
   ShardIterator: shardIterator,
  })
  if err != nil {
   log.Fatalf("failed to get records, %v", err)
  }

  if 0 < len(output.Records) {
   for _, record := range output.Records {
    var event events.DynamoDBEvent

    change, _ := convertStreamRecordUsingJSON(record.Dynamodb)
    event.Records = append(event.Records, events.DynamoDBEventRecord{
     EventID:      *record.EventID,
     EventName:    string(record.EventName),
     EventVersion: *record.EventVersion,
     EventSource:  *record.EventSource,
     AWSRegion:    *record.AwsRegion,
     Change:       change,
    })

    if err := debugHandle(ctx, event); err != nil {
     log.Fatalf("failed to handle request, %v", err)
    }
   }
  }

  if output.NextShardIterator == nil {
   break
  }
  shardIterator = output.NextShardIterator
  time.Sleep(1 * time.Second)
 }
}

func convertStreamRecordUsingJSON(streamRecord *types.StreamRecord) (dynamoStreamRecord events.DynamoDBStreamRecord, error error) {
 if streamRecord == nil {
  return events.DynamoDBStreamRecord{}, fmt.Errorf("streamRecord is nil")
 }

 dynamoStreamRecord.Keys = convertAttributeValueMap(streamRecord.Keys)
 dynamoStreamRecord.NewImage = convertAttributeValueMap(streamRecord.NewImage)
 dynamoStreamRecord.OldImage = convertAttributeValueMap(streamRecord.OldImage)
 dynamoStreamRecord.SequenceNumber = *streamRecord.SequenceNumber
 dynamoStreamRecord.SizeBytes = *streamRecord.SizeBytes
 dynamoStreamRecord.StreamViewType = string(streamRecord.StreamViewType)

 return dynamoStreamRecord, nil
}

// いい感じにConvertしてくれるライブラリが見つけられなかったので、自作です。(不具合あるかも)
func convertAttributeValueMap(attributeValueMap map[string]types.AttributeValue) map[string]events.DynamoDBAttributeValue {
 result := make(map[string]events.DynamoDBAttributeValue)
 for k, v := range attributeValueMap {
  result[k] = convertAttributeValue(v)
 }
 return result
}

func convertAttributeValue(attributeValue types.AttributeValue) events.DynamoDBAttributeValue {
 switch v := attributeValue.(type) {
 case *types.AttributeValueMemberS:
  return events.NewStringAttribute(v.Value)
 case *types.AttributeValueMemberN:
  return events.NewNumberAttribute(v.Value)
 case *types.AttributeValueMemberBOOL:
  return events.NewBooleanAttribute(v.Value)
 case *types.AttributeValueMemberB:
  return events.NewBinaryAttribute(v.Value)
 case *types.AttributeValueMemberSS:
  return events.NewStringSetAttribute(v.Value)
 case *types.AttributeValueMemberNS:
  return events.NewNumberSetAttribute(v.Value)
 case *types.AttributeValueMemberBS:
  return events.NewBinarySetAttribute(v.Value)
 case *types.AttributeValueMemberM:
  return events.NewMapAttribute(convertAttributeValueMap(v.Value))
 case *types.AttributeValueMemberL:
  var list []events.DynamoDBAttributeValue
  for _, item := range v.Value {
   list = append(list, convertAttributeValue(item))
  }
  return events.NewListAttribute(list)
 case *types.AttributeValueMemberNULL:
  return events.NewNullAttribute()
 default:
  return events.NewNullAttribute()
 }
}

func main() {
 if os.Getenv("GO_ENV") == "local" {
  // ストリーム確認でstreamのARMの値を設定してね
  streamArn := "arn:aws:dynamodb:ddblocal:000000000000:table/User/stream/2024-06-03T22:11:19.260"
  ctx := context.Background()
  PollStreamAndInvokeHandler(ctx, streamArn, handle)
 } else {
  lambda.Start(handle)
 }
}
```

###### Docker Composeで環境設定

```yaml
version: "3.8"
services:
  dynamodb-local:
    command: "-jar DynamoDBLocal.jar -sharedDb -dbPath ./data"
    image: "amazon/dynamodb-local:latest"
    container_name: dynamodb-local
    ports:
      - "8000:8000"
    volumes:
      - "./docker/dynamodb:/home/dynamodblocal/data"
    working_dir: /home/dynamodblocal
  app-node:
    depends_on:
      - dynamodb-local
    image: amazon/aws-cli
    container_name: app-node
    ports:
      - "8081:8080"
    environment:
      AWS_ACCESS_KEY_ID: "DUMMYIDEXAMPLE"
      AWS_SECRET_ACCESS_KEY: "DUMMYEXAMPLEKEY"
    command: dynamodb describe-limits --endpoint-url http://dynamodb-local:8000 --region us-west-2
  dynamodb-admin:
    image: "aaronshaf/dynamodb-admin:latest"
    container_name: dynamodb-admin
    environment:
      - DYNAMO_ENDPOINT=dynamodb-local:8000
    ports:
      - "8001:8001"
    depends_on:
      - dynamodb-local
```
