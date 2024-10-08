---
title: "VSCodeでGoを効率的に開発するための設定"
date: 2024-05-31T06:00:00
weight: 4
categories:
- go
description: ""
---

# 思い

Goをvscodeで開発するときの設定を紹介します。

## Go言語用VSCode拡張機能のインストール

Go Team at [Googleの拡張機能](https://marketplace.visualstudio.com/items?itemName=golang.Go)をインストールします。

## settings.jsonの設定

```json
{
  "go.formatTool": "goimports",
  "go.lintTool": "golangci-lint",
  "go.lintFlags": ["--fast"],
  "editor.formatOnSave": true,
  "[go]": {
    "editor.defaultFormatter": "golang.go"
  }
}
```

### コードフォーマット

[Goのフォーマッタ一覧](https://github.com/life4/awesome-go-code-formatters)

Go言語では、`gofmt` がデフォルトのフォーマッターとして提供されています。`goimports`は`gofmt`に加えimportをサポートしてくれます。

#### Linterの設定

Linterは[公式サイト](https://golangci-lint.run/usage/linters/)で紹介されている`golangci-lintで良いと思います。
