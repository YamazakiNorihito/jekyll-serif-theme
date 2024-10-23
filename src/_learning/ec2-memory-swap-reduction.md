---
title: "メモリ使用量が減った!? その理由はSwapファイルでした"
date: 2024-09-06T14:22:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - EC2
  - AWS
  - Memory Management
  - Swap File
  - Linux
  - System Performance
  - CloudWatch
  - Troubleshooting
description: "EC2インスタンスで発生したメモリ不足問題の対策としてSwapファイルを導入し、その結果メモリ使用量が減少した経緯について解説します。Swapファイルの作成によるメモリ管理の改善、CloudWatchでのメモリモニタリング、LinuxシステムでのメモリおよびSwapの使用状況確認方法など、トラブルシューティングに役立つ情報を提供します。"
---

## 背景

先日、EC2インスタンス上でメモリ不足により`oom-killer`が発動し、メモリを一番消費していたプロセスが強制終了されるという問題が発生しました。この問題を受け、メモリ不足への一時的な対応としてSwapファイルを作成しました。

## メモリ使用量の変化

CloudWatch Agentでメモリ使用量をモニタリングしていたところ、メモリの使用量が700MBから500MBに減少していることに気づきました。この減少の原因を調査した結果、Swapファイルにメモリのデータが移動したためであることが判明しました。

### Swapイベントの確認

以下のコマンドを使用して、Swapのイベントが発生した記録を確認しました。

```bash
# Swapのイベントが発生した記録を確認します
$ sar -S 1 10

Linux {ip.amzn2.x86_64 (ip-{ip}.ec2.internal)  2024年09月06日  _x86_64_ (1 CPU)
05時16分47秒 kbswpfree kbswpused  %swpused  kbswpcad   %swpcad
05時16分48秒    236284    288000     54.93     51132     17.75
05時16分49秒    236284    288000     54.93     51132     17.75
05時16分50秒    236284    288000     54.93     51132     17.75
05時16分51秒    236284    288000     54.93     51132     17.75
05時16分52秒    236284    288000     54.93     51132     17.75
```

また、システム全体のメモリおよびSwapの使用状況も以下のコマンドで確認しました。

```bash
# システム全体のメモリおよびスワップの使用状況を確認
$ free -h
              total        used        free      shared  buff/cache   available
Mem:           964M        519M        128M         76K        316M        300M
Swap:          511M        281M        230M
```

メモリ使用量が700MBから500MBに減少した時点で、ちょうどSwapファイルへのデータ移行が確認され、原因が特定できました。

## 関連リンク

- [14.4. スワップファイルの作成](https://docs.redhat.com/ja/documentation/red_hat_enterprise_linux/8/html/managing_storage_devices/creating-a-swap-file_getting-started-with-swap)
- [Adding swap space to an EC2 Amazon Linux instance](https://www.photographerstechsupport.com/tutorials/adding-swap-space-ec2-amazon-linux-instance/)
- [Adding Swap Memory to Centos/RHEL/Amazon Linux Servers](https://bluescionic.com/2020/08/29/adding-swap-memory-to-centos-rhel-amazon-linux-servers/)
