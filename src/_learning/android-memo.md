---
title: "Android開発めも"
date: 2024-4-8T10:00:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
---

## Kotlin スタイルガイド

[公式サイト](https://developer.android.com/kotlin/style-guide?hl=ja)

Kotlin でコードを記述する際に、Google の Android コーディング標準に従うことです。
スタイルガイドを遵守することの目的は、コードを読みやすくするとともに、他の Android デベロッパーの記述方法との一貫性を持たせることです。この一貫性は、大規模なプロジェクトで共同作業を行う場合に重要となります。これにより、プロジェクト内のすべてのファイルでコードのスタイルが統一されます。

## uses-sdk

**公式ドキュメント**：[uses-sdk-element](https://developer.android.com/guide/topics/manifest/uses-sdk-element?hl=ja)

`<uses-sdk>`はAndroidアプリのマニフェストファイル内で使用され、アプリが動作するのに必要な最低限のAPIレベル（Androidのバージョン）、目標とするAPIレベル、そしてアプリがサポートする最高のAPIレベルを定義します。Google Playはこの情報を使って、互換性のないデバイスにはアプリが表示されないようにします。

### **android:minSdkVersion**

`android:minSdkVersion`は、アプリがインストールできる最低限のAndroidのAPIレベルを指定します。この数値より低いAPIレベルのデバイスでは、ユーザーはアプリをインストールできません。例えば、`android:minSdkVersion="16"`とすることで、APIレベル16（Android 4.1）未満のデバイスにはインストール不可となります。

※注意:この属性を宣言しない場合、システムはデフォルト値を「1」であると見なします。この値は、アプリがすべての Android バージョンと互換性を持つことを示します。

### **android:targetSdkVersion**

`android:targetSdkVersion`は、アプリがテストされ、最適化されたAPIレベルを指定します。この設定により、アプリは指定したAPIレベルに合わせて最新の挙動を利用できます。例えば、APIレベルを`android:targetSdkVersion="30"`に設定すると、Android 11の挙動に最適化されますが、それ以前のバージョンのAndroidでも動作します。

### **android:maxSdkVersion**

`android:maxSdkVersion`は、アプリが動作することが許可される最大のAPIレベルを指定します。しかし、この属性の使用は推奨されません。なぜなら、将来的に新しいAndroidバージョンがリリースされた際に、アプリがそのバージョンで動作しなくなる可能性があるからです。大多数のケースでは、アプリは新しいバージョンのAndroidでも下位互換性を持って動作します。

### **APIレベル**

APIレベルは、Androidの特定のバージョンにおけるフレームワークAPIのセットを識別する整数値です。この値は、アプリがどのバージョンのAndroidと互換性があるかをシステムに伝えます。開発者は、アプリの`<uses-sdk>`要素内で、最小、目標、最大のAPIレベルを指定することで、アプリの互換性範囲を明確に定義できます。

## onCreate

チュートリアル:[テキストを更新する](https://developer.android.com/codelabs/basic-android-kotlin-compose-first-app?hl=ja#4)

`onCreate()`関数は、Androidアプリのライフサイクルの中で最初に呼ばれる関数です。これはアプリが起動された時の「エントリーポイント」となります。主に、アプリの初期設定やユーザーインターフェースの構築を行います。

``kotlin
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    // ここに初期化のコードを書きます
}
``

`onCreate()`はアクティビティが生成される時に一度だけ呼び出されます。この関数内で、アプリのUIをセットアップするために`setContent()`関数が使用されます。

onCreate()メソッドの実行が完了すると、アクティビティは"開始"状態に移行し、システムはonStart()とonResume()メソッドを連続して呼び出します。これにより、アプリはユーザーとのインタラクションが可能な"実行中"状態になります。

### 行うこと

- **UIのセットアップ**: `setContentView()`メソッドを使って、アクティビティのレイアウトを定義します。これにより、指定したXMLレイアウトファイルが画面に表示されます。

    ```kotlin
    setContentView(R.layout.main_activity)
    ```

- **メンバー変数の初期化**: UIコンポーネント（例：`TextView`）の参照を取得し、アクティビティ内の変数に保存します。これにより、他のメソッドからこれらのコンポーネントを操作できるようになります。

    ```kotlin
    textView = findViewById(R.id.text_view)
    ```

- **インスタンス状態の復元**: `savedInstanceState`パラメータをチェックして、以前のインスタンス状態からデータを復元します。これは、デバイスの回転などでアクティビティが再作成された時に役立ちます。

    ```kotlin
    gameState = savedInstanceState?.getString(GAME_STATE_KEY)
    ```

### インスタンス状態の保存と復元

アクティビティがシステムによって破棄された場合（例えばデバイスが回転したとき）、`onSaveInstanceState()`メソッドをオーバーライドして、アクティビティの現在の状態を保存することができます。その後、アクティビティが再作成されると、`onCreate()`メソッド（または`onRestoreInstanceState()`メソッド）でこの保存された状態を復元できます。

## `setContent()`

`setContent()`関数はJetpack Composeを使用しているAndroidアプリで見られます。この関数を使って、UIのレイアウトを定義します。`@Composable`アノテーションがついた関数を`setContent`内で呼び出して、UIを構築します。

```kotlin
setContent {
    // ここで`@Composable`関数を呼び出してUIを定義
}
```

**`onCreate()`と`setContent()`の関係**

```mermaid
graph TD;
    A[アプリ起動] --> B[`onCreate()`が呼ばれる];
    B --> C[`setContent()`でUI構築];
    C --> D[`@Composable`関数でUI部品を定義];
```

アプリが起動すると、`onCreate()`が最初に呼び出され、その中で`setContent()`を使用してUIを構築します。`setContent()`は`@Composable`アノテーションが付いた関数を呼び出し、これによって実際のUI部品が定義されます。

## `@Composable`

`@Composable`アノテーションがついた関数は、UIの一部を構築するために使用されます。これらの関数は`setContent()`内や他の`@Composable`関数から呼び出されることができます

```kotlin
`@Composable`
fun MyApp() {
    // UIコンポーネントを定義
}
```

## composeのガイドライン

<https://github.com/androidx/androidx/tree/androidx-main/compose/docs>

### Compose関数の命名規則

- **パスカルケースを使用**: 複合語内の各単語の最初の文字は大文字にします。
  - 正しい例: `DoneButton`, `RoundIcon`
  - 誤った例: `doneButton`, `roundIcon`

- **名詞で命名**: 関数名は必ず名詞または名詞句であるべきです。
  - 正しい例: `UserProfile`, `SettingsMenu`
  - 誤った例: `ShowProfile`, `OpenSettings`

- **動詞や動詞句を避ける**: 関数名を動詞または動詞句にしないでください。
  - 正しい例: `SearchButton`, `InputField`
  - 誤った例: `SearchingData`, `DrawingCanvas`

- **名詞の前置詞を避ける**: 名詞の前に前置詞を付けないでください。
  - 正しい例: `LinkTextField`, `IconWithText`
  - 誤った例: `TextFieldForLink`, `IconAndText`

- **形容詞を避ける**: 関数名を形容詞にしないでください。
  - 正しい例: `PrimaryButton`, `LargeTextField`
  - 誤った例: `Clickable`, `Editable`

- **副詞を避ける**: 関数名を副詞にしないでください。
  - 正しい例: `OuterContainer`, `ExternalLink`
  - 誤った例: `QuicklyLoad`, `EasilyAccessible`

- **名詞の前に記述形容詞を付ける**: 名詞の前に形容詞を付けて、より具体的な説明をすることができます。
  - 正しい例: `SmallProfilePicture`, `BlueActionButton`
  - 誤った例: `ProfilePictureSmall`, `ButtonActionBlue`

## Composeの基本的な標準レイアウト要素

Composeには、UIを構築するための3つの基本的なレイアウト要素があります:

### [`Column`](https://developer.android.com/reference/kotlin/androidx/compose/foundation/layout/package-summary#Column(androidx.compose.ui.Modifier,androidx.compose.foundation.layout.Arrangement.Vertical,androidx.compose.ui.Alignment.Horizontal,kotlin.Function1))

- 縦にコンテンツを並べるレイアウトです。
- 子要素は縦方向に一つずつ重ねられて表示されます。
- スクロールビューなどでラップすることで、縦方向に多くのコンテンツを配置することが可能です。

### [`Row`](https://developer.android.com/reference/kotlin/androidx/compose/foundation/layout/package-summary#Row(androidx.compose.ui.Modifier,androidx.compose.foundation.layout.Arrangement.Horizontal,androidx.compose.ui.Alignment.Vertical,kotlin.Function1))

- 横にコンテンツを並べるレイアウトです。
- 子要素は横方向に隣り合って配置されます。
- 水平方向に複数のアイテムを並べたい場合に便利です。

### [`Box`](https://developer.android.com/reference/kotlin/androidx/compose/foundation/layout/package-summary#Box(androidx.compose.ui.Modifier,androidx.compose.ui.Alignment,kotlin.Boolean,kotlin.Function1))

- 重ね合わせのレイアウトです。
- 子要素はZ軸方向（画面に対して垂直方向）に重ねられます。
- 背景に画像を置いた上にテキストを重ねるなど、コンテンツを重ね合わせる際に使用します。

## Sync Project with Gradle Files

- `Sync Project with Gradle Files`は、Android Studioプロジェクトの設定をGradleビルドシステムと同期させる操作です。
- Gradleは、依存関係の管理、ビルドプロセスの設定、アプリケーションのコンパイルなどを行うビルド自動化ツールです。
- この同期により、Android Studioは最新のプロジェクト設定に基づいて正しくビルドできるようになります。

### 実行が必要になるタイミング

1. **プロジェクトの依存関係が変更されたとき**  
   新しいライブラリを追加したり、既存のライブラリのバージョンを変更した場合など。
2. **ビルド設定を変更したとき**  
   `build.gradle`ファイルに変更を加えた場合（例：ビルドスクリプトを編集したとき）。
3. **プロジェクトをリポジトリからクローンした直後**  
   プロジェクトを新しくセットアップする際に、初期同期を行う必要があります。
4. **Android Studioがプロジェクトの構造を誤って解釈しているとき**  
   不具合や予期しない挙動が見られる場合、同期を試みることで問題が解決することがあります。
5. **IDEやプラグインを更新した後**  
   大きな更新の後には、新しい設定や依存関係の変更を反映させるために同期が必要です。

## [リソースタイプ](https://developer.android.com/guide/topics/resources/available-resources?hl=ja)

Androidアプリ開発における`res/`ディレクトリは、アプリのさまざまなリソースを管理するための中心的な場所です。以下は、主要なリソースタイプとその用途です。

### アニメーション リソース

- **トゥイーン アニメーション**: `res/anim/`に保存し、`R.anim`クラスからアクセスします。
- **フレーム アニメーション**: `res/drawable/`に保存し、`R.drawable`クラスからアクセスします。

### 色状態リストのリソース

- **カラーリソース**: Viewの状態に応じて色を変えるために使用します。`res/color/`に保存し、`R.color`クラスからアクセスします。

### ドローアブル リソース

- **ビットマップやXMLグラフィック**: `res/drawable/`に保存し、`R.drawable`クラスからアクセスします。

### レイアウト リソース

- **UIレイアウト**: `res/layout/`に保存し、`R.layout`クラスからアクセスします。

### メニュー リソース

- **アプリメニュー**: `res/menu/`に保存し、`R.menu`クラスからアクセスします。

### 文字列リソース

- **文字列や文字列配列、複数形**: `res/values/`に保存し、`R.string`、`R.array`、`R.plurals`クラスからアクセスします。

### スタイル リソース

- **UI要素のスタイル**: `res/values/`に保存し、`R.style`クラスからアクセスします。

### フォント リソース

- **フォントファミリー**: `res/font/`に保存し、`R.font`クラスからアクセスします。

### その他のリソースタイプ

- **ブール値、色、ディメンション、ID、整数、整数配列、型付き配列**: 基本的な値や静的リソースとして`res/values/`に定義し、適切なクラスからアクセスします。

## 適切なコード プラクティスを採用

- **Android Studioでの抽出方法**:
  1. ハードコードされた文字列を選択します。
  2. 画面左側の電球アイコンをクリックし、「Extract string resource」を選択します。
  3. ダイアログで文字列リソースの名前（`happy_birthday_text`など）を指定し、「OK」をクリックします。

- **命名規則**:
  - 文字列リソースの名前には小文字を使用し、複数の単語はアンダースコアで区切ります。

- **strings.xmlファイル**:
  - 抽出された文字列リソースは`res/values/strings.xml`に保存されます。
  
  ```xml
  <resources>
      <string name="app_name">Happy Birthday</string>
      <string name="happy_birthday_text">Happy Birthday Sam!</string>
      <string name="signature_text">From Emma</string>
  </resources>
  ```

- コード内での使用方法:
  - getString(R.string.happy_birthday_text)またはstringResource(R.string.happy_birthday_text)を使用して、リソースファイルから文字列を取得します。
注: stringResourceを使用する場合は、必要に応じてimport androidx.compose.ui.res.stringResourceを追加する必要があります。
