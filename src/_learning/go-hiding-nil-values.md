---
title: "Hiding nil values in Go: Understanding Why Go Fails Here"
date: 2024-7-5T16:07:00
#image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: "jekyll-sitemap"
linkedinurl: ""
weight: 7
---

### 議題

StackOverflowで議論された内容を理解する

[元の投稿はこちら](https://stackoverflow.com/questions/29138591/hiding-nil-values-understanding-why-go-fails-here/29138676#29138676)

---

### nil値を隠す、Goがここで失敗する理由を理解する

この場合に何かがnilでないことを正しく保証する方法がわかりません：

```go
package main

type shower interface {
    getWater() []shower
}

type display struct {
    SubDisplay *display
}

func (d display) getWater() []shower {
    return []shower{display{}, d.SubDisplay}
}

func main() {
    // SubDisplayはnullで初期化されます
    s := display{}
    // water := []shower{nil}
    water := s.getWater()
    for _, x := range water {
        if x == nil {
            panic("すべて正常、nilが見つかりました")
        }

        // 最初のイテレーションではdisplay{}はnilではないため
        // 正常に動作しますが、2回目のイテレーションで
        // xはnilになり、getWaterはpanicします。
        x.getWater()
    }
}
```

その値が実際にnilであるかどうかを確認する唯一の方法は、リフレクションを使用することです。

これは本当に期待される動作ですか？それとも、私のコードに大きな誤りを見落としているのでしょうか？

---

### 回答

問題は、`shower`がインターフェース型であることです。Goのインターフェース型は実際の値とその動的型を保持します。詳細については、リフレクションの法則（The Laws of Reflection）の「インターフェースの表現」を参照してください。

戻り値のスライスには2つの非nil値が含まれます。2番目の値はインターフェース値であり、nilポインタ値と*display具体型を持つ（値;型）ペアです。Go言語仕様書の比較演算子の項から引用します：

インターフェース値は比較可能です。2つのインターフェース値は、同一の動的型と等しい動的値を持つ場合、または両方がnilの場合に等しいと見なされます。

したがって、nilと比較するとfalseになります。しかし、（nil;*display）ペアを表すインターフェース値と比較するとtrueになります：

```go
if x == (*display)(nil) {
    panic("すべて正常、nilが見つかりました")
}
```

これは、インターフェースが保持する実際の型を知っている必要があるため、実現が困難です。しかし、リフレクションを使用して非nilインターフェース値がnil値をラップしているかどうかを確認することができます。

### なぜこのように実装されているのか？

インターフェースは他の具体的な型（非インターフェース）とは異なり、異なる具体的な型（異なる静的型）の値を保持できます。ランタイムはインターフェース型の変数に格納されている値の動的型やランタイム型を知る必要があります。

インターフェースは単なるメソッドセットであり、同じメソッドがその型のメソッドセットの一部であれば、任意の型がそれを実装します。nilになりえない型もあります。たとえば、構造体や基底型がintであるカスタム型などです。この場合、その特定の型のnil値を格納する必要はありません。

しかし、任意の型にはnilが有効な値である具体的な型（例：スライス、マップ、チャネル、すべてのポインタ型）も含まれるため、インターフェースを満たす値をランタイムに格納するために、インターフェース内にnilを格納することをサポートするのが合理的です。しかし、インターフェース内のnilに加えて、その動的型を格納する必要があります。nil値はそのような情報を持っていないからです。代替案は、格納する値がnilである場合、インターフェース値自体をnilとして使用することですが、この解決策では動的型情報を失うため不十分です。

一部の人々は、Goのインターフェースは動的に型付けされていると言いますが、それは誤解を招く表現です。インターフェース型の変数は常に同じ静的型を持ち、実行時にインターフェース変数に格納された値の型が変わる可能性がありますが、その値は常にインターフェースを満たします。

---

### デモンストレーション

```go
type MyErr string

func (m MyErr) Error() string {
    return "big fail"
}

func doSomething(i int) error {
    switch i {
    default:
        return nil // == nil
    case 1:
        var p *MyErr
        return p // != nil
    case 2:
        return (*MyErr)(nil) // != nil
    case 3:
        var p *MyErr
        return error(p) // != nil インターフェースは
                        // nilアイテムを指していますが、インターフェース自体はnilではありません。
    case 4:
        var err error // == nil: インターフェースのゼロ値はnilです
        return err    // これはtrueになります。なぜならerrはすでにインターフェース型だからです
    }
}

func main() {
    for i := 0; i <= 4; i++ {
        err := doSomething(i)
        fmt.Println(i, err, err == nil)
    }
}
```

出力:

```
0 <nil> true
1 <nil> false
2 <nil> false
3 <nil> false
4 <nil> true
```

ケース2ではnilポインタが返されますが、最初にインターフェース型（error）に変換されるため、nil値と*MyErr型を持つインターフェース値が作成され、インターフェース値はnilではありません。

### 解説

Goのインターフェースは、値とその型情報のペアを保持します。これにより、インターフェースはさまざまな具体的な型を扱うことができます。

問題のコードは、インターフェースの値が`nil`かどうかを正しくチェックできていないことです。インターフェースの値は（値;型）のペアです。`SubDisplay`が`nil`の場合でも、その型情報が存在するため、インターフェース値自体は`nil`ではありません。

この問題を解決するには、インターフェースの値が`nil`ポインターを保持しているかどうかをチェックする必要があります。具体的な型にキャストして比較する方法もありますが、リフレクションを使ってより一般的にチェックすることもできます。

```go
package main

import (
    "fmt"
    "reflect"
)

type shower interface {
    getWater() []shower
}

type display struct {
    SubDisplay *display
}

func (d display) getWater() []shower {
    return []shower{display{}, d.SubDisplay}
}

func main() {
    s := display{}
    water := s.getWater()
    for _, x := range water {
        if x == nil {
            panic("すべて正常、nilが見つかりました")
        }

        // リフレクションを使ってnil値をチェックする
        if reflect.ValueOf(x).IsNil() {
            panic("すべて正常、リフレクションを使用してnilが見つかりました")
        }

        x.getWater()
    }
}
```
