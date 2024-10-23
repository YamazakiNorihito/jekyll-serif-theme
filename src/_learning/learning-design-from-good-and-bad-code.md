---
title: "良いコード悪いコードで学ぶ設計入門を読んだ"
date: 2024-5-13T06:27:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - Code Quality
  - Software Design
  - Static Methods
  - Best Practices
  - Design Patterns
  - Tell Don't Ask
  - Switch Case
  - Polymorphism
  - Inheritance
  - YAGNI
  - Null Handling
  - Development Process
  - Code Review
description: ""
---

## 学び

#### Static メソッドの誤用

`static`メソッドの誤用は、凝集度の低下を招くことがあります。`static`メソッドはインスタンス変数を使用できないため、データとデータを操作するロジックが乖離する可能性があります。

###### 問題点

例えば、以下のコードでは`static`メソッドが、データクラスとは独立して存在しています。これにより、データとロジックの分離が進み、低凝集の状態になってしまいます。

```csharp
class MoneyData {
    public int amount;
}

class StaticExample {
    public static int Add(int moneyAmount1, int moneyAmount2) {
        return moneyAmount1 + moneyAmount2;
    }
}

MoneyData moneyData1 = new MoneyData { amount = 100 };
MoneyData moneyData2 = new MoneyData { amount = 150 };

// データとロジックが別のクラスに定義されているため、低凝集に陥ります。
moneyData1.amount = StaticExample.Add(moneyData1.amount, moneyData2.amount);
```

###### 正しい使用法

`static`メソッドは、凝集度に影響がない特定のケースで有用です。例えば、ログ出力、データのフォーマット変換、ファクトリーメソッドなど、データを直接操作しない補助的な処理に適しています。以下は、`static`メソッドの適切な使用例です。

```csharp
class Logger {
    public static void Log(string message) {
        Console.WriteLine(message);
    }
}

// ログ出力のためのstaticメソッド使用例
Logger.Log("処理を開始します。");
```

#### Tell Don't Ask

ソフトウェア設計には、「訪ねるな、命じろ」という有名な格言があります。他のオブジェクトの内部状態（変数）を問いただすのではなく、呼び出し側はメソッドを通じて直接指示を出すだけで済ませます。そして、指示を受けた側はその内部状態に基づいて適切な判断や制御を行うように設計されています。

###### 例

通常、オブジェクトの状態を外部から確認し、その状態に基づいて処理を分岐するようなコードは、カプセル化の原則に反します。以下の例では、改善前と改善後のコードを示しています。

######## 改善前

```csharp
class Account {
    private decimal balance;

    public decimal GetBalance() {
        return balance;
    }
}

// 利用例
Account account = new Account();
if (account.GetBalance() > 0) {
    // 残高がある場合の処理
}

```

######## 改善後

```csharp
class Account {
    private decimal balance;

    public void ProcessAccount() {
        if (balance > 0) {
            // 残高がある場合の処理をここで完結
        }
    }
}

// 利用例
Account account = new Account();
account.ProcessAccount(); // 状態を問わずに命令を出す

```

このように、Accountクラスの内部で残高のチェックを行い、処理を分岐させることで、オブジェクトの状態が外部に露出されることなく、よりカプセル化された設計を実現できます。

#### Switch分岐問題

各動物の音を出す処理が一つのメソッド内に集約されています。これは以下のような問題を引き起こす可能性があります:

- 拡張の難しさ: 新しい動物を追加するたびにSwitch文に新たなcaseを追加する必要があります。これは時間が経つにつれて、メソッドが複雑になり、管理が困難になる原因となります。
- コードの見通しの悪さ: 場合によってはSwitchの各Case内に多くの処理が書かれていることがあり、その結果としてコードの見通しが悪くなります。これは、処理の目的やロジックの流れを見失う原因にもなり得ます。
- 分散したロジック: この種の判定ロジックがプログラムの一箇所に限られないこともあります。複数の場所で同様のSwitch文が使われていると、コードのどこを変更すれば良いのか把握しづらくなり、エラーの原因ともなります。

```csharp
using System;

enum AnimalType
{
    Dog,
    Cat,
    Bird
}

class Animal
{
    public static void MakeSound(AnimalType type)
    {
        switch (type)
        {
            case AnimalType.Dog:
                Console.WriteLine("Bark");
                break;
            case AnimalType.Cat:
                Console.WriteLine("Meow");
                break;
            case AnimalType.Bird:
                Console.WriteLine("Tweet");
                break;
            default:
                throw new ArgumentOutOfRangeException();
        }
    }
}

// 使用例
class Program
{
    static void Main(string[] args)
    {
        Animal.MakeSound(AnimalType.Dog);
    }
}


```

######## 改善後

```csharp
using System;
using System.Collections.Generic;

enum AnimalType
{
    Dog,
    Cat,
    Bird
}

interface IAnimal
{
    void MakeSound();
}

class Dog : IAnimal
{
    public void MakeSound()
    {
        Console.WriteLine("Bark");
    }
}

class Cat : IAnimal
{
    public void MakeSound()
    {
        Console.WriteLine("Meow");
    }
}

class Bird : IAnimal
{
    public void MakeSound()
    {
        Console.WriteLine("Tweet");
    }
}

class AnimalFactory
{
    private readonly Dictionary<AnimalType, IAnimal> animals;

    public AnimalFactory()
    {
        animals = new Dictionary<AnimalType, IAnimal>
        {
            { AnimalType.Dog, new Dog() },
            { AnimalType.Cat, new Cat() },
            { AnimalType.Bird, new Bird() }
        };
    }

    public IAnimal GetAnimal(AnimalType type)
    {
        if (!animals.ContainsKey(type))
        {
            throw new ArgumentOutOfRangeException(nameof(type), "No animal of this type exists.");
        }
        return animals[type];
    }
}

// 使用例
class Program
{
    static void Main(string[] args)
    {
        var factory = new AnimalFactory();
        IAnimal animal = factory.GetAnimal(AnimalType.Dog);
        animal.MakeSound();
    }
}
```

#### ポリシーパターン

ポリシーパターンは、柔軟性を持たせた条件判断のためのデザインパターンです。ビジネスロジックの各部分が独立しているため、特定の条件やルールに基づくビジネスロジックを効率的に管理することができます。これにより、以下の利点があります：

- 条件の追加や変更の容易さ: 新しいビジネスルールや条件を追加、更新、または削除する際に、他の部分への影響を最小限に抑えることができる
- ビジネスロジックの明確な分離: ビジネスロジックを小さな部分に分割することで、それぞれの部分が独立して機能する
- 再利用性の向上: 同じルールを異なるコンテキストで再利用できる

```csharp
using System;
using System.Collections.Generic;

public class Customer
{
    public double PurchaseAmount { get; set; }
    public int VisitFrequency { get; set; }
    public double TipAmount { get; set; }
}

public interface IRule
{
    bool IsSatisfied(Customer customer);
}

public class PurchaseAmountRule : IRule
{
    private readonly double requiredAmount;

    public PurchaseAmountRule(double amount)
    {
        requiredAmount = amount;
    }

    public bool IsSatisfied(Customer customer)
    {
        return customer.PurchaseAmount >= requiredAmount;
    }
}

public class VisitFrequencyRule : IRule
{
    private readonly int requiredVisits;

    public VisitFrequencyRule(int visits)
    {
        requiredVisits = visits;
    }

    public bool IsSatisfied(Customer customer)
    {
        return customer.VisitFrequency >= requiredVisits;
    }
}

public class TipAmountRule : IRule
{
    private readonly double requiredTip;

    public TipAmountRule(double tip)
    {
        requiredTip = tip;
    }

    public bool IsSatisfied(Customer customer)
    {
        return customer.TipAmount >= requiredTip;
    }
}

public class MembershipPolicy
{
    public string Name { get; set; }
    private readonly List<IRule> rules = new List<IRule>();

    public MembershipPolicy(string name)
    {
        Name = name;
    }

    public void AddRule(IRule rule)
    {
        rules.Add(rule);
    }

    public bool ApplyPolicy(Customer customer)
    {
        foreach (var rule in rules)
        {
            if (!rule.IsSatisfied(customer))
            {
                return false;
            }
        }
        return true;
    }
}

public class MembershipEvaluator
{
    private List<MembershipPolicy> policies = new List<MembershipPolicy>();

    public void AddPolicy(MembershipPolicy policy)
    {
        policies.Add(policy);
    }

    public string EvaluateMembership(Customer customer)
    {
        foreach (var policy in policies)
        {
            if (policy.ApplyPolicy(customer))
            {
                return policy.Name;
            }
        }
        return "Standard";
    }
}

class Program
{
    static void Main()
    {
        var customer = new Customer
        {
            PurchaseAmount = 1000,
            VisitFrequency = 12,
            TipAmount = 100
        };

        var goldPolicy = new MembershipPolicy("Gold");
        goldPolicy.AddRule(new PurchaseAmountRule(800));
        goldPolicy.AddRule(new VisitFrequencyRule(10));
        goldPolicy.AddRule(new TipAmountRule(80));

        var silverPolicy = new MembershipPolicy("Silver");
        silverPolicy.AddRule(new PurchaseAmountRule(500));
        silverPolicy.AddRule(new VisitFrequencyRule(5));
        silverPolicy.AddRule(new TipAmountRule(50));

        var evaluator = new MembershipEvaluator();
        evaluator.AddPolicy(goldPolicy);
        evaluator.AddPolicy(silverPolicy);

        var membership = evaluator.EvaluateMembership(customer);
        Console.WriteLine($"The customer qualifies for {membership} membership.");
    }
}

```

#### [車輪の再発明](https://ja.wikipedia.org/wiki/%E8%BB%8A%E8%BC%AA%E3%81%AE%E5%86%8D%E7%99%BA%E6%98%8E)

「車輪の再発明」とは、すでに存在する技術や解決策を知らずに、同じものを一から再び作り上げることを指します。

しかし、「車輪の再発明」が常に悪いわけではありません。
学習目的で一から作り直すことで、技術の本質を理解し、技術力を高めることができます。

#### First Class Collection

コレクション専用のクラスを作成するデザインパターンです。

**利点**

- 集約操作のカプセル化
  - コレクションに対する操作（例えば、追加、削除、フィルタリングなど）をコレクションクラス内にカプセル化します。これにより、操作が分散されることを防ぎ、データの不正な操作を防ぎます。

**注意**

- 副作用の管理
  - Itemの追加時の副作用や、コレクションを外部に渡す際に副作用が生じないように、実装に注意を払いましょう。

```csharp
public class Party
{
    private readonly ImmutableList<Member> _members;

    public Party(IEnumerable<Member> members)
    {
        _members = members.ToImmutableList();
    }

    // 不変
    public ImmutableList<Member> Members => _members;

    // メンバーを追加し、新しい Party インスタンスを返す
    public Party AddMember(Member member)
    {
        if (member == null) throw new ArgumentNullException(nameof(member));
        if (_members.Contains(member)) return this; // すでに存在する場合は追加しない

        var newMembers = _members.Add(member);
        return new Party(newMembers);
    }

    // メンバーを削除し、新しい Party インスタンスを返す
    public Party RemoveMember(Member member)
    {
        if (member == null) throw new ArgumentNullException(nameof(member));
        if (!_members.Contains(member)) return this; // 存在しない場合は何もしない

        var newMembers = _members.Remove(member);
        return new Party(newMembers);
    }
}

```

#### [単一責任](https://learn.microsoft.com/ja-jp/dotnet/architecture/modern-web-apps-azure/architectural-principles##single-responsibility)

オブジェクトは１つの責任のみを持つべきです。

単一責任に則って、製品の価格に関して通常割引と夏季割引を実装してみるとこんな感じ

```csharp
public interface IDiscountStrategy
{
    decimal ApplyDiscount(decimal originalPrice);
}

public class RegularDiscount : IDiscountStrategy
{
    public decimal ApplyDiscount(decimal originalPrice)
    {
        // ここでは例として10%の割引を適用
        return originalPrice * 0.90m;
    }
}

public class SummerDiscount : IDiscountStrategy
{
    public decimal ApplyDiscount(decimal originalPrice)
    {
        // 夏季割引として例として20%の割引を適用
        return originalPrice * 0.80m;
    }
}
public class Product
{
    public string Name { get; set; }
    public decimal Price { get; set; }
    private IDiscountStrategy discountStrategy;

    public Product(string name, decimal price, IDiscountStrategy discountStrategy)
    {
        Name = name;
        Price = price;
        this.discountStrategy = discountStrategy;
    }

    public decimal GetPriceWithDiscount()
    {
        return discountStrategy.ApplyDiscount(Price);
    }
}
```

#### 継承

継承はオブジェクト指向プログラミングにおいて強力なツールですが、それには注意が必要です。継承を利用する際、基底クラスの変更が派生クラスに影響を与える可能性があります。基底クラスは派生クラスの事情を考慮せずに変更されることが多いため、これは重要なリスクとなります。

もし派生クラスが基底クラスのメソッドを完全にオーバーライドする場合、継承の本来の利点が問われます。全てのメソッドをオーバーライドすると、派生クラスは基底クラスの実装とは異なる振る舞いを持つことになり、そもそも継承する理由が薄れてしまいます。

継承が便利である一方で、ドメインやビジネスロジックの知識が分散してしまうという問題があります。
これにより、保守が難しくなる可能性があります。
継承の使用を検討する前に、単一責任の原則に従い、コンポジションや値オブジェクトを利用して設計できないかを検討をお勧めします。

```csharp
using System;

public interface IDiscountStrategy
{
    decimal ApplyDiscount(decimal originalPrice);
}

public class RegularDiscount : IDiscountStrategy
{
    public decimal ApplyDiscount(decimal originalPrice)
    {
        // 通常の割引として10%オフを適用
        return originalPrice * 0.90m;
    }
}

public class SummerDiscount : RegularDiscount
{
    public override decimal ApplyDiscount(decimal originalPrice)
    {
        // 夏季割引として、通常の割引に追加して更に5%オフを適用
        decimal priceAfterRegularDiscount = base.ApplyDiscount(originalPrice);
        return priceAfterRegularDiscount * 0.95m;  // 追加5%オフ
    }
}

```

#### [YAGNI](https://ja.wikipedia.org/wiki/YAGNI)

You ain't gonna need it

将来の予測に基づいて汎用的な機能や複雑な設計をするのではなく、現在の実際のニーズに基づいて限定的かつシンプルに実装することだと理解

#### null問題

結論から言えば、nullは扱うべきではありません。「nullを返さない」「nullを渡さない」という原則が大切です。nullの発明者である[アントニー・ホーア](https://ja.wikipedia.org/wiki/%E3%82%A2%E3%83%B3%E3%83%88%E3%83%8B%E3%83%BC%E3%83%BB%E3%83%9B%E3%83%BC%E3%82%A2)さんは、nullを発明したことをとても後悔しています。

nullとは未初期化状態を表し、何かを持っていない状態や未設定状態など、その状態すら存在しないのがnullなのです。nullがあるために、至る所でnullチェックをしなければならなくなります。

#### 開発プロセス

###### 設計

- **「早く終わらせたい」心理が品質低下の罠**
  - 速やかな実装は、しばしば品質を無視したコードを生み、後に問題を引き起こす
  - 読解が困難でメンテナンスが複雑になり、小さな修正で新たな不具合が生じやすい
  - TDDを採用することで、最終的には全体的に安定した実装が可能

- **厳密に設計しすぎず、サイクルを回し続けるのがコツ**
  - 厳格な初期設計は見落としを招き、実装との乖離が精神的負担を増加させる
  - 完璧な設計は初回からでは難しく、設計と実装の繰り返しによるフィードバックで改善される
  - チーム内でのサイクルに対する合意が不一致を防ぎ、共有理解を深める

- **設計ルールを多数決で決めるとコード品質が最低になる**
  - 多数決で設計ルールを決めると、コード品質が低下する可能性がある
    - これは、基準が経験の浅いメンバーに合わせられがちだから
  - 設計スキルが未熟なメンバーでは、設計の良し悪しの判断が難しい
  - シニアエンジニアやスキルの高いメンバーがルール作りを主導するべき
    - チームリーダーは権限を利用してルールの推進を図る
  - 設計ルールには常にその理由や意図を明記する
  - 設計ルールは、パフォーマンスやフレームワークの制約とのトレードオフを考慮する必要がある
  - 絶対的なルールではなく、状況に応じて妥協点や落とし所を模索することが重要

###### 実装

- **コーディング規約の利用**
  - 統一されたコードは読みやすく、保守性が向上します。
  - コーディングスタイルや命名規則など、コードの問題を未然に防ぐためのルールが定められています。
  - 主要な言語ごとにコーディング規約が存在します：
    - [Java](https://google.github.io/styleguide/javaguide.html)
    - [C##](https://learn.microsoft.com/ja-jp/dotnet/csharp/fundamentals/coding-style/coding-conventions)
    - [TypeScript](https://google.github.io/styleguide/tsguide.html)

###### レビュー

- GitHubを使ってコードレビューしApproveしたからPRのみマージ可能な仕組みを利用する
- コードを設計視点でレビュー
  - 設計的に妥当性に重点を置いてレビューすえる
- 敬意と礼儀
  - 攻撃的なコメントは、どんなに正しい内容であれ許されません。
    - 人格を木津付け、生産性を低下させ、コードを良くするという本来の目的を阻害する
