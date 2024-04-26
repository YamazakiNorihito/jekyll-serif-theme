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

### ドメインオブジェクト

ドメインオブジェクトは、値オブジェクトやエンティティなどを含むドメインモデルを表現したオブジェクトです。

ドメインオブジェクトを利用するメリット

1. コードのドキュメント性が高まる
   1. コード自体がドメインの知識の「ドキュメント」として機能する
2. ドメインにおける変更をコードに伝えやすくなる

### 値オブジェクト

#### 性質

1. 不変性
   1. 定義: 値オブジェクトが作成された後、その状態が変更されない性質。
   2. 例: りんごを箱に入れたとき、そのりんごは永遠にりんごのままで、ミカンに変わることはありません。つまり、一度箱に入れたリンゴはその形状や特性を保持し続けます。
2. 交換可能性
   1. 定義: 同じ値を持つオブジェクト同士が互いに置き換え可能である性質。
   2. 例: 重さと種類が完全に同じ二つのりんごは、互いに交換しても全体の状況に影響を与えません。これは、同じ特性を持つリンゴ同士は「等価」であると見なされるからです。
3. 等価性によって比較される
   1. 定義: オブジェクトがその属性や値に基づいて比較される性質。(オブジェクトが同じ属性を持つ別のオブジェクトと容易に置き換えられる)
   2. 例: 二つのリンゴが同じ種類で同じ大きさの場合、それらは「等しい」とみなされます。この比較は、見た目や重さなどの具体的な値に基づいて行われます。

#### モチベーション

- 表現力が増す
- 不正な値を存在させない
- 誤った代入を防ぐ

#### サンプルコード

性質とモチベーションを盛り込んだサンプルコードがこちら

```csharp
using System;

class Program
{
    static void Main()
    {
        // 不変性のデモンストレーション
        var originalName = new Name("John Doe", "Doe");
        Console.WriteLine("Original Full Name: " + originalName.firstName);
        
        /* 下記のコード行はプログラマにとっては理解しやすいかもしれませんが、値オブジェクトの観点からは、
           値の変更を試みることになります。*/
        // originalName.firstName = "Jane Doe"; // コンパイルエラー: set アクセサーがないため、値を変更できません。

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

        // 誤った代入を防ぐ
        var name7 = new Name("Alice Johnson", "Johnson");
        // 以下のような代入は、型の不一致によりコンパイルエラーとなるため実行できません。
        // name7 = "日本"; // コンパイルエラー: Name型の変数にstring型を代入しようとしている

        // 文字列の場合、誤って他の文字列に変更してしまう可能性があります
        string name8 = "佐藤一郎";
        name8 = "日本"; // 誤った値に変更してしまう可能性がある
    }
}

// 表現力が増す:Nameは単なる文字列ではなく、名と姓という具体的な概念を持つ
public class Name : IEquatable<Name>
{
    public string firstName { get; }
    public string LastName { get; }

    public Name(string firstName, string lastName)
    {
        /*
            不正な値を存在させない:無効または不正な値（この場合は 名または姓にnull や３文字以下）が Name オブジェクトに設定されることを防ぎます
        */
        firstName = firstName ?? throw new ArgumentNullException(nameof(firstName));
        LastName = lastName ?? throw new ArgumentNullException(nameof(lastName));

        if(firstName.Length < 3) throw new ArgumentNullException("名は３文字以上です。",nameof(firstName));
        if(lastName.Length < 3) throw new ArgumentNullException("姓は３文字以上です。",nameof(lastName));
    }

    public override bool Equals(object obj)
    {
        return Equals(obj as Name);
    }

    public bool Equals(Name other)
    {
        return other != null &&
               firstName == other.firstName &&
               LastName == other.LastName;
    }

    public override int GetHashCode()
    {
        return HashCode.Combine(firstName, LastName);
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

### エンティティ

#### 性質

1. 可変である
   1. 定義: エンティティはその属性（状態）が時間と共に変化することができるが、同一性を保持する。
   2. 例: ファームで管理されているりんごがあるとします。このりんごは成長に伴いサイズや色が変わるかもしれませんが、それぞれのりんごに割り当てられたタグ番号によって、常に特定のりんごとして識別されます。

1. 同じ属性であっても区別される
   1. 定義: エンティティは表面上同じ属性を持っていても、一意の識別子によって区別される。
   2. 例: 箱に入れられたりんごが複数あり、全て同じ種類とサイズかもしれませんが、それぞれには独自のシリアルナンバーがあり、これによって個々のりんごが区別されます。

1. 同一性により区別される
   1. 定義: エンティティは一意の識別子（IDなど）によってその存在が定義され、継続的に追跡される。
   2. 例: 特定のりんごには一意のIDが付けられており、このIDによって、そのりんごがどこにあるのか、どのような処理がなされたのかを追跡できます。他のりんごと同じ外見を持っていても、このIDによって区別されます。

#### エンティティと値オブジェクトを区別する際の基準

##### エンティティの判断基準

1. 同一性の重要性:
    - オブジェクトが一意の識別子を必要とし、時間や状況の変化に関わらずその識別子で追跡される必要がある場合、それはエンティティです。
    - 例: ユーザー、注文、車など。
2. ライフサイクル:
   - オブジェクトが生成から終了までの明確なライフサイクルを持ち、その過程で状態が変化する可能性がある場合、それはエンティティです。
3. 状態の変化:
   - オブジェクトの属性が時間とともに変化し、それでも同一のオブジェクトとして扱われるべき場合、エンティティとして扱われます。

##### 値オブジェクトの判断基準

1. 不変性:
   - オブジェクトが作成後にその状態が変わらない場合、それは値オブジェクトです。
   - 例: 日付、金額、座標など。
2. 属性の等価性:
   - オブジェクトがその属性の値に基づいて等価性が判断される場合、それは値オブジェクトです。つまり、属性が同じであれば、それらのオブジェクトは同一とみなされます。
3. 置換可能性:
   - オブジェクトが同じ属性を持つ別のオブジェクトと容易に置き換えられる場合、それは値オブジェクトです。
   -

#### サンプルコード

性質とモチベーションを盛り込んだサンプルコードがこちら
Nameクラスは値オブジェクトで作成したクラスです。

```csharp
using System;

public class Person : IEquatable<Person>
{
    public Guid Id { get; private set; }
    public Name FullName { get; private set; }

    public Person(Guid Id, Name fullName)
    {
        Id = Id;
        FullName = fullName ?? throw new ArgumentNullException(nameof(fullName));
    }

    public Person(Name fullName)
    {
        Id = Guid.NewGuid(); // 一意の識別子を自動生成
        FullName = fullName ?? throw new ArgumentNullException(nameof(fullName));
    }

    // 他のエンティティとの等価性を Id ベースで判断
    public override bool Equals(object obj)
    {
        return Equals(obj as Person);
    }

    public bool Equals(Person other)
    {
        return other != null && Id == other.Id;
    }

    public override int GetHashCode()
    {
        return HashCode.Combine(Id);
    }

    public static bool operator ==(Person left, Person right)
    {
        return EqualityComparer<Person>.Default.Equals(left, right);
    }

    public static bool operator !=(Person left, Person right)
    {
        return !(left == right);
    }

    // 例えば、属性を変更するメソッド
    public void UpdateName(Name newName)
    {
        FullName = newName ?? throw new ArgumentNullException(nameof(newName));
    }
}
```

### ドメインサービス

#### 性質

1. ステートレス性:
   ドメインサービスは状態を保持せず、外部から提供された情報に基づいて処理を実行します。これにより、サービスの再利用性とテストの容易さが保証されます。

2. ドメインロジックの封じ込め:
   複数のエンティティや値オブジェクトでは自然に表現できないビジネスルールや計算を担当し、ドメインモデルを簡潔に保ちます。

3. ビジネスプロセスの管理:
   重要なビジネスロジックの実行や複数のドメインオブジェクト間の協調を通じて、ビジネスプロセスを適切に管理し、必要な状態遷移を実施します。

#### ドメインモデル貧血症

あまりにもドメインサービスに実装してしまうと、値オブジェクトやエンティティにビジネスロジックが不足することがあり、
それが「ドメインモデル貧血症」と呼ばれる状態に陥ります。この状態では、エンティティや値オブジェクトが単なるデータのコンテナと化し、
ビジネスロジックはドメインサービスに集中してしまいます。これにより、ドメインのモデルがその実際の振る舞いやルールを適切に表現できなくなることが問題とされます。

ドメインモデルを設計する際には、エンティティ自身が基本的にビジネスロジックを持つべきです。

#### サンプルコード

```csharp
using System.Collections.Generic;
using System.Linq;

public interface IPersonService {
    bool IsDuplicate(Person person);
}

public class PersonService : IPersonService
{
    private readonly List<Person> _people;

    public PersonService(List<Person> people)
    {
        _people = people ?? throw new ArgumentNullException(nameof(people));
    }

    // Personがリスト内に既に存在するかどうかを確認するメソッド
    public bool IsDuplicate(Person person)
    {
        if (person == null)
        {
            throw new ArgumentNullException(nameof(person));
        }

        return _people.Any(p => p.FullName == person.FullName);
    }
}
```

## アプリケーションを実現するためのパターン

### リポジトリ

#### 性質

1. データアクセスの抽象化と分離: ドメインモデルとデータアクセス層の間に抽象化層を提供し、ビジネスロジックをデータアクセスコードから分離します。

2. 集約根の管理: 集約根の永続化、取得、更新、削除を一元管理し、データの一貫性と整合性を維持します。

3. インフラストラクチャとの分離: 永続化に関わる詳細（SQLクエリ、データベース設定など）をリポジトリ内に隔離し、ドメインモデルがこれらの詳細に依存することを防ぎます。

#### サンプルコード

```csharp
using Microsoft.EntityFrameworkCore;
using System;
using System.ComponentModel.DataAnnotations;

public class PersonDbContext : DbContext
{
    public DbSet<PersonDataModel> People { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<PersonDataModel>()
            .HasKey(p => p.Id);
        modelBuilder.Entity<PersonDataModel>()
            .Property(p => p.FirstName).IsRequired();
        modelBuilder.Entity<PersonDataModel>()
            .Property(p => p.LastName).IsRequired();
    }

    public class PersonDataModel
    {
        public Guid Id { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }

        public Person ToModel()
        {
            return new Person(Id, new Name(FirstName, LastName));
        }

        public static PersonDataModel FromEntity(Person person)
        {
            return new PersonDataModel
            {
                Id = person.Id,
                FirstName = person.FullName.firstName,
                LastName = person.FullName.LastName
            };
        }
    }
}
public interface IPersonRepository
{
    Person Find(Name name);
    void Save(Person person);
}

public class PersonRepository : IPersonRepository
{
    private readonly PersonDbContext _context;

    public PersonRepository(PersonDbContext context)
    {
        _context = context;
    }

    public Person Find(Name name)
    {
        var personDataModel = _context.People
            .FirstOrDefault(p => p.FirstName == name.firstName && p.LastName == name.LastName);
        return personDataModel?.ToModel();
    }

    public void Save(Person person)
    {
        var existingPerson = _context.People.Find(person.Id);
        if (existingPerson == null)
        {
            var newPersonDataModel = PersonDbContext.PersonDataModel.FromEntity(person);
            _context.People.Add(newPersonDataModel);
        }
        else
        {
            existingPerson.FirstName = person.FullName.firstName;
            existingPerson.LastName = person.FullName.LastName;
            _context.People.Update(existingPerson);
        }
        _context.SaveChanges();
    }
}

public class PersonService
{
    private readonly IPersonRepository _repository;

    public PersonService(IPersonRepository repository)
    {
        _repository = repository;
    }

    public bool Exists(Name name)
    {
        return _repository.Find(name) != null;
    }

    public void SavePersonIfNotExists(Person person)
    {
        if (!Exists(person.FullName))
        {
            _repository.Save(person);
            Console.WriteLine("Person saved successfully.");
        }
        else
        {
            Console.WriteLine("A person with the same name already exists.");
        }
    }
}

class Program
{
    static void Main()
    {
        IPersonRepository repository = new PersonRepository();
        PersonService service = new PersonService(repository);

        // 新しいPersonオブジェクトを作成
        Person person1 = new Person(new Name("John", "Doe"));
        service.SavePersonIfNotExists(person1);

        // 重複チェックを行うために同じ名前のPersonオブジェクトを作成
        Person person2 = new Person(new Name("John", "Doe"));
        service.SavePersonIfNotExists(person2);  // この場合、保存されません。
    }
}

```

## 参考

- [ドメイン駆動設計入門](https://www.seshop.com/product/detail/20675)
- [Best Practice - An Introduction To Domain-Driven Design](https://learn.microsoft.com/en-us/archive/msdn-magazine/2009/february/best-practice-an-introduction-to-domain-driven-design)
