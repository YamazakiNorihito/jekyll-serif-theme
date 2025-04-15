---
title: "Amazon DynamoDBのBest practicesのメモ"
date: 2024-10-7T07:15:00
mermaid: true
weight: 7
tags:
  - AWS
  - DynamoDB
  - NoSQL
description: "自分用のメモとして、DynamoDBのコアコンポーネント（テーブル、アイテム、属性）、プライマリキー、セカンダリindex、DynamoDB Streamsについて整理。設計に役立つベストプラクティスも含む"
---

# Amazon DynamoDBのBest practicesのメモ

## [Partition key design](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-partition-key-design.html)

- 読み取りコストの基準は **4 KB/RCU**、書き込みコストの基準は **1 KB/WCU**。
- 各パーティションは最大 **3,000 RCU/秒** を処理できる。
- 各パーティションは最大 **1,000 WCU/秒** を処理できる。
- **強い整合性** で 4 KB までのアイテム 1 件を読むと **1 RCU** 消費する。
- **結果整合性** で 4 KB までのアイテム 1 件を読むと **0.5 RCU**（課金は切り上げ）を消費する。つまり **1 RCU** で 2 件まで読める。
- アイテムサイズが **20 KB** の場合、1 つの強い整合性 read で **5 RCU** を消費する。
- パーティションあたりの最大スループットが **3,000 RCU/秒** なので、1 パーティションにおいて **同時に 600 回の read オペレーション**（= 3000 / 5）が可能。
- 読み取りスループットはアイテムサイズに比例して RCU を多く消費するため、**大きなアイテムはスループット制限を早く使い切る**。
- DynamoDB のスループットには「テーブルレベルの制限」がある。([ServiceQuotas#Read/write throughput](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ServiceQuotas.html#default-limits-throughput-capacity-modes))
  - **Provisioned モード**では、以下の2つの制限がある：
    - **Per table クォータ**：1つのテーブルで使用できる最大 RCU/WCU（例：40,000）
    - **Per account クォータ**：アカウント全体で使用できる RCU/WCU の合計（例：80,000）
    → つまり、1テーブルのスループットも、アカウント全体の合計も制限される
  - **On-Demand モード**では、**Per table クォータのみが適用される**
    - アカウント全体の上限（Per account）は適用されない
    - 各テーブルは自動スケーリングするが、最大でも Per table 上限まで

### [Distributing workloads](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-partition-key-uniform-load.html)

- "hot" partitionsとは  
  - 並列で1つのパーティションに複数のアイテムを書き込むと、そのパーティションに割り当てられたWCU（Write Capacity Unit）を超えてスロットリングされる。
    - 超えた分は ProvisionedThroughputExceededException となり、アプリ側でのリトライが必要
    - スロットリングされたリクエストはWCUを消費しない
  - 特定のパーティションに集中すると、I/Oのレイテンシーが上がり、全体として非効率になる。
- partition keyはunderlying physical partitionsに影響を与えるので、きちんと設計されるべき  
  - これがされないと  
    - "hot" partitionsを起こす可能性がある  
    - → DynamoDBの「物理パーティション」はパーティションキーによって決まり、偏ると効率が落ちる
- TableのPartitionKeyでアクセスすることで、１つのpartionに対する負荷が分散されるので"hot" partitionsが発生しづらくなる  
  - 特に、１つのテーブルでpartition keyの数が少ない場合は、writeするときにdistinct partition keyになるように考慮する必要がある。  
- 「キーの種類」＝「Good or Bad」じゃない。実際の使い方・アクセス分布が「均等かどうか」で判断すべき。  
  - 表に書かれている評価は「一般的なユースケースにおける傾向」に過ぎない  
  - → たとえば：
    - 「User ID は Good」って書いてあるけど、Device IDの説明からヘビーユーザーが偏れば普通に Bad になるよね？
    - → 実際には「アクセスされるキーの種類がどれくらいあるか」「それらがどれくらい均等に使われているか」が重要

| Partition key value                                                                 | Uniformity |
|---------------------------------------------------------------------------------------|------------|
| User ID, where the application has many users.                                        | Good       |
| Status code, where there are only a few possible status codes.                       | Bad        |
| Item creation date, rounded to the nearest time period (for example, day, hour, or minute). | Bad        |
| Device ID, where each device accesses data at relatively similar intervals.            | Good       |
| Device ID, where even if there are many devices being tracked, one is by far more popular than all the others. | Bad        |

### [Write sharding](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-partition-key-sharding.html)

**sharding:**  
大きなものを複数の小さなグループに分けて、それぞれが別々に作業できるようにすることで、全体としての処理能力を上げたり、管理をしやすくしたりする技術

あくまで１つの方法として  
パーティションキーに追加情報（例: 日付に連番を付加する）を加えることで、キー空間（namespace）を拡張し、物理的パーティションへの書き込み分散を図るという考え方

---

- **Sharding using random suffixes**  
  - ランダムなサフィックス（末尾の数値）をパーティションキーに付加することで、書き込みを分散できる  
    - 例：元のキーが `2014-07-09` の場合  
      - `2014-07-09.1`, `2014-07-09.2`, ..., `2014-07-09.200` のようにランダムな数値を追加して書き込む
  - ランダム化されたキーは、DynamoDB によって自動的に複数の物理パーティションに分散される  
    - → 負荷が分散され、スループット効率が向上  
    - → 書き込み時の並列性も高くなる
  - 読み取り時にはデメリットもある  
    - 同じ論理キー（例：2014-07-09）で分散されているため、全件取得には複数の Query が必要  
      - 例：`2014-07-09.1` ～ `2014-07-09.200` を個別にクエリ  
      - クライアント側でそれらの結果をマージ（統合）する必要がある
  - 読み取り負荷が高いユースケースでは注意が必要  
    - クエリ数増加により、パフォーマンスやコストに影響が出る可能性あり  
    - 並列クエリや Batch 処理などの工夫が必要
  - ランダムだけでなく、意味のある値（例：ハッシュ値、ユーザーIDなど）を使って制御可能なシャーディングを行うこともできる

---

- **Sharding using calculated suffixes**  
  - `Sharding using random suffixes` とほぼ同じだが、Random の部分を計算で求める点が異なる  
  - 例えば、Order ID = "AB1", 日付 = "2014-07-09" の場合  
    - Order ID の UTF-8 コードポイントは `65`, `66`, `49` なので  
      - number = (65 *66* 49) % 200 + 1 = 209790 % 200 + 1 = 10 + 1 = 11  
      - partition key は `2014-07-09.11`
  - これは、Order ID と日付でアクセスすることがある場合、有効である
  - ただし、read all the items するときは `Sharding using random suffixes` と同じ問題がある

### [Uploading data efficiently](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-partition-key-data-upload.html)

データをDynamoDBに書き込む際は、**partition key を分散して書き込む**ことが重要である。  
ここでは、そのための一つの手法が提示されている。

たとえば、**UserID を partition key、MessageID を sort key とする複合プライマリキー**を持つテーブルに対して、  
各ユーザー（100人分）に100件程度のメッセージをアップロードするケースを考える。

このとき、ユーザー単位でまとめて書き込む（例: U1 の全件 → U2 の全件 …）と、  
**特定の partition（UserID）にアクセスが集中**してしまい、パフォーマンス劣化が起きる。  
これは、DynamoDBの内部でデータが複数のパーティション（サーバー）に分散されているにも関わらず、**一部のパーティションしか使われないため**である。

この問題を避けるには、**sort key（MessageID）を基準にして、全ユーザーに対して1件ずつ書き込む → 2件目を書き込む → ...**  
というように **各partition keyに対して均等にアクセスする**ことで、  
**複数のDynamoDBサーバーが同時に稼働し、スループットが最大限に活用される**ようになる。

- **悪い例**：U1の100件 → U2の100件 → U3の100件  
  → 特定パーティションが hot になり、他のサーバーが遊んでしまう
- **良い例**：U1の1件 → U2の1件 → U3の1件 → 次にU1の2件目 → U2の2件目  
  → 各サーバーに均等に負荷を分散できる（＝高スループット）

## [Sort key design](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-sort-keys.html)

関連するデータをまとめて、範囲クエリで効率よく取得できる

1. 関連するデータをまとめて、範囲クエリで効率よく取得できる
   1. 同じパーティションキーの下に、関連データを並べられる。
   2. begins_with, between, <, > などの演算子を使って一部だけ取り出せる。
2. コンポジットソートキーによって階層的なデータ構造を表現できる
   1. 形式例：country#region#state#city など
   2. これにより、任意の階層レベルで柔軟に検索できる。
      1. 例: begins_with(sort key, "japan#kanto") → 関東地方に属する全データが取得できる。

### Sort Key を使った Version Control パターン

Itemの更新履歴（バージョン）を保持しつつ、最新バージョンを高速に取得できるように設計できます。

#### 考え方

- 各バージョンを識別するために、Sort Key にバージョンプレフィックス（例：v1_, v2_）を付ける。
- 最新版を示す特別なプレフィックス（例：v0_）を使って、常に最新データにアクセスできるようにする。

---

#### パターンA：v0 に最新データをコピーする方法

##### 動作の流れ

1. 作成時
   - 最初のデータを `v1_` と `v0_` の 2 つの Sort Key で登録する。
   - `v1_` は初回バージョン、`v0_` は最新版のコピーとして使用。

2. 更新時
   - `v2_`, `v3_` … のようにバージョン番号をインクリメント。
   - 同時に `v0_` を上書きして最新状態に保つ。

3. 取得時
   - 最新データ：`begins_with(sort key, "v0_")`
   - 履歴データ：パーティションキーで全件取得し、`v0_` を除外

---

#### パターンB：v0 をポインタとして使う方法（間接参照）

##### 動作の流れ

1. `v0_` アイテムに、最新バージョンの Sort Key や ID を記録する。
2. 実際のデータは `v1_`, `v2_` などに格納。
3. 最新データを取得するには、`v0_` を読み、指定された Sort Key を参照して取得。

## Secondary indexes

- Global secondary index (GSI)
  - 元のテーブルとは異なる partition key および sort key を定義できる
  - “global” とは、元のテーブルのすべてのパーティションにまたがって検索できることを意味する
  - indexにはサイズの制限がない
  - provisioned throughput settingsはベーステーブルとは独立している
  - 1つのテーブルにつき最大 20 個まで作成できる
- Local secondary index (LSI)
  - 元のテーブルと同じ partition key を持ち、sort key のみ異なる定義ができる
  - “local” とは、indexが元のテーブルのパーティション（同じ partition key を持つ範囲）に限定されていることを意味する
  - 1つの partition key に対して、ベーステーブルおよびすべての LSI のindex対象アイテムの合計サイズが 10GB を超えてはならない
  - Provisioned throughput settings はベーステーブルと共有される
  - 1つのテーブルにつき最大 5 個まで作成できる

### Choose projections carefully

- Secondary indexesのサイズはできるだけ小さく保つべき
  - なぜなら、storageとprovisioned throughputを消費するため
- indexが小さいほど、テーブル全体をクエリする場合に比べてパフォーマンスの利点が大きくなる
- クエリで頻繁に使用する属性だけをプロジェクションに含めると良い

書き込みが読み込みより多いケース

- indexに書き込むattributesは可能な限り少なくする
  - ただし、index項目のサイズが1KB未満なら、それ以上削減してもスループットの節約にはならない
  - [UpdateItem](https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_UpdateItem.html)で特定のattributeに追加、更新ができそう。
- 非投影属性をQueryで取得すれば読み込みコスト（RCU）は増えるが、indexに含めていると書き込みのたびにその属性もindexに反映され、更新コスト（WCU）が増える。
  - そのため、indexに含めない方がトータルのスループットコストを抑えられる場合がある。(DynamoDB: Non-Projected Attributes とコストの関係を参照)
- [ALL](https://docs.aws.amazon.com/ja_jp/amazondynamodb/latest/developerguide/GSI.html#GSI.Projections)を指定すると、GSIだけで全ての属性を返せるようになる（=テーブルフェッチ不要）
  - GSIに全ての属性が複製されるため、**ストレージと書き込みコストが約2倍になる**

<details markdown="1">

<summary>DynamoDB: Non-Projected Attributes とコストの関係</summary>

## ✅ 状況の例

あなたのテーブル：

| userId | name  | email           | address         |
|--------|-------|------------------|------------------|
| 1      | John  | <john@email.com>  | Tokyo, Japan     |
| 2      | Sarah | <sarah@email.com> | Osaka, Japan     |

---

## 🔍 GSI（グローバルセカンダリindex）

- GSIを作成：`email` をキーにして、`name` だけプロジェクション
- `address` は GSI に含めない（＝Non-Projected Attribute）

---

## 🏃‍♂️ クエリで address も欲しくなった

- GSI に含まれてない属性は、**元のテーブルから追加で読み込む**
- DynamoDB は自動的に元のデータにもアクセスしてくれる(fetches from table)

---

## 💸 コストの違い

| パターン                      | 読み込みコスト（RCU） | 書き込みコスト（WCU） |
|-------------------------------|-------------------------|--------------------------|
| 必要な属性だけ GSI に含める   | 高い（元テーブルも読む）| 低い（更新が軽い）      |
| 全部の属性を GSI に含める     | 低い（GSIだけで完結）   | 高い（毎回GSI更新）     |

---

## 🧾 結論（元の英文の意味）

> GSI に含めない属性（Non-Projected Attributes）もクエリで取得できるが、  
> 読み取りのコスト（RCU）が高くなる。  
> でも、GSI を頻繁に更新するコスト（WCU）と比べると、  
> そのほうが安く済む場合がある。

</details>

### Optimize frequent queries to avoid fetches

- fetches from table とは：クエリで Local Secondary Index (LSI) を使い、プロジェクションされていない属性（projectedされていないattribute） を指定した場合、DynamoDB は自動的にベーステーブル（元のテーブル）からその属性を取得（fetch）して返す。
  - Fetchが発生すると、レイテンシー増加 & 追加I/O発生
- よく使う属性は 必ずIndexにプロジェクションしておく
- 「たまに使う属性」も将来よく使う可能性あり → 最初から含める検討を

## [Sparse indexes](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-indexes-general-sparse-indexes.html)

- sparse index（スパースindex） とは：

DynamoDB のSecondary indexにおいて、
Partition Key や Sort Key が一部のアイテムにしか存在しない場合に構成されるindexのことです。

DynamoDB は、index定義に使われるキーがアイテムに存在する場合にのみ、indexにエントリを書き込みます。

<details markdown="1">
<summary>例：注文管理システム（Open Orders の抽出）</summary>

### 🔸 ベーステーブル：`Orders`

| CustomerId | OrderId | Status     | isOpen | OrderDate   |
|------------|---------|------------|--------|-------------|
| C001       | O001    | Shipped    | ❌     | 2025-01-10  |
| C001       | O002    | Processing | ✅     | 2025-04-10  |
| C002       | O003    | Shipped    | ❌     | 2025-03-10  |
| C002       | O004    | Pending    | ✅     | 2025-04-11  |

- `isOpen` が **存在するアイテム = 未発送（開いている）注文**

---

### 🔸 スパースインデックス：`OpenOrdersIndex`

- **Partition Key**: `CustomerId`  
- **Sort Key**: `isOpen`（or `OrderDate`）

このインデックスに含まれるのは：

| CustomerId | OrderId | isOpen | OrderDate   |
|------------|---------|--------|-------------|
| C001       | O002    | ✅     | 2025-04-10  |
| C002       | O004    | ✅     | 2025-04-11  |

</details>

### [Aggregation](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-gsi-aggregation.html)

DynamoDB Streams + Lambda を使ってデータの変化を検知・集計し、スパースな GSI を活用することで、ほぼリアルタイムに集計結果を高速に取得できるアーキテクチャが構築できます。

1. 元データの変更（追加・更新など）を DynamoDB Streams で検知  
   → テーブルに対する書き込み操作をトリガーとしてストリームにイベントが送られる
2. Lambda 関数が実行され、集計対象データを処理  
   → イベントごとに Lambda が起動して、例えばダウンロード数などを集計
3. 集計結果を別のアイテムとして DynamoDB に書き込み  
   → songIDごと・月ごとのような形式で保存する
4. 必要なクエリ用にスパースな Global Secondary Index (GSI) を作成  
   → 集計結果のみにインデックスが作られ、無駄なデータを含まないため効率的
5. GSI を通じてリアルタイムで集計結果を高速に取得可能  
   → 「月＝2018-01」「ScanIndexForward=False」「Limit=1」などで最新ランキング取得

※ Lambda のリトライによって同じイベントが複数回処理されると、集計値が過大評価される可能性があります。そのため、集計結果は「厳密な値」ではなく「近似値」となることがあります。

### Creating a replica

DynamoDBで グローバルセカンダリーインデックス（GSI）を利用して、元のテーブルと同じキー定義・同じ属性をすべて（ALL）投影（project）することにより、元のテーブルの「レプリカのような役割」を持つ別テーブルが作成できる。

ただし、この方法で作成されたGSIは eventually consistent（結果整合性） であるため、ベーステーブルへの書き込みが即時に反映されるわけではありません。常に短い遅延がある点に注意が必要。
