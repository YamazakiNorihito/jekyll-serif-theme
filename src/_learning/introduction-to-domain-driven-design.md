---
title: "ドメイン駆動設計入門"
date: 2024-4-24T06:00:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  -
description: ""
---

## ドメイン駆動設計 (DDD) 入門

### 知識を表現するパターン

#### ドメインオブジェクト

ドメインオブジェクトは、値オブジェクトやエンティティなどを含むドメインモデルを表現したオブジェクトです。

ドメインオブジェクトを利用するメリット

1. コードのドキュメント性が高まる
   1. コード自体がドメインの知識の「ドキュメント」として機能する
2. ドメインにおける変更をコードに伝えやすくなる

#### 値オブジェクト

##### 性質

1. 不変性
   1. 定義: 値オブジェクトが作成された後、その状態が変更されない性質。
   2. 例: りんごを箱に入れたとき、そのりんごは永遠にりんごのままで、ミカンに変わることはありません。つまり、一度箱に入れたリンゴはその形状や特性を保持し続けます。
2. 交換可能性
   1. 定義: 同じ値を持つオブジェクト同士が互いに置き換え可能である性質。
   2. 例: 重さと種類が完全に同じ二つのりんごは、互いに交換しても全体の状況に影響を与えません。これは、同じ特性を持つリンゴ同士は「等価」であると見なされるからです。
3. 等価性によって比較される
   1. 定義: オブジェクトがその属性や値に基づいて比較される性質。(オブジェクトが同じ属性を持つ別のオブジェクトと容易に置き換えられる)
   2. 例: 二つのリンゴが同じ種類で同じ大きさの場合、それらは「等しい」とみなされます。この比較は、見た目や重さなどの具体的な値に基づいて行われます。

##### モチベーション

- 表現力が増す
- 不正な値を存在させない
- 誤った代入を防ぐ

##### サンプルコード

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

#### エンティティ

##### 性質

1. 可変である

   1. 定義: エンティティはその属性（状態）が時間と共に変化することができるが、同一性を保持する。
   2. 例: ファームで管理されているりんごがあるとします。このりんごは成長に伴いサイズや色が変わるかもしれませんが、それぞれのりんごに割り当てられたタグ番号によって、常に特定のりんごとして識別されます。

1. 同じ属性であっても区別される

   1. 定義: エンティティは表面上同じ属性を持っていても、一意の識別子によって区別される。
   2. 例: 箱に入れられたりんごが複数あり、全て同じ種類とサイズかもしれませんが、それぞれには独自のシリアルナンバーがあり、これによって個々のりんごが区別されます。

1. 同一性により区別される
   1. 定義: エンティティは一意の識別子（ID など）によってその存在が定義され、継続的に追跡される。
   2. 例: 特定のりんごには一意の ID が付けられており、この ID によって、そのりんごがどこにあるのか、どのような処理がなされたのかを追跡できます。他のりんごと同じ外見を持っていても、この ID によって区別されます。

##### エンティティと値オブジェクトを区別する際の基準

####### エンティティの判断基準

1. 同一性の重要性:
   - オブジェクトが一意の識別子を必要とし、時間や状況の変化に関わらずその識別子で追跡される必要がある場合、それはエンティティです。
   - 例: ユーザー、注文、車など。
2. ライフサイクル:
   - オブジェクトが生成から終了までの明確なライフサイクルを持ち、その過程で状態が変化する可能性がある場合、それはエンティティです。
3. 状態の変化:
   - オブジェクトの属性が時間とともに変化し、それでも同一のオブジェクトとして扱われるべき場合、エンティティとして扱われます。

####### 値オブジェクトの判断基準

1. 不変性:
   - オブジェクトが作成後にその状態が変わらない場合、それは値オブジェクトです。
   - 例: 日付、金額、座標など。
2. 属性の等価性:
   - オブジェクトがその属性の値に基づいて等価性が判断される場合、それは値オブジェクトです。つまり、属性が同じであれば、それらのオブジェクトは同一とみなされます。
3. 置換可能性:
   - オブジェクトが同じ属性を持つ別のオブジェクトと容易に置き換えられる場合、それは値オブジェクトです。
   -

##### サンプルコード

性質とモチベーションを盛り込んだサンプルコードがこちら
Name クラスは値オブジェクトで作成したクラスです。

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

#### ドメインサービス

##### 性質

1. ステートレス性:
   ドメインサービスは状態を保持せず、外部から提供された情報に基づいて処理を実行します。これにより、サービスの再利用性とテストの容易さが保証されます。

2. ドメインロジックの封じ込め:
   複数のエンティティや値オブジェクトでは自然に表現できないビジネスルールや計算を担当し、ドメインモデルを簡潔に保ちます。

3. ビジネスプロセスの管理:
   重要なビジネスロジックの実行や複数のドメインオブジェクト間の協調を通じて、ビジネスプロセスを適切に管理し、必要な状態遷移を実施します。

##### ドメインモデル貧血症

あまりにもドメインサービスに実装してしまうと、値オブジェクトやエンティティにビジネスロジックが不足することがあり、
それが「ドメインモデル貧血症」と呼ばれる状態に陥ります。この状態では、エンティティや値オブジェクトが単なるデータのコンテナと化し、
ビジネスロジックはドメインサービスに集中してしまいます。これにより、ドメインのモデルがその実際の振る舞いやルールを適切に表現できなくなることが問題とされます。

ドメインモデルを設計する際には、エンティティ自身が基本的にビジネスロジックを持つべきです。

##### サンプルコード

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

### アプリケーションを実現するためのパターン

#### リポジトリ

##### 性質

1. データアクセスの抽象化と分離: ドメインモデルとデータアクセス層の間に抽象化層を提供し、ビジネスロジックをデータアクセスコードから分離します。

2. 集約根の管理: 集約根の永続化、取得、更新、削除を一元管理し、データの一貫性と整合性を維持します。

3. インフラストラクチャとの分離: 永続化に関わる詳細（SQL クエリ、データベース設定など）をリポジトリ内に隔離し、ドメインモデルがこれらの詳細に依存することを防ぎます。

##### サンプルコード

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

#### アプリケーションサービス

##### 性質

1. データの形状変換とマッピング:

   - アプリケーションサービスはドメインモデルからクライアントが必要とするデータ形式へのマッピングと変換を行います。ドメインオブジェクトを直接公開せず、データ更新はクライアントではなくサービスを通じて行います。

2. ドメインモデル依存性:

   - 値オブジェクト、エンティティ、リポジトリ、ドメインサービスに依存し、これらを統合してシステムの機能を実現します。

3. ビジネスロジックの実装:

   - アプリケーションサービスは、ビジネスロジックを処理し、システム間の調整や外部 API との連携を担います。これにより、アプリケーションの核となる機能が効率的に運用されます。

4. ステートレス性:
   - アプリケーションサービスはステートレスに設計されており、状態情報を保持せずにリクエストを処理します。これにより、スケーラビリティと再利用性が向上します。

##### サンプルコード

```csharp
public class PersonDto
{
    public Guid Id { get; }
    public string FirstName { get; }
    public string LastName { get; }

    public PersonDto(Person person)
    {
        if (person == null) throw new ArgumentNullException(nameof(person));
        Id = person.Id;
        FirstName = person.FullName.firstName;
        LastName = person.FullName.LastName;
    }
}

public class RegisterPersonCommand
{
    public string FirstName { get; set; }
    public string LastName { get; set; }
}

public class GetPersonCommand
{
    public string FirstName { get; set; }
    public string LastName { get; set; }
}

public interface IPersonRegistrationService
{
    PersonDto Handle(RegisterPersonCommand command);
}

public interface IPersonRetrievalService
{
    PersonDto Handle(GetPersonCommand command);
}

public class PersonRegistrationService : IPersonRegistrationService
{
    private readonly IPersonRepository _personRepository;
    private readonly IPersonService _personService;

    public PersonRegistrationService(IPersonRepository personRepository, IPersonService personService)
    {
        _personRepository = personRepository ?? throw new ArgumentNullException(nameof(personRepository));
        _personService = personService ?? throw new ArgumentNullException(nameof(personService));
    }

    public PersonDto Handle(RegisterPersonCommand command)
    {
        var name = new Name(command.FirstName, command.LastName);
        var newPerson = new Person(name);

        if (_personService.IsDuplicate(newPerson))
        {
            throw new ArgumentException("このユーザーは既に登録されています。");
        }

        _personRepository.Save(newPerson);
        return new PersonDto(newPerson);
    }
}

public class PersonRetrievalService : IPersonRetrievalService
{
    private readonly IPersonRepository _personRepository;

    public PersonRetrievalService(IPersonRepository personRepository)
    {
        _personRepository = personRepository ?? throw new ArgumentNullException(nameof(personRepository));
    }

    public PersonDto Handle(GetPersonCommand command)
    {
        var name = new Name(command.FirstName, command.LastName);
        Person person = _personRepository.Find(name);

        if (person == null)
        {
            throw new KeyNotFoundException("指定されたユーザーは見つかりませんでした。");
        }

        return new PersonDto(person);
    }
}
```

#### 実装のポイント

##### インターフェースの使用

- **インターフェース**: `IPersonRegistrationService` と `IPersonRetrievalService`。
- **目的**: 依存性の逆転原則（Dependency Inversion Principle）を適用し、高レベルのモジュールが低レベルのモジュールに依存しないように設計。
- **結果**: より柔軟でテストしやすいコードを実現。

##### 責務の分離

- **分離内容**: アプリケーションサービスを「登録」と「取得」という明確に区別される責務に分割。
- **目的**: 各サービスが単一の機能に集中し、高い凝縮度を実現。
- **結果**: 凝縮度が高まることで、各コンポーネントの再利用性とテスト容易性が向上し、システム全体の理解とメンテナンスが容易になる。

##### command オブジェクトの使用

- **オブジェクト**: `RegisterPersonCommand` および `GetPersonCommand`。
- **目的**: パラメータを一つのオブジェクトにまとめ、将来的にパラメータが増えてもメソッドシグネチャの変更を避ける。
- **結果**: 機能拡張が容易に。

#### ファクトリ

##### 性質

- 明確化
  - ファクトリーメソッドによって、オブジェクト生成の複雑なロジックが一箇所に集約され、全体のコードの読解性と整合性が向上します。
- 再利用性の向上
  - 同じ生成ロジックをファクトリークラスで管理することで、コードの重複を防ぎ、一貫性のあるオブジェクト生成が可能になります。
- カプセル化
  - オブジェクトの生成詳細をクライアントから隠蔽することで、使用する側はオブジェクトの生成方法を意識せずに済むため、コードの簡潔さが保たれます。

#### サンプルコード

```csharp
using System;


public interface IPersonFactory
{
    Person CreatePerson(Name fullName);
}
public class PersonFactory : IPersonFactory
{
    public Person CreatePerson(Name fullName)
    {
        if (fullName == null)
        {
            throw new ArgumentNullException(nameof(fullName), "Full name cannot be null.");
        }

        return new Person(Guid.NewGuid(), fullName);
    }
}


public class Person : IEquatable<Person>
{
    public Guid Id { get; private set; }
    public Name FullName { get; private set; }

    // factoryからの生成
    public Person(Guid Id, Name fullName)
    {
        this.Id = Id;
        FullName = fullName ?? throw new ArgumentNullException(nameof(fullName));
    }

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

    public void UpdateName(Name newName)
    {
        FullName = newName ?? throw new ArgumentNullException(nameof(newName));
    }
}
```

### 知識を表現する、より発展的なパターン

#### 集約

##### 性質

- ルート

  - 集約ルートは集約内の主要なエンティティであり、集約内の他のオブジェクトに対するアクセスポイントの役割を果たす

- 境界:
  - 集約内のオブジェクトがどこまでの範囲かを定めるもの

#### サンプルコード

```csharp

public class User
{
    public Guid Id { get; private set; }
    public string Name { get; private set; }

    public User(string name)
    {
        Id = Guid.NewGuid();
        Name = name;
    }

    public void ChangeName(string newName)
    {
        if (string.IsNullOrWhiteSpace(newName))
        {
            throw new ArgumentException("Name cannot be empty.");
        }

        Name = newName;
    }
}

public class Circle
{
    public Guid Id { get; private set; }
    public User Owner { get; private set; }
    // サンプルとしてUser集約を定義しているが
    // 本来はUserId(識別子)だけを持つ方がいいだろう
    // 集約のサイズが小さくなる。またメモリ消費量を抑えられる
    private List<User> members;
    private const int MaxMembers = 30;

    public Circle(User owner)
    {
        Id = Guid.NewGuid();
        Owner = owner;
        members = new List<User>();
    }

    public void Join(User user)
    {
        if (IsFull())
            throw new InvalidOperationException("Cannot join: Circle is full.");

        if (members.Any(m => m.Id == user.Id) || user.Id == Owner.Id)
            throw new InvalidOperationException("User is already a member.");

        members.Add(user);
    }

    public void Leave(User user)
    {
        if (user.Id == Owner.Id)
            throw new InvalidOperationException("Owner cannot leave.");

        if (!members.Remove(user))
            throw new InvalidOperationException("User not a member.");
    }

    // オーナーを含むサークルの総人数を計算する。
    private int CountMember() => members.Count + 1;
    private bool IsFull() => CountMember() >= MaxMembers;
}


public class Program
{
    public static void Main()
    {
        var owner = new User("Alice");
        var circle = new Circle(owner);
        var user1 = new User("Bob");
        var user2 = new User("Charlie");

        circle.Join(user1);
        circle.Join(user2);
        // 集約の外部から境界内部のオブジェクトへの直接の操作はしてはいけません。
        // circle.members.add(user1);
        // circle.members.add(user2);

        circle.Leave(owner);

        /*
            UserとCircleは異なる集約に属しているため、Userに対する操作はUser集約を通じて行う必要があります。
            例えば、Circleから直接Userの名前を変更するのではなく、User自身のメソッドを使用します。

            // 不適切な例: circle.changeMemberName("Mary");
            // 適切な例:
            user1.ChangeName("Mary");
        */
        user1.ChangeName("Mary");
    }
}
```

##### 集約の分け方

集約はとトランザクション整合性の境界と同義のようです。

トランザクション整合性を保つために設計された境界です。
この境界内のエンティティやオブジェクトは、一つのトランザクション内で一貫性を持って処理されるべき最小の項目として定義すべきです。

サンプルコードにおいて、`Circle`クラスは`User`オブジェクトのリストをメンバーとして保持していますが、
これは集約の設計として最適ではない場合があります。
理想的には、`Circle`は`User`の詳細を直接持つのではなく、
必要なのはユーザーを識別するための`UserId`のみです。
これにより、`Circle`集約のサイズを小さく保つことができ、
メモリ消費量も抑えることが可能になります。
各`User`への参照はその識別子を通じて行うべきで、
これによって集約間の疎結合が保たれ、システム全体の拡張性とメンテナンス性が向上します。

##### 結果整合性について

集約が大きくなると、トランザクションも大規模になり、それに伴ってパフォーマンスの問題や複雑さが増すことがあります。
これを解決する一つの方法として「結果整合性」があります。結果整合性とは、データの一貫性が即座にではなく、
最終的には保証されることを意味します。
つまり、システムの各部分が一時的には非整合状態にあることを許容し、
時間が経過するにつれて整合性が保証される状態に収束することを許します。

#### 仕様

##### 性質

- **Entity のバリデーション**
  - 個々の属性がそれぞれ妥当であっても、Entity 全体として必ずしも妥当な状態であるとは限りません。この全体的な妥当性を評価するために仕様は重要な役割を果たします。

##### 契約プログラミングとドメインモデルのバリデーション

####### 契約プログラミングの原則

呼び出しもとは特定の義務を果たす必要があり、対価として、呼び出したコードは目的の値を返すべきです。

- **条件**
  - **事前条件**: システムのあるべき状態や、コードに提供されるべき入力など、コードを呼び出す前に満たされるべき条件です。
  - **事後条件**: システムの新しい状態や、返されるべき特定の値など、コードを呼び出した後に保証されるべき条件です。
  - **不変条件**: コードの呼び出し前後で比較した際に、変わるべきでない条件です。

**事前条件**は、Value Object や Entity のインスタンス生成時に重要です。これにより、インスタンスが正しい状態で作成されることが保証されます。
**事後条件**は、Entity の操作後の状態を保証するために利用されます。
これはしばしば複雑な仕様のロジックとなるため、Specification クラスを実装し、そこでのバリデーションが効果的です。これにより、ドメインモデルの整合性を保つことができます。

ウェブアプリケーションなどでは、プレゼンテーション層で事前条件を満たすように validation を行うことが効果的になるでしょう。

#### サンプルコード

```csharp

public interface ISpecification<T>
{
    bool IsSatisfiedBy(T entity);
}

public class AgeSpecification : ISpecification<User>
{
    private readonly int _minimumAge;

    public AgeSpecification(int minimumAge)
    {
        _minimumAge = minimumAge;
    }

    public bool IsSatisfiedBy(User user)
    {
        return user.Age >= _minimumAge;
    }
}

public class User
{
    public int Age { get; set; }
}

public class Program
{
    public static void Main(string[] args)
    {
        User user = new User { Age = 25 };
        ISpecification<User> ageSpecification = new AgeSpecification(18);

        bool isEligible = ageSpecification.IsSatisfiedBy(user);

        Console.WriteLine($"Is the user eligible? {isEligible}");
    }
}

```

```csharp
// domain entity
public class Customer
{
  public Customer(string name)
  {
    this.Name = name;
  }

  string name;

  public string Name
  {
    get { return this.name; }
    set
    {
      if (value == null)
        throw new ArgumentNullException();
      this.name = value;
    }
  }
}

// web view model
public class CustomerViewModel
{
  [Required]
  public string Name { get; set; }

  public Customer ToCustomer()
  {
    return new Customer(this.Name);
  }
}
```

### 参考

- [ドメイン駆動設計入門](https://www.seshop.com/product/detail/20675)
- [Best Practice - An Introduction To Domain-Driven Design](https://learn.microsoft.com/en-us/archive/msdn-magazine/2009/february/best-practice-an-introduction-to-domain-driven-design)
- [VaughnVernon/IDDD_Samples](https://github.com/VaughnVernon/IDDD_Samples)
- [ドメイン モデル レイヤーでの検証を設計する](https://learn.microsoft.com/ja-jp/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/domain-model-layer-validations)
