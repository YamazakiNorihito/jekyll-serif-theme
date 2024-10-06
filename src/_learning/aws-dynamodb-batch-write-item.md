---
title: AWS DynamoDB - BatchWriteItemの使用方法と注意点
date: 2024-10-06T07:15:00
tags:
  - AWS
  - DynamoDB
  - BatchWriteItem
---

### BatchWriteItem概要

[BatchWriteItem](https://docs.aws.amazon.com/ja_jp/amazondynamodb/latest/APIReference/API_BatchWriteItem.html)は、複数のアイテムを1回の操作でDynamoDBに対して追加（PutItem）または削除（DeleteItem）することができる機能です。

---

#### BatchWriteItemの機能

- BatchWriteItemは、1つ以上のテーブルに対して、PutItemまたはDeleteItem操作をまとめて実行できる。
- 1回の呼び出しで、最大16MBのデータを送信可能で、25個までのアイテムを操作できる。
- 各アイテムは最大400KBまで保存可能だが、送信時にDynamoDBのJSONフォーマットを使用するため、送信中のサイズが400KBを超えることがある。

---

#### 注意点: 更新操作は不可

BatchWriteItemでは更新操作（Update）はできません。既存のアイテムを上書きする場合は、アイテムが更新されたように見えることがありますが、正しく更新したい場合は、[UpdateItem](https://docs.aws.amazon.com/ja_jp/amazondynamodb/latest/APIReference/API_UpdateItem.html)を使用することが推奨されます。

---

### BatchWriteItem全体はアトミックじゃない

- **Atomic操作**: BatchWriteItem全体はアトミックではなく、バッチ内の一部の操作が失敗しても他の操作は成功する場合があります。これにより、部分的な成功と失敗が発生する可能性があるため、`UnprocessedItems` を適切に処理する必要があります。
- 操作が失敗する可能性は、2つの主な理由があります。1つはテーブルのプロビジョンされたスループットの超過、もう1つは内部処理のエラーです。失敗した操作は`UnprocessedItems`として返されるため、再試行が可能です。

---

#### 例外処理

- **ProvisionedThroughputExceededException**: テーブルのプロビジョニングされたスループットが不足している場合などに発生します。

詳細なエラーについては、[AWSのエラードキュメント](https://docs.aws.amazon.com/ja_jp/amazondynamodb/latest/APIReference/API_BatchWriteItem.html#API_BatchWriteItem_Errors)を参照

---

### リトライとExponential Backoffアルゴリズム

DynamoDBが未処理のアイテムを返す場合、それらに対して再度バッチ操作を実行することができます。しかし、即時のリトライはスロットリングにより再度失敗する可能性があるため、Exponential Backoffアルゴリズムを使用して適切なタイミングで再試行することが推奨されます。

---

#### BatchWriteItemの制限事項

BatchWriteItemは個別のPutItemItemやDeleteItemItemとは異なる動作をします:

例)

- 各PutItemやDeleteItemリクエストに条件を指定することはできません。
- 削除されたアイテムはレスポンスで返されません。

---

#### BatchWriteItemの利点: 並列処理の簡易化

BatchWriteItemを使用することで、アプリケーション側でPutItemやDeleteItem操作の並列スレッドを管理するための複雑なロジックを追加する必要がなくなります。

---

### 並列処理の利点とリソース消費

並列処理によりレイテンシが削減されますが、各PutItemやDeleteItemリクエストは、並列かどうかに関わらず同じ数のライトキャパシティユニットを消費します。存在しないアイテムに対する削除操作も1つのライトキャパシティユニットを消費します。

---

### BatchWriteItemが拒否される条件

以下のいずれかの条件を満たす場合、BatchWriteItemは全体が拒否されます:

1. 指定されたテーブルが存在しない場合。
2. リクエスト内のプライマリキー属性が、対応するテーブルのスキーマと一致しない場合。
3. 同じアイテムに対して複数の操作を1つのリクエストで行おうとした場合（例: PutItemとDeleteItemを同時に行う）。
4. 同じアイテムに対して複数回のPutItem操作を行おうとした場合。
5. 25個を超えるリクエストを含む場合。
6. 個々のアイテムが400KBを超える場合。
7. 総リクエストサイズが16MBを超える場合。
8. 個々のアイテムのキーが、キーの長さ制限（パーティションキーは2048バイト、ソートキーは1024バイト）を超える場合。

---

### 実装例: DynamoDBでのBatchWriteItem操作

以下は、Go言語を使用したDynamoDBの`BatchWriteItem`の例です。25個ごとにアイテムを削除し、未処理のアイテムがある場合には自動的に再試行を行うロジックが実装されています。

```go
func (r *DynamoDBStore) BatchDeleteItems(ctx context.Context, deleteInputs []dynamodb.DeleteItemInput) error {
 chunks := utils.ChunkSlice(deleteInputs, 25)

 for _, chunk := range chunks {
  writeRequests := make([]types.WriteRequest, len(chunk))
  for j, input := range chunk {
   writeRequests[j] = types.WriteRequest{
    DeleteRequest: &types.DeleteRequest{
     Key: input.Key,
    },
   }
  }

  input := &dynamodb.BatchWriteItemInput{
   RequestItems: map[string][]types.WriteRequest{
    r.TableName: writeRequests,
   },
  }

  result, err := r.client.BatchWriteItem(ctx, input)
  if err != nil {
   return err
  }

  for len(result.UnprocessedItems) > 0 {
   input.RequestItems = result.UnprocessedItems
   result, err = r.client.BatchWriteItem(ctx, input)
   if err != nil {
    return err
   }
  }
 }

 return nil
}
```
