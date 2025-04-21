---
title: "Amazon DynamoDBのBest practicesのメモ"
date: 2024-10-7T07:15:00
mermaid: true
weight: 7
tags:
  - AWS
  - DynamoDB
  - NoSQL
description: "自分用のメモとして、DynamoDBのBestプラクティスを書き留める"
---

# Amazon DynamoDBのBest practicesのメモ

## [NoSQL design](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-general-nosql-design.html)

### RDBMS と NoSQL（DynamoDB）の違い

| 項目       | RDBMS                                                | NoSQL（DynamoDB）                                                                 |
|------------|------------------------------------------------------|-----------------------------------------------------------------------------------|
| 強み       | - クエリが柔軟（JOIN・複雑な条件に対応）             | - 限られた方法でのクエリは高速・低コスト                                        |
| 弱み       | - クエリコストが高い<br>- 高トラフィックに弱い       | - クエリ方法が限られる<br>- それ以外の方法はコストが高く遅い   <br>- リレーション（JOIN）を使えません                 |
| 設計方針   | - 実装や内部構造をあまり意識せず設計できる<br>- クエリ最適化はスキーマに大きな影響を与えない<br>- 正規化が重要 | - よく使うクエリを高速・低コストにするための設計が必要<br>- アクセスパターンに最適化した設計が必要 |

### NoSQLを設計する上で２つの考え

1. まず何を解決したいか（ビジネス課題やユースケース）をはっきりさせてから、DynamoDBのスキーマ（データ構造）を設計するべき。
   1. 理由は、RDBMS と NoSQL（DynamoDB）の違いのデメリット
2. 使用するテーブルの数はなるべく少なくする
   1. そのほうがスケーラブル（拡張しやすく）、
   2. 権限の管理も楽で、
   3. 運用の負担が減るし、
   4. バックアップコストも安くなる。

### Approaching NoSQL design

**STEP 1: クエリパターンを定義する**

特に理解しておくべきアクセスパターンの3つの特性

- Data size
  - 1回のリクエストで「どのくらいの量のデータを書き込むか・読み込むか」を把握しておくこと
- Data shape
  - 「後で整える」のではなく「最初から整えて保存」
    - RDBMSのように、クエリのたびに JOIN などでデータを集めて整形するのではなく
      - NoSQL では、あらかじめ「そのクエリで必要になるデータ」を一つのアイテムにまとめて保存しておく
- Data velocity（データアクセス頻度）
  - アクセスの偏り（≒velocityのピーク）をあらかじめ予測して設計
    - 単位時間(秒・分・時間単位)でどの操作どの操作が、いつ、どれくらいの頻度で行われるのか
      - 例：1秒間にGetItemが1000回
      - 例：毎分100回の書き込み
      - 例：夜9時〜10時だけ急にアクセスが集中する
    - アクセスが偏るキーはどれか
      - 同じキーにばかりアクセスが集中しないか？
        - 例：みんな userId = "admin" にアクセスしている
        - 例：timestamp = "2025-04-01" だけにアクセスしてる

**STEP 2: 一般原則に従ってデータを整理する**

- Keep related data together
  - 'locality of reference'の原則に従う
    - 関連するデータは同じパーティションにまとめて保存する（DynamoDBのPartition Key設計）
  - DynamoDBの一般的な設計ルール
    - テーブルはできる限り1つにまとめるのが理想
      - 単一テーブル設計では、inverted indexes（GSI/LSI）を活用して、様々なアクセスパターンに対応できる
      - 例外もある
        - 時系列データ
        - アクセスパターンが大きく異なるデータ
- Use sort order
  - 関連するデータは同じパーティションにまとめてあり、sort key によって自動で並べられている
  - クエリ時に順序の指定が不要なので効率が良い
  - また、sort key は範囲検索などに使えるので、アクセスパターンに合わせて活用する
- Distribute queries
  - クエリが特定のパーティションキーに集中すると、I/O 制限に引っかかりパフォーマンスが低下する（ホットスポットになる）
  - そのため、パーティションキーの設計によってアクセスをできるだけ分散させる必要がある
  - ランダム性や日付＋識別子などを組み合わせて、複数パーティションに均等に分散するよう工夫する
- Use global secondary indexes
  - メインテーブルのキー構造だけでは対応できないクエリがある場合、GSIを使って別の視点からアクセスできるようにする
  - GSIは独自のパーティションキー・ソートキーを持ち、異なるアクセスパターンに対応できる
  - GSIを活用すれば、複数の効率的なクエリを実現しつつ、パフォーマンスとコストも抑えられる

### [Partition key design](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-partition-key-design.html)

- 読み取りコストの基準は **4 KB/RCU**、書き込みコストの基準は **1 KB/WCU**。
- 各パーティションは最大 **3,000 RCU/秒** を処理できる。
- 各パーティションは最大 **1,000 WCU/秒** を処理できる。
- **強い整合性** で 4 KB までのitem 1 件を読むと **1 RCU** 消費する。
- **結果整合性** で 4 KB までのitem 1 件を読むと **0.5 RCU**（課金は切り上げ）を消費する。つまり **1 RCU** で 2 件まで読める。
- itemサイズが **20 KB** の場合、1 つの強い整合性 read で **5 RCU** を消費する。
- パーティションあたりの最大スループットが **3,000 RCU/秒** なので、1 パーティションにおいて **同時に 600 回の read オペレーション**（= 3000 / 5）が可能。
- 読み取りスループットはitemサイズに比例して RCU を多く消費するため、**大きなitemはスループット制限を早く使い切る**。
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
  - 並列で1つのパーティションに複数のitemを書き込むと、そのパーティションに割り当てられたWCU（Write Capacity Unit）を超えてスロットリングされる。
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

1. `v0_` itemに、最新バージョンの Sort Key や ID を記録する。
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
  - 1つの partition key に対して、ベーステーブルおよびすべての LSI のindex対象itemの合計サイズが 10GB を超えてはならない
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
Partition Key や Sort Key が一部のitemにしか存在しない場合に構成されるindexのことです。

DynamoDB は、index定義に使われるキーがitemに存在する場合にのみ、indexにエントリを書き込みます。

<details markdown="1">
<summary>例：注文管理システム（Open Orders の抽出）</summary>

### 🔸 ベーステーブル：`Orders`

| CustomerId | OrderId | Status     | isOpen | OrderDate   |
|------------|---------|------------|--------|-------------|
| C001       | O001    | Shipped    | ❌     | 2025-01-10  |
| C001       | O002    | Processing | ✅     | 2025-04-10  |
| C002       | O003    | Shipped    | ❌     | 2025-03-10  |
| C002       | O004    | Pending    | ✅     | 2025-04-11  |

- `isOpen` が **存在するitem = 未発送（開いている）注文**

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
3. 集計結果を別のitemとして DynamoDB に書き込み  
   → songIDごと・月ごとのような形式で保存する
4. 必要なクエリ用にスパースな Global Secondary Index (GSI) を作成  
   → 集計結果のみにインデックスが作られ、無駄なデータを含まないため効率的
5. GSI を通じてリアルタイムで集計結果を高速に取得可能  
   → 「月＝2018-01」「ScanIndexForward=False」「Limit=1」などで最新ランキング取得

※ Lambda のリトライによって同じイベントが複数回処理されると、集計値が過大評価される可能性があります。そのため、集計結果は「厳密な値」ではなく「近似値」となることがあります。

### Creating a replica

DynamoDBで グローバルセカンダリーインデックス（GSI）を利用して、元のテーブルと同じキー定義・同じ属性をすべて（ALL）投影（project）することにより、元のテーブルの「レプリカのような役割」を持つ別テーブルが作成できる。

ただし、この方法で作成されたGSIは eventually consistent（結果整合性） であるため、ベーステーブルへの書き込みが即時に反映されるわけではありません。常に短い遅延がある点に注意が必要。

## [Large items](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-use-s3-too.html)

今の所扱う予定ないので読まない

## [Time series data](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-time-series.html)

今の所扱う予定ないので読まない

## [Many-to-many relationships](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-adjacency-graphs.html)

今の所扱う予定ないので読まない

## [Querying and scanning](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-query-scan.html)

---

### データ取得の4つの方法

1. [ExecuteStatement](https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_ExecuteStatement.html) or [BatchExecuteStatement](https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_BatchExecuteStatement.html)
   1. どちらも PartiQL（SQLライクな言語）を使って DynamoDB を操作する。
   2. BatchExecuteStatement は複数のステートメントを一括で実行できる。
   3. ExecuteStatement は単一のステートメントのみ実行可能。
2. [GetItem](https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_GetItem.html) or [BatchGetItem](https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_BatchGetItem.html)
   1. どちらも Primary Keyを指定して、itemに直接アクセスする方式で、非常に効率的。
   2. BatchGetItem は複数のitem（最大100件）を一括取得できる。
   3. GetItem は単一のitemを取得する。
3. [Query](https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_Query.html)
   1. 指定した Partition Key に一致するすべてのitemを取得する。
   2. Sort Key に条件（Condition）を指定することで、その条件に一致する一部のitem（subset）だけを絞り込んで取得できる。
4. [Scan](https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_Scan.html)
   1. テーブル内すべてのitemを取得する。

---

### Scan の注意点

Scanはテーブルまたはインデックス全体を順に読み取るため、DynamoDBの中で最も非効率な読み取り操作です。
特に、対象のデータがテーブルの一部でしかない場合でも全アイテムを検査するため、スループットやレイテンシへの影響が大きくなります。
また、`filters`処理は、Table全体をScanに対してさらに対象外の値を取り除くという余計なStepが発生します。

---

### PartiQL（SQLライクな言語） の注意点

SELECT 文は、条件によっては Scan（全件スキャン）として実行される可能性があります。
公式ドキュメント：[PartiQL select statements for DynamoDB](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ql-reference.select.html?utm_source=chatgpt.com)

WHERE 句で Partition Key を使わずに、他の属性に対して = や IN を使った場合、DynamoDB は内部的に Scan を実行します。

急なスパイクを回避するためにread and write capacity unit は設定すべき。

---

### `Scan`のパフォーマンス影響を抑えるテクニック

1. ページサイズを減らす
   1. Limit パラメータを使って 1 回の Query / Scan リクエストで取得するアイテム数（ページサイズ）を減らせる。
   2. 小さなリクエストが分散されるため、リクエスト間に「間（pause）」ができてスロットリングのリスクが下がる。
2. Scan用の独立したTableを使う
   1. a "mission-critical" table, and a "shadow" table.の2つを作成する。
      1. アプリケーションは両方のテーブルに同じデータを書き込むことで、整合性を保ちつつ、スキャンの負荷を本番トラフィックから切り離す。
   2. スキャン処理はシャドウテーブル上で行うことで、"mission-critical" tableのパフォーマンスに影響を与えない。

### スパイク対策：Exponential Backoff の導入

たまに、ワークロードの一時的なスパイクによって provisioned throughput を超えてレスポンスコードが返されることがあります。
そのような場合に備えて、アプリケーション側では exponential backoff（指数バックオフ） を用いた リトライ処理 を実装しておくと良いでしょう。

詳細は公式ガイドへ →
[Error retries and exponential backoffの実装情報](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Programming.Errors.html#Programming.Errors.RetryAndBackoff)

### parallel scanを使う条件

1. 20GB以上のテーブル
2. プロビジョンドのリードスループットがフルに使われていない
3. Sequential Scan（直列スキャン）が遅すぎる

[並列Scan](https://docs.aws.amazon.com/ja_jp/amazondynamodb/latest/developerguide/Scan.html#Scan.ParallelScan)するときのTotalSegmentsの値の決め方
**TotalSegments** は、DynamoDBのテーブル全体をいくつの部分（セグメント）に分けて並列スキャンするかを決める数。

- クライアント側の**同時実行できるスレッド数**などのリソース状況に応じて、TotalSegments を調整する。  
- 調整の目安：  
  - スループット余ってるのにスキャンが遅い → TotalSegments を**増やす**  
  - スループット使いすぎて他に影響出る → TotalSegments を**減らす**  

## [Global table design](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-global-table-design.html)

そこまで頭が回らないので読まない

## [Control plane](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-control-plane.html)

今の所扱う予定ないので読まない

## Bulk data operations

今の所扱う予定ないので読まない

## [Implementing version control](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/BestPractices_ImplementingVersionControl.html)

今の所扱う予定ないので読まない

## [Billing and Usage Reports](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-understanding-billing.html)

そこまで頭が回らないので読まない

## [Migrating a DynamoDB table from one account to another](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-migrating-table-between-accounts.html)

今の所扱う予定ないので読まない

## [DAX prescriptive guidance](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/dax-prescriptive-guidance.html)

今の所扱う予定ないので読まない
