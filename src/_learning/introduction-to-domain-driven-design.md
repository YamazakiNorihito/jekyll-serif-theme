---
title: "ドメイン駆動設計入門(工事中)"
date: 2024-4-24T06:00:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
---

# ドメイン駆動設計 (DDD) 入門

## 知識を表現するパターン

### 値オブジェクト

値オブジェクトは以下の性質を持つ

1. 不変である
   1. 定義: 値オブジェクトが作成された後、その状態が変更されない性質。
   2. 例: りんごを箱に入れたとき、そのりんごは永遠にりんごのままで、ミカンに変わることはありません。つまり、一度箱に入れたリンゴはその形状や特性を保持し続けます。
2. 交換可能である
   1. 定義: 同じ値を持つオブジェクト同士が互いに置き換え可能である性質。
   2. 例: 重さと種類が完全に同じ二つのりんごは、互いに交換しても全体の状況に影響を与えません。これは、同じ特性を持つリンゴ同士は「等価」であると見なされるからです。
3. 等価性によって比較される
   1. 定義: オブジェクトがその属性や値に基づいて比較される性質。
   2. 例: 二つのリンゴが同じ種類で同じ大きさの場合、それらは「等しい」とみなされます。この比較は、見た目や重さなどの具体的な値に基づいて行われます。

```csharp
using System;

class Program
{
    static void Main()
    {
        // 不変性のデモンストレーション
        var originalName = new Name("John Doe", "Doe");
        Console.WriteLine("Original Full Name: " + originalName.FullName);
        
        /* 下記のコード行はプログラマにとっては理解しやすいかもしれませんが、値オブジェクトの観点からは、
           値の変更を試みることになります。*/
        // originalName.FullName = "Jane Doe"; // コンパイルエラー: set アクセサーがないため、値を変更できません。

        // 交換可能性のデモンストレーション
        // 変更は値と同じように代入
        var name1 = new Name("Alice Johnson", "Johnson");
        name1 = new Name("Alice Johnson", "Johnson");
        
        // 等価性のデモンストレーション
        var name3 = new Name("Alice Johnson", "Johnson");
        var name4 = new Name("Alice Johnson", "Smith");
        Console.WriteLine("Name3 and Name4 are equal: " + (name3.Equals(name4))); // Falseを出力

        // 同じ名前で異なる姓を試す
        var name5 = new Name("Alice Johnson", "Johnson");
        var name6 = new Name("Alice Johnson", "Johnson");
        Console.WriteLine("Name5 and Name6 are equal: " + (name5.Equals(name6))); // Trueを出力
    }
}

public class Name : IEquatable<Name>
{
    public string FullName { get; }
    public string LastName { get; }

    public Name(string fullName, string lastName)
    {
        FullName = fullName ?? throw new ArgumentNullException(nameof(fullName));
        LastName = lastName ?? throw new ArgumentNullException(nameof(lastName));
    }

    public override bool Equals(object obj)
    {
        return Equals(obj as Name);
    }

    public bool Equals(Name other)
    {
        return other != null &&
               FullName == other.FullName &&
               LastName == other.LastName;
    }

    public override int GetHashCode()
    {
        return HashCode.Combine(FullName, LastName);
    }

    public static bool operator ==(Name left, Name right)
    {
        return EqualityComparer<Name>.Default.Equals(left, right);
    }

    public static bool operator !=(Name left, Name right)
    {
        return !(left == right);
    }
}
```

## 参考

- [ドメイン駆動設計入門](https://www.seshop.com/product/detail/20675)
- [Best Practice - An Introduction To Domain-Driven Design](https://learn.microsoft.com/en-us/archive/msdn-magazine/2009/february/best-practice-an-introduction-to-domain-driven-design)
