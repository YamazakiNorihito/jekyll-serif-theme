---
title: "(工事中)"
date: 2024-3-24T13:25:00
#image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: ""
linkedinurl: ""
weight: 7
---


```bash

npm init -y

npm install express inversify@6.0.2 reflect-metadata@0.2.1 inversify-express-utils@6.4.6 --save
npm install typescript@5.4.2 @types/node@20.11.27  --save-dev
```

### アプリケーションの作成手順
<https://inversify.io/のThe> Basics　セクションに従う

<https://github.com/inversify/inversify-express-example/blob/master/BindingDecorators/controller/user.ts>

### TypeScript (`typescript@5.4.2`) と `@types/node` の役割

- **TypeScript (`typescript@5.4.2`):**
  - 静的型付けを提供し、JavaScriptに型安全性と予測可能性をもたらす。
  - 最新のECMAScript機能をサポートし、古いブラウザーや環境での実行を可能にするためにこれらをJavaScriptにトランスパイルする。
  - 開発過程でのエラーチェックを強化し、より堅牢なコードの作成をサポートする。
  - IDEやエディターでの自動補完、リファクタリング、インテリセンス機能を向上させる。

- **`@types/node`:**
  - Node.jsの標準ライブラリのAPIに対する型定義を提供し、TypeScript環境での使用を可能にする。
  - Node.jsの各API関数の引数、戻り値、オブジェクトのプロパティなどに対する正確な型情報を提供し、開発者が型ミスを減らすのを助ける。
  - 開発者がNode.jsのAPIを使用する際にリアルタイムで型情報に基づくフィードバックを得られるようにし、開発効率を向上させる。
  - Node.jsのバージョンごとに異なる可能性があるAPIの変更に対応し、プロジェクトが特定のNode.jsバージョンと互換性を持つようにする。

# npm installの`--save-dev`オプションについて

`npm install`コマンドに`--save-dev`をつけるかどうかは、インストールしたいパッケージが開発時のみに必要なものなのか、それとも本番環境でも必要なものなのかによって判断します。

## `--save-dev`オプションとは？

`--save-dev`オプションは、パッケージをプロジェクトの開発依存関係（`devDependencies`）としてインストールします。これは、そのパッケージが開発プロセス中にのみ必要であり、本番環境の実行時には不要であることを意味します。

## 判断基準

- **開発依存関係（`--save-dev`を使用）:** テストランナー（Jestなど）、ビルドツール（webpack、gulpなど）、リントツール（ESLint、Prettierなど）など、開発プロセスを支援するツールやライブラリ。これらは開発時に必要ですが、本番環境では不要です。
- **通常の依存関係:** React、Vue、Expressなど、アプリケーションの実行時に必要なライブラリやフレームワーク。これらは開発時だけでなく、本番環境でも必要です。

## コマンド例

- **開発依存関係としてパッケージをインストール:**  
  `npm install <パッケージ名> --save-dev`

- **本番依存関係としてパッケージをインストール:**  
  `npm install <パッケージ名>`

## `@types/node`と`typescript`の例

`@types/node`や`typescript`は`devDependencies`に入れる典型的な例です。これらは開発プロセス（TypeScriptのコードをJavaScriptにトランスパイルする等）においてのみ必要であり、本番環境では不要です。

- **`@types/node`:** Node.jsのAPIをTypeScriptで使用する際に型チェックやオートコンプリートを提供します。実行時には不要です。
- **`typescript`:** TypeScriptのコードをJavaScriptにトランスパイルするためのコンパイラ。開発中にのみ必要です。

これらのパッケージは開発中にのみ使用されるため、`--save-dev`オプションを使って`devDependencies`に追加されます。ビルドプロセスを経て、TypeScriptのコードはJavaScriptにトランスパイルされ、最終的にはトランスパイルされたJavaScriptのみが実行環境で使用されます。
