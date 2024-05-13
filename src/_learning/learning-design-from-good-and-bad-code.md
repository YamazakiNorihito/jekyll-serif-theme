---
title: "良いコード悪いコードで学ぶ設計入門を読んだ"
date: 2024-5-13T06:27:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
---

# 学び

## Static メソッドの誤用

`static`メソッドの誤用は、凝集度の低下を招くことがあります。`static`メソッドはインスタンス変数を使用できないため、データとデータを操作するロジックが乖離する可能性があります。

### 問題点

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

### 正しい使用法

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

## Tell Don't Ask

ソフトウェア設計には、「訪ねるな、命じろ」という有名な格言があります。他のオブジェクトの内部状態（変数）を問いただすのではなく、呼び出し側はメソッドを通じて直接指示を出すだけで済ませます。そして、指示を受けた側はその内部状態に基づいて適切な判断や制御を行うように設計されています。

### 例

通常、オブジェクトの状態を外部から確認し、その状態に基づいて処理を分岐するようなコードは、カプセル化の原則に反します。以下の例では、改善前と改善後のコードを示しています。

#### 改善前

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

#### 改善後

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

## Switch分岐問題

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

#### 改善後

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

## ポリシーパターン

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
