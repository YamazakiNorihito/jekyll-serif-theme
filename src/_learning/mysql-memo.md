---
title: "MySQL のメモ"
date: 2024-02-16T11:24:00
jobtitle: ""
linkedinurl: ""
weight: 7
tags:
  - MySQL
  - SQL
  - EXPLAIN
  - Database Performance
  - Query Optimization
  - Database Management
  - SQL Indexing
  - MySQL EXPLAIN ANALYZE
  - MySQL SHOW STATUS
  - Disk Management
  - Query Execution Plan
  - MySQL Table Size
  - SQL Error Handling
  - MySQL Binary Logs
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

## [MySQL 8.0.18 では、EXPLAIN ANALYZE](https://dev.mysql.com/doc/refman/8.0/ja/explain.html)

```sql
EXPLAIN analyze select * from messages

-- 実行結果
/*
# EXPLAIN
'-> Table scan on messages  (cost=198 rows=1900) (actual time=4.43..23 rows=1900 loops=1)\n'

*/
```

# [SHOW STATUS ステートメント](https://dev.mysql.com/doc/refman/8.0/ja/show-status.html)

## MySQLサーバーに接続されているスレッドの数

```sql
SHOW STATUS WHERE `variable_name` = 'Threads_connected';
```

## table status

```sql
SHOW TABLE STATUS LIKE 'messages';
```

# [tableのSize](https://dev.mysql.com/doc/refman/8.0/ja/information-schema-introduction.html)

```sql
SELECT 
  TABLE_SCHEMA AS `Database`, 
  TABLE_NAME AS `Table`, 
  ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) AS `Size in MB`
FROM 
  information_schema.TABLES
WHERE 
  TABLE_SCHEMA = 'ここにデータベース名を指定'
ORDER BY 
  (DATA_LENGTH + INDEX_LENGTH) DESC;
```

# [統計情報更新](https://dev.mysql.com/doc/refman/8.0/ja/analyze-table.html)

```sql
ANALYZE TABLE {tableName}

--　複数(カンマまで繋げる)
ANALYZE TABLE {tableName1},{tableName2}
```

# [クエリキャッシュの SELECT オプション](https://dev.mysql.com/doc/refman/5.7/en/query-cache-in-select.html)

クエリ キャッシュは MySQL 5.7.20 で非推奨となり、MySQL 8.0 では削除されました。

```sql
select SQL_CACHE id from message;
```

# エラー対応

1. case1

```bash
Error Code: 3675. Create table/tablespace 'states' failed, as disk is full
```

  1. システム全体のディスク使用状況を確認

     ```bash
      df -h | sort -r -k 5,5
     ```

  2. 使用率が高いファイルシステムの特定<参考サイト　[CentOS ディスク容量不足の原因調査＆MySQLのバイナリログ自動削除設定](https://qiita.com/myzkyy/items/53e985cf028e3c3edfe5)>

      <details><summary>実際の調査コマンド</summary>

        ```bash
            bash-4.4# du -sh /*
            0 /bin
            4.0K /boot
            0 /dev
            28K /docker-entrypoint-initdb.d
            0 /entrypoint.sh
            3.1M /etc
            4.0K /home
            0 /lib
            0 /lib64
            4.0K /media
            4.0K /mnt
            4.0K /opt
            du: cannot read directory '/proc/1/task/1/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/208/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/211/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/212/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/213/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/214/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/215/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/216/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/217/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/218/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/219/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/220/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/222/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/223/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/224/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/225/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/226/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/227/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/232/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/233/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/234/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/235/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/236/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/237/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/238/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/239/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/240/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/241/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/245/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/246/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/247/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/248/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/249/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/250/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/251/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/252/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/253/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/255/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/256/fdinfo': Permission denied
            du: cannot read directory '/proc/1/task/257/fdinfo': Permission denied
            du: cannot read directory '/proc/1/map_files': Permission denied
            du: cannot read directory '/proc/1/fdinfo': Permission denied
            du: cannot access '/proc/281/task/281/fd/3': No such file or directory
            du: cannot access '/proc/281/task/281/fdinfo/3': No such file or directory
            du: cannot access '/proc/281/task/283/fd/3': No such file or directory
            du: cannot access '/proc/281/task/283/fdinfo/3': No such file or directory
            du: cannot access '/proc/281/fd/3': No such file or directory
            du: cannot access '/proc/281/fdinfo/3': No such file or directory
            0 /proc
            20K /root
            32K /run
            0 /sbin
            4.0K /srv
            0 /sys
            4.0K /tmp

            541M /usr
            39G /var
            bash-4.4# 
            bash-4.4# du -sh /var/*
            4.0K /var/adm
            28K /var/cache
            4.0K /var/db
            4.0K /var/empty
            4.0K /var/ftp
            4.0K /var/games
            4.0K /var/gopher
            12K /var/kerberos
            39G /var/lib
            4.0K /var/local
            0 /var/lock
            4.0K /var/log
            0 /var/mail
            4.0K /var/nis
            4.0K /var/opt
            4.0K /var/preserve
            0 /var/run
            12K /var/spool
            4.0K /var/tmp
            4.0K /var/yp
            bash-4.4# du -sh /var/lib/*
            16K /var/lib/alternatives
            988K /var/lib/dnf
            4.0K /var/lib/games
            4.0K /var/lib/misc
            39G /var/lib/mysql
            4.0K /var/lib/mysql-files
            4.0K /var/lib/mysql-keyring
            11M /var/lib/rpm
            4.0K /var/lib/rpm-state
            8.0K /var/lib/selinux
            4.0K /var/lib/supportinfo
            bash-4.4# du -sh /var/lib/mysql/*
            192K /var/lib/mysql/#ib_16384_0.dblwr
            8.2M /var/lib/mysql/#ib_16384_1.dblwr
            101M /var/lib/mysql/#innodb_redo
            804K /var/lib/mysql/#innodb_temp
            44K /var/lib/mysql/0b8459b69ac1.log
            148K /var/lib/mysql/attendances
            4.0K /var/lib/mysql/auto.cnf
            4.0K /var/lib/mysql/binlog.000061
            32K /var/lib/mysql/binlog.000062
            4.0K /var/lib/mysql/binlog.000063
            4.0K /var/lib/mysql/binlog.000064
            4.0K /var/lib/mysql/binlog.000065
            4.0K /var/lib/mysql/binlog.000066
            4.0K /var/lib/mysql/binlog.000067
            4.0K /var/lib/mysql/binlog.000068
            32K /var/lib/mysql/binlog.000069
            52K /var/lib/mysql/binlog.000070
            1.3M /var/lib/mysql/binlog.000071
            15M /var/lib/mysql/binlog.000072
            32K /var/lib/mysql/binlog.000073
            8.0K /var/lib/mysql/binlog.000074
            1.1G /var/lib/mysql/binlog.000075
            1.1G /var/lib/mysql/binlog.000076
            1.1G /var/lib/mysql/binlog.000077
            1.1G /var/lib/mysql/binlog.000078
            1.1G /var/lib/mysql/binlog.000079
            1.1G /var/lib/mysql/binlog.000080
            1.1G /var/lib/mysql/binlog.000081
            285M /var/lib/mysql/binlog.000082
            2.5M /var/lib/mysql/binlog.000083
            1.1G /var/lib/mysql/binlog.000084
            1.1G /var/lib/mysql/binlog.000085
            1.1G /var/lib/mysql/binlog.000086
            1.1G /var/lib/mysql/binlog.000087
            732M /var/lib/mysql/binlog.000088
            1.1G /var/lib/mysql/binlog.000089
            1.1G /var/lib/mysql/binlog.000090
            1.1G /var/lib/mysql/binlog.000091
            1.1G /var/lib/mysql/binlog.000092
            1.1G /var/lib/mysql/binlog.000093
            1.1G /var/lib/mysql/binlog.000094
            1.1G /var/lib/mysql/binlog.000095
            1.1G /var/lib/mysql/binlog.000096
            1.1G /var/lib/mysql/binlog.000097
            1.1G /var/lib/mysql/binlog.000098
            1.1G /var/lib/mysql/binlog.000099
            1.1G /var/lib/mysql/binlog.000100
            1.1G /var/lib/mysql/binlog.000101
            1.1G /var/lib/mysql/binlog.000102
            1.1G /var/lib/mysql/binlog.000103
            1.1G /var/lib/mysql/binlog.000104
            1.1G /var/lib/mysql/binlog.000105
            734M /var/lib/mysql/binlog.000106
            1.1G /var/lib/mysql/binlog.000107
            1.1G /var/lib/mysql/binlog.000108
            1.1G /var/lib/mysql/binlog.000109
            1.1G /var/lib/mysql/binlog.000110
            1.1G /var/lib/mysql/binlog.000111
            1.1G /var/lib/mysql/binlog.000112
            259M /var/lib/mysql/binlog.000113
            367M /var/lib/mysql/binlog.000114
            4.0K /var/lib/mysql/binlog.000115
            4.0K /var/lib/mysql/binlog.index
            4.0K /var/lib/mysql/ca-key.pem
            4.0K /var/lib/mysql/ca.pem
            4.0K /var/lib/mysql/client-cert.pem
            4.0K /var/lib/mysql/client-key.pem
            1.3M /var/lib/mysql/conference
            266M /var/lib/mysql/contacts
            420K /var/lib/mysql/emergencys
            24K /var/lib/mysql/ib_buffer_pool
            0 /var/lib/mysql/ib_buffer_pool.incomplete
            12M /var/lib/mysql/ibdata1
            12M /var/lib/mysql/ibtmp1
            148K /var/lib/mysql/monitorings
            36K /var/lib/mysql/mysql
            31M /var/lib/mysql/mysql.ibd
            0 /var/lib/mysql/mysql.sock
            1.7M /var/lib/mysql/performance_schema
            4.0K /var/lib/mysql/private_key.pem
            4.0K /var/lib/mysql/public_key.pem
            4.0K /var/lib/mysql/server-cert.pem
            4.0K /var/lib/mysql/server-key.pem
            116K /var/lib/mysql/sys
            977M /var/lib/mysql/undo_001
            241M /var/lib/mysql/undo_002

        ```

      </details>
  3. バイナリログのディスクスペース使用量を減らす方法:
     1. バイナリログの削除: MySQLではPURGE BINARY LOGSコマンドを使用して古いバイナリログを安全に削除できます。例えば、特定の日付より前の全てのログを削除するには、次のコマンドを使用します（MySQLプロンプト内で）:

        ```bash
          PURGE BINARY LOGS BEFORE '2024-02-20 22:46:26';
        ```

     2. バイナリログの自動削除設定: expire_logs_days オプションをMySQLの設定ファイル（通常はmy.cnfまたはmy.ini）に追加して、古いバイナリログが自動的に削除されるように設定できます。例えば、7日より古いバイナリログを自動的に削除するには、次の行を設定ファイルに追加します:

         ```config
            [mysqld]
            expire_logs_days = 7
         ```
