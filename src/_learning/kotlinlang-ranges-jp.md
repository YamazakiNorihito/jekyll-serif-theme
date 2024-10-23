---
title: "Ranges and progressions（翻訳）"
date: 2024-4-9T09:15:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  -
description: "Kotlinで範囲と進行を簡単に作成する方法について解説します。閉区間と開区間の範囲作成、forループでの使用、逆順の処理、任意のステップでの反復処理など、範囲の基本的な使い方から進行の特性までカバーしています。また、Int、Long、Charの進行についても触れ、範囲を反復処理する際の詳細なステップ計算やコレクション関数での利用方法を紹介します。"
---

元サイト：<https://kotlinlang.org/docs/ranges.html>

### Ranges and progressions

Kotlin では、kotlin.ranges パッケージの.rangeTo()関数と.rangeUntil()関数を使用して値の範囲を簡単に作成できます。

次のように作成します：

- 閉区間の範囲は、..演算子を使用して.rangeTo()関数を呼び出します。
- 開区間の範囲は、..<演算子を使用して.rangeUntil()関数を呼び出します。

例：

```kotlin
// 閉区間の範囲
println(4 in 1..4)
// true

// 開区間の範囲
println(4 in 1..<4)
// false
```

範囲は、for ループを繰り返す際に特に便利です：

```kotlin
for (i in 1..4) print(i)
// 1234

```

逆順で数値を反復処理するには、...の代わりに downTo 関数を使用します。

```kotlin
for (i in 4 downTo 1) print(i)
// 4321

```

また、任意のステップ（必ずしも 1 ではない）で数値を反復処理することもできます。これは step 関数を使用して行います。

```kotlin
for (i in 0..8 step 2) print(i)
println()
// 02468
for (i in 0..<8 step 2) print(i)
println()
// 0246
for (i in 8 downTo 0 step 2) print(i)
// 86420

```

## 進行

Int、Long、Char などの整数型の範囲は、算術進行として扱うことができます。Kotlin では、これらの進行は特別な型で定義されます：IntProgression、LongProgression、CharProgression。

進行には 3 つの重要な属性があります：最初の要素、最後の要素、およびゼロでないステップ。最初の要素は最初であり、以降の要素は前の要素にステップを加えたものです。正のステップで進行を反復処理すると、Java/JavaScript のインデックス付き for ループと同等です。

```kotlin
for (int i = first; i <= last; i += step) {
  // ...
}

```

範囲を反復処理することで進行が暗黙的に作成される場合、この進行の最初の要素と最後の要素は範囲のエンドポイントであり、ステップは 1 です。

```kotlin
for (i in 1..10) print(i)
// 12345678910

```

カスタムの進行ステップを定義するには、範囲に step 関数を使用します。

```kotlin
for (i in 1..8 step 2) print(i)
// 1357

```

進行の最後の要素は次のように計算されます：

- 正のステップの場合：(last - first) % step == 0 を満たす、エンド値より大きくない最大の値。
- 負のステップの場合：(last - first) % step == 0 を満たす、エンド値より小さくない最小の値。
  したがって、最後の要素は常に指定されたエンド値とは限りません。

```kotlin
for (i in 1..9 step 3) print(i) // 最後の要素は7
// 147

```

進行は Iterable<N>を実装しており、N は Int、Long、または Char です。そのため、これらを map、filter などのさまざまなコレクション関数で使用できます。

```kotlin
println((1..10).filter { it % 2 == 0 })
// [2, 4, 6, 8, 10]

```
