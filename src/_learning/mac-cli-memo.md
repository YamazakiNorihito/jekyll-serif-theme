---
title: "mac memo"
date: 2024-3-6T09:00:00
jobtitle: "memo"
linkedinurl: ""
weight: 7
tags:
  - macOS
  - Bash Scripting
  - File Management
  - Cron Jobs
  - Automation
  - Timezone Settings
  - ZIP Compression
  - Task Scheduling
description: "macOSでのファイル操作や圧縮、定期処理設定の手順を解説。パス確認、Cronを使用したスクリプト実行、タイムゾーン設定など、日常の作業を効率化する方法を紹介します。"
---


# path

```bash
# Currentディレクトリ内のファイルを一覧表示
~/Downloads$ ls
Dump20240227.sql Dump20240227_1.sql.zip
Dump20240227.sql.zip Dump20240227_2.sql

# 特定のファイルのフルパス取得
~/Downloads$ realpath Dump20240227_2.sql
/Users/n.{user}/Downloads/Dump20240227_2.sql
```

# zip

```bash
~/Documents/mystady/simple-codes/DEV-746/速度調査プログラム$ ls
experiment_log_1709605333885_山口さんのSQLと比較.txt            実行計画_1.txt
experiment_log_1709615324311.md                                 実行計画_2.txt
experiment_log_1709615324311.txt                                検索速度検証.md
index.js
~/Documents/mystady/simple-codes/DEV-746/速度調査プログラム$ zip 検索速度検証_実行計画.zip 実行計画_1.txt  実行計画_2.txt    検索速度検証.md
  adding: 実行計画_1.txt (deflated 92%)
  adding: 実行計画_2.txt (deflated 93%)
  adding: 検索速度検証.md (deflated 77%)
```

# Cronを使用した定期処理のセットアップ

このガイドでは、macOSでCronを使用してスクリプト`archive_and_delete.sh`を定期的に実行する方法

## 1. バッチ処理スクリプトの作成

まず、以下の内容を持つ`archive_and_delete.sh`スクリプトを作成します。
<details markdown="1"><summary>スクリプト</summary>

```bash
#!/bin/bash

# 現在の日時を YYYYMMDD-HHMMSS 形式で取得し、変数に代入
current_datetime=$(date "+%Y%m%d-%H%M%S")

# ログディレクトリのパスを変数に代入
# ここではユーザー名を明示的に指定する必要がある（または環境変数から読み込む）
log_directory="/Users/{userName}/Documents/mystady/simple-codes/DEV-746/unit-test-log/"

# ログファイルのパスを変数に代入
log_file="${log_directory}${current_datetime}_script_log.txt"

# ログディレクトリ内の特定のパターンにマッチし、1分前以上に作成されたファイルを検索
# 対象ファイルをZIPに圧縮し、その後削除する
find "$log_directory" -name 'dev-746_searched_urls_log@*.txt' -type f -mmin +1 -print0 |
while IFS= read -r -d $'\0' file; do
    echo "Processing: $file" >> "$log_file"
    archive_path="${log_directory}${current_datetime}_archive.zip"
    if zip "$archive_path" "$file" >> "$log_file" 2>&1; then
        echo "Archived: $file" >> "$log_file"
        rm "$file" && echo "Deleted: $file" >> "$log_file"
    else
        echo "Failed to archive: $file" >> "$log_file"
    fi
done
```

</details>

<br>
スクリプトを作成したら、実行可能にするために次のコマンドを実行してください。

```bash
chmod +x /Users/{userName}/Documents/mystady/simple-codes/DEV-746/unit-test-log/archive_and_delete.sh
```

## 2. Cronの設定とアクセス権限

### 2.1 参考サイト

以下のサイトが参考になります:
[【crontab】mac-bookで処理を定期実行する方法【超簡単】](https://spreadsheep.net/%E3%80%90crontab%E3%80%91mac-book%E3%81%A7%E5%87%A6%E7%90%86%E3%82%92%E5%AE%9A%E6%9C%9F%E5%AE%9F%E8%A1%8C%E3%81%99%E3%82%8B%E6%96%B9%E6%B3%95%E3%80%90%E8%B6%85%E7%B0%A1%E5%8D%98%E3%80%91/)

## 3. Cron Jobの登録

`crontab -e`コマンドを使用してCron Jobを登録します。以下の手順に従ってください。

1. Terminalを開いて`crontab -e`を実行します。
1. `i`キーを押して挿入モードに入ります。
1. 適切な行に以下を追加します。

```bash
# これは、3分ごとにスクリプトを実行するようにCronに指示します。
*/3 * * * * /Users/{userName}/Documents/mystady/simple-codes/DEV-746/unit-test-log/archive_and_delete.sh

```

## 4. 登録されたCron Jobの確認

`crontab -l`コマンドを使用して、登録されたジョブが正しく設定されているか確認します。

## 5. Cron Jobのログ確認

Cron Jobが正しく実行されているかを確認するには、以下のコマンドを使用してログを確認します。

```bash
log show --predicate 'process == "cron"' --info --debug
```

## timezone

```bash
# 設定できるTimeZone一覧
$ sudo systemsetup -listtimezones

# timezone設定
$ sudo systemsetup -settimezone "Asia/Tokyo"

# 確認
$ date
```
