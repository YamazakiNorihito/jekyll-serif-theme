---
title: "Docker Compose で AWS Logs を利用するための設定ガイド"
date: 2024-7-25T16:48:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - Docker
  - Docker Compose
  - AWS
  - CloudWatch
  - Logging
  - EC2
description: "AWS CloudWatch Logs (`awslogs`)を使用して、Docker Compose でログを CloudWatch に送信する方法を説明します。Elastic Beanstalk 上の EC2 インスタンスに Docker Compose をデプロイした際に、ログを CloudWatch に出力するための設定例を紹介し、必要な IAM ポリシーについても言及します。サンプルとして NGINX サービスの Docker Compose 設定を示し、`awslogs` ドライバーを使用したログ出力の設定を解説します。"
---

## Docker Compose で AWS Logs を利用するための設定ガイド

Elastic BeanStalk で EC2 に docker compose を deploy したときに、CloudWatch にログを出力するにはどうしたものかと思った。

そしたらなんと AWS CloudWatch Logs (`awslogs`)という、[docker の log driver](https://matsuand.github.io/docs.docker.jp.onthefly/config/containers/logging/configure/)に設定することができ、それを使えば CloudWatch にログを出力できる。
なので Docker Compose ファイルを設定する方法を紹介します。

これにより `docker logs`で出力されている内容が CloudWatch に出力されます。

Amazon CloudWatch Logs logging driver についてのドキュメントは[こちら](https://docs.docker.com/config/containers/logging/awslogs/)

#### Docker Compose YAML 設定

以下は、`awslogs` ドライバーを使用する NGINX サービスのサンプル Docker Compose YAML 設定です：

```yaml
version: "3.8"

services:
  nginx:
    image: public.ecr.aws/docker/library/nginx:stable-alpine3.19-slim
    ports:
      - "8080:8080"
      - "443:443"
    volumes:
      - /home/ec2-user/nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf
      - /home/ec2-user/ssl:/etc/nginx/ssl
    depends_on:
      keycloak:
        condition: service_started
      app:
        condition: service_started
    logging:
      driver: awslogs
      options:
        awslogs-region: us-east-1
        awslogs-group: identity-server-develop/nginx
        awslogs-create-group: "true"
```

[credentials](https://docs.docker.com/config/containers/logging/awslogs/##credentials)に書いてあるとおり、EC2 インスタンスから CloudWatch へ`logs:CreateLogStream`と`logs:PutLogEvents`のポリシーを追加しないといけないのでお忘れずに。
