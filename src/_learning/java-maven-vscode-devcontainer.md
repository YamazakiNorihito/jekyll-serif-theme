---
title: "JavaとMavenを使った開発環境の整備"
date: 2024-10-17T13:00:00
jobtitle: "Java/Maven開発者"
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - Java
  - Maven
  - VSCode
  - Dev Container
  - 開発環境
description: "Java 11とMavenを使用して、VSCodeとDev Containerで開発環境を整える方法を解説します。詳細な設定手順とプロジェクト作成の例を紹介します。"
---

KeycloakのSPIを開発するために、開発環境を整えます。本記事では、VSCodeとDev Containerを使用して環境を整備する手順を説明します。対象とするKeycloakのバージョンは[Keycloak 22.0.0](https://www.keycloak.org/docs/latest/release_notes/index.html#keycloak-22-0-0)であり、Java 11を利用します。

## 開発環境の準備

以下のコンテナイメージと設定を使用して、開発環境を構築します。

- **コンテナイメージ**: `mcr.microsoft.com/devcontainers/java:1-21-bullseye`
  - VSCodeの開発環境として推奨されているため、このイメージをそのまま使用します。重要なのはJava 11が利用可能であることです。

- **Features**: 開発に必要なSDKやツールがあらかじめセットアップされた状態で利用できる「Features」を使用します。
  - Java開発用に[ghcr.io/devcontainers/features/java:1](https://containers.dev/features)を使用します。
  - パッケージ管理およびビルドには`Maven`を使用します（KeycloakのリポジトリがMavenを使用しているため）。

- **カスタマイズ**: `customizations.vscode`
  - フォーマッターにはGoogleのJava Style Guideを使用します。
  - 推奨する拡張機能は、[Microsoftのサイト](https://code.visualstudio.com/docs/java/extensions)から以下を使用します。
    - Language Support for Java™ by Red Hat
    - Debugger for Java
    - Test Runner for Java
    - Maven for Java
    - Project Manager for Java
    - Visual Studio IntelliCode
  - 追加のおすすめ拡張機能
    - Prettier - Code formatter: Java以外のコード（MarkdownやJSONなど）のフォーマットにも使用できます。

**.devcontainer/devcontainer.json**

```json
{
 "name": "Java",
 "image": "mcr.microsoft.com/devcontainers/java:1-21-bullseye",
 "features": {
  "ghcr.io/devcontainers/features/java:1": {
   "version": "11",
   "installMaven": "true",
   "installGradle": "false"
  }
 },
 "postCreateCommand": "java -version",
 "customizations": {
  "vscode": {
   "settings": {
    "java.format.settings.url": "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
    "java.format.settings.profile": "GoogleStyle"
   },
   "extensions": [
    "redhat.java",
    "vscjava.vscode-java-debug",
    "vscjava.vscode-java-test",
    "vscjava.vscode-maven",
    "vscjava.vscode-java-dependency",
    "VisualStudioExptTeam.vscodeintellicode",
    "esbenp.prettier-vscode"
   ]
  }
 }
}
```

## 試しに動かしてみよう

開発環境を整えたら、JavaとMavenの動作確認を行いましょう。以下の手順で、シンプルなMavenプロジェクトを作成し、ビルドおよび実行してみます。

### 1. 新しいMavenプロジェクトを作成する

1. **VSCodeのターミナルを開く**
   - メニューバーから「Terminal」→「New Terminal」を選択します。

2. **Mavenコマンドでプロジェクトを生成する**
   - 次のコマンドをターミナルに入力し、Enterキーを押してMavenプロジェクトを作成します。

   ```sh
   mvn archetype:generate -DgroupId=com.example -DartifactId=my-app -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
   ```

   - `groupId`: プロジェクトの組織名やドメインに対応します（例：`com.example`）。
   - `artifactId`: プロジェクトの名前です（例：`my-app`）。

### 2. プロジェクト構成を確認する

コマンドが成功すると、`my-app`というディレクトリが作成されます。このディレクトリには以下の構成のファイルが含まれます。

```
my-app/
├── pom.xml
└── src/
    ├── main/
    │   └── java/
    │       └── com/
    │           └── example/
    │               └── App.java
    └── test/
        └── java/
            └── com/
                └── example/
                    └── AppTest.java
```

### 3. Mavenプロジェクトのビルドと実行

1. **プロジェクトをビルドする**
   - プロジェクトのルートディレクトリ（`my-app`）に移動し、Mavenでプロジェクトをビルドします。

   ```sh
    cd my-app
    mvn package
   ```

   - `target`フォルダ内に`my-app-1.0-SNAPSHOT.jar`というJARファイルが生成されます。

2. **アプリケーションを実行する**
   - ビルドが成功したら、次のコマンドでJavaアプリケーションを実行します。

   ```sh
    java -cp target/my-app-1.0-SNAPSHOT.jar com.example.App
   ```

   - 正常に動作すると、次のような出力が表示されるはずです。

   ```txt
    Hello World!
   ```

### 4. テストの実行

1. **Mavenでテストを実行する**
   - 次に、Mavenを使ってプロジェクトのテストを実行します。

   ```sh
    mvn test
   ```

- `AppTest.java`が実行され、テストが成功したかどうかが表示されます。

これでMavenとJavaの基本的な動作確認が完了し、プロジェクトが正しく動作していることを確認できます。ぜひ試してみてください！
