---
title: "Node.jsとTypeScriptのプロジェクト構築: 本と作者の管理プロジェクトの依存関係と設定の解説"
date: 2023-10-23T06:45:00
weight: 4
categories:
  - javascript
  - nodejs
  - typescript
description: "Node.jsとTypeScriptを使用した本と作者の管理プロジェクトの依存関係、設定、データモデルについて解説。開発環境から本番環境へのデプロイまでの実践的なガイド。"
tags: 
  - "Node.js"
  - "TypeScript"
  - "Express"
  - "Sequelize"
  - "SQLite"
  - "ORM"
  - "API"
  - "データベース設計"
---

## bookshelf パッケージの依存関係説明

ここで実装した[コード](/tech/article/js-ts-create-webapi-bookshelf/)の説明をします。

#### Dependencies

1. **Express**:
   - Expressは、Node.jsで動作する軽量で柔軟なWebアプリケーションフレームワークです。Expressは、ミドルウェア、ルーティング、およびテンプレートエンジンを提供し、Webおよびモバイルアプリケーションを構築するための強力な基盤を提供します。
1. **Sequelize**:
   - Sequelizeは、Node.js用の強力なORM（Object Relational Mapper）であり、SQLデータベース（PostgreSQL、MySQL、SQLite、およびMSSQLを含む）とのやり取りを容易にします。Sequelizeは、データベーススキーマの定義、データの検索と操作、およびマイグレーションのサポートを提供します。
1. **SQLite3**:
   - SQLiteは、サーバーの設定が不要な軽量のディスクベースのデータベースエンジンです。SQLite3は、SQLiteデータベースの最新バージョンであり、組み込みアプリケーションやプロトタイプ制作に最適です。
1. **TypeScript**:
   - TypeScriptは、JavaScriptのスーパーセットであり、静的型付けとクラスベースのオブジェクト指向プログラミングを提供します。TypeScriptは、大規模なアプリケーションの開発と保守を容易にし、型安全とエディターの支援を提供します。
1. **ts-node**:
   - ts-nodeは、TypeScriptを直接実行し、リアルタイムでコンパイルするためのツールです。ts-nodeは、TypeScriptプロジェクトを簡単にテストおよび実行することを可能にします。
1. **@types/node**:
   - `@types/node`は、Node.jsの型定義ファイルを提供するnpmパッケージです。これにより、TypeScriptプロジェクトでNode.jsのAPIを型安全な方法で使用することができます。
1. **@types/express**:
   - `@types/express`は、Expressフレームワークの型定義ファイルを提供するnpmパッケージです。これにより、TypeScriptプロジェクトでExpressのAPIを型安全な方法で使用することができます。
1. **dotenv**:
   - `dotenv`は、アプリケーションの設定を`.env`ファイルから簡単に読み込むためのツールです。このツールを使用することで、データベースの接続情報やAPIキーなどの機密情報をソースコードから分離し、安全に管理することができます。
1. **express-validator**:
   - `express-validator`は、Expressアプリケーションで受け取ったリクエストのデータを検証・整形するためのミドルウェアです。例えば、ユーザー登録フォームからの入力値が正しいフォーマットであるかチェックする際などに役立ちます。

#### tsconfig.json

この`tsconfig.json`([とは](https://runebook.dev/ja/docs/typescript/tsconfig-json))ファイルは、プロジェクトのコンパイルに必要なルート ファイルと[コンパイラ オプション](https://www.typescriptlang.org/ja/tsconfig)を指定します。

1. **`compilerOptions`**:
   - TypeScriptコンパイラのオプションを設定するオブジェクトです。
1. **`target`** (`"ES2022"`):
   - コンパイルされたJavaScriptのターゲットとなるECMAScriptバージョンを指定します。`"ES2022"`は、ECMAScript 2022の機能をターゲットとすることを意味します。
1. **`module`** (`"commonjs"`):
   - 出力ファイルで使用されるモジュールシステムを指定します。`"commonjs"`は、Node.jsで一般的に使用されるモジュールシステムです。
   - commonjs
     - **独立したモジュール**: CommonJSでは、各ファイルは独立したモジュールとして扱われます。
     - **デフォルトのアクセス制限**: モジュール内で定義された関数や変数は、デフォルトで他のモジュールからアクセスできないようになっています。
     - **エクスポートとインポート**: `exports`オブジェクトを使用して関数や変数をエクスポートし、`require`関数を使用して他のモジュールをインポートします。
1. **`outDir`** (`"./dist"`):
   - コンパイルされたJavaScriptファイルを出力するディレクトリを指定します。この例では、`./dist`ディレクトリにファイルが出力されます。
1. **`rootDir`** (`"./src"`):
   - TypeScriptファイルのルートディレクトリを指定します。この例では、`./src`ディレクトリがルートとして設定されています。
1. **`strict`** (`true`):
   - 厳密な型チェックを有効にするかどうかを指定します。`true`に設定すると、より厳密な型チェックが行われ、型関連のエラーをより簡単に検出できます。
1. **`esModuleInterop`** (`true`):
   - ECMAScriptモジュールとの相互運用性を改善するためのフラグです。これは、`import`文を使用してCommonJSモジュールをインポートするときに便利です。これにより、デフォルトのインポート形式が必要なくなります。
1. **`noImplicitAny`** (`true`):
  `noImplicitAny`オプションは、TypeScriptの型チェックに関連する設定です。このオプションを`true`に設定すると、型注釈が明示的に提供されていない変数、パラメータ、または関数の戻り値に対して、TypeScriptコンパイラは`any`型を暗黙的に割り当てることを許可せず、エラーをスローします。

**参考リンク**:

- [ECMAScriptの最新版 公式サイト](https://www.ecma-international.org/)
- [わかりやすいECMAScriptの解説](https://note.com/takamoso/n/ndac801520eaf)

#### データモデルの定義

Modelクラスを継承して定義する方法は3つある。

```typescript

BookAttributes {
    id?: number;
    title: string;
    authorId: number;
}

// ジェネリック型のみを使用
class Book extends Model<BookAttributes> {}
// ジェネリック型とプロパティの宣言を併用
class Book extends Model<BookAttributes> implements BookAttributes {
    public id!: number;
    public title!: string;
    public authorId!: number;
}
// ジェネリック型を使用せずにプロパティのみを宣言
class Book extends Model {
    public id!: number;
    public title!: string;
    public authorId!: number;
}
```

1. ジェネリック型のみを使用

   *メリット:*
      - シンプル: モデル定義がコンパクトであり、読みやすい。
      - 型の基本的なサポート: BookAttributes を使用して、基本的な型のサポートが提供される

   *デメリット:*
      - 直接アクセス時の不確実性:

        ```typescript
        const book = new Book();
        book.title = "Sample Title"; // TypeScriptエラーが発生する可能性
        ```

1. ジェネリック型とプロパティの宣言を併用

   *メリット:*
      - 明確な型のサポート: プロパティの明示的な宣言により、型の安全性が向上。
      - エディタのサポート: 型のヒントやコード補完が向上する。
      - コードの可読性: モデルの属性が明確に定義されており、可読性が高まる。

   *デメリット:*
      - 冗長性: モデルの属性を2回（インターフェースとクラス内で）定義する必要がある。
1. ジェネリック型を使用せずにプロパティのみを宣言

   *メリット:*
      - 直接アクセスのサポート: インスタンスのプロパティに直接アクセスする際のサポート。

        ```typescript
        const book = new Book();
        book.title = "Sample Title"; // 問題なく動作
        ```

   *デメリット:*
      - 型の不完全性: ジェネリック型が不在であるため、モデルに関連するメソッドや他のプロパティの型推論が不完全。
      - コードの不一致: データベースの変更や他のコードとの不一致が生じた際、この不整合を検出するのが難しくなる。

#### middleware

1. errorHandler:
   1. このミドルウェアは、サーバー上でエラーが発生した場合のハンドリングを行います。エラーオブジェクトが存在すれば、そのエラーのメッセージをレスポンスとして返します。エラーオブジェクトが存在しない場合は、一般的なエラーメッセージを返します。
   2. 使い方:

        ```typescript
        // app.ts
        app.use(errorHandler);
        ```

2. asyncHandler
   1. このミドルウェアは非同期のルートハンドラやコントローラ関数で発生するエラーをキャッチし、次のミドルウェア（通常はエラーハンドリングのミドルウェア）に渡します。非同期関数内でのエラーは通常のtry-catchで取得することが難しいため、このミドルウェアはそのギャップを埋めます。
   2. 使い方

      ```typescript
        // authorRoutes.ts
        router.get('/', asyncHandler(authorController.getAllAuthors));
      ```

3. express.json():
   1. Expressの組み込みミドルウェアで、クライアントからのJSON形式のリクエストボディをJavaScriptのオブジェクトとしてパースします。
   2. 使い方

      ```typescript
        // app.ts
        app.use(express.json());
      ```  

4. validateCreateAuthor
   1. `author` の作成時にデータのバリデーションを行います。このミドルウェアは`express-validator`を使用していると思われます。
   2. 2. 使い方

      ```typescript
        // authorRoutes.ts
        router.post('/', validateCreateAuthor, asyncHandler(authorController.createAuthor));

        // authorController.ts
        export const validateCreateAuthor = [
            body('name').isString().notEmpty().withMessage('Name is required'),
        ];
      ```

#### データモデルの定義データベースの接続設定

1. Sequelizeのインポート:
   1. Sequelizeライブラリから`Sequelize`クラスをインポートしています。このクラスはデータベース接続やモデルの定義、データのクエリなどの操作を行うための主要なクラスです。

    ```typescript
      import { Sequelize } from 'sequelize';
    ```

2. データベースの接続設定:
   1. ここで新しいSequelizeインスタンスを作成しています。このインスタンスは、特定のデータベース設定（この場合はSQLite）を使用してデータベースへの接続を行います。

      ```typescript
      export const sequelize = new Sequelize({
        dialect: 'sqlite',
        storage: './database.sqlite'
      });
      ```

      ※1 他のDB接続方法は[ドキュメント](https://sequelize.org/docs/v6/getting-started/##connecting-to-a-database)見てください。
      ※2 Sequelizeクラスの[Constructors](https://sequelize.org/api/v6/class/src/sequelize.js~sequelize##instance-constructor-constructor)
   2. 使用方法:
       - このように、database.tsはアプリケーション全体で一貫したデータベース接続を提供する基盤として機能します。

          ```typescript
          import { Model, DataTypes } from 'sequelize';
          import { sequelize } from './database.ts';

          class User extends Model {}
          User.init({
            username: DataTypes.STRING,
            password: DataTypes.STRING,
          }, {
            sequelize,
            modelName: 'user'
          });
          ```

#### 環境変数

   1. `app.ts`:
       - `dotenvはNode.js`で環境変数を操作するための便利なnpmパッケージです。`dotenv.config()`を呼び出すと、`.env`ファイルから環境変数を読み込み、それをprocess.envに追加します。

        ```typescript
        dotenv.config();
        ```

   1. `environment.ts`:
       - `isProduction`はヘルパー関数で、現在の環境が本番環境（`production`）かどうかを確認します。この関数は、`process.env.NODE_ENV`の値が`production`と等しい場合に`true`を返します。

        ```typescript
        export function isProduction(): boolean {
            return process.env.NODE_ENV === 'production';
        }
        ```

   1. `.env`:
       - `.env`ファイルは、環境変数を定義するためのファイルです。このファイル内で設定された変数は、`dotenv.config()`が呼び出されると、`process.env`に追加されます。
       - ここでは、`NODE_ENV`変数が`develop`として設定されています。このため、上記の`isProduction`関数は`false`を返します。

        ```typescript
        NODE_ENV=develop
        ```

#### サーバの起動

**説明**:

- `isProduction()`関数によって現在の環境が本番環境かどうかを確認しています。
- 本番環境の場合、アプリケーションはポート3000で直接起動します。
- 本番環境以外の場合（例: 開発環境）、Sequelizeを使ってデータベースとの同期を行った後にサーバを起動します。コメントアウトされている部分はテーブルの再作成オプション（`force: true`）を示していますが、このオプションは現在は使用されていません。代わりに`alter: true`オプションが使われており、これによってデータベースのテーブルの現在の状態を確認し、必要な変更を適用することができます。

```javascript
if (isProduction()) {
    app.listen(3000, () => {
        console.log('Server is running on port 3000');
    });
} else {
    /*
    sequelize.sync({ force: true }).then(() => {
        // テーブルを作成し、既に存在する場合は最初に削除します
        app.listen(3000, () => {
            console.log('Server is running on port 3000');
        });
    });
    */
    // または

    sequelize.sync({ alter: true }).then(() => {
        // データベース内のテーブルの現在の状態を確認し、必要な変更を適用します
        app.listen(3000, () => {
            console.log('Server is running on port 3000');
        });
    });
}
```

#### sequelize.sync()

`sequelize.sync()`はSequelizeを使用したNode.jsアプリケーションで、モデル定義とデータベースのスキーマとの間の同期をとるためのメソッドです。この同期は以下のような動作を含むことがあります：

- テーブルの作成
- テーブル構造の変更
- テーブルの削除

以下が、sequelize.sync()を本番環境で使用しない主な理由です：

1. 安全性：sequelize.sync({ force: true })のようにforceオプションをtrueにすると、既存のテーブルが削除され、新しくテーブルが作成されます。これは、本番環境のデータを完全に失うリスクがあります。
