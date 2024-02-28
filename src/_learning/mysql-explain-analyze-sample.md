---
title: "mysql-explain-analyze-sample"
date: 2024-02-27T15:27:00
jobtitle: ""
linkedinurl: ""
weight: 7
---

### クエリの実行計画解説

クエリの実行計画は、データベースがSQLクエリをどのように実行するかの詳細を提供します。以下の実行計画を分析しました：



```sql
set @ownerId = 4242;
set @hospitalId = 21;

EXPLAIN ANALYZE SELECT 
    (SELECT 
            contactName
        FROM
            contacts
                INNER JOIN
            phone_numbers ON contacts.id = phone_numbers.contactId
        WHERE
            phone_numbers.phoneNumber = `call`.pairPhoneNumber
                AND contacts.hospitalId = @hospitalId
        LIMIT 1) AS display_contacts
FROM
    (SELECT 
        *
    FROM
        calls
    WHERE
        `type` = 1 AND `ownerId` = @ownerId) `call`
ORDER BY `call`.`callAt`
LIMIT 0 , 1000

```

```text
-> Limit: 1000 row(s)  (cost=3974 rows=1000) (actual time=440..442 rows=1000 loops=1)
    -> Sort: callAt, limit input to 1000 row(s) per chunk  (cost=3974 rows=4277) (actual time=440..442 rows=1000 loops=1)
        -> Filter: (calls.`type` = 1)  (cost=3974 rows=4277) (actual time=9.37..436 rows=4277 loops=1)
            -> Index lookup on calls using index_calls_owner (ownerId=(@ownerId))  (cost=3974 rows=4277) (actual time=9.35..434 rows=4277 loops=1)
-> Select #2 (subquery in projection; dependent)
    -> Limit: 1 row(s)  (cost=1138 rows=1) (actual time=17.8..17.8 rows=0.767 loops=1000)
        -> Nested loop inner join  (cost=1138 rows=137) (actual time=17.8..17.8 rows=0.767 loops=1000)
            -> Index lookup on contacts using index_contacts_extensionNumber (hospitalId=(@hospitalId))  (cost=564 rows=1299) (actual time=0.456..5.85 rows=1060 loops=1000)
            -> Filter: (phone_numbers.phoneNumber = calls.pairPhoneNumber)  (cost=0.336 rows=0.105) (actual time=0.0105..0.0105 rows=724e-6 loops=1.06e+6)
                -> Index lookup on phone_numbers using indeex_phonenumber_contact (contactId=contacts.id)  (cost=0.336 rows=1.05) (actual time=0.0085..0.00956 rows=0.486 loops=1.06e+6)
```



#### 解説

- **Limit**: 最初に1000行の制限が設定されています。これは、クエリの結果が1000行に限定されることを意味します。
- **Sort**: 結果は`callAt`でソートされ、各チャンクで1000行に限定されます。
- **Filter**: `calls.type = 1`でフィルタリングされ、タイプが1の通話記録のみが選択されます。
- **Index Lookup**: `index_calls_owner`を使用して`ownerId`に基づくインデックスルックアップが行われます。
- **サブクエリ**: 各ループで1行を返すように制限されており、内部的にネストされたループ結合を使用しています。

### クエリの総コスト計算

クエリの総コストは、メインクエリとサブクエリのコストを合計して計算されます。

- **メインクエリのコスト**: `3974`
- **サブクエリのコスト**: `1138` (各実行におけるコスト)
- **サブクエリの実行回数**: `1000` (メインクエリが処理する行数)

クエリ全体の総コストは、以下の計算により`1,141,974`となります。

```javascript
const mainQueryCost = 3974;
const subQueryCostPerExecution = 1138;
const numberOfExecutions = 1000;

// サブクエリの総コスト
const totalSubQueryCost = subQueryCostPerExecution * numberOfExecutions;

// クエリ全体の総コスト
const totalCost = mainQueryCost + totalSubQueryCost;

console.log(totalCost);
```
