---
title: "(工事中)"
date: 2024-3-24T13:25:00
##image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: ""
linkedinurl: ""
weight: 7
tags:
  - Node.js
  - TypeScript
  - npm
  - 開発環境
  - Inversify
  - Express
  - プロジェクトセットアップ
  - 開発依存
description: ""
---

```bash

npm init -y

npm install express inversify@6.0.2 reflect-metadata@0.2.1 inversify-express-utils@6.4.6 --save
npm install typescript@5.4.2 @types/node@20.11.27  --save-dev
```

###### アプリケーションの作成手順

<https://inversify.io/のThe> Basics 　セクションに従う

<https://github.com/inversify/inversify-express-example/blob/master/BindingDecorators/controller/user.ts>

###### TypeScript (`typescript@5.4.2`) と `@types/node` の役割

- **TypeScript (`typescript@5.4.2`):**

  - 静的型付けを提供し、JavaScript に型安全性と予測可能性をもたらす。
  - 最新の ECMAScript 機能をサポートし、古いブラウザーや環境での実行を可能にするためにこれらを JavaScript にトランスパイルする。
  - 開発過程でのエラーチェックを強化し、より堅牢なコードの作成をサポートする。
  - IDE やエディターでの自動補完、リファクタリング、インテリセンス機能を向上させる。

- **`@types/node`:**
  - Node.js の標準ライブラリの API に対する型定義を提供し、TypeScript 環境での使用を可能にする。
  - Node.js の各 API 関数の引数、戻り値、オブジェクトのプロパティなどに対する正確な型情報を提供し、開発者が型ミスを減らすのを助ける。
  - 開発者が Node.js の API を使用する際にリアルタイムで型情報に基づくフィードバックを得られるようにし、開発効率を向上させる。
  - Node.js のバージョンごとに異なる可能性がある API の変更に対応し、プロジェクトが特定の Node.js バージョンと互換性を持つようにする。

## npm install の`--save-dev`オプションについて

`npm install`コマンドに`--save-dev`をつけるかどうかは、インストールしたいパッケージが開発時のみに必要なものなのか、それとも本番環境でも必要なものなのかによって判断します。

#### `--save-dev`オプションとは？

`--save-dev`オプションは、パッケージをプロジェクトの開発依存関係（`devDependencies`）としてインストールします。これは、そのパッケージが開発プロセス中にのみ必要であり、本番環境の実行時には不要であることを意味します。

#### 判断基準

- **開発依存関係（`--save-dev`を使用）:** テストランナー（Jest など）、ビルドツール（webpack、gulp など）、リントツール（ESLint、Prettier など）など、開発プロセスを支援するツールやライブラリ。これらは開発時に必要ですが、本番環境では不要です。
- **通常の依存関係:** React、Vue、Express など、アプリケーションの実行時に必要なライブラリやフレームワーク。これらは開発時だけでなく、本番環境でも必要です。

#### コマンド例

- **開発依存関係としてパッケージをインストール:**  
  `npm install <パッケージ名> --save-dev`

- **本番依存関係としてパッケージをインストール:**  
  `npm install <パッケージ名>`

#### `@types/node`と`typescript`の例

`@types/node`や`typescript`は`devDependencies`に入れる典型的な例です。これらは開発プロセス（TypeScript のコードを JavaScript にトランスパイルする等）においてのみ必要であり、本番環境では不要です。

- **`@types/node`:** Node.js の API を TypeScript で使用する際に型チェックやオートコンプリートを提供します。実行時には不要です。
- **`typescript`:** TypeScript のコードを JavaScript にトランスパイルするためのコンパイラ。開発中にのみ必要です。

これらのパッケージは開発中にのみ使用されるため、`--save-dev`オプションを使って`devDependencies`に追加されます。ビルドプロセスを経て、TypeScript のコードは JavaScript にトランスパイルされ、最終的にはトランスパイルされた JavaScript のみが実行環境で使用されます。
