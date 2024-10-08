---

title: "android 自動テストの基本"
date: 2024-4-15T010:40:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
description: "Androidアプリ開発における自動テストの基本を解説。ローカルテストとインストルメンテーションテストの違いや使い分け、ベストプラクティス、ディレクトリ構造、テストの実践的なコードサンプルを紹介します。"
---

## 自動テストの種類

### ローカルテスト

ローカルテストは、コードの小規模な部分を直接テストし、その部分が適切に機能するかを確認する自動テストの一種です。以下の特徴があります。

- **目的**: ローカルテストは、アプリケーションの小さな単位（例えば、個々の関数やクラス）が正しく動作するかを検証するために使用されます。これにより、特定のロジックや機能が期待どおりに動くかを確認できます。
- **実行環境**: 個人のワークステーションや開発環境で実行され、デバイスやエミュレータは不要。
- **テスト対象**: 関数、クラス、プロパティ。
- **リソース**: コンピュータリソースのオーバーヘッドが非常に少なく、限られたリソースでも高速に実行可能。
- **ツール**:  Android Studio が自動実行をサポート。

使いどころ:

- コードの単純な機能確認：個々の関数やクラスが正しく動作するかテストしたい場合に適しています。
- 高速な実行：コンピュータの基本的なリソースだけで実行できるため、テストの実行速度が非常に速いです。
- 開発初期：新しい機能を開発している最中に、その機能が正しく動作するかをすぐに確認したい時に役立ちます。

### インストルメンテーションテスト

インストルメンテーションテストは、Android開発におけるUIテストで、以下のような特徴を持っています。

- **目的**: インストルメンテーションテストは、アプリケーションのUIや、Android APIを含む複雑なインタラクションが正しく動作するかを検証するために使用されます。これには、アプリがユーザーの入力にどう反応するかや、異なる画面間の遷移が正確に行われるかなどが含まれます。
- **実行環境**: 物理デバイスまたはエミュレータ。
- **テスト対象**: Android APIとそのプラットフォームのAPIおよびサービスに依存するアプリの要素。
- **APK**: テストコードは固有のAndroid Application Package（APK）に組み込まれ、通常のアプリAPKと共にデバイスにインストールされます。

使いどころ:

- UIの動作確認：ユーザーインターフェースが期待通りに機能するかテストしたい場合に適しています。
- 実デバイスでのテスト：アプリが実際のデバイスや特定のAndroidバージョンでどのように動作するかを確認できます。
- 統合テスト：異なるアプリコンポーネントが連携して動作するかを検証します。

## テストのベストプラクティス

- **テストの記述**: メソッドの形式で記述し、`@Test` アノテーションを付けます。これにより、そのメソッドがテストメソッドであることがコンパイラによって認識されます。
- **テストメソッド名**: テストする内容と期待される結果を明確に示す名前をつけます。
- **アサーション**: テストは通常、アサーション（例: `assertTrue()`）で終了し、特定の条件が満たされたことを確認します。

## @VisibleForTesting

`@VisibleForTesting`アノテーションは、本来非公開であるべきメソッドやプロパティをテストのために公開する際に使用します。これにより、テスト時のみアクセス可能となり、本番環境での誤用を防ぎます。これは、テストの信頼性を保ちながら、アーキテクチャの整合性を保つのに役立ちます。

## ディレクトリ階層のベストプラクティス

テストファイルを作成する際には、ソースディレクトリ（src）とは別のテスト専用のディレクトリ（test）に配置します。これにより、テストコードとアプリケーションコードが明確に区分され、管理が容易になります。

```plaintext
TipTime/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/
│   │   │   │   └── com/
│   │   │   │       └── example/
│   │   │   │           └── tiptime/
│   │   │   │               └── MainActivity.kt  # メインアクティビティ
│   │   │   ├── res/                             # リソースファイル
│   │   │   └── AndroidManifest.xml              # アプリのマニフェストファイル
│   │   ├── test/
│   │   │   ├── java/
│   │   │   │   └── com/
│   │   │   │       └── example/
│   │   │   │           └── tiptime/
│   │   │   │               └── MainActivityTest.kt  # メインアクティビティのテスト
│   │   └── androidTest/
│   │       ├── java/
│   │       │   └── com/
│   │       │       └── example/
│   │       │           └── tiptime/
│   │       │               └── MainActivityInstrumentedTest.kt  # インストルメンテーションテスト
│   └── build.gradle                              # Gradle ビルド設定ファイル
└── build.gradle                                  # トップレベルの Gradle ビルド設定ファイル

```

- main ディレクトリには、アプリケーションの主要なソースコードが含まれます。これには Kotlin ファイル、リソースファイル、および AndroidManifest.xml が含まれます。
- test ディレクトリには、JUnit などを使用した単体テスト（ローカルテスト）のコードが含まれます。これらのテストはデバイスやエミュレータを必要とせずに実行できます。
- androidTest ディレクトリには、インストルメンテーションテストが含まれます。これらのテストはデバイスやエミュレータ上で実行され、アプリケーションのUIや外部依存関係を含む統合テストをカバーします。

## 二つのテストの使い分け

ローカルテストはコードの基本的な部分を迅速にテストするために使用し、インストルメンテーションテストはアプリケーション全体の動作を実際のデバイスやエミュレータ上で確認するために使用します。
開発の初期段階ではローカルテストを多用し、アプリが成熟してきたらインストルメンテーションテストでより広範なテストを行うことが一般的です。

## 参考リンク

- [Android でアプリをテストする](https://developer.android.com/training/testing?hl=ja)
- [自動テストを作成する](https://developer.android.com/codelabs/basic-android-kotlin-compose-write-automated-tests?hl=ja&continue=https%3A%2F%2Fdeveloper.android.com%2Fcourses%2Fpathways%2Fandroid-basics-compose-unit-2-pathway-3%3Fhl%3Dja%23codelab-https%3A%2F%2Fdeveloper.android.com%2Fcodelabs%2Fbasic-android-kotlin-compose-write-automated-tests#0)

### サンプルコード

**MainActivity.kt**

```java
package com.example.tiptime

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.annotation.StringRes
import androidx.annotation.VisibleForTesting
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.tiptime.ui.theme.TipTimeTheme
import java.text.NumberFormat
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            TipTimeTheme {
                // A surface container using the 'background' color from the theme
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    TipTimeLayout()
                }
            }
        }
    }
}
@Composable
fun TipTimeLayout() {
    var amountInput by remember { mutableStateOf("") }
    var tipInput by remember { mutableStateOf("") }
    val amount = amountInput.toDoubleOrNull() ?: 0.0
    val tipPercent = tipInput.toDoubleOrNull() ?: 0.0
    var roundUp by remember { mutableStateOf(false) }

    val tip = calculateTip(amount, tipPercent,roundUp)
    Column(
        modifier = Modifier.padding(40.dp).verticalScroll(rememberScrollState()),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = stringResource(R.string.calculate_tip),
            modifier = Modifier
                .padding(bottom = 16.dp)
                .align(alignment = Alignment.Start)
        )
        EditNumberField(
            label = R.string.bill_amount,
            keyboardOptions = KeyboardOptions.Default.copy(
                keyboardType = KeyboardType.Number,
                imeAction = ImeAction.Next
            ),
            value = amountInput,
            onValueChange = { amountInput = it },
            modifier = Modifier
                .padding(bottom = 32.dp)
                .fillMaxWidth()
        )
        EditNumberField(
            label = R.string.how_was_the_service,
            keyboardOptions = KeyboardOptions.Default.copy(
                keyboardType = KeyboardType.Number,
                imeAction = ImeAction.Done
            ),
            value = tipInput,
            onValueChange = { tipInput = it },
            modifier = Modifier
                .padding(bottom = 32.dp)
                .fillMaxWidth()
        )
        RoundTheTipRow(
            roundUp = roundUp,
            onRoundUpChanged = { roundUp = it },
            modifier = Modifier.padding(bottom = 32.dp)
        )
        Text(
            text = stringResource(R.string.tip_amount, tip),
            style = MaterialTheme.typography.displaySmall
        )
        Spacer(modifier = Modifier.height(150.dp))
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditNumberField(
    @StringRes label: Int,
    keyboardOptions: KeyboardOptions,
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier) {

    TextField(
        value = value,
        onValueChange = onValueChange,
        modifier = Modifier.fillMaxWidth(),
        label = { Text(stringResource(label)) },
        singleLine = true,
        keyboardOptions = keyboardOptions,
    )
}

@Composable
fun RoundTheTipRow(
    roundUp: Boolean,
    onRoundUpChanged: (Boolean) -> Unit,
    modifier: Modifier = Modifier) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .size(48.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text = stringResource(R.string.round_up_tip))
        Switch(
            modifier = modifier
                .fillMaxWidth()
                .wrapContentWidth(Alignment.End),
            checked = roundUp,
            onCheckedChange = onRoundUpChanged,
        )
    }
}

@VisibleForTesting
internal fun calculateTip(amount: Double, tipPercent: Double = 15.0,roundUp: Boolean): String {
    var tip = tipPercent / 100 * amount
    if (roundUp) {
        tip = kotlin.math.ceil(tip)
    }
    return NumberFormat.getCurrencyInstance().format(tip)
}

@Preview(showBackground = true)
@Composable
fun GreetingPreview() {
    TipTimeTheme {
        TipTimeLayout()
    }
}

```

**MainActivityTest.kt**

```java
package com.example.tiptime

import org.junit.Test

import org.junit.Assert.*
import java.text.NumberFormat

/**
 * Example local unit test, which will execute on the development machine (host).
 *
 * See [testing documentation](http://d.android.com/tools/testing).
 */
class MainActivityTest {

    @Test
    fun calculateTip_20PercentNoRoundup() {
        val amount = 10.00
        val tipPercent = 20.00
        val expectedTip = NumberFormat.getCurrencyInstance().format(2)
        val actualTip = calculateTip(amount = amount, tipPercent = tipPercent, false)
        assertEquals(expectedTip, actualTip)
    }
}
```

**MainActivityInstrumentedTest**

```java
package com.example.tiptime

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performTextInput
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.tiptime.ui.theme.TipTimeTheme

import org.junit.Test
import org.junit.runner.RunWith

import org.junit.Assert.*
import org.junit.Rule
import java.text.NumberFormat

/**
 * Instrumented test, which will execute on an Android device.
 *
 * See [testing documentation](http://d.android.com/tools/testing).
 */
@RunWith(AndroidJUnit4::class)
class ExampleInstrumentedTest {
    @get:Rule
    val composeTestRule = createComposeRule()
    @Test
    fun calculate_20_percent_tip() {
        composeTestRule.setContent {
            TipTimeTheme {
                Surface (modifier = Modifier.fillMaxSize()){
                    TipTimeLayout()
                }
            }
        }
        composeTestRule.onNodeWithText("Bill Amount")
            .performTextInput("10")
        composeTestRule.onNodeWithText("Tip Percentage").performTextInput("20")
        val expectedTip = NumberFormat.getCurrencyInstance().format(2)
        composeTestRule.onNodeWithText("Tip Amount: $expectedTip").assertExists(
            "No node with this text was found."
        )
    }
}

```
