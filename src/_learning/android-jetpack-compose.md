---

title: "android-jetpack-composeの理解を深めていく"
date: 2024-4-9T09:15:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
---
<https://developer.android.com/develop/ui/compose/mental-model?hl=ja>

## Jetpack Compose

Jetpack Composeとは、Androidアプリの画面を作るための最新ツールです。これを使うと、アプリの見た目を作るのがすごく簡単になります。どう簡単になるかというと、画面のデザインを「宣言的」に書くことで、プログラムが自動で画面を更新してくれるんです。

### 宣言型プログラミングって何？

今までのAndroidアプリでは、ユーザーが何か操作をするたびに、プログラマーが手動で画面を更新する必要がありました。例えば、「このボタンを押したら、この文字を表示する」という風に、一つ一つ指示を出していました。

でも、これって結構面倒で、間違えやすいんです。データが色んな場所に表示されていると、どこを更新したらいいかわからなくなったり、2つの更新がかち合ってしまって変な画面になったり…。

#### Jetpack Composeを使用する前

Androidの従来のUI開発では、XMLでUIのレイアウトを定義し、ActivityやFragmentのコード内でUIコンポーネントに対する操作を行っていました。

**XMLレイアウト (activity_main.xml):**

```xml
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    tools:context=".MainActivity">

    <Button
        android:id="@+id/button"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="ボタン" />

    <TextView
        android:id="@+id/textView"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_below="@id/button"
        android:text="ここに文字が表示されます"
        android:visibility="gone"/>

</RelativeLayout>

```

**Activity (MainActivity.java):**

```java
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Button button = findViewById(R.id.button);
        TextView textView = findViewById(R.id.textView);

        button.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                textView.setVisibility(View.VISIBLE);
                textView.setText("ボタンが押されました！");
            }
        });
    }
}
```

#### Jetpack Composeを使用した後

**Compose UI (MainActivity.kt):**

このComposeの例では、UIの状態を変更するために状態変数textVisibleを使っています。ボタンがクリックされると、この状態が更新され、UIが自動的に再描画されます。これにより、明示的にUIコンポーネントを探して更新する必要がなくなり、コードがよりシンプルで読みやすくなります。

```java
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Column
import androidx.compose.material.Button
import androidx.compose.material.Text
import androidx.compose.runtime.*

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            var textVisible by remember { mutableStateOf(false) }

            Column {
                Button(onClick = { textVisible = !textVisible }) {
                    Text("ボタン")
                }
                if (textVisible) {
                    Text("ボタンが押されました！")
                }
            }
        }
    }
}
```

### 宣言型UIで何が変わる？

宣言型UIでは、画面のどんな部分がどんな状態であるべきかを「宣言」します。あとはComposが勝手に、その指示に従って画面を更新してくれます。これにより、手動で画面をいじる必要がなくなり、エラーが減ってプログラムがシンプルになります。

### でも、画面を毎回全部作り直すって大変じゃない？

確かに、画面をゼロから作り直すのは、時間もパワーもバッテリーも使います。でも大丈夫！Composは賢いので、本当に更新する必要がある部分だけを選んで、それだけを再描画します。これにより、パフォーマンスも保ちつつ、開発がラクになるんです。

というわけで、Jetpack Composeは、アプリの見た目を簡単に、エラー少なく、効率的に作れるすごいツールなんです！

## 宣言型パラダイム シフト

Androidアプリの世界では、画面上で見えるモノ（ボタンやテキストなど）は「ウィジェット」と呼ばれる小さな部品で作られています。今までのやり方では、これらのウィジェットを組み合わせて画面を作るためには、一種の設計図であるXMLファイルを使って、どんなウィジェットがどこにあるかを指定していました。そして、プログラムが動いている間、プログラマーが手動でウィジェットをいじって、画面の見た目を変えていました。

### 昔のやり方の問題点は？

ウィジェットは、自分自身がどんな状態か（例えば、ボタンが押されたかどうか）を覚えている必要がありました。それに、プログラマーがウィジェットを直接いじるためには、そのウィジェットを探してくる必要があり、これがなかなか面倒だったんです。

<details>

<summary>たとえ</summary>

```bash
あなたが部屋の中にいて、部屋の中にはたくさんのボタンがあるとします。それぞれのボタンは、ライトをつけたり、音楽を流したりする役割があります。でも、ある特定のボタンを押したいとき、そのボタンがどこにあるかを毎回探さなければなりません。見つけたら、そのボタンが今、どんな状態にあるか（つまり、ライトがついているか、音楽が流れているか）を確認して、必要に応じて操作します。これが、従来のウィジェットを使った画面更新の方法です。つまり、「探して、確認して、操作する」というステップを踏むわけです。

このやり方の問題点は、特に大きな部屋（たくさんの機能があるアプリ）では、そのボタンを探すのが本当に大変だということです。また、たくさんのボタンがあると、どのボタンがどの状態にあるのかを覚えておくのも一苦労です。

Jetpack Composeの登場で、このやり方が変わります。部屋の中にあるボタンを直接探す代わりに、あなたが何をしたいかをただ「宣言」するだけです。「この部屋でライトをつけて」と言えば、自動的にライトがつきます。ボタンを探したり、現在の状態を確認したりする必要がなくなるわけです。これが「宣言型」のアプローチで、画面の更新がもっとシンプルに、効率的に行えるようになります。

```

</details>

### Composeは何が違うの？

Jetpack Composeという新しいツールを使うと、このやり方がガラリと変わります。Composeでは、ウィジェットを直接いじるのではなく、ウィジェットがどうあるべきかを「宣言」するだけです。画面上で何かが変わる必要がある時は、Composeが自動で画面を更新してくれます。つまり、プログラマーは「このボタンが押されたら、この文字を表示する」という結果だけを指定すればいいので、ずっとシンプルになります。

### どうやって動くの？

1. **アプリのロジック**が、画面に表示するデータを持っています。
2. このデータは、Composeによって画面の**「レシピ」**となるコードに渡されます。
3. ユーザーが画面で何か操作をする（例えばボタンを押す）と、そのイベントはアプリのロジックに伝えられ、データが更新されます。
4. データが変わると、Composeが自動で画面を最新の状態に更新します。このプロセスを**「再コンポーズ」**と呼びます。

### 図で理解する

- **図2**：アプリのロジックがデータを持っていて、それをComposeのレシピに渡す流れ。
- **図3**：ユーザーが操作すると、イベントが発生してアプリのロジックがデータを更新、Composeが画面を再描画する流れ。

## 動的コンテンツ

Jetpack Composeを使うと、画面の見た目をプログラミングのコードで直接記述できます。これができるのは、ComposeがKotlinというプログラミング言語で書かれているからです。これにより、動的なコンテンツを非常に柔軟に扱うことが可能になります。

### 柔軟性

Jetpack Composeの素晴らしい点は、これだけではありません。プログラムの条件（ifステートメント）を使って、特定の条件下で特定のUI要素を表示したり隠したりすることができます。また、ループ（例えばforループ）を使ってリストの各要素に対して操作を行ったり、他の関数を呼び出してコードを再利用したりすることが可能です。

### なぜこれが良いのか？

このような柔軟性と機能の豊富さが、Jetpack Composeを使う大きな利点の一つです。XMLのように静的なレイアウトファイルを使う代わりに、動的でリッチなユーザーインターフェイスをプログラムのコードで直接記述できるので、開発者はより創造的で効率的にアプリのUIをデザインできるようになります。

## 再コンポーズ

Jetpack Composeでの「再コンポーズ」というのは、ちょっとした魔法みたいなものです。画面の一部分が変わる必要がある時、Composeはその部分だけを賢く更新します。これは、アプリをもっと早く、バッテリーを長持ちさせる秘密の技です。

### 例：クリックカウンターボタン

あなたがボタンをクリックするたびに、画面に「このボタンは○回クリックされました」と表示させたいとしましょう。

```java
@Composable
fun ClickCounter(clicks: Int, onClick: () -> Unit) {
    Button(onClick = onClick) {
        Text("I've been clicked $clicks times")
    }
}
```

このコードは、ボタンがクリックされるたびに、ボタンの上にあるテキストを更新します。Composeは、クリックの数が変わるたびに、このテキストだけを再描画します。

### 再コンポーズって何がすごいの？

- 賢い更新：Composeは変わった部分だけを更新します。画面の他の部分はそのままで、必要なところだけをピンポイントで直します。
- 高速＆バッテリー長持ち：全てを一から作り直す代わりに、変更があった部分だけを直すので、速くてバッテリーにも優しいです。

### 注意点

- 副作用に注意：コンポーズ可能な関数は何回も実行されることがあるので、外部のデータを変えるような操作（副作用）には注意が必要です。例えば、データベースを更新するようなことをこの関数の中でやると、予想外のことが起こるかもしれません。
- アニメーション中は特に注意：アニメーションがスムーズに動くように、コンポーズ可能な関数は早く動く必要があります。重たい処理はバックグラウンドでやりましょう

## Compose を使用するときに注意すべき点

### コンポーズ可能な関数は任意の順序で実行できる

Composeでは、画面のコンポーネントを作る関数は、必ずしも書かれた順番通りに動くわけではありません。これは、Composeが画面の更新を効率的に行うために、関数を最適な順序で実行するからです。つまり、画面の一部を描画するために、関数Aが先に、関数Bが後に実行されるとは限らないのです。

### コンポーズ可能な関数は並行して実行できる

Composeは、画面を更新するための関数を同時に（並行して）実行することができます。これにより、画面の更新が速くなり、アプリがスムーズに動作します。ただし、この特性のために、関数内で外部のデータを変更するような「副作用」があると問題が起こることがあります。

### 再コンポーズは可能な限りスキップする

画面の小さな部分だけが変更された場合、Composeは必要最低限の更新だけを行います。つまり、変更があった部分に関連する関数だけが再び実行され、他の部分はそのままにされます。これにより、アプリのパフォーマンスが向上します。

### 再コンポーズは厳密なものではない

画面を更新するために関数が再び実行される（再コンポーズされる）とき、その処理は中断されることがあります。たとえば、更新中に関数が再び実行されるべき新しいデータが来た場合です。このため、関数の中で外部の状態に依存することは避けるべきです。

### コンポーズ可能な関数は何度も実行されることがある

アニメーションなどのために、コンポーズ可能な関数が何度も繰り返し実行されることがあります。そのため、関数が重い処理を含むと、アプリの動作が遅くなったり、不自然になったりすることがあります。重い処理は、別の場所で行い、結果だけを関数に渡すようにしましょう。
