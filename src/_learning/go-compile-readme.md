---
title: "the Go compilerのドキュメントを日本語翻訳"
date: 2024-7-20T16:07:00
#image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: "jekyll-sitemap"
linkedinurl: ""
weight: 7
tags:
  - 
---

# 日本語翻訳

元ページ「[Introduction to the Go compiler](https://go.dev/src/cmd/compile/README)」

## Introduction to the Go compiler

cmd/compile には、Go コンパイラを構成する主要なパッケージが含まれています。コンパイラは論理的に4つのフェーズに分割されることがあり、それぞれのフェーズに対応するパッケージの一覧とともに簡単に説明します。

コンパイラに関して「フロントエンド」や「バックエンド」という用語を耳にすることがあるかもしれません。大まかに言うと、これらはここでリストアップする最初の2つのフェーズと最後の2つのフェーズに相当します。もう一つの用語である「ミドルエンド」は、主に2番目のフェーズで行われる作業の多くを指すことがよくあります。

go/*ファミリーのパッケージ、例えば go/parser や go/types は、コンパイラではほとんど使用されていないことに注意してください。コンパイラは最初 C 言語で書かれていたため、go/* パッケージは gofmt や vet などの Go コードを扱うツールを書くために開発されました。しかし、時間が経つにつれて、コンパイラの内部 API は go/* パッケージの利用者にとってより親しみやすいものへと徐々に進化してきました。

「gc」という名前は「Go コンパイラ」を意味しており、大文字の「GC」（ガベージコレクション）とはほとんど関係がないことを明確にしておく必要があります。

## 1. パース

- cmd/compile/internal/syntax（字句解析器、構文解析器、構文木）

コンパイルの最初のフェーズでは、ソースコードがトークン化（字句解析）され、パース（構文解析）され、各ソースファイルに対して構文木が構築されます。

各構文木は、それぞれのソースファイルの正確な表現であり、式、宣言、文などのソースのさまざまな要素に対応するノードを持っています。構文木には、エラー報告やデバッグ情報の作成に使用される位置情報も含まれています。

### イメージ

```go
package main

import "fmt"

func main() {
    fmt.Println("Hello, world!")
}
```

### (追加補足)

このプログラムは、パッケージ宣言、インポート宣言、関数宣言から構成されています。構文木はこれらの要素をノードとして表現します。

```
Program
├── PackageDecl
│   └── "main"
├── ImportDecl
│   └── "fmt"
└── FuncDecl
    ├── FuncName
    │   └── "main"
    └── FuncBody
        └── CallExpr
            ├── SelectorExpr
            │   ├── "fmt"
            │   └── "Println"
            └── Arguments
                └── "Hello, world!"
```

## 2. 型チェック

- cmd/compile/internal/types2（型チェック）

types2 パッケージは go/ast の代わりに syntax パッケージの AST（抽象構文木）を使用するように go/types を移植したものです。

### (追加補足)

元々、Go の型チェックのために使われていた go/types パッケージは、[go/ast パッケージの抽象構文木（AST）](https://golangdocs.com/golang-ast-package)を利用していました。しかし、コンパイラが進化する過程で、go/ast パッケージの代わりに syntax パッケージの AST を使うことが望まれるようになりました。

types2 パッケージは、この syntax パッケージの AST を利用するように go/types パッケージを移植（改変）したものです。つまり、types2 パッケージは、元々の go/types パッケージと同じように型チェックを行いますが、syntax パッケージの AST を利用している点が異なります。

## 3. IR（中間表現）の構築（「ノーディング」）

- cmd/compile/internal/types（コンパイラの型）
- cmd/compile/internal/ir（コンパイラの AST）
- cmd/compile/internal/noder（コンパイラの AST を作成）

コンパイラのミドルエンドは、C 言語で書かれていた時のままの独自の AST 定義と Go 型の表現を使用しています。そのため、型チェックの後の次のステップは、syntax と types2 の表現を ir と types に変換することです。このプロセスは「ノーディング」と呼ばれます。

ノーディングは Unified IR と呼ばれるプロセスを使用して行われ、これはステップ 2 の型チェック済みコードのシリアライズされたバージョンを使用してノード表現を構築します。Unified IR は、パッケージのインポート/エクスポートやインライン化にも関与しています。

## 4. ミドルエンド

- cmd/compile/internal/deadcode（不要なコードの削除）
- cmd/compile/internal/inline（関数呼び出しのインライン化）
- cmd/compile/internal/devirtualize（既知のインターフェースメソッド呼び出しの仮想化解除）
- cmd/compile/internal/escape（エスケープ解析）

IR 表現に対して、いくつかの最適化パスが実行されます。これには、不要なコードの削除、初期の仮想化解除、関数呼び出しのインライン化、およびエスケープ解析が含まれます。

### 追加補足

1. 不要なコードの削除（dead code elimination）
   1. 不要なコードの削除は、プログラム内で実行されないコードを検出し、取り除くプロセスです。
2. 仮想化解除（devirtualization）
   1. 仮想化解除は、インターフェースメソッド呼び出しの際に、実際の実装が既知であれば直接そのメソッドを呼び出すように変換するプロセスです。
   2. 参考になったサイト
      1. [PGOによるコンパイラ最適化 / Compiler Optimization with PGO](https://speakerdeck.com/ciarana/compiler-optimization-with-pgo)
      2. [Devirtualization (脱仮想化)](https://ufcpp.net/blog/2018/12/devirtualization/)
3. 関数呼び出しのインライン化（function call inlining）
   1. 関数呼び出しのインライン化は、関数呼び出しをその呼び出し元に直接展開するプロセスです。
4. エスケープ解析（escape analysis）
   1. エスケープ解析は、変数がヒープに割り当てられるべきか、スタックに割り当てられるべきかを決定します。
   2. 参考になったサイト
      1. [Allocation efficiency in high-performance Go services](https://segment.com/blog/allocation-efficiency-in-high-performance-go-services/)

## 5. Walk

- cmd/compile/internal/walk（評価の順序、構文の単純化）

IR（中間表現）に対する最終パスは「walk」と呼ばれ、以下の2つの目的があります：

1. 複雑な文を個々のよりシンプルな文に分解し、一時変数を導入しつつ評価の順序を尊重します。このステップは「order」とも呼ばれます。
2. 高レベルのGo構文をよりプリミティブなものに変換します。例えば、switch文はバイナリサーチやジャンプテーブルに変換され、マップやチャネルの操作はランタイム呼び出しに置き換えられます。

## 6. Generic SSA

- cmd/compile/internal/ssa（SSA パスとルール）
- cmd/compile/internal/ssagen（IR から SSA への変換）

このフェーズでは、IR が静的単一代入（SSA）形式に変換されます。SSA 形式は、最適化の実装を容易にし、最終的に機械語を生成しやすくする特定の特性を持つ低レベルの中間表現です。

この変換の過程で、関数のイントリンシックが適用されます。これらは、コンパイラがケースバイケースで最適化されたコードに置き換えるように教えられた特殊な関数です。

また、AST から SSA への変換中に、特定のノードがより単純なコンポーネントに分解され、コンパイラの残りの部分がそれらを扱いやすくします。例えば、`copy` 組み込み関数はメモリ移動に置き換えられ、範囲ループは `for` ループに書き換えられます。これらの一部は現在、歴史的な理由から SSA への変換前に行われていますが、長期的にはすべてをこのフェーズに移行する計画です。

その後、一連の機械非依存のパスとルールが適用されます。これらは特定のコンピュータアーキテクチャに依存せず、すべての GOARCH バリアントで実行されます。これらのパスには、不要なコードの削除、不要な nil チェックの削除、未使用の分岐の削除が含まれます。一般的な書き換えルールは主に式に関係し、一部の式を定数値に置き換えたり、乗算や浮動小数点演算を最適化したりします。

## 7. 機械語コードの生成

- cmd/compile/internal/ssa（SSAの低下とアーキテクチャ固有のパス）
- cmd/internal/obj（機械語コードの生成）

コンパイラの機械依存フェーズは「lower」パスから始まり、汎用的な値を機械固有のバリアントに書き換えます。例えば、amd64アーキテクチャではメモリオペランドが可能であるため、多くのロードストア操作が統合される場合があります。

lowerパスは、すべての機械固有の書き換えルールを実行するため、多くの最適化も適用されます。

SSAが「低下」され、ターゲットアーキテクチャにより特化したものになると、最終的なコード最適化パスが実行されます。これには、もう一つの不要なコードの削除、値を使用に近づけること、読み取られないローカル変数の削除、およびレジスタ割り当てが含まれます。

このステップの一部として行われる他の重要な作業には、スタックフレームのレイアウト（ローカル変数にスタックオフセットを割り当てる）やポインタのライフネス解析（各GCセーフポイントでのオンスタックポインタのライブ状態を計算する）が含まれます。

SSA生成フェーズの最後には、Go関数は一連の `obj.Prog` 命令に変換されます。これらはアセンブラ（cmd/internal/obj）に渡され、機械語に変換されて最終的なオブジェクトファイルが書き出されます。オブジェクトファイルには、リフレクトデータ、エクスポートデータ、およびデバッグ情報も含まれます。

## 8. ヒント

### はじめに

- コンパイラに初めて貢献する場合、調査している内容についての初期の洞察を得るために、ログステートメントや panic("here") を追加することから始めると簡単です。

- コンパイラ自体には、次のようなログ、デバッグ、および可視化機能が備わっています：

```sh
go build -gcflags=-m=2                   # 最適化情報を表示（インライン化、エスケープ解析など）
go build -gcflags=-d=ssa/check_bce/debug # 境界チェック情報を表示
go build -gcflags=-W                     # 型チェック後の内部解析ツリーを表示
GOSSAFUNC=Foo go build                   # 関数 Foo の ssa.html ファイルを生成
go build -gcflags=-S                     # アセンブリコードを表示
go tool compile -bench=out.txt x.go      # コンパイラフェーズのタイミングを表示
```

- コンパイラの動作を変更するいくつかのフラグは以下のとおりです：

```sh
go tool compile -h file.go               # 最初のコンパイルエラーでパニック
go build -gcflags=-d=checkptr=2          # 追加の安全でないポインタチェックを有効にする
```

- 多くの追加フラグがあります。いくつかの説明は以下で確認できます：

```sh
go tool compile -h              # コンパイラフラグの表示、例： go build -gcflags='-m=1 -l'
go tool compile -d help         # デバッグフラグの表示、例： go build -gcflags=-d=checkptr=2
go tool compile -d ssa/help     # SSA フラグの表示、例： go build -gcflags=-d=ssa/prove/debug=2
```

`-gcflags` の詳細や `go build` と `go tool compile` の違いについては、以下の[セクション](https://go.dev/src/cmd/compile/README#-gcflags-and-go-build-vs-go-tool-compile)で追加の情報が提供されています。

- 一般的に、コンパイラの問題を調査する際には、可能な限りシンプルな再現方法から始め、何が起こっているのかを正確に理解することが重要です。

## 変更をテストする

- 変更を迅速にテストする方法については、Go貢献ガイドの「[Quickly testing your changes](https://go.dev/doc/contribute#quick_test)」セクションを必ず読んでください。

- いくつかのテストは `cmd/compile` パッケージ内にあり、`go test ./...` などのコマンドで実行できますが、多くの `cmd/compile` テストはトップレベルの `test` ディレクトリにあります：

```sh
go test cmd/internal/testdir                           # 'test' ディレクトリ内のすべてのテストを実行
go test cmd/internal/testdir -run='Test/escape.*.go'   # 'test' ディレクトリ内の特定のファイルをテスト
```

詳細については、`testdir` の [README](https://github.com/golang/go/tree/master/test#readme) を参照してください。[`testdir_test.go`](https://github.com/golang/go/blob/master/src/cmd/internal/testdir/testdir_test.go) にある `errorCheck` メソッドは、多くのテストで使用される `ERROR` コメントの説明に役立ちます。

さらに、標準ライブラリの `go/types` パッケージと `cmd/compile/internal/types2` の共有テストが `src/internal/types/testdata` にあり、そこに変更がある場合は両方の型チェッカーをチェックする必要があります。

- 新しいアプリケーションベースの[カバレッジプロファイリング](https://go.dev/testing/coverage/)は、コンパイラと共に使用できます。例えば：

```sh
go install -cover -coverpkg=cmd/compile/... cmd/compile  # カバレッジ計測付きでコンパイラをビルド
mkdir /tmp/coverdir                                      # カバレッジデータの保存場所を作成
GOCOVERDIR=/tmp/coverdir go test [...]                   # コンパイラを使用してカバレッジデータを保存
go tool covdata textfmt -i=/tmp/coverdir -o coverage.out # 従来のカバレッジ形式に変換
go tool cover -html coverage.out                         # 従来のツールでカバレッジを表示
```

## コンパイラバージョンの切り替え

- 多くのコンパイラテストは、PATH に見つかる `go` コマンドのバージョンとそれに対応する `compile` バイナリを使用します。

- ブランチにいて、PATH に `<go-repo>/bin` が含まれている場合、`go install cmd/compile` を実行すると、ブランチのコードを使用してコンパイラがビルドされ、適切な場所にインストールされます。その後の `go build` や `go test ./...` などのコマンドで、新しくビルドされたコンパイラが使用されます。

- [`toolstash`](https://pkg.go.dev/golang.org/x/tools/cmd/toolstash) は、既知の良好な Go ツールチェーンのコピーを保存、実行、および復元する方法を提供します。例えば、最初にブランチをビルドしてそのバージョンのツールチェーンを保存し、その後、作業中のコンパイラバージョンをコンパイルするために既知の良好なバージョンのツールを復元することが良い方法です。

Sample set up steps:

```sh
go install golang.org/x/tools/cmd/toolstash@latest
git clone https://go.googlesource.com/go
cd go
git checkout -b mybranch
./src/all.bash               # ビルドして良好な開始点を確認する
export PATH=$PWD/bin:$PATH
toolstash save               # 現在のツールを保存する
```

その後、編集/コンパイル/テストサイクルは以下のように進められます：

```sh
<… cmd/compile のソースを編集 …>
$ toolstash restore && go install cmd/compile   # 既知の良好なツールを復元してコンパイラをビルド
<… ‘go build’, ‘go test’ など …>             # 新しくビルドされたコンパイラを使用」
```

- `toolstash` を使用すると、インストールされたコンパイラと保存されたコンパイラを比較することもできます。例えば、リファクタリング後に動作が同等であることを期待する場合、標準ライブラリをビルドする際に変更されたコンパイラが保存されたコンパイラと同一のオブジェクトファイルを生成するかどうかを確認できます。

```sh
toolstash restore && go install cmd/compile   # 最新のコンパイラをビルド
go build -toolexec "toolstash -cmp" -a -v std # 最新のコンパイラと保存されたコンパイラを比較
```

- バージョンが同期しなくなった場合（例えば、`devel go1.21-db3f952b1f` のようなバージョン文字列でリンクされたオブジェクトヘッダの不一致エラーが発生する場合）、次のコマンドを実行して `cmd` 配下のすべてのツールを更新する必要があります：

```sh
toolstash restore && go install cmd/...
```

## 追加の便利なツール

- [`compilebench`](https://pkg.go.dev/golang.org/x/tools/cmd/compilebench) は、コンパイラの速度をベンチマークします。
- [`benchstat`](https://pkg.go.dev/golang.org/x/perf/cmd/benchstat) は、コンパイラの変更による性能変化を報告する標準ツールであり、改善が統計的に有意かどうかも判断します：

```sh
go test -bench=SomeBenchmarks -count=20 > new.txt   # 新しいコンパイラを使用
toolstash restore                                   # 古いコンパイラを復元
go test -bench=SomeBenchmarks -count=20 > old.txt   # 古いコンパイラを使用
benchstat old.txt new.txt                           # 古いコンパイラと新しいコンパイラを比較
```

- [`bent`](https://pkg.go.dev/golang.org/x/benchmarks/cmd/bent) は、Dockerコンテナ内で様々なコミュニティのGoプロジェクトからの大規模なベンチマークセットを実行するのを支援します。
- [`perflock`](https://github.com/aclements/perflock) は、Linux上でCPU周波数スケーリング設定を操作することで、より一貫したベンチマーク結果を得るのを助けます。
- [`view-annotated-file`](https://github.com/loov/view-annotated-file)（コミュニティ提供）は、インライン化、境界チェック、およびエスケープ情報をソースコードに重ねて表示します。
- [`godbolt.org`](https://go.godbolt.org/) は、多くのコンパイラからのアセンブリ出力を調べて共有するために広く使用されています。Goコンパイラのバージョン間や関数の異なるバージョンのアセンブリを比較することもでき、調査やバグ報告に役立ちます。

## -gcflags と ‘go build’ vs. ‘go tool compile’

`-gcflags` は `go` コマンドの[ビルドフラグ](https://pkg.go.dev/cmd/go#hdr-Compile_packages_and_dependencies)です。`go build -gcflags=<args>` は、指定された `<args>` を基礎となるコンパイル呼び出しに渡しつつ、`go build` コマンドが通常行うすべての操作（ビルドキャッシュの処理、モジュールの管理など）を実行します。対照的に、`go tool compile <args>` は、標準の `go build` メカニズムを使用せずに、`compile <args>` を1回実行するように `go` コマンドに指示します。小さな独立したソースファイルが `go build` の助けなしにコンパイルできる場合など、部品が少ない方が便利な場合には、`go tool compile <args>` を使用することが有用です。一方、`go build`、`go test`、`go install` のようなビルドコマンドに `-gcflags` を渡す方が便利な場合もあります。

`-gcflags` はデフォルトではコマンドラインで指定されたパッケージに適用されますが、`-gcflags='all=-m=1 -l'` のようにパッケージパターンを使用することもできます。また、`-gcflags='all=-m=1' -gcflags='fmt=-m=2'` のように複数のパッケージパターンを使用することも可能です。詳細については、`cmd/go` の[ドキュメント](https://pkg.go.dev/cmd/go#hdr-Compile_packages_and_dependencies)を参照してください。

## さらなる読み物

SSA パッケージの動作について、パスやルールを含めてさらに掘り下げて学びたい場合は、[`cmd/compile/internal/ssa/README.md`](https://go.dev/src/cmd/compile/README#:~:text=cmd/compile/internal/ssa/README.md) を参照してください。

最後に、この README や SSA README に不明確な点がある場合や改善のアイデアがある場合は、気軽に [issue 30074](https://go.dev/issue/30074) にコメントを残してください。
