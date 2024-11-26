---
title: "Python virtual env memo"
date: 2024-11-26T04:25:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - Python
description: ""
---

## Python仮想環境メモ

### 仮想環境の使用方法

以下の手順に従って、仮想環境を作成および利用します。

#### 1. 仮想環境を作成する

`venv`モジュールを使って、プロジェクト専用の仮想環境を作成します。

```sh
python3 -m venv path/to/venv
```

- `path/to/venv` は仮想環境のディレクトリパスです。例えば、`venv`ディレクトリを現在のプロジェクトフォルダ内に作成する場合は次のようにします:

```sh
python3 -m venv venv
```

#### 2. 仮想環境を有効化する

仮想環境を有効化すると、以降のPythonコマンドや`pip`コマンドは仮想環境内で実行されます。

- Linux/macOS:

  ```sh
  source path/to/venv/bin/activate
  ```

- Windows:

  ```sh
  path\to\venv\Scripts\activate
  ```

有効化されると、ターミナルのプロンプトに仮想環境の名前が表示されます。

#### 3. パッケージをインストールする

仮想環境内で必要なパッケージをインストールします。

```sh
pip install パッケージ名
```

例:

```sh
pip install cfn-lint
```

#### 4. 仮想環境を無効化する

作業を終了したら、仮想環境を無効化します。

```sh
deactivate
```

無効化すると、元のPython環境に戻ります。

#### 5. 仮想環境を削除する

不要になった仮想環境は、作成したディレクトリを削除することで簡単に消去できます。

```sh
rm -rf path/to/venv
```
