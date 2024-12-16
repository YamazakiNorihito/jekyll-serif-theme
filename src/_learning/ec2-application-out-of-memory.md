---
title: "EC2で動かしていたアプリケーションが突然動かなくなった時の話"
date: 2024-8-29T16:34:00
weight: 7
tags:
  - EC2
  - AWS
  - Troubleshooting
  - Out of Memory
  - Keycloak
  - System Logs
  - OOM Killer
  - Java
  - メモリ管理
  - パフォーマンス最適化
description: "EC2インスタンスで動作していたKeycloakアプリケーションが突然停止した問題について、原因調査と解決方法を記録。Out of Memory (OOM) Killerによるプロセス終了のメカニズムを解説し、メモリ不足への対応策や再発防止方法について詳しく説明します。"
---

EC2インスタンスでアプリケーションを動かしていた際、突然プロセスが終了した原因を調査したときの記録です。

## はじめに

EC2上でKeycloakを動かしていたところ、予期せずアプリケーションが停止してしまいました。ここでは、その原因を特定するために実施した手順をまとめます。

## 調査手順

1. **ログ取得**  
   まず、EC2インスタンスに接続してログを取得しました。直接インスタンスにログインして確認するか、`scp`でログをダウンロードすることが可能です。いずれの場合も、`/var/log/messages`ファイルを確認することが重要です。

   ```bash
   ssh -t {EC2インスタンスのIP} 'sudo cat /var/log/messages' > messages
   ```

2. **ログ確認**  
   アプリケーションが停止した時間の近くのログを調べます。以下はその抜粋です。

   ```log
   Sep  3 18:18:13 ip-10-0-1-127 kernel: Out of memory: Killed process 18267 (java) total-vm:2405852kB, anon-rss:515832kB, file-rss:0kB, shmem-rss:0kB, UID:0 pgtables:1492kB oom_score_adj:0
   ```

   このログから、`java`プロセスがメモリ不足（Out of Memory, OOM）によって`oom-killer`により殺されたことが確認できます。該当プロセスはKeycloak（PID 18267）であり、大量のメモリを消費していたことがわかります。

   また、その前には以下のようなログが記録されていました。

   ```log
   Sep  3 18:18:13 ip-10-0-1-127 kernel: amazon-cloudwat invoked oom-killer: gfp_mask=0x100cca(GFP_HIGHUSER_MOVABLE), order=0, oom_score_adj=0
   ```

   `amazon-cloudwat`が`oom-killer`を実行したことがわかります。これにより、システム全体のメモリ不足が引き金となり、Keycloakのプロセスが終了しました。
