---
title: "Go言語「log/slog」パッケージの日本語翻訳"
date: 2024-06-08T05:26:00
jobtitle: ""
linkedinurl: ""
weight: 7
tags:
  - Go言語
  - ログ記録
  - 構造化ログ
  - slogパッケージ
  - ハンドラー
  - ログレベル管理
  - JSONログ
  - 開発ツール
description: "Go言語の「log/slog」パッケージを日本語で解説した記事です。構造化ログ、ハンドラー設定、ログレベル管理、カスタムハンドラーの作成方法を詳細に説明。JSON出力やTextHandlerの使い方、ログ属性のグルーピングや効率的なログ記録の実現方法も紹介し、Goでの効果的なログ管理を支援します。"
---

<https://pkg.go.dev/log/slogのページを日本語に翻訳しただけです。>

Package slogは、ログレコードにメッセージ、重大度レベル、およびキーと値のペアとして表現されるさまざまな属性を含む構造化ログを提供します。

このパッケージでは、興味のあるイベントを報告するためのいくつかのメソッド（Logger.InfoやLogger.Errorなど）を提供するLoggerというタイプを定義しています。

各LoggerはHandlerに関連付けられています。Loggerの出力メソッドはメソッド引数からRecordを作成し、それをHandlerに渡します。Handlerはそれをどのように処理するかを決定します。対応するLoggerメソッドを呼び出すトップレベルの関数（InfoやErrorなど）を通じてアクセス可能なデフォルトのLoggerが存在します。

ログレコードは、時間、レベル、メッセージ、およびキーと値のペアのセットで構成され、キーは文字列、値は任意の型です。例えば、

```go
slog.Info("hello", "count", 3)

```

呼び出し時の時間、Infoレベル、メッセージ「hello」、およびキー「count」と値3のペアを含むレコードを作成します。

Infoトップレベル関数は、デフォルトのLoggerに対してLogger.Infoメソッドを呼び出します。Logger.Infoに加えて、Debug、Warn、Errorレベル用のメソッドもあります。これらの共通レベルの便利なメソッドの他に、レベルを引数として受け取るLogger.Logメソッドもあります。これらの各メソッドには、デフォルトのLoggerを使用する対応するトップレベル関数があります。

デフォルトのハンドラーは、ログレコードのメッセージ、時間、レベル、および属性を文字列としてフォーマットし、それをログパッケージに渡します。

例:

```
2022/11/08 15:28:26 INFO hello count=3
```

出力形式をより詳細に制御するためには、異なるハンドラーを使用してロガーを作成します。以下のステートメントは、構造化レコードをテキスト形式で標準エラーに書き込むTextHandlerを使用して、新しいロガーを作成します：

```go
logger := slog.New(slog.NewTextHandler(os.Stderr, nil))
```

TextHandlerの出力は、機械が容易かつ明確に解析できるキー=値ペアのシーケンスです。以下のステートメント：

```go
logger.Info("hello", "count", 3)
```

は次の出力を生成します：

```
time=2022-11-08T15:28:26.000-05:00 level=INFO msg=hello count=3
```

このパッケージには、行区切りのJSONを出力するJSONHandlerも含まれています。

```go
logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
logger.Info("hello", "count", 3)
```

このコードは次の出力を生成します：

```json
{"time":"2022-11-08T15:28:26.000000000-05:00","level":"INFO","msg":"hello","count":3}
```

TextHandlerとJSONHandlerの両方は、HandlerOptionsで設定を変更することができます。これには、最小レベルの設定（以下のレベル参照）、ログ呼び出しのソースファイルと行の表示、ログ前の属性の変更オプションがあります。

次のコードでロガーをデフォルトとして設定することができます：

```go
slog.SetDefault(logger)
```

これにより、Infoのようなトップレベルの関数がこのロガーを使用します。SetDefaultは、logパッケージで使用されるデフォルトのロガーも更新するため、log.Printfや関連する関数を使用する既存のアプリケーションは、コードを書き換えることなくロガーのハンドラーにログレコードを送信します。

多くのログ呼び出しに共通の属性があります。例えば、サーバーリクエストから発生するすべてのログイベントにURLやトレース識別子を含めたい場合があります。毎回ログ呼び出しで属性を繰り返す代わりに、Logger.Withを使用して属性を含む新しいロガーを構築できます：

```go
logger2 := logger.With("url", r.URL)
```

Withの引数はLogger.Infoで使用されるのと同じキーと値のペアです。結果は、元のロガーと同じハンドラーを持つ新しいロガーであり、追加の属性がすべての呼び出しの出力に表示されます。

### レベル

レベルは、ログイベントの重要性や重大度を表す整数です。レベルが高いほど、イベントはより重大です。このパッケージでは、最も一般的なレベルの定数を定義していますが、任意の整数をレベルとして使用することができます。

アプリケーションでは、特定のレベル以上のメッセージのみをログに記録したい場合があります。一般的な設定の一つは、Info以上のレベルのメッセージをログに記録し、デバッグログは必要になるまで抑制することです。組み込みのハンドラーは、[HandlerOptions.Level]を設定することで出力する最小レベルを設定できます。プログラムの`main`関数でこれを行うのが一般的です。デフォルト値はLevelInfoです。

[HandlerOptions.Level]フィールドにレベル値を設定すると、そのハンドラーの有効期間中、最小レベルが固定されます。LevelVarを設定すると、レベルを動的に変更することができます。LevelVarはレベルを保持し、複数のゴルーチンからの読み書きが安全です。プログラム全体のレベルを動的に変更するためには、まずグローバルなLevelVarを初期化します：

```go
var programLevel = new(slog.LevelVar) // デフォルトはInfo
```

次に、このLevelVarを使用してハンドラーを構築し、それをデフォルトに設定します：

```go
h := slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{Level: programLevel})
slog.SetDefault(slog.New(h))
```

これで、プログラムは単一のステートメントでログレベルを変更できます：

```go
programLevel.Set(slog.LevelDebug)
```

### グループ

属性はグループにまとめることができます。グループには名前があり、その名前は属性名を修飾するために使用されます。この修飾の表示方法はハンドラーによって異なります。TextHandlerはグループ名と属性名をドットで区切ります。JSONHandlerは各グループを別々のJSONオブジェクトとして扱い、グループ名をキーとします。

Groupを使用して、名前とキーと値のペアのリストからグループ属性を作成します：

```go
slog.Group("request",
    "method", r.Method,
    "url", r.URL)
```

TextHandlerはこのグループを次のように表示します：

```
request.method=GET request.url=http://example.com
```

JSONHandlerは次のように表示します：

```json
"request":{"method":"GET","url":"http://example.com"}
```

Logger.WithGroupを使用して、ロガーのすべての出力にグループ名を修飾します。LoggerでWithGroupを呼び出すと、元のLoggerと同じHandlerを持ち、すべての属性がグループ名で修飾される新しいLoggerが作成されます。

これは、大規模なシステムでサブシステムが同じキーを使用する場合に、重複する属性キーを防ぐのに役立ちます。各サブシステムに異なるグループ名を持つLoggerを渡すことで、潜在的な重複を修飾できます：

```go
logger := slog.Default().With("id", systemID)
parserLogger := logger.WithGroup("parser")
parseInput(input, parserLogger)
```

parseInputがparserLoggerでログを記録すると、そのキーは「parser」で修飾されるため、共通キー「id」を使用していてもログ行に異なるキーが含まれます。

### コンテキスト

一部のハンドラーは、呼び出し元で利用可能なcontext.Contextから情報を含めたい場合があります。例えば、トレースが有効になっている場合の現在のスパンの識別子などの情報です。

Logger.LogとLogger.LogAttrsメソッドは、最初の引数としてコンテキストを受け取ります。これに対応するトップレベル関数も同様です。

Loggerの便利なメソッド（Infoなど）および対応するトップレベル関数はコンテキストを受け取りませんが、「Context」で終わる代替メソッドは受け取ります。例えば、

```go
slog.InfoContext(ctx, "message")
```

コンテキストが利用可能な場合は、出力メソッドにコンテキストを渡すことが推奨されます。

### AttrsとValues

Attrはキーと値のペアです。Loggerの出力メソッドは、交互のキーと値だけでなく、Attrも受け取ります。以下の文は

```go
slog.Info("hello", slog.Int("count", 3))
```

次の文と同じ動作をします

```go
slog.Info("hello", "count", 3)
```

Attrの便利なコンストラクタとして、Int、String、Boolなどの一般的な型があります。また、任意の型のAttrを構築するためのAny関数もあります。

Attrの値部分は、Valueという型です。[any]のように、Valueは任意のGo値を保持できますが、すべての数値や文字列などの一般的な値を割り当てなしで表現できます。

最も効率的なログ出力のためには、Logger.LogAttrsを使用します。これはLogger.Logに似ていますが、交互のキーと値を受け取らず、Attrのみを受け取ります。これにより、割り当てを避けることができます。

以下の呼び出しは

```go
logger.LogAttrs(ctx, slog.LevelInfo, "hello", slog.Int("count", 3))
```

次の出力を最も効率的に達成する方法です：

```go
slog.InfoContext(ctx, "hello", "count", 3)
```

### カスタムタイプのログ動作のカスタマイズ

タイプがLogValuerインターフェースを実装している場合、そのLogValueメソッドから返されるValueがログ出力に使用されます。これを使用して、ログに表示されるタイプの値の表示方法を制御できます。例えば、パスワードなどの秘密情報を隠す、または構造体のフィールドをグループにまとめることができます。詳細については、LogValuerの例を参照してください。

LogValueメソッドは、LogValuerを実装するValueを返すことができます。Value.Resolveメソッドはこれらのケースを注意深く処理し、無限ループや無限再帰を避けます。ハンドラーの作成者やその他の人々は、LogValueを直接呼び出すのではなく、Value.Resolveを使用することをお勧めします。

### 出力メソッドのラップ

ロガー関数はリフレクションを使用して、アプリケーション内のログ呼び出しのファイル名と行番号を見つけます。これは、slogをラップする関数に対して誤ったソース情報を生成する可能性があります。例えば、ファイルmylog.goで以下のような関数を定義した場合：

```go
func Infof(logger *slog.Logger, format string, args ...any) {
    logger.Info(fmt.Sprintf(format, args...))
}
```

そしてmain.goで次のように呼び出した場合：

```go
Infof(slog.Default(), "hello, %s", "world")
```

slogはソースファイルをmain.goではなくmylog.goとして報告します。

正しいInfofの実装は、ソース位置（pc）を取得し、それをNewRecordに渡します。パッケージレベルの例「wrapping」で示されているInfof関数がこの方法を示しています。

### レコードの操作

時々、ハンドラーはレコードを他のハンドラーやバックエンドに渡す前に変更する必要があります。レコードは単純な公開フィールド（例：Time、Level、Message）と、間接的に状態（属性など）を参照する隠しフィールドの混合です。これは、レコードの単純なコピーを変更すること（例：Record.AddやRecord.AddAttrsを呼び出して属性を追加すること）が、元のレコードに予期しない影響を与える可能性があることを意味します。レコードを変更する前に、Record.Cloneを使用して元のレコードと状態を共有しないコピーを作成するか、NewRecordを使用して新しいレコードを作成し、Record.Attrsで古いレコードの属性を辿って新しいレコードのAttrsを構築します。

### パフォーマンスに関する考慮事項

アプリケーションのプロファイリングでログ記録に多くの時間がかかっていることが示された場合、次の提案が役立つかもしれません。

多くのログ行に共通の属性がある場合は、その属性を持つLoggerを作成するためにLogger.Withを使用します。組み込みのハンドラーは、Logger.Withの呼び出し時にその属性を一度だけフォーマットします。Handlerインターフェースはその最適化を可能にするよう設計されており、よく書かれたHandlerはそれを活用するべきです。

ログ呼び出しの引数は、ログイベントが破棄されても常に評価されます。可能であれば、実際に値がログに記録される場合にのみ計算が行われるように計算を遅延させます。例えば、次の呼び出しを考えてみます。

```go
slog.Info("starting request", "url", r.URL.String())  // Stringを不要に計算するかもしれない
```

この場合、ロガーがInfoレベルのイベントを破棄しても、URL.Stringメソッドは呼び出されます。代わりにURLを直接渡します。

```go
slog.Info("starting request", "url", &r.URL) // 必要な場合のみURL.Stringを呼び出す
```

組み込みのTextHandlerは、ログイベントが有効な場合にのみStringメソッドを呼び出します。Stringの呼び出しを避けることで、基礎となる値の構造を保持します。例えば、JSONHandlerは解析されたURLのコンポーネントをJSONオブジェクトとして出力します。String呼び出しのコストを回避しつつ、ハンドラーが値の構造を調べるのを防ぎたい場合、Marshalメソッドを隠すfmt.Stringer実装で値をラップします。

また、LogValuerインターフェースを使用して、無効なログ呼び出しで不要な作業を避けることもできます。例えば、高価な値をログに記録する必要がある場合：

```go
slog.Debug("frobbing", "value", computeExpensiveValue(arg))
```

この行が無効でも、computeExpensiveValueが呼び出されます。これを避けるために、LogValuerを実装するタイプを定義します。

```go
type expensive struct { arg int }

func (e expensive) LogValue() slog.Value {
    return slog.AnyValue(computeExpensiveValue(e.arg))
}
```

次に、ログ呼び出しでそのタイプの値を使用します。

```go
slog.Debug("frobbing", "value", expensive{arg})
```

これで、computeExpensiveValueは行が有効な場合にのみ呼び出されます。

組み込みのハンドラーは、各レコードが一度に書き込まれるようにするため、io.Writer.Writeを呼び出す前にロックを取得します。ユーザー定義のハンドラーは、自分でロック処理を行う責任があります。

### ハンドラーの作成

カスタムハンドラーの作成に関するガイドについては、以下のリンクを参照してください：
[https://golang.org/s/slog-handler-guide](https://golang.org/s/slog-handler-guide)

### 例（ラッピング）

```go
package main

import (
 "context"
 "fmt"
 "log/slog"
 "os"
 "path/filepath"
 "runtime"
 "time"
)

// Infofは、slogをラップするユーザー定義のログ関数の例です。
// ログレコードには、Infofの呼び出し元のソース位置が含まれます。
func Infof(logger *slog.Logger, format string, args ...any) {
 if !logger.Enabled(context.Background(), slog.LevelInfo) {
  return
 }
 var pcs [1]uintptr
 runtime.Callers(2, pcs[:]) // [Callers, Infof]をスキップ
 r := slog.NewRecord(time.Now(), slog.LevelInfo, fmt.Sprintf(format, args...), pcs[0])
 _ = logger.Handler().Handle(context.Background(), r)
}

func main() {
 replace := func(groups []string, a slog.Attr) slog.Attr {
  // 時間を削除
  if a.Key == slog.TimeKey && len(groups) == 0 {
   return slog.Attr{}
  }
  // ソースのファイル名からディレクトリを削除
  if a.Key == slog.SourceKey {
   source := a.Value.Any().(*slog.Source)
   source.File = filepath.Base(source.File)
  }
  return a
 }
 logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{AddSource: true, ReplaceAttr: replace}))
 Infof(logger, "message, %s", "formatted")
}

```

### 出力

```
level=INFO source=example_wrap_test.go:43 msg="message, formatted"
```

この例では、Infof関数がslogをラップしており、ログレコードにはInfofの呼び出し元のソース位置が含まれます。main関数では、ReplaceAttr関数を使用して、ログ出力から時間を削除し、ソースのファイル名からディレクトリを削除する方法を示しています。
