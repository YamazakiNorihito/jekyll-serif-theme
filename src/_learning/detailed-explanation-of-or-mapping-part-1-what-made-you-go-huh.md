---
title: "O/R Mapping In Detail読んで「ん？」と思ったところ解説（１）"
date: 2023-10-20T04:42:00
#image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: "O/R Mapping 基本概念の解説"
linkedinurl: ""
weight: 7
tags:
  - O/R Mapping
  - データベース設計
  - オブジェクト指向
  - リレーショナルデータベース
  - Entity Framework
  - Sequelize
  - Shadow Information
  - プロパティマッピング
description: "O/R Mapping の基本概念を解説。Mapping の定義や Property、Relationship mapping、Shadow information を整理し、オブジェクト指向とリレーショナルデータベース間のギャップを埋める手法を具体例とともに紹介します。"
---
[Mapping Objects to Relational Databases: O/R Mapping In Detail](http://agiledata.org/essays/mappingObjects.html)　を読んでいて
意味わからんぷーとなったところ自分なりの理解をまとめる。
まずは`1. Basic Concepts`に焦点を当てる。

>Mapping (v). （動詞形）

オブジェクトやその関連性をデータベースにどのように保存するかの具体的な定義や構造

（例）
新しく`Book`というオブジェクトを作成しました。この`Book`オブジェクトには`title`、`author`、`publishedDate`などのプロパティがあります。
次のステップは、この`Book`オブジェクトをRelational DataBaseに保存する方法を決定することです。

1. まず、Bookオブジェクトをどのテーブルに保存するかを決定します。この場合、新しくbooksテーブルを作成することを決定しました。
2. 次に、Bookオブジェクトの各プロパティがbooksテーブルのどの列に対応するかを決定します。例えば、titleはtitle列、authorはauthor_name列、publishedDateはpublished_date列にマップすることを決定しました。
3. さらに、特定のプロパティ（例えば、publishedDate）に制約やフォーマットが必要な場合、その詳細も決定します。この場合、publishedDateは日付形式で保存することを決定しました。
4. すべてのマッピングの決定が完了したら、実際にデータベーススキーマやORM（Object-Relational Mapping）ツールを使用してマッピングを実装します。

この１つ１つの行為がMapping (v)にあたります。

>Mapping (n). （名詞形）

Mapping (v)の結果やプロセスを終えた後に得られる「オブジェクトのプロパティや関連性がデータベースにどのように保存されるかの具体的な定義」を意味

（例）
`Book`と`Author`の2つのエンティティがあり、それぞれのエンティティが1対多のリレーションを持つ。つまり、`1人の著者`は`複数の書籍`を持つ。
Entity Framework CoreとSequelize ORMで例を書きます。

```csharp
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;

public class Book
{
    public int BookId { get; set; }
    public string Title { get; set; }
    public int AuthorId { get; set; }
    public Author Author { get; set; }
}

public class Author
{
    public int AuthorId { get; set; }
    public string Name { get; set; }
    public ICollection<Book> Books { get; set; }
}

public class AppDbContext : DbContext
{
    public DbSet<Book> Books { get; set; }
    public DbSet<Author> Authors { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Author>()
            .HasMany(a => a.Books)  // Author has many Books
            .WithOne(b => b.Author) // Each Book has one Author
            .HasForeignKey(b => b.AuthorId); // Set the foreign key on Book
    }
}

```

```javascript
const { Model, DataTypes } = require('sequelize');
const sequelize = new Sequelize('sqlite::memory:');

class Author extends Model {}
Author.init({
    name: {
        type: DataTypes.STRING,
        allowNull: false
    }
}, { sequelize, modelName: 'author' });

class Book extends Model {}
Book.init({
    title: {
        type: DataTypes.STRING,
        allowNull: false
    }
}, { sequelize, modelName: 'book' });

// Relations
Author.hasMany(Book, { foreignKey: 'authorId' });
Book.belongsTo(Author, { foreignKey: 'authorId' });

sequelize.sync();

```

つまりこの設定結果をMapping (n)

>Property.

「オブジェクト内のデータ要素や属性」や「オブジェクトが持つ個々のデータ」

Mapping (n). で決定したBook.BookIdなどがPropertyを指しています。

>Relationship mapping.

エンティティ間の関連性をどのようにデータベースに保存するかの定義や構造を意味する

Mapping (n). で決定した`.HasMany(a => a.Books)`や`.WithOne(b => b.Author)`がRelationship mapping.を指している。

> shadow information
オブジェクトが正常に永続化するために必要な追加の情報

オブジェクト指向プログラミングの中で、オブジェクトはそのビジネスの意味や機能に従って設計されます。
しかし、データベースのような永続化メカニズムでは、
データの一貫性や整合性を保つために追加の情報が必要となることがあります。
この追加の情報がShadow Informationです。

主なShadow Informationの例

1. 主キー (Primary Key): これは、データベース内の各レコードを一意に識別するためのキーです。サロゲートキーとして知られる主キーは、ビジネス上の意味を持たないが、データの識別に必要なキーです。
2. 同時実行制御のマーキング (Concurrency Control Markings): これは、複数のユーザーが同時に同じデータにアクセスした場合に、データの一貫性を維持するためのものです。タイムスタンプやインクリメンタルカウンターがこの例として挙げられます。
3. バージョン番号 (Versioning Numbers): これは、オブジェクトやレコードのバージョンを追跡するためのものです。これにより、変更履歴や更新の追跡が可能となります。
要するに、shadow informationは、オブジェクトとデータベースの間のギャップを埋めるための情報です。
