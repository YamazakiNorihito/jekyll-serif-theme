---
title: "Amazon DynamoDBの基礎知識のメモ"
date: 2024-10-07T07:15:00
tags:
  - AWS
  - DynamoDB
  - NoSQL
description: "自分用のメモとして、DynamoDBのコアコンポーネント（テーブル、アイテム、属性）、プライマリキー、セカンダリインデックス、DynamoDB Streamsについて整理。設計に役立つベストプラクティスも含む"
---

[What is Amazon DynamoDB?](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html)のIf you're a first-time user of DynamoDB, we recommend that you begin by reading the following topics:を順番に読んでいく

## Core components of Amazon DynamoDB

### [Tables, items, and attributes](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.CoreComponents.html)

Amazon DynamoDBは、3つの主要なコアコンポーネントで構成されています。

1. Tables（テーブル）

   - データのストレージとして機能します。
   - Items（item）の集合体であり、データを格納します。
   - 一般的なデータベースのテーブルのような役割を果たします。

2. Items（item）

   - 各テーブルには0個以上のitemが含まれます。
   - itemは、属性（attributes）のグループで構成されています。
   - 各itemはユニークであり、主キー（primary key）を使用して識別されます。
   - 一般的なデータベースの行やレコードに相当します。
   - 主キー以外の属性はスキーマレスで、事前に属性やそのデータ型を定義する必要はありません。
   - 各itemは独自の属性を持つことができ、全てのitemが同じ属性を持つ必要はありません。

3. Attributes（属性）

   - 各itemには1つ以上の属性が含まれます。
   - 属性は、データを格納する最小単位です。
   - 一般的なデータベースのフィールドやカラムに相当します。
   - 多くの属性はスカラー型（文字列や数値などの単一の値）ですが、ネストされた属性もサポートしており、32階層まで深くネスト可能です。

#### [Naming Rules](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.NamingRulesDataTypes.html)

- 全てのName
  - UTF-8でエンコードされる
  - 大文字小文字を区別する
  - Reserved wordsは使用できない
    - [Reserved words in DynamoDB](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ReservedWords.html)
- Table NameとIndex Name
  - 3文字以上255文字以下
  - 使用可能な文字
    - a-z
    - A-Z
    - 0-9
    - _(underscore)
    - -(dash)
    - .(dot)
  - Attribute Name
    - １文字以上
    - 64KB未満

#### [Data Type](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.NamingRulesDataTypes.html#HowItWorks.DataTypes)

AttributeのサポートしているData Type

- Data Types
  - Scalar Types
    - 1つの値しか持たないシンプルな型
    - 対応するType
      - number
        - 最大38桁まで対応
        - DynamoDBに送信する際は「文字列」として送信されるが、内部で数値として扱われる
        - dateやtimestampはepoch time（UNIX時間）として数値で表現可能
      - string
        - UTF-8バイナリエンコーディングを使用したUnicode文字列
        - 空文字（0文字）も使用可能
        - dateやtimestampはISO 8601形式の文字列で表現可能
      - binary
        - 圧縮テキスト、暗号化データ、画像などのバイナリデータを保持できる
        - 空バイト（0 byte）も使用可能
        - Base64形式でDynamoDBに送信し、内部でデコードしてバイト配列に変換される
      - boolean
        - `true` または `false` を扱う
      - null
        - unknown または undefinedの意味で使われる
  - Document Types
    - 複雑なデータ構造を保持する型で、ListやMapが該当
    - 対応するType
      - List
        - 空のListで登録可能
        - 順序が保持される（JSON配列に類似）
        - List内の要素の型が異なっても問題ない
        - 例：
          - FavoriteThings: ["Cookies", "Coffee", 3.14159]
          - key: ["values1", "values2"]
      - Map
        - 空のMapで登録可能
        - 順序は保持されない（JSONオブジェクトに類似）
        - name-valueペアのコレクションを保持
        - Map内の要素の型が異なっても問題ない
        - 例：
          - {Day: "Monday", FavoriteThings: ["Cookies", "Coffee", 3.14159]}
          - {name1: value1, name2: value2}
    - 共通仕様
      - MapやListの中にさらに別のMapやListをネストでき、最大32階層まで許容される
      - List、Mapの要素数に制限はない
      - 空の文字列や空のバイナリ値は、テーブルやインデックスキーでない限り使用可能
      - ListやMap内では、空の文字列や空のバイナリ値も使用可能
      - 空のListやMapは登録可能
  - Set Types
    - 複数のScalar Typesを持つ集合体で、number set, string set, binary setが対応
    - 空のSetは登録不可（エラーとなる）
    - number, string, binaryのいずれか1つの型で要素を持つ
    - Set内の全要素は同じ型でなければならない
    - Set内の値はユニークでなければならない
    - 順序は保持されないため、アプリ側で順序を前提とした実装は避けること

##### data type descriptors(記述子)

| 記述子 | データタイプ     | 説明            |
|--------|------------------|-----------------|
| S      | String           | 文字列          |
| N      | Number           | 数値            |
| B      | Binary           | バイナリ        |
| BOOL   | Boolean          | 真偽値          |
| NULL   | Null             | 無効値          |
| M      | Map              | マップ（辞書）  |
| L      | List             | リスト（配列）  |
| SS     | String Set       | 文字列セット    |
| NS     | Number Set       | 数値セット      |
| BS     | Binary Set       | バイナリセット  |

Document Typesに関してHandsOn

```bash
# Create a DynamoDB table named TestTable
aws dynamodb create-table \
  --table-name TestTable \
  --attribute-definitions AttributeName=ID,AttributeType=S \
  --key-schema AttributeName=ID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --endpoint-url http://localhost:8000

# Response from create-table
{
    "TableDescription": {
        "AttributeDefinitions": [
            {"AttributeName": "ID", "AttributeType": "S"}
        ],
        "TableName": "TestTable",
        "KeySchema": [{"AttributeName": "ID", "KeyType": "HASH"}],
        "TableStatus": "ACTIVE",
        "ProvisionedThroughput": {
            "ReadCapacityUnits": 5,
            "WriteCapacityUnits": 5,
            "NumberOfDecreasesToday": 0
        },
        "TableArn": "arn:aws:dynamodb:ddblocal:000000000000:table/TestTable"
    }
}

# Insert an item with an empty string in the 'Name' attribute
aws dynamodb put-item \
  --table-name TestTable \
  --item '{"ID": {"S": "1"}, "Name": {"S": ""}}' \
  --endpoint-url http://localhost:8000

# Attempt to insert an empty string set (Triggers ValidationException)
aws dynamodb put-item \
  --table-name TestTable \
  --item '{"ID": {"S": "2"}, "Tags": {"SS": []}}' \
  --endpoint-url http://localhost:8000

# Response from put-item with empty string set
An error occurred (ValidationException) when calling the PutItem operation: 
One or more parameter values were invalid: An string set may not be empty

# Insert an item with an empty list in the 'Items' attribute
aws dynamodb put-item \
  --table-name TestTable \
  --item '{"ID": {"S": "3"}, "Items": {"L": []}}' \
  --endpoint-url http://localhost:8000

# Insert an item with a list containing an empty string and a file name
aws dynamodb put-item \
  --table-name TestTable \
  --item '{"ID": {"S": "4"}, "Documents": {"L": [{"S": ""}, {"S": "file1.pdf"}]}}' \
  --endpoint-url http://localhost:8000

# Scan the table to retrieve all items
aws dynamodb scan \
  --table-name TestTable \
  --endpoint-url http://localhost:8000

# Response from scan
{
    "Items": [
        {
            "ID": {"S": "1"},
            "Name": {"S": ""}
        },
        {
            "ID": {"S": "4"},
            "Documents": {
                "L": [{"S": ""}, {"S": "file1.pdf"}]
            }
        },
        {
            "ID": {"S": "3"},
            "Items": {"L": []}
        }
    ],
    "Count": 3,
    "ScannedCount": 3,
    "ConsumedCapacity": null
}

```

#### Best practice

- Names should be meaningful(意味のある) and concise(簡潔)
- Attribute Nameをできるだけ短くすること
  - ReadCapacityUnitsの消費削減に役立つ
  - スループットとストレージコストを削減できる

## DynamoDB Table Classes

DynamoDBには以下の2つのテーブルクラスがあります。

1. **Standard table class**  
   - ほとんどのワークロードに最適  
   - デフォルト設定で推奨される  
2. **Standard-Infrequent Access (DynamoDB Standard-IA) table class**  
   - あまりアクセスされないデータ向け  
   - ストレージコストを重視  
   - **使用例:**
     - アプリケーションログ  
     - 古いソーシャルメディア投稿  
     - Eコマース注文履歴  
     - 過去のゲーム実績  

すべてのTableは上記のいずれかのclassに関連づけられ、  
Secondary Indexも元Tableと同じclassが適用されます。

### StandardとStandard-IAの共通点  

- パフォーマンス  
- 耐久性 (durability)  
- 可用性 (availability)  

Standard-IAはStandardと同様に以下の機能をサポート:

- 自動スケーリング (auto scaling)  
- オンデマンドモード (on-demand mode)  
- 有効期限の設定 (time-to-live, TTL)  
- オンデマンドバックアップ (on-demand backups)  
- 時点復元 (point-in-time recovery, PITR)  
- グローバルセカンダリーインデックス (global secondary indexes)

### DynamoDB Table Classesの変更管理  

- AWS Management Console、AWS CLI、AWS SDKから変更可能  
- CloudFormationでシングルリージョンおよびグローバルテーブルも管理可能  

### 判断基準

| 項目 | Standard | Standard-IA |
|--------|----------|--------------|
| スループットコスト (読み書き) | 低 | 高 |
| ストレージコスト | 高 | 低 |

- ストレージがスループットコストの50%を超える場合、Standard-IAに変更を検討すると良い。  
- 例: 月間でスループットに10,000円かかり、ストレージコストが6,000円の場合、ストレージコストは全体のスループットコストの60%にあたる。このケースでは「50%を超えている」と判断できる。  

AWS Cost and Usage ReportsやAWS Cost Explorerを利用して履歴を確認し、最適なクラスを選択することが推奨される。  

---

### Primary key

Primary Keyは、テーブル内の各Itemを一意に識別するためのキーです。

Primary Keyには2種類があります。

1. Partition key
   1. 1つの属性で構成される単純なPrimary Keyです。
   2. Partition Keyの値はDynamoDBの内部ハッシュ関数の入力として使用され、得られたハッシュ値をもとに異なる物理パーティションに分散してItemが格納されます。
   3. Partition keyはmaxsize `2048 bytes`

2. Partition key and sort key
   1. 2つの属性で構成される複合的なPrimary Keyです。Partition KeyとSort Keyで構成されます。
   2. Partition Keyの値に基づいて、DynamoDBの内部ハッシュ関数が実行され、その結果に応じてデータが物理パーティションに割り当てられます。
   3. Sort Keyは同じPartition Key内でのitemの順序を決定し、DynamoDBはSort Keyの値に基づいてitemをソートして保存します。
   4. 同じPartition Keyを持つ複数のitemを格納できますが、その場合はSort Keyの値が一意である必要があります。
   5. sort keyはmaxsize `1024 bytes`

Partition Keyに許可されているデータ型は、String、Number、Binaryのいずれかです。
補足：

- Partition Keyは"Hash attribute"とも呼ばれ、内部ハッシュ関数に基づきデータが均等に分散されます。
- Sort Keyは"Range attribute"とも呼ばれ、同じPartition Keyを持つitemを物理的に近い場所に並べ、Sort Keyの値でソートします。

## [Secondary indexes](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/SecondaryIndexes.html)

- Secondary indexesは、テーブルのプライマリキーとは異なるキーを使ってクエリを実行するための代替手段。
- 必須ではないが、クエリの柔軟性を高める役割を持つ。
- indexからのデータ取得方法は、テーブルからのデータ取得方法とほぼ同じ。
- すべてのindexはテーブルに所属する。

Secondary Indexesには2種類があります。

1. Global Secondary Index (GSI)  
   - パーティションキーとソートキーの両方を、元のテーブルとは異なるキーで定義できる。
     - パーティションキーだけで定義することも可能です。ソートキーはオプションです。
   - テーブル全体に対してindexを作成する。
   - すべてのパーティションキーをまたいでクエリを実行できる。
   - 最大20個のGSIを作成可能。

2. Local Secondary Index (LSI)  
   - パーティションキーは元のテーブルと同じだが、ソートキーのみ異なるものを設定できる。
   - 同じパーティションキー内のデータに対してindexを作成する。
   - 最大5個のLSIを作成可能。

indexの管理と属性の投影

- DynamoDBはindexを自動で管理:
  - テーブルに対してitemが追加、更新、削除されると、index内の対応するitemも自動的に更新される。
- 投影属性の指定:
  - 最低限プライマリキーが投影される。
  - その他の属性も選択可能で、必要に応じてindexに複製できる。

---

## [DynamoDB Streams](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Streams.html)

オプション機能でDynamoDBテーブルのデータ変更イベントをほぼリアルタイムで記録します。イベントは発生順にストリーム内に表示され、各イベントはstream recordとして表されます。

データ変更イベントは3種類あります：

1. 新しいitemの追加
   1. item全体（全属性を含む）のスナップショットがキャプチャされます。
2. itemの更新
   1. 変更された属性に関して、更新前と更新後のスナップショットがキャプチャされます。
3. itemの削除
   1. 削除される前のitem全体のスナップショットがキャプチャされます。

各stream recordには以下の情報が含まれます：

1. テーブル名
2. イベントのタイムスタンプ
3. その他のメタデータ

stream recordの有効期間は24時間で、その後自動的に削除されます。

## Best practices for designing and architecting with DynamoDB

### Two key concepts for NoSQL design

1. スキーマ設計よりもユースケースの理解を優先する
   - アプリケーションのユースケースやビジネス上の問題を前もって理解することが重要
2. テーブル数を最小限にする
   - スケーラビリティの向上
   - 権限管理の簡素化
   - アプリケーションのオーバーヘッド削減
   - バックアップコストの低減

---

### Approaching NoSQL design

#### Application’s Access Patterns: 必須クエリパターンを理解する

1. Data Size (データ量)
    1. 1回のリクエストで読み書きされるデータ量を把握することが重要。
    2. これにより、効率的にデータをパーティション化するために役立つ。
2. Data Shape (データ形状)
    1. クエリされるデータに応じて、事前にデータを整形して保存する。
    2. これにより、処理速度とスケーラビリティが向上する。
3. Data Velocity (データ速度)
    1. ピーク時のクエリ負荷を予想する。
    2. これにより、データを適切にパーティション化することでI/Oキャパシティを効率的に利用できる。
    3. スケールするとは、"クエリで利用できる物理パーティションを増やし、そのパーティションにデータを分散させる"こと

<details>

<summary>DynamoDBのスケーリングとパーティションの動作</summary>

##### DynamoDBのパーティショニングの基本

DynamoDBは、Partition Key（ハッシュキー）を使ってデータを分散します。このPartition Keyは、データの物理パーティションにどこに格納するかを決めるために使われます。つまり、ハッシュ関数を使ってPartition Keyを計算し、対応する物理パーティションにデータが格納されます。

この仕組みによって、均等にデータが分散されるため、どのクエリも一定の速度で処理されるようになります。これは、DynamoDBが大量のデータとクエリをスケーラブルに処理するための基盤となる仕組みです。

**物理パーティションの役割**

しかし、DynamoDBは負荷やデータ量が増加したとき、自動的に物理パーティションを増やすことで、さらなるスケーリングを実現します。ここで重要なのは、DynamoDBがテーブルのスループット（読み書き容量）やデータサイズに応じて物理パーティションを分けることで、データアクセスの競合を減らし、パフォーマンスを向上させるという点です。

物理パーティションの数が増えると、次のような効果が得られます。

 1. クエリの負荷分散
    1. クエリが各物理パーティションに対して均等に分散されるため、1つのパーティションに対する負荷が集中するのを避けられます。例えば、負荷が1つのパーティションに集中すると、そのパーティションのI/O容量が限界に達し、クエリの速度が低下しますが、物理パーティションが増えれば、負荷が分散され、各パーティションがより少ないデータを処理することになります。
 2. I/O容量の増加
    1. 物理パーティションを増やすことで、DynamoDBはパーティションごとに割り当てられるI/O容量（読み取り/書き込みスループット）も増加させます。これにより、全体のスループットが増え、より多くの同時クエリを効率的に処理できるようになります。

なぜ物理パーティションが増えると速度が上がるのか？

DynamoDBはテーブルに対して物理パーティションを自動で追加することによって、以下のような理由で速度やスケーラビリティが向上します。

 1. 負荷分散の効率化
    1. 1つのパーティションに多くのクエリやデータが集中すると、**「ホットパーティション」**と呼ばれる状態が発生し、そのパーティションのリソースが不足するため、クエリが遅くなることがあります。物理パーティションを増やすことで、データとクエリの負荷を分散させ、各パーティションにかかる負荷を減らすことができます。
 2. パーティションごとのスループットの割り当て
    1. DynamoDBは各パーティションに対して特定の読み取り/書き込みキャパシティを割り当てます。パーティションが増えることで、全体のスループットも増加し、結果的にパフォーマンスが向上します。つまり、物理パーティションが増えることで、各パーティションの処理能力が増強され、クエリや書き込み速度が向上します。

</details>

<details>

<summary>Data Velocityについての例</summary>

##### 例: オンラインショッピングサイトでのDynamoDBスケーリングとセカンダリーインデックス

**シナリオ: セール時のピーククエリ**

オンラインショッピングサイトでは、毎日夜8時にセールが開始されると、以下のクエリが大量に発生すると予想されています。

1. **商品検索クエリのピーク**  
   ユーザーが「スマホケース」など、特定のカテゴリの商品を大量に検索する。

   - **対応策**:  
     DynamoDBで、Global Secondary Index (GSI) を使用して「商品カテゴリ」をパーティションキーに設定します。これにより、「スマホケース」というカテゴリの全商品を素早く検索できるようになります。結果として、ピーク時のクエリ処理を効率化し、スループットを維持できます。

   - **インデックス例**:  
     - パーティションキー: 商品カテゴリ  
     - ソートキー: 商品名

2. **注文履歴クエリのピーク**  
   多くのユーザーがセール後に「自分の注文履歴」を確認する。

   - **対応策**:  
     Local Secondary Index (LSI) を使用して、「ユーザーID」をパーティションキー、「注文日時」をソートキーにしたインデックスを作成します。これにより、ユーザーが自身の最近の注文履歴を素早く取得できるようになり、ピーク時でもスループットが維持されます。

   - **インデックス例**:  
     - パーティションキー: ユーザーID  
     - ソートキー: 注文日時

</details>

### you can organize data according to general principles that govern performance: パフォーマンスを左右する一般的な原則に従ってデータを整理

1. Keep related data together (リレーショナルデータは一緒にまとめる)
   1. “locality of reference"の原則(principle)に従う。
      1. 関連データを近くに置くことで、アクセス時のパフォーマンス向上が期待できるという考え
   2. 関連するデータを一つの場所(テーブル)に一緒にまとめる
      1. これは必ずしもリレーショナルデータを1つのItemにすることを意味するわけではない。
   3. 一般的なルールとして、DynamoDBアプリケーション内ではできるだけ少ないテーブルを維持するべき
      1. 例外として、高トラフィックな時系列データや、アクセスパターンが大きく異なるデータセットの場合は、複数のテーブルを使用することが適切。
2. Use sort order(sort keyを使う)
   1. データのグルーピングとは、PartitionKeyを同じにし、SortKeyを使って関連するデータを識別・整理すること
   2. これによりクエリが効率的になる
      1. PartitionKeyだけで検索すれば、そのキーに対応するすべてのデータ（同じグループのデータ）が一括で取得できます
      2. SortKeyを日付などに設定しておけば、範囲クエリが効率的にできます。
   3. この考えはNoSQLにおいて、重要なデザイン戦略
3. Distribute queries (クエリを分散させる)
   1. [Using write sharding to distribute workloads evenly in your DynamoDB table](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-partition-key-sharding.html)
   2. `hot spots`とは、特定の物理パーティションにクエリが集中することで、そのパーティションのI/Oキャパシティを超え、結果として`latency`(遅延時間)が増大し、パフォーマンスが低下する現象です。
   3. 特定の`partition key`にクエリが集中しないようにするため、キー設計を工夫する必要があります。
      1. 例えば、`partition key`が `log001` の場合:
         - 元々のキーが `log001` だとすると、クエリが集中してホットスポットが発生する可能性があります。
         - そこで、`log001-2014-07-09.1`や`log001-2014-07-09.2` のように、同じ `log001` を分割して使用することでトラフィックを均等に分散させます。
4. Use global secondary indexes(GSIを使う)
   1. テーブル自体が持つキーとは異なるキーに基づいた効率的なクエリが可能になります。
   2. 非常に高速かつ比較的安価に実行できる

<details>

<summary>DynamoDBにおける反転インデックスの例</summary>

反転インデックス（inverted index）は、データベースや検索エンジンで使用される索引の一種で、一般的には特定の値がどのレコード（アイテム）に関連しているかを素早く見つけるための仕組みです。DynamoDBのコンテキストでは、反転インデックスはテーブルの構造を最適化するために使用され、クエリやスキャンのパフォーマンスを向上させるための技法です。

**DynamoDBにおける反転インデックスの例**

DynamoDBでは「単一テーブル設計」を使用することが一般的で、その中で反転インデックスを活用して、異なるクエリパターンに対応できるようにすることができます。この場合、Global Secondary Index（GSI）を反転インデックスとして設定します。
通常の設計では、パーティションキーとソートキーの組み合わせでデータを検索します。しかし、あるクエリでは別の項目をキーとして検索したい場合があるかもしれません。そこで、反転インデックスを使用すると、検索したい項目を新たなインデックス（GSI）に割り当てることができます。

具体例：
例えば、ユーザー情報を管理するテーブルがあるとします。このテーブルは以下の2つのフィールドを持っているとしましょう：

- userId: ユーザーID（パーティションキー）
- email: メールアドレス

通常、このテーブルはuserIdでクエリされますが、時にはemailでユーザーを探したいこともあるでしょう。そこで、反転インデックスを設定すると、emailをパーティションキーとした別のインデックスが作られ、メールアドレスでのクエリが高速化されます。

```plaintext
Main Table:
Partition Key: userId
Sort Key: email

Inverted Index (GSI):
Partition Key: email
Sort Key: userId
```

</details>

## DynamoDB API

### 管理操作(Control plane)

以下は管理操作ができるAPIです。

- CreateTable
  - テーブル作成する
  - オプション
    - 複数のsecondary indexesの作成
    - DynamoDB Streamの有効
- DescribeTable
  - テーブルの情報を取得する
    - primary key schema
    - throughput settings
    - secondary indexes information
- ListTables
  - すべてのテーブル名をリストで取得する
- UpdateTable
  - テーブルの設定またはindexを更新する
    - indexは作成や削除が可能
    - dynamoDB Stream の設定を更新
- DeleteTable
  - テーブルを削除する
    - 依存するすべてのオブジェクトも削除される

### データ操作(Data plane)

テーブル内のデータに対してCRUD 操作を行うAPI。
データを処理する操作には、PartiQLとclassic APIsの２種類ある。

#### [PartiQL - A SQL-compatible query language](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ql-reference.html)

PartiQL の読み方は 「パーティークエル」

- ExecuteStatement
  - 1つのテーブルから複数のアイテムを読み取る
  - 1つのアイテムに対して、書き込みや更新が可能
    - 操作にはprimary keyを指定する必要がある
- BatchExecuteStatement
  - 1つのテーブルから複数のアイテムに対して、書き込み、更新、または読み取りを実行する
  - ExecuteStatementより効率的
    - 1回のネットワーク往復で操作を完了できる

#### Classic APIs

- Creating data
  - PutItem
    - 1つのItemを書き込む
      - 操作にはprimary keyを指定する必要がある
      - primary key以外のattributesは指定しなくてもよい
  - BatchWriteItem
    - 上限25のItemをを書き込む
    - PutItemを複数呼ぶより効率的
      - 1回のネットワーク往復で操作を完了できる
- Reading data
  - GetItem
    - 1 Itemを取得する
      - 操作にはprimary keyを指定する必要がある
      - アイテム全体、または一部のattributesを選択できる
  - BatchGetItem
    - 複数のテーブルから上限100 Itemを取得する
    - GetItemを複数呼ぶより効率的
      - 1回のネットワーク往復で操作を完了できる
  - Query
    - 指定したpartition keyを持つ全てのItemを取得する
      - 操作にはpartition keyを指定する必要がある
      - アイテム全体、または一部のattributesを選択できる
    - オプション
      - sort keyに対して条件を適用し、取得するアイテムを絞り込むことができる
      - この操作は、partition keyとsort keyを持つテーブルまたはインデックスに対してのみ使用できる
  - Scan
    - 全てのItemを取得する
      - アイテム全体、または一部のattributesを選択できる
    - オプション
      - filtering condition を使用して、必要なアイテムのみ取得する
- Updating data
  - UpdateItem
    - Item内の1つ以上のattributesを更新する
      - 操作にはpartition keyを指定する必要がある
    - 新しい属性の追加、既存の属性の削除が可能
    - 条件付き更新ができる
      - 更新成功と判断されるのはユーザー定義の条件を満たすとき
    - オプション
      - [Atomic counter](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithItems.html#WorkingWithItems.AtomicCounters)の実装ができる
        - 数値属性をインクリメントまたはデクリメントする
- Deleting data
  - DeleteItem
    - テーブルから1つのItemを削除する
      - 操作にはpartition keyを指定する必要がある
  - BatchWriteItem
    - Deletes up to 25 items from one or more tables. This is more efficient than calling DeleteItem multiple times because your application only needs a single network round trip to delete the items.
    - 上限25のItemを削除する
      - 操作にはpartition keyを指定する必要がある
      - DeleteItemを複数呼ぶより効率的
        - 1回のネットワーク往復で操作を完了できる

##### Atomic counters

Atomic countersとは、ロックを使わずに、効率的にスレッドセーフなインクリメントやデクリメントを実行する仕組み。
[[AWS Developer Guide]Atomic counters](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/WorkingWithItems.html)
[[Blog]Implement resource counters with Amazon DynamoDB](https://aws.amazon.com/jp/blogs/database/implement-resource-counters-with-amazon-dynamodb/)

特徴:

- 他のWrite Requestに干渉しない
  - incrementやdecrementは、他の書き込み操作に影響されず、受信した順番通りに適用されます。
- 冪等ではない
  - UpdateItem 操作は冪等ではありません。
  - UpdateItem 操作が繰り返し実行されると、値がそのたびに増減します。これにより、操作が失敗してリトライが発生した際に、incrementやdecrementが生じる可能性があります。
- overcounting&undercounting
  - UpdateItem 操作のリトライによって「overcounting」や「undercounting」が起きる可能性がある
    - 正確な数値が求められる場合、誤差が許されないケースでは条件付き更新が推奨されます。

**Atomic Counter**

```bash
aws dynamodb update-item \
    --table-name ProductCatalog \
    --key '{"Id": { "N": "601" }}' \
    --update-expression "SET Price = Price + :incr" \
    --expression-attribute-values '{":incr":{"N":"5"}}' \
    --return-values UPDATED_NEW
```

**条件付き更新**
条件付き更新を使用することで、特定の条件が満たされている場合のみ値を更新できます。これにより、過剰計数や不足計数を防ぐことができます。

```bash
aws dynamodb update-item \
    --table-name ProductCatalog \
    --key '{"Id": { "N": "601" }}' \
    --update-expression "SET Price = Price + :incr" \
    --expression-attribute-values '{":incr":{"N":"5"}, ":currentPrice":{"N":"100"}}' \
    --condition-expression "Price = :currentPrice" \
    --return-values UPDATED_NEW
```

### DynamoDB Streams
