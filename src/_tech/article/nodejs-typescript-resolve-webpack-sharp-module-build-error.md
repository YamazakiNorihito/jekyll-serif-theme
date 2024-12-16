---
title: "Webpackでsharpモジュールのビルドエラーを解決する方法"
date: 2023-11-08T21:15:00
weight: 4
categories:
  - javascript
  - nodejs
  - typescript
description: "Webpackでsharpライブラリをビルドする際のエラーを、node-loaderを使って解決する方法を紹介します。ネイティブモジュールの扱いに関する設定方法も解説。"
tags:
  - Webpack
  - sharp
  - node-loader
  - ビルドエラー
  - Node.js
  - TypeScript
  - ネイティブモジュール
---

Webpackでビルドをしているのですが、sharpライブラリをinstallしたら突然Buildエラーになった。

```bash
ERROR in ./node_modules/sharp/build/Release/sharp-darwin-arm64v8.node 1:0
Module parse failed: Unexpected character '�' (1:0)
You may need an appropriate loader to handle this file type, currently no loaders are configured to process this file. See https://webpack.js.org/concepts#loaders
(Source code omitted for this binary file)
 @ ./node_modules/sharp/build/Release/ sync ^\.\/sharp\-.*\.node$ ./sharp-darwin-arm64v8.node
 @ ./node_modules/sharp/lib/sharp.js 10:19-76
 @ ./node_modules/sharp/lib/input.js 8:14-32
 @ ./node_modules/sharp/lib/index.js 7:0-18
 @ ./src/utils.ts 21:30-46
 @ ./src/index.ts 13:14-32

webpack 5.88.2 compiled with 1 error and 1 warning in 19696 ms
```

原因は、Node.jsの画像処理ライブラリである`sharp`をWebpackでビルドしようとした際に発生しています。
`sharp`は内部でネイティブのバイナリファイルを使用しており、Webpackはデフォルトではこれらのバイナリファイルを扱うことができません。

Webpackで`sharp`モジュールのビルドエラーを解決するために、
`node-loader`を設定に追加する方法が効果的でした。
`node-loader`はWebpackがネイティブの
.nodeファイルを扱う際に必要なローダーです。
以下の設定をwebpack.config.jsに追加することで、問題を解決することができます：

*Webpack*

```javascript
module: {
  rules: [
    {
      test: /\.node$/,
      use: 'node-loader',
    },
  ],
},
```

[node-loader](https://webpack.js.org/loaders/node-loader/)はWebpackのローダーの一つで、
Node.jsの[ネイティブモジュール](https://js.studio-kingdom.com/webpack/getting_started/using_loaders)（.node拡張子を持つファイル）をWebpackで扱えるように変換する役割を持っています。
これにより、サーバーサイドやデスクトップアプリケーションでよく使用されるネイティブモジュールを、
Webアプリケーション内で利用することが可能になります。

### 環境設定

*package.json*

```javascript
{
  "name": "sample",
  "version": "0.0.0",
  "description": "sample api",
  "main": "./src/index.ts",
  "scripts": {
    "local": "DEBUG=* nodemon ./src/index.ts",
    "build": "webpack --env NODE_OPTIONS=--openssl-legacy-provider --stats-error-details",
    "start": "DEBUG=* node ./dist/index.js"
  },
  "author": "",
  "license": "ISC",
  "dependencies": {
    "@aws-sdk/client-cognito-identity-provider": "^3.409.0",
    "@aws-sdk/client-mediaconvert": "^3.409.0",
    "@aws-sdk/client-s3": "^3.409.0",
    "@aws-sdk/lib-storage": "^3.438.0",
    "@types/node": "^20.6.0",
    "amazon-cognito-identity-js": "^6.3.5",
    "axios": "^1.5.0",
    "body-parser": "^1.20.2",
    "cdate": "^0.0.7",
    "co": "^4.6.0",
    "cors": "^2.8.5",
    "debug": "^4.3.4",
    "dotenv": "^16.3.1",
    "express": "^4.18.2",
    "file-type": "^18.5.0",
    "inversify": "^6.0.1",
    "inversify-binding-decorators": "^4.0.0",
    "inversify-express-utils": "^6.4.3",
    "ioredis": "^5.3.2",
    "jmespath": "^0.16.0",
    "jose": "^4.15.1",
    "json2csv": "^6.0.0-alpha.2",
    "jwk-to-pem": "^2.0.5",
    "make-error": "^1.3.6",
    "mysql2": "^3.6.0",
    "node-fetch": "^3.3.2",
    "reflect-metadata": "^0.1.13",
    "sequelize": "^6.33.0",
    "sequelize-cli": "^6.6.1",
    "sharp": "^0.32.6",
    "ts-jose": "^4.15.1",
    "uuid": "^9.0.0"
  },
  "devDependencies": {
    "@babel/plugin-proposal-decorators": "^7.22.15",
    "@babel/preset-env": "^7.22.15",
    "@babel/preset-typescript": "^7.22.15",
    "@types/cors": "^2.8.15",
    "@types/express": "^4.17.17",
    "@types/jsonwebtoken": "^9.0.3",
    "@types/jwk-to-pem": "^2.0.1",
    "@types/redis": "^4.0.11",
    "@typescript-eslint/eslint-plugin": "^6.6.0",
    "aws-crt": "^1.18.0",
    "babel-loader": "^9.1.3",
    "eslint": "^8.49.0",
    "eslint-config-prettier": "^9.0.0",
    "eslint-config-standard-with-typescript": "^39.0.0",
    "eslint-plugin-import": "^2.28.1",
    "eslint-plugin-jest": "^27.6.0",
    "eslint-plugin-n": "^16.0.2",
    "eslint-plugin-promise": "^6.1.1",
    "jest": "^29.6.4",
    "node-loader": "^2.0.0",
    "nodemon": "^3.0.1",
    "pg-hstore": "^2.3.4",
    "prettier": "^3.0.3",
    "terser-webpack-plugin": "^5.3.9",
    "ts-loader": "^9.4.4",
    "ts-node": "^10.9.1",
    "tsconfig-paths-webpack-plugin": "^4.1.0",
    "typescript": "^5.2.2",
    "webpack": "^5.88.2",
    "webpack-cli": "^5.1.4",
    "webpack-node-externals": "^3.0.0",
    "zod": "^3.22.2"
  },
  "nodemonConfig": {
    "watch": [
      "src"
    ],
    "ext": "ts",
    "exec": "node --inspect --require ts-node/register ./src/index.ts"
  }
}
```

*tsconfig.json*

```javascript
{
  "compilerOptions": {
    "sourceMap": true,
    "target": "esnext",
    "module": "CommonJS",
    "moduleResolution": "node",
    "outDir": "./dist",
    "rootDir": "./",
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "strict": true,
    "skipLibCheck": true,
    "noImplicitAny": true,
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true,
    "useDefineForClassFields": true,
    "strictPropertyInitialization": false,
    "typeRoots": ["./types", "./node_modules/@types"]
  },
  "ts-node": {
    "esm": true,
    "experimentalSpecifierResolution": "node"
  },
  "include": ["src/**/*"]
}
```

*webpack.config.js*

```javascript
const path = require('path');
const TerserPlugin = require('terser-webpack-plugin');
const { TsconfigPathsPlugin } = require('tsconfig-paths-webpack-plugin');
const nodeExternals = require('webpack-node-externals');

module.exports = {
  mode: 'production', //development | production
  target: 'node',
  externals: [nodeExternals()], // ネイティブモジュールを外部依存関係として扱う
  entry: './src/index.ts',
  output: {
    filename: 'index.js',
    path: path.resolve(__dirname, 'dist'),
    libraryTarget: 'commonjs2',
  },
  devtool: 'inline-source-map',
  module: {
    rules: [
      {
        test: /\.ts$/,
        include: [path.resolve(__dirname, 'src'), path.resolve(__dirname, 'test')],
        exclude: /(node_modules | test)/,
        loader: 'babel-loader',
        options: {
          babelrc: false,
          presets: ['@babel/preset-env', ['@babel/preset-typescript', { allownamespaces: true }]],
          plugins: [['@babel/plugin-proposal-decorators', { version: '2023-05' }]],
        },
      },
      {
        test: /\.ts$/,
        include: [path.resolve(__dirname, 'src'), path.resolve(__dirname, 'test')],
        exclude: /(node_modules | test)/,
        use: [{ loader: 'ts-loader' }],
      },
      {
        test: /\.node$/,
        use: 'node-loader',
      },
    ],
  },
  optimization: {
    minimizer: [
      new TerserPlugin({
        terserOptions: {
          compress: {
            drop_console: true,
          },
          keep_classnames: true,
          keep_fnames: true,
          sourceMap: true,
        },
        parallel: true,
      }),
    ],
  },
  resolve: {
    extensions: ['.ts', '...'],
    alias: {
      'aws-crt': path.resolve(__dirname, 'node_modules/aws-crt'),
    },
    plugins: [new TsconfigPathsPlugin()],
  },
  ignoreWarnings: [
    { module: /aws-crt/ },
    { module: /express/ },
    { module: /sequelize/ },
    { module: /express/ },
    {
      message: /Critical dependency: the request of a dependency is an expression/,
    },
  ],
};

```
