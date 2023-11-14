---

title: "大量データをStreamに処理するすごいぞsetImmediate"
date: 2023-11-04T07:00:00
weight: 4
categories:
  - javascript
  - nodejs
  - typescript
---

大量データをメモリを大量に使わずに処理するのに最適なFunctionを見つけました。
それは `setImmediate`です。（[ドキュメント](https://nodejs.org/en/learn/asynchronous-work/understanding-setimmediate)


## タスクの性質

- **長時間実行されるタスク:** タスクが長時間実行され、他のイベントの処理に影響を与える可能性がある場合、`setImmediate` は良い選択です。これにより、各イベントループの反復の間に他の操作が処理される機会を提供します。

- **大量のデータ処理:** 大量のデータをバッチで処理する場合、`setImmediate` を使用すると、各バッチ処理の間にノードが他のタスクを実行できるようになります。

- **I/O操作とのバランス:** システムがI/Oバウンド操作（データベースクエリ、ファイルシステム操作など）を頻繁に実行する場合、`setImmediate` を使用して、これらの操作とCPUバウンドタスク（データ処理など）のバランスを取ることができます。

## アプリケーションの要件

- **応答性:** アプリケーションがリアルタイムの応答性を維持する必要がある場合、`setImmediate` はイベントループをスムーズに保ち、応答性を高めます。

- **リソースの使用率:** コールスタックの深さやメモリ使用量に影響を与える重い処理を実行する場合、`setImmediate` はこれらのリソースの使用率を管理し、スタックオーバーフローを回避するのに役立ちます。

- **スケーラビリティ:** 大規模なアプリケーションやシステムでスケーラビリティを保つために、`setImmediate` は長時間の処理を分散させ、システムの負荷を均等にするのに役立ちます。

## 判断の際の注意点

- `setImmediate` はイベントループをブロックしないため、他のイベントやI/O操作に対する応答性を維持するのに適していますが、処理自体の完了が少し遅れる可能性があります。

- `process.nextTick` や `setTimeout` と比較した場合、`setImmediate` はイベントループに対してよりフレンドリーですが、タスクの実行順序やタイミングに影響を与える可能性があります。

# setImmediate の使用判断基準

`setImmediate` の使用に関する判断基準は、主にタスクの性質とアプリケーションの要件に基づいています。以下は、`setImmediate` を使うかどうかを判断する際の主要な考慮事項です：


```typescript
import { format } from 'fast-csv';

public exportJapanPostsCsv(): Readable {
  
    const headers = [
      'postalCode',
      'prefectureName',
      'cityName',
      'districtName',
    ];
    const csvStream = format({ headers, quoteColumns: true, quoteHeaders: true, alwaysWriteHeaders: true });
    const readableStream = new Readable().wrap(csvStream);

    let offset = 0;
    const LIMIT_ROW_COUNT = 100;

    const fetchData = async () => {
      const japanPosts = await this._japanPostRepository.search(offset, LIMIT_ROW_COUNT);

      if (!japanPosts.length) {
        csvStream.end();
        return;
      }

      japanPosts.forEach(japanPost => {
        csvStream.write({
          postalCode: japanPost.postalCode,
          prefectureName: japanPost.prefectureName,
          cityName: japanPost.cityName,
          districtName: japanPost.districtName,
        });
      });

      offset += LIMIT_ROW_COUNT;
      setImmediate(fetchData);
    };

    fetchData();

    return readableStream;
}
```

このアプローチは、メモリ使用量を効率的に管理しつつ、アプリケーションの応答性を維持するために特に有効です。
大規模な郵便情報データセットを扱う際に、全てのデータを一度に取得してメモリに保持するのではなく、
`LIMIT_ROW_COUNT` に設定されたサイズの小さなバッチでデータを取得し、処理することで、メモリの過剰使用を防ぎます。
また、`setImmediate(fetchData)`の使用により、Node.js のイベントループは各バッチ処理の間に他のタスク
（例えば、ユーザーからのリクエスト応答や他の非同期操作）に対応できるようになります。
これは、特にサーバーが高いトラフィックを処理している場合や、リアルタイム性が重要なアプリケーションにおいて重要です。
この方法で、アプリケーションはデータの大量処理を行いながらも、ユーザーからの新しいリクエストに迅速に応答することができます。