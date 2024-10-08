---
title: 
date: 2024-10-07T07:15:00
tags:
  - AWS
  - DynamoDB
  - 
description: ""
---

## Core components of Amazon DynamoDB

### Tables, items, and attributes

Amazon DynamoDBは、3つの主要なコアコンポーネントで構成されています。

1. Tables（テーブル）

   - データのストレージとして機能します。
   - Items（アイテム）の集合体であり、データを格納します。
   - 一般的なデータベースのテーブルのような役割を果たします。

2. Items（アイテム）

   - 各テーブルには0個以上のアイテムが含まれます。
   - アイテムは、属性（attributes）のグループで構成されています。
   - 各アイテムはユニークであり、主キー（primary key）を使用して識別されます。
   - 一般的なデータベースの行やレコードに相当します。
   - 主キー以外の属性はスキーマレスで、事前に属性やそのデータ型を定義する必要はありません。
   - 各アイテムは独自の属性を持つことができ、全てのアイテムが同じ属性を持つ必要はありません。

3. Attributes（属性）

   - 各アイテムには1つ以上の属性が含まれます。
   - 属性は、データを格納する最小単位です。
   - 一般的なデータベースのフィールドやカラムに相当します。
   - 多くの属性はスカラー型（文字列や数値などの単一の値）ですが、ネストされた属性もサポートしており、32階層まで深くネスト可能です。

### Primary key

Primary keyはテーブル内の各Itemをuniquely identifies。テーブル内のItemを直接提供するために使われるKey

primary keys:は２種類ある

1. Partition key
   1. 1つのattributeで構成される単純primary key
   2. Partition keyはDynamoDBの internal hash functionのinput valueとして使われる
      1. そのhash値をpartitionとして物理Storageを確保し、Itemを保存する
2. Partition key and sort key
   1. ２つのattributeで構成される複合primary key
   2. partition keyと sort key
   2. Partition keyはDynamoDBの internal hash functionのinput valueとして使われる
      1. そのhash値をpartitionとして物理Storageを確保し、Itemを保存する
   3. sort keyはPartition ないでソート順の値を
      1. 同じpartition keyで複数のItemを持つことが可能とする
      2. そのためにはsort keyのValueを異なるValueにしないといけない
   4. 
