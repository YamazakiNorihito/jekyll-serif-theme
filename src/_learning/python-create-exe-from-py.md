---
title: "Python ファイルから EXE ファイルを作成する方法"
date: 2025-04-07T10:26:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - Python
description: "Pythonで作成したスクリプトを EXE ファイルとして配布する方法について、PyInstaller の使い方や GitHub Actions を使った自動ビルド手順をまとめています。"
---

Python で作成したファイルを EXE ファイルとして配布するための手順をまとめました。

---

## 対象の Python コード

`main.py` の内容：

```python
# main.py
import json

realm_info = {
  "name": "hogemaru",
  "lang": "ja"
}

with open("sample.json", "w", encoding="utf-8") as f:
    json.dump(realm_info, f, ensure_ascii=False, indent=2)
```

---

## EXE ファイル作成手順

1. **PyInstaller をインストール**

```bash
pip install pyinstaller
```

2. **EXE ファイルを作成**

以下のコマンドで `dist/sample.exe` が生成されます：

```bash
pyinstaller --onefile --name sample.exe main.py
```

3. **生成された実行ファイルの場所**

```
dist/sample.exe
```

---

## GitHub Actions によるビルド自動化

`main.py` をビルドして `.exe` をアーティファクトとしてアップロードするワークフローです。

`.github/workflows/build.yml`

```yaml
name: Build EXE

on:
  push:
    branches: [ develop ]

jobs:
  build-windows-exe:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: pip install pyinstaller

      - name: Build .exe
        run: pyinstaller --onefile --name sample.exe main.py

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: sample.exe
          path: dist/sample.exe
```

---

必要に応じて `.spec` ファイルを調整することで、アイコンの設定や追加ファイルの同梱も可能です。  
EXE 化でつまづいた点なども、今後追記していくと便利です 🔧
