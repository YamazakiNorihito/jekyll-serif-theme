---
title: "Best Practices for Structuring Go Projects"
date: 2024-05-31T05:00:00
weight: 4
categories:
  - go
description: ""
---

## 思い

[golang-standards/project-layout](https://github.com/golang-standards/project-layout/blob/master/README_ja.md)をベースに自分が必要そうな
ディレクトリ構成を記述する。もし悩んだら`golang-standards/project-layout`に立ち返り、構成を見直す。

#### Go Version

```bash
~$ go version
go version go1.22.2 darwin/arm64
```

#### Project tree

```bash
.
├── Makefile
├── README.md
├── cmd
│   └── lambda
│       ├── api
│          ├── create
│          │   ├── Makefile
│          │   ├── bootstrap
│          │   ├── function.zip
│          │   ├── go.mod
│          │   ├── go.sum
│          │   └── main.go
│          ├── get
│          │   ├── Makefile
│          │   ├── bootstrap
│          │   ├── function.zip
│          │   ├── go.mod
│          │   ├── go.sum
│          │   └── main.go
│          ├── list
│          │   ├── Makefile
│          │   ├── bootstrap
│          │   ├── function.zip
│          │   ├── go.mod
│          │   └── main.go
│          └── shared
│              ├── error_response.go
│              └── client_factory.go
├── go.mod
├── go.sum
├── go.work
├── go.work.sum
├── internal
│   ├── domain
│   │   ├── alarm.go
│   │   ├── alarm_repository.go
│   │   ├── alarm_service.go
│   └── infrastructure
│       └── logger.go
├── template.yaml
├── tests
│   ├── helper
│   │   ├── alarm_helper.go
│   │   └── dynamoDB_helper.go
│   └── internal
│       └── domain
│           ├── alarm_repository_test.go
│           └── alarm_test.go
└── wiki
```

###### `/cmd`

- アプリケーションのディレクトリ名で、実行ファイルを生成する。
- /internal と /pkg ディレクトリからコードをインポートして呼び出すだけの小さな main 関数にする。
- Lambda など記述方法に制限がある場合、使用するアプリケーションの種類によってハンドラが異なるため、ハンドラごとにディレクトリを作成する。
  - 共通の処理がある場合には shared ディレクトリを作成し、共通の処理をそこに配置できる。

###### internal

- プライベートなアプリケーションやライブラリのコードを配置
- 同じプロジェクトツリー内の特定の範囲でのみインポート可能

###### pkg

- 外部アプリケーションで使用しても問題ないライブラリコードを配置
- 他のプロジェクトや公開するコード（例：go get hogehogeの対象）をここに配置
- 自分のプロジェクト内だけでなく、他人に公開して使用してもらうためのコード
- 他人に公開するコードを書く予定がない場合は、このディレクトリを作成する必要はない

###### (不要) vendorディレクトリ

vendorディレクトリは以前、アプリケーションが依存している外部ライブラリやパッケージをプロジェクト内に格納するために使用されていました。
しかし、Go 1.13以降、Goモジュールとモジュールプロキシ機能の導入により、vendorディレクトリはなくても問題なくなりました。
依存関係は`go.mod`と`go.sum`ファイルによって管理され、必要なライブラリは[モジュールプロキシ](https://proxy.golang.org)を通じて自動的にダウンロードされます。

#### 参考サイト

- [golang-standards/project-layout](https://github.com/golang-standards/project-layout/blob/master/README_ja.md)
- [Golang project directory structure](https://stackoverflow.com/questions/46646559/golang-project-directory-structure)
- [awsdocs/aws-doc-sdk-examples](https://github.com/awsdocs/aws-doc-sdk-examples/tree/main/gov2)
- [kubernetes](https://github.com/kubernetes/kubernetes)
- [terraform](https://github.com/hashicorp/terraform)
- [Golang AWS Lambda project structure](https://how.wtf/golang-aws-lambda-project-structure.html)
- [Go: AWS Lambda Project Structure Using Golang](https://medium.com/dm03514-tech-blog/go-aws-lambda-project-structure-using-golang-98b6c0a5339d)
- [AWS Lambda 関数を使用するためのベストプラクティス](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/best-practices.html)
