---
title: "AWS SAMでのECRログイン方法 - PublicとPrivateの違いに注意"
date: 2024-9-11T09:44:00
weight: 7
tags:
  - AWS
  - SAM
  - ECR
  - Docker
description: "AWS SAM で Lambda 関数をローカルで動作確認する際に、ECR (Elastic Container Registry) からイメージを取得する方法を解説。Public ECR と Private ECR でログイン方法が異なるため、正しいコマンドを使用することが重要です。Go ランタイムの例を挙げ、Public ECR へのログイン方法やエラーの対処法についても説明します。"
---

## AWS SAM 使用時の ECR ログイン方法

AWS SAM（Serverless Application Model）を使って Lambda 関数などをローカルで動作確認する際、Lambda ランタイムは Docker イメージを使って実行されます。この際、**AWS ECR (Elastic Container Registry)** からイメージを取得しますが、**Public** と **Private** でログイン方法が異なるため、間違えないよう注意が必要です。

特に、Go ランタイムを使用する場合、Lambda は **Public ECR** からイメージを取得します（参考: [Go ランタイムのイメージ](https://gallery.ecr.aws/lambda/go)）。Public ECR にログインしないとイメージが取得できず、エラーが発生します。

### Private ECR リポジトリにログインする場合

もし AWS のプライベートリポジトリからイメージを取得する場合は、事前に認証が必要です。以下のコマンドで Private ECR にログインします。

```bash
aws ecr get-login-password --region <region> --profile <your-aws-profile> | docker login --username AWS --password-stdin <private-ecr-url>
```

**例:**

```bash
aws ecr get-login-password --region us-east-1 --profile medcom.ne.jp | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
```

このコマンドでは、指定した AWS プロファイル（例：`medcom.ne.jp`）を使用し、Private ECR にログインします。

### Public ECR リポジトリにログインする場合

Go ランタイムなど、Public ECR からイメージを取得する場合もログインが必要です。以下のコマンドを実行して Public ECR にログインします。

```bash
aws ecr-public get-login-password --region <region> | docker login --username AWS --password-stdin public.ecr.aws
```

**例:**

```bash
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
```

このコマンドでは、Public ECR に対してログインします。間違えて Private ECR にログインすると、Public ECR のイメージを取得できず、エラーが発生します。

### エラー発生時の対処

もし、次のようなエラーメッセージが表示された場合:

```
Error response from daemon: pull access denied for public.ecr.aws/lambda/go, repository does not exist or may require 'docker login': denied: Your authorization token has expired. Reauthenticate and try again.
```

これは、認証トークンが期限切れか、あるいは Public ECR に正しくログインしていないためです。正しく Public ECR にログインしているかを確認し、再度ログインコマンドを実行して、問題を解消してください。

### まとめ

AWS SAM を使って Lambda 関数をローカルで動作確認する際、Public と Private の ECR ログインを間違えないように注意しましょう。特に Go ランタイムなどのイメージは Public ECR から取得するため、正しいログインコマンドを使用することが重要です。
