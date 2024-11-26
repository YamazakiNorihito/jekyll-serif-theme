---
title: ""
date: 2024-11-25T07:11:00
jobtitle: ""
linkedinurl: ""
weight: 7
tags:

- エンジニアリング
- 思考法
- 生産性
- チームビルディング
- コミュニケーション
- AI時代
- プログラミング
- キャリア
description: ""
---

## CI CD

### Continuous delivery(CD)

ソフトウェアのリリースプロセスを自動化したデプロイ方法論。
すべてのソフトウェア変更が自動的にビルド、テストされ、production環境にデプロイ可能な状態になる。
ただし、最終的なproductionへのリリースタイミングは、人間、テスト、自動化されたビジネスルールなどが決定する。
すべての変更を即座にリリース可能だが、必ずしも全ての変更をすぐにリリースする必要はない。

### Continuous integration(CI)

ソフトウェア開発におけるプラクティスの一つで、チームメンバーがバージョン管理システムを使い、頻繁に作業内容を統合する（例: メインブランチ）。
各変更は自動的にビルド・テストされ、統合エラーを早期に検出できるようにする。
CIはコードのビルドとテストの自動化に重点を置いており、CD（Continuous Delivery）がリリースプロセス全体の自動化を目指している点とは異なる。

For more information, see [Practicing Continuous Integration and Continuous Delivery on AWS: Accelerating Software Delivery with DevOps.](https://d0.awsstatic.com/whitepapers/DevOps/practicing-continuous-integration-continuous-delivery-on-AWS.pdf)

## 参考ページ

- [Continuous delivery and continuous integration](https://docs.aws.amazon.com/codepipeline/latest/userguide/concepts-continuous-delivery-integration.html)
