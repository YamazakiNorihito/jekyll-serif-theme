---
title: "MySQL のメモ"
date: 2024-02-16T11:24:00
jobtitle: ""
linkedinurl: ""
weight: 7
---


# [実行計画(EXPLAIN ステートメント)](https://dev.mysql.com/doc/refman/8.0/ja/explain.html)

```sql
EXPLAIN select * from messages

-- 実行結果
/*
# id, select_type, table, partitions, type, possible_keys, key, key_len, ref, rows, filtered, Extra

'1', 'SIMPLE', 'messages', NULL, 'ALL', NULL, NULL, NULL, NULL, '997277', '100.00', NULL

*/
```

| Column        | Description |
|---------------|-------------|
| `id`          | SELECT識別子。同一のクエリ内でのSELECT文の順番や、サブクエリやUNIONなどの関係を示す。 |
| `select_type` | SELECTクエリのタイプ。例えば、`SIMPLE`（単純SELECT）、`SUBQUERY`（サブクエリ内のSELECT）、`UNION`（UNIONの2番目以降のSELECT）などがある。 |
| `table`       | クエリが参照しているテーブル名。 |
| `partitions`  | クエリが参照しているパーティション。パーティショニングされていない場合はNULL。 |
| `type`        | ジョインのタイプ。例えば、`ALL`（フルテーブルスキャン）、`index`（インデックス全スキャン）、`range`（範囲指定によるインデックス使用）など。 |
| `possible_keys` | クエリ実行時に使用可能なインデックス。 |
| `key`         | 実際にクエリで使用されているインデックス。 |
| `key_len`     | 使用されているインデックスの長さ。 |
| `ref`         | インデックスを検索する際に参照されるカラムや定数。 |
| `rows`        | クエリ実行によって読み込まれる行数の推定値。 |
| `filtered`    | テーブルの行がクエリの条件にどれだけマッチするかのパーセンテージ。 |
| `Extra`       | クエリ実行に関する追加情報。例えば、`Using index`（インデックスのみを使用してデータを取得）、`Using where`（WHERE条件を使用する）、`Using temporary`（一時テーブルを使用する）、などがある。 |

### `select_type`
- **`SIMPLE`**: 単純なSELECTクエリで、サブクエリやUNIONが使われていない場合。
- **`PRIMARY`**: サブクエリやUNIONの最も外側のSELECT。
- **`SUBQUERY`**: サブクエリ内のSELECT。最も外側ではないSELECT文。
- **`DERIVED`**: FROM句内のサブクエリで生成された一時テーブルを参照するSELECT。
- **`UNION`**: UNIONによって結合された二番目以降のSELECTクエリ。
- **`UNION RESULT`**: UNIONクエリの結果を含む一時テーブル。

### `type`
- **`ALL`**: フルテーブルスキャン。テーブルの全行がスキャンされる。
- **`index`**: インデックス全スキャン。インデックスの全エントリがスキャンされる。
- **`range`**: 範囲スキャン。インデックスを使って特定の範囲の行が検索される。
- **`ref`**: インデックスを使って、一つまたは複数の値で行が検索される。
- **`eq_ref`**: 主キーまたはユニークキーのインデックスを使って、単一の行が検索される。
- **`const`**: 主キーまたはユニークキーによって、単一の行が検索される。クエリ実行時に結果が定数として扱われる。
- **`system`**: テーブルに一行のみ存在する（または空の場合）。クエリ実行時に結果が定数として扱われる。

### `Extra`
- **`Using index`**: クエリがインデックスのみを使用してデータを取得し、テーブルの行を読み込む必要がない場合。
- **`Using where`**: WHERE句を使用して、特定の行をフィルタリングする場合。
- **`Using temporary`**: クエリの結果を格納するために一時テーブルを使用する場合。例えば、ORDER BYやGROUP BYを含むクエリで一時テーブルが必要な場合。
- **`Using filesort`**: MySQLが結果をソートするために外部のソート操作を使用する場合。インデックスを利用できないソート処理に使われる。


# [SHOW STATUS ステートメント](https://dev.mysql.com/doc/refman/8.0/ja/show-status.html)
## MySQLサーバーに接続されているスレッドの数
```sql
SHOW STATUS WHERE `variable_name` = 'Threads_connected';
```