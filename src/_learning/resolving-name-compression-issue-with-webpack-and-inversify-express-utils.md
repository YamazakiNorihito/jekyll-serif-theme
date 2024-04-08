---
title: "Webpackとinversify-express-utilsの組み合わせでの名前圧縮問題の解決"
date: 2023-10-24T09:11:00
#image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: "Graphic Designer"
linkedinurl: ""
weight: 7
---

Webpackと`inversify-express-utils`を組み合わせてWeb APIを実装する際に遭遇した、
クラス名や関数名の圧縮に関する問題とその解決方法について説明します。

`npx webpack`コマンドでのビルド後、`node dist/index.js`を実行した時に特定のエラーが発生しました。
このエラーの内容や発生原因、そして解決策について詳しく見ていきます。

```bash
Error: Two controllers cannot have the same name: s
    at /Users/sugimoto/Desktop/GitHub/api-server_V2/dist/index.js:2:884127
    at Array.forEach (<anonymous>)
    at e.registerControllers (/Users/sugimoto/Desktop/GitHub/api-server_V2/dist/index.js:2:884042)
    at e.build (/Users/sugimoto/Desktop/GitHub/api-server_V2/dist/index.js:2:883828)
    at t.createApp (/Users/sugimoto/Desktop/GitHub/api-server_V2/dist/index.js:2:2048727)
    at 63607 (/Users/sugimoto/Desktop/GitHub/api-server_V2/dist/index.js:2:2104226)
    at n (/Users/sugimoto/Desktop/GitHub/api-server_V2/dist/index.js:2:4180918)
    at /Users/sugimoto/Desktop/GitHub/api-server_V2/dist/index.js:2:4181422
    at Object.<anonymous> (/Users/sugimoto/Desktop/GitHub/api-server_V2/dist/index.js:2:4181449)
    at Module._compile (node:internal/modules/cjs/loader:1256:14)
```

解決方法として、`webpack.config.js`内でTerserPluginを使用し、
Class名とFunction名の圧縮・最小化を防ぐ設定を行うことです。

```javascript
// targetがes6以降の場合
const path = require('path');
const TerserPlugin = require('terser-webpack-plugin');

module.exports = {
    entry: './src/server.ts',
    mode: 'production',
    target: 'node',
    output: {
        filename: 'index.js',
        path: path.resolve(__dirname, 'dist')
    },
    resolve: {
        extensions: ['.ts', '.js']
    },
    module: {
        rules: [
            {
                test: /\.ts$/,
                use: 'ts-loader',
                exclude: /node_modules/
            }
        ]
    },
    optimization: {
        minimizer: [
            new TerserPlugin({ // ここ重要
                terserOptions: {
                    keep_classnames: true, // 必須
                },
                parallel: true,
            }),
        ],
    }
};
```

```javascript
// targetがes5以前の場合
const path = require('path');
const TerserPlugin = require('terser-webpack-plugin');

module.exports = {
    entry: './src/server.ts',
    mode: 'production',
    target: 'node',
    output: {
        filename: 'index.js',
        path: path.resolve(__dirname, 'dist')
    },
    resolve: {
        extensions: ['.ts', '.js']
    },
    module: {
        rules: [
            {
                test: /\.ts$/,
                use: 'ts-loader',
                exclude: /node_modules/
            }
        ]
    },
    optimization: {
        minimizer: [
            new TerserPlugin({ // ここ重要
                terserOptions: {
                    keep_fnames: true,// 必須
                },
                parallel: true,
            }),
        ],
    }
};
```

この問題は、`inversify-express-utils`の特定の箇所でクラスや関数の名前が圧縮された結果、
同じ名前を持つコントローラーが複数存在すると[判断](https://github.com/inversify/inversify-express-utils/blob/3368cd285e9db1e5918ae7fa90af9280de07e2ba/src/server.ts#L132)されてしまうことが原因でした。
具体的には以下のようなメタデータが生成され、エラーが発生します。

```javascript
// targetがes6以降の場合
Metadata: [
  {
    middleware: [ [Function (anonymous)] ],
    path: '/api',
    target: [class s]
  },
  {
    middleware: [ [Function (anonymous)] ],
    path: '/api',
    target: [class s]
  }
]
```

```javascript
// targetがes5以前の場合
Metadata: [
  {
    middleware: [ [Function (anonymous)] ],
    path: '/api',
    target: [function s]
  },
  {
    middleware: [ [Function (anonymous)] ],
    path: '/api',
    target: [function s]
  }
]
```

#### 補足: ES5とES6のクラス名表示の違い

ES5までのJavaScript環境では、クラスはコンストラクタ関数として扱われ、ログに関数として出力されるのが一般的でした。
しかし、ES6からは新しいクラス構文が導入され、ログの出力形式も変わりました。
この違いを理解することで、上記の問題がどのように発生するのかの背景をより深く理解できます。
（[TypeScriptでのクラス定義がES6とES5でどのようにコンパイルされるか](/learning/typescript-class-compilation-es6-vs-es5)少し詳しく書きました。）

```javascript
// targetがes6以降の場合
class MyNewClass {}
console.log(MyNewClass); // 出力: [class MyNewClass]
```

```javascript
// targetがes5以前の場合
function MyClass() {}
console.log(MyClass); // 出力: [Function: MyClass]
```
