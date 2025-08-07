---
title: "Node.jsのmaxSockets設定によるAPI障害の学び"
date: 2025-8-07T09:44:00
weight: 7
tags:
  - AWS
  - Node.js
  - SDK
  - パフォーマンスチューニング
  - トラブルシューティング
description: "AWS SDK for JavaScriptにおけるmaxSocketsの見落としにより発生したAPI障害とその対処法についての学びを共有します。"
---

[Node.jsのmaxSockets](https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/node-configuring-maxsockets.html)設定を見落としていたことで、APIの応答が止まるというトラブルを経験しました。

AWS SDK for JavaScriptを用いてAWSリソースへHTTPアクセスする際には、接続数上限であるmaxSocketsの設定が可能です。
デフォルトは50となっており、負荷やアクセスパターンに応じて適切な値へ調整することが重要です。

実際に私の環境では、S3へのアクセスが想定以上に集中し、デフォルトの50を大きく超過してしまいました。

```bash
@smithy/node-http-handler:WARN - socket usage at capacity=50 and 10684 additional requests are enqueued.
```

このような場合には、キャッシュ機能の導入によるリクエスト削減や、maxSocketsの値の調整が有効です。
また、Auto Scalingによって負荷を分散する手段も考えられます。サービス特性に応じて柔軟に対応することが求められます。

トラブルから多くを学べることもあります。今回はmaxSocketsについての気づきでした。
