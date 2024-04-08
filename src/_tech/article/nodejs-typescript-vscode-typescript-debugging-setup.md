---
title: "vscodeでtypescriptで構築したアプリのデバックを快適にしよう"
date: 2024-3-26T10:08:00
weight: 4
mermaid: true
categories:
  - javascript
  - nodejs
  - typescript
---


Visual Studio Code (VSCode) を使用してTypeScriptで構築されたアプリケーションのデバッグプロセスを、
コード変更時の自動再ビルドと再起動を通じて、
より快適にする方法を解説します。
TypeScript開発では、ソースコードの変更後に都度コンパイルを行う必要がありますが、
この作業は手間と時間がかかります。
そこで、VSCodeのtasks.jsonとlaunch.jsonの設定を適切に行うことで、
変更を監視し自動でビルドとデバッグセッションの再起動を行う環境を構築します。

## 目的

- TypeScriptで開発されたアプリケーションのデバッグプロセスを効率化する。
- コード変更時に自動で再ビルドと再起動を行い、開発者が手動での再起動作業から解放されるようにする。

## 使用するVSCode機能

- タスクランナー(tasks.json): プロジェクトビルドや外部ツールの実行を自動化するために使用します。ここでは、TypeScriptの自動コンパイル設定を行います。
- デバッグ設定(launch.json): デバッグセッションを管理する設定を行います。ここでは、Nodemonを使用して変更があった場合に自動でアプリケーションを再起動する設定を加えます。

## tasks.jsonの設定

tasks.jsonでは、TypeScriptコンパイラ(tsc)を使用してプロジェクトをビルドするタスクを設定します。--watchオプションを使用することで、ソースファイルの変更をリアルタイムで監視し、変更があるたびに自動的にビルドを実行します。

| プロパティ       | 設定値                                 | 説明                                                                                                   |
| ---------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| `version`        | `2.0.0`                                | タスク設定のバージョン。`2.0.0`が現在のバージョンです。                                                |
| `label`          | `tsc: build - tsconfig.json`           | タスクの識別名。この名前でタスクを参照できます。                                                       |
| `type`           | `shell`                                | タスクの実行タイプ。`shell`はシェルコマンドの実行を意味します。                                        |
| `command`        | `tsc`                                  | 実行するコマンド。TypeScriptコンパイラ(`tsc`)を実行します。                                            |
| `args`           | `["--watch", "-p", "tsconfig.json"]`   | コマンドに渡される引数。プロジェクトを監視モードでビルドします。                                       |
| `isBackground`   | `true`                                 | タスクがバックグラウンドで実行されるかどうか。`true`ならバックグラウンド実行を意味します。             |
| `problemMatcher` | `$tsc-watch`                           | 出力を解析し、問題を特定するためのパターン。`$tsc-watch`はTypeScriptの監視モードに最適化されています。 |
| `group`          | `{"kind": "build", "isDefault": true}` | タスクを`build`グループに分類し、デフォルトのビルドタスクとして設定します。                            |

## launch.jsonの設定

launch.jsonでは、デバッグセッションの設定を行います。NodemonをruntimeExecutableとして使用することで、ビルド後のファイル(build/index.js)に対する変更を監視し、変更があった場合にNode.jsアプリケーションを自動的に再起動します。また、preLaunchTaskによりデバッグセッション開始前にTypeScriptのビルドタスクを実行し、最新のコードでデバッグが行われるようにします。

| プロパティ          | 設定値                                         | 説明                                                                                     |
| ------------------- | ---------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `version`           | `0.2.0`                                        | ランチ設定のバージョン。`0.2.0`が現在のバージョンです。                                  |
| `name`              | `Launch with Nodemon`                          | デバッグ設定の識別名。この名前で設定を参照できます。                                     |
| `type`              | `node`                                         | デバッグセッションのタイプ。Node.jsアプリケーションのデバッグを意味します。              |
| `request`           | `launch`                                       | デバッグセッションの要求タイプ。`launch`は新しいデバッグセッションの開始を意味します。   |
| `runtimeExecutable` | `${workspaceFolder}/node_modules/.bin/nodemon` | デバッグ実行時に使用する実行ファイル。Nodemonを指定しています。                          |
| `program`           | `${workspaceFolder}/build/index.js`            | デバッグするプログラムのパス。ビルド後のJavaScriptファイルを指定します。                 |
| `restart`           | `true`                                         | ファイル変更時にデバッグセッションが自動的に再起動するかどうか。`true`なら再起動します。 |
| `preLaunchTask`     | `tsc: build - tsconfig.json`                   | デバッグセッション開始前に実行されるタスク。TypeScriptのビルドを行います。               |
| `outFiles`          | `["${workspaceFolder}/build/**/*.js"]`         | デバッグされるトランスパイル済みファイルの場所。ビルドディレクトリ                       |

## 各ファイル

*task.json*

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "tsc: build - tsconfig.json",
            "type": "shell",
            "command": "tsc",
            "args": ["--watch", "-p", "tsconfig.json"],
            "isBackground": true,
            "problemMatcher": "$tsc-watch",
            "group": {
                "kind": "build",
                "isDefault": true
            }
        }
    ]
}
```

<details>
<summary>*launch.json*</summary>

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Launch with Nodemon",
            "type": "node",
            "request": "launch",
            "runtimeExecutable": "${workspaceFolder}/node_modules/.bin/nodemon",
            "program": "${workspaceFolder}/build/index.js",
            "restart": true,
            "preLaunchTask": "tsc: build - tsconfig.json",
            "outFiles": [
                "${workspaceFolder}/build/**/*.js"
            ],
            "skipFiles": [
                "<node_internals>/**"
            ],
            // https://github.com/node-config/node-config/wiki/Strict-Mode#node_env-value-of-local-is-ambiguous
            "env": {
                "NODE_ENV": "myhost"
            },
            "sourceMaps": true,
            "smartStep": true,
            "runtimeVersion": "20"
        }
    ]
}

```

</details>

<details>

<summary>launch.json</summary>

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Launch with Nodemon",
            "type": "node",
            "request": "launch",
            "runtimeExecutable": "${workspaceFolder}/node_modules/.bin/nodemon",
            "program": "${workspaceFolder}/build/index.js",
            "restart": true,
            "preLaunchTask": "tsc: build - tsconfig.json",
            "outFiles": [
                "${workspaceFolder}/build/**/*.js"
            ],
            "skipFiles": [
                "<node_internals>/**"
            ],
            // https://github.com/node-config/node-config/wiki/Strict-Mode#node_env-value-of-local-is-ambiguous
            "env": {
                "NODE_ENV": "myhost"
            },
            "sourceMaps": true,
            "smartStep": true,
            "runtimeVersion": "20"
        }
    ]
}
```

</details>

<details>

<summary>package.json</summary>

```json
{
  "name": "myapp",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "jest",
    "start": "node build/index.js",
    "lint": "gts lint",
    "clean": "gts clean",
    "compile": "tsc",
    "fix": "gts fix",
    "prepare": "npm run compile",
    "pretest": "npm run compile",
    "posttest": "npm run lint"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "engines": {
    "node": "20.x"
  },
  "devDependencies": {
    "@types/config": "^3.3.4",
    "@types/express": "^4.17.21",
    "@types/inversify": "^2.0.33",
    "@types/jest": "^29.5.12",
    "@types/node": "20.8.2",
    "@types/prettyjson": "^0.0.33",
    "@types/uuid": "^9.0.8",
    "gts": "^5.2.0",
    "jest": "^29.7.0",
    "jest-mock-extended": "^3.0.5",
    "nodemon": "^3.1.0",
    "ts-jest": "^29.1.2",
    "typescript": "~5.1.6"
  },
  "dependencies": {
    "axios": "^1.6.7",
    "config": "^3.3.11",
    "dayjs": "^1.11.10",
    "express": "^4.18.3",
    "inversify": "^6.0.2",
    "inversify-express-utils": "^6.4.6",
    "jose": "^5.2.3",
    "mysql2": "^3.9.2",
    "prettyjson": "^1.2.5",
    "redis": "^4.6.13",
    "reflect-metadata": "^0.2.1",
    "uuid": "^9.0.1"
  }
}

```

</details>
