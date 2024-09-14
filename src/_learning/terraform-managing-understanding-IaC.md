---
title: "Terraformを理解する：インフラストラクチャをコードとして管理する方法"
date: 2024-6-27T09:15:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - Terraform
  - Infrastructure as Code
  - IaC
  - Cloud Infrastructure
  - Automation
  - DevOps
  - Configuration Management
  - HashiCorp
  - Infrastructure Management
---

<https://developer.hashicorp.com/terraform/intro>

## What is Terraform?

HashiCorp Terraformは、インフラストラクチャをコードとして扱うツールであり、クラウドおよびオンプレミスのリソースを、人間が読める構成ファイルで定義することができます。これらの構成ファイルは、バージョン管理、再利用、共有が可能です。その後、一貫したワークフローを使用して、インフラストラクチャのライフサイクル全体を通じてプロビジョニングおよび管理を行うことができます。Terraformは、コンピューティング、ストレージ、ネットワークリソースなどの低レベルのコンポーネントから、DNSエントリやSaaS機能などの高レベルのコンポーネントまで管理することができます。

> 実践：人気のあるクラウドプロバイダーでインフラを管理するために、「Get Started」チュートリアルを試してみましょう。対象のクラウドプロバイダーには、> [Amazon Web Services](https://developer.hashicorp.com/terraform/tutorials/aws-get-started)、[Azure](https://developer.hashicorp.com/terraform/intro#:~:text=Web%20Services%2C-,Azure,-%2C%20Google%20Cloud)、[Google Cloud Platform](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started)、Oracle Cloud Infrastructure、そして[Docker](https://developer.hashicorp.com/terraform/intro#:~:text=Infrastructure%2C%20and-,Docker,-.)があります。

## How does Terraform work?

Terraformは、クラウドプラットフォームやその他のサービスのアプリケーションプログラミングインターフェース（API）を通じて、リソースを作成および管理します。プロバイダーは、Terraformがアクセス可能なAPIを持つほぼすべてのプラットフォームやサービスと連携できるようにします。

HashiCorpとTerraformコミュニティは、多くの異なる種類のリソースやサービスを管理するために、すでに数千のプロバイダーを作成しています。Amazon Web Services (AWS)、Azure、Google Cloud Platform (GCP)、Kubernetes、Helm、GitHub、Splunk、DataDogなど、すべての公開プロバイダーは[Terraform Registry](https://registry.terraform.io/)で見つけることができます。

Terraformの基本的なワークフローは以下の三つのステージで構成されています：

- **Write（記述）**：複数のクラウドプロバイダーやサービスにわたるリソースを定義します。例えば、セキュリティグループやロードバランサーを備えた仮想プライベートクラウド (VPC) ネットワーク上の仮想マシンにアプリケーションをデプロイする構成を作成することができます。
- **Plan（計画）**：Terraformは、既存のインフラストラクチャとあなたの構成に基づいて、作成、更新、または破棄するインフラストラクチャを記述する実行計画を作成します。
- **Apply（適用）**：承認後、Terraformは提案された操作を正しい順序で実行し、リソースの依存関係を尊重します。例えば、VPCのプロパティを更新し、そのVPC内の仮想マシンの数を変更する場合、Terraformは仮想マシンをスケールする前にVPCを再作成します。

## Manage any infrastructure

Terraform Registryで、すでに使用している多くのプラットフォームやサービスのプロバイダーを見つけることができます。また、自分自身でプロバイダーを書くことも可能です。Terraformはインフラストラクチャに対して不変のアプローチを採用しており、サービスやインフラストラクチャのアップグレードや変更の複雑さを軽減します。

## Track your infrastructure

Terraformはプランを生成し、インフラストラクチャを変更する前にあなたの承認を求めます。また、状態ファイルに実際のインフラストラクチャを記録し、これを環境の信頼できる情報源として扱います。Terraformは状態ファイルを使用して、インフラストラクチャを構成に一致させるために行う変更を判断します。

Terraformは、インフラの変更計画を作成し、承認を得てから実行し、状態ファイルでインフラの現状を管理・調整します。

## Standardize configurations

Terraformは、再利用可能な構成コンポーネントであるモジュールをサポートしており、インフラストラクチャの設定可能なコレクションを定義します。これにより、時間を節約し、ベストプラクティスを促進します。Terraform Registryから公開されているモジュールを使用することも、自分自身でモジュールを書くこともできます。

## Collaborate

構成がファイルに書かれているため、それをバージョン管理システム（VCS）にコミットし、HCP Terraformを使用してチーム全体でTerraformのワークフローを効率的に管理することができます。HCP Terraformは、Terraformを一貫性のある信頼できる環境で実行し、共有状態と秘密データへの安全なアクセス、ロールベースのアクセス制御、モジュールとプロバイダーの両方を共有するためのプライベートレジストリなどを提供します。
