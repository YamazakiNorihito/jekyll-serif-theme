---
title: "TypeScriptでのクラス定義がES6とES5でどのようにコンパイルされるか"
date: 2023-10-25T04:43:00
#image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: ""
linkedinurl: ""
weight: 7
tags:
  - TypeScript
  - JavaScript
  - ES6
  - ES5
  - ECMAScript
  - Programming
  - Class Definition
  - Compilation
---


ES6からクラス定義が使えるようになった。
[公式 ECMAScript® 2015 Language Specification](https://262.ecma-international.org/6.0/#sec-makeclassconstructor)

[原文](https://262.ecma-international.org/6.0/#:~:text=The%20ECMAScript%20built,permit%20programmers%20to%20concisely%20define)
> The ECMAScript built-in objects themselves follow such a class-like pattern. Beginning with ECMAScript 2015, the ECMAScript language includes syntactic class definitions that permit programmers to concisely define objects that conform to the same class-like abstraction pattern used by the built-in objects.

（DeepL翻訳）ECMAScript の組み込みオブジェクトは、このようなクラスのようなパターンに従っている。ECMAScript 2015 以降、ECMAScript 言語には構文的なクラス定義が含まれており、プログラマは組み込みオブジェクトで使用されているのと同じクラスのような抽象化パターンに準拠したオブジェクトを簡潔に定義することができます。

```javascript
class Person {
  constructor(name, age) {
    this.name = name;
    this.age = age;
  }
}

// インスタンス生成
var alice = new Person("Alice", 7);
```

ES5（ECMAScript 5）以前においては、JavaScriptにはclassキーワードが存在せず、
クラスのような構造は関数とプロトタイプを使用して模倣されていました。

```javascript
function Person(name, age) {
  this.name = name;
  this.age = age;
}

var alice = new Person("Alice", 7);
```

このような背景から、TypeScriptでクラスを定義しても、コンパイル時のECMAScriptターゲットによって展開内容が異なります。

1. ES6ターゲット:

```javascript
class Person {
  constructor(private name: string, private age: number) {}
}

// Compiled to ES6/ES2015:
class Person {
  constructor(name, age) {
    this.name = name;
    this.age = age;
  }
}
```

2. ES5ターゲット:

```javascript
class Person {
  constructor(private name: string, private age: number) {}
}

// Compiled to ES5:
function Person(name, age) {
  this.name = name;
  this.age = age;
}
```

TypeScriptは`tsconfig.json`ファイルの`target`オプションを通じて、どのECMAScriptバージョンにコンパイルするかを指定できます。
例えば、`"target": "ES5"`と設定すると、TypeScriptはES5にコンパイルされ、
`"target": "ES6"`または`"target": "ES2015"`と設定すると、
ES6/ES2015にコンパイルされます。

※[ECMAScriptとは](https://ja.wikipedia.org/wiki/ECMAScript)・・・・Ecma Internationalもとで標準化されたJavaScriptの規格である。
