---
title: "Node.jsと`worker_threads`モジュール"
date: 2024-3-13T10:00:00
weight: 4
mermaid: true
categories:
  - nodejs
  - javascript
description: ""
---

# Node.jsと`worker_threads`モジュールの概要

Node.jsはシングルスレッドのランタイム環境であるため、デフォルトでは1つのCPUコアしか使用しません。
Node.jsの`worker_threads`モジュールを利用することで、マルチスレッド処理を実現し、アプリケーションのパフォーマンスを向上させることができます。ここでは、基本的な使用例と、CPUとの関連性について説明します。

## 簡単な使用例

### `main.js`

```javascript
const { Worker } = require('worker_threads');

function runWorker(workerData) {
    return new Promise((resolve, reject) => {
        const worker = new Worker('./worker.js', { workerData });
        worker.on('message', resolve);
        worker.on('error', reject);
        worker.on('exit', code => {
            if (code !== 0)
                reject(new Error(`Worker stopped with exit code ${code}`));
        });
    });
}

async function main() {
    const numbersArray = [1, 2, 3, 4, 5];
    try {
        const sum = await runWorker(numbersArray);
        console.log(`The sum is: ${sum}`);
    } catch (error) {
        console.error(`Main script error: ${error.message}`);
    }
}

main();

```

### `worker.js`

```javascript
const { parentPort, workerData } = require('worker_threads');

function calculateSum(numbers) {
    return numbers.reduce((acc, val) => acc + val, 0);
}

const sum = calculateSum(workerData);
parentPort.postMessage(sum);

```

この例では、メインスクリプトがワーカースレッドを生成し、そのスレッドで数の配列の合計を計算し、結果をメインスクリプトに送り返します。
ワーカースレッドはメインスレッドとは独立してバックグラウンドで実行され、メインスレッドのブロッキングを防ぎます。

## `worker_threads`とCPU

`worker_threads`モジュールを使用すると、Node.jsアプリケーションが複数のCPUコアを活用できるようになります。これは、CPU密集型のタスクをメインスレッドから独立させ、複数のワーカースレッドに分散することで、アプリケーション全体の処理能力を向上させるためです。ワーカースレッドはメインスレッドとは独立してバックグラウンドで実行され、メインスレッドのブロッキングを防ぎます。

### メリット

- **CPU密集型タスクの高速化**: 複数のCPUコアを並列に利用することで、CPU密集型のタスクを効率的に処理できます。
- **応答性の向上**: メインスレッドがI/O操作やユーザーインタラクションの処理に集中できるため、アプリケーションの応答性が向上します。

### 使用上の注意

- **リソースの管理**: ワーカースレッドを過剰に使用すると、オーバーヘッドが増加し、逆にパフォーマンスが低下する可能性があります。
- **データ共有と通信**: メインスレッドとワーカースレッド間でのデータの受け渡しは、メッセージベースで行われます。大量のデータを頻繁に交換する場合、性能に影響を与える可能性があります。
