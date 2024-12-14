---
title: "Amazon CodePipelineメモ(作業中)"
date: 2024-11-1T07:15:00
mermaid: true
weight: 7
tags:
  - AWS
  - CodePipeline
  - CI/CD
  - DevOps
  - Pipeline
description: "AWS CodePipelineの基本概念と構成要素を解説。パイプラインのステージ、トランジション、アクション、実行プロセスの仕組みとステータスについての詳細な情報を提供します。"
---

## [CodePipeline concepts](https://docs.aws.amazon.com/codepipeline/latest/userguide/concepts.html)

**Pipelines**

workflowの構成要素であり、ソフトウェアの変更がリリース処理に至るまでの流れを記述したもの。

**Stages**

- stageは環境を分けたり、変更の同時実行を制限する論理的単位。
- 各stageにはアプリケーションのアーティファクト（例：ソースコード）に対するactionを含む。
- 主なstage例：
  - ビルドstage：ソースコードのビルドやテストを実行。
  - デプロイstage：コードを実行環境にデプロイ。
- actionは直列または並列で実行可能。

**Transitions**

- transitionは、pipelineが次のstageに移るpoint。
- stageのインバウンドtransitionを無効化すると、そのstageへの実行を一時停止可能。
- transitionを再度有効化すると、実行が再開。
- 無効化中に複数の実行が到着した場合、最新の実行のみが有効化後に次のstageへ進む。
- 新しい実行が到着するたびに待機中の実行を上書きし、有効化後は最も新しい実行が進行する。

**Actions**

- actionは、pipeline内で特定のタイミングで実行されるアプリケーションコードへの操作セット。
- 例：コード変更によるソースaction、インスタンスへのデプロイactionなど。
- actionの種類：source, build, test, deploy, approval, invoke
  - [Valid action providers by action type](https://docs.aws.amazon.com/codepipeline/latest/userguide/actions-valid-providers.html)
- actionは直列または並列で実行可能。
- 詳細は「[action構造要件のrunOrder情報](https://docs.aws.amazon.com/codepipeline/latest/userguide/reference-pipeline-structure.html#action-requirements)」を参照。

**Pipeline executions**

以下は、Pipeline executions についての要約です：

Pipeline executions

- Executionの概要
  - Executionは、パイプラインによってリリースされた変更操作のセットを表します。
  - 各Executionは一意で、固有のIDを持っています。
  - 変更セット（例えば、マージされたコミットや最新コミットの手動リリース）に対応します。
- 並行処理について
  - パイプラインは複数のExecutionを同時に処理することが可能です。
  - ただし、各パイプラインステージでは1つのExecutionしか処理できません。
  - ステージはExecutionの処理中にロックされ、同時に複数のExecutionを受け付けません。
- 待機中のExecution
  - ステージが埋まっている場合、次のExecutionは「インバウンドExecution」として待機状態になります。
  - インバウンドExecutionは失敗、上書き（Superseded）、または手動停止される可能性があります。
- Executionのステータス
  - Executionはパイプラインステージを順に通過します。
  - 有効なステータスは以下の通りです：
    - InProgress: 実行中
    - Stopping: 停止中
    - Stopped: 停止済み
    - Succeeded: 成功
    - Superseded: 上書き済み
    - Failed: 失敗

「インバウンドExecutionの詳細」については、How Inbound Executions Work を参照してください。

**Stopped executions**
