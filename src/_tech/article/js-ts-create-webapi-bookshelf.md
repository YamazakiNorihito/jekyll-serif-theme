---
title: "Node.js と TypeScript での WebAPI の構築: 本と作者の管理"
date: 2023-10-21T23:23:00
weight: 4
categories:
  - javascript
  - nodejs
  - typescript
---

この記事では、TypeScript を使用して Node.js の WebAPI を作成する手順を学びます。
具体的には、本とその著者を管理するシンプルな WebAPI の開発を通して、
プロジェクトのセットアップからデータモデルの定義、ルーティング、
コントローラの設定までの詳細な手順を網羅します。Sequelize と SQLite を
データベースとして使用し、モデル間のリレーションシップも考慮に入れた実践的なガイドです。
(１つ１つのコード説明は[別ページ](/tech/article/js-ts-create-webapi-bookshelf-explanation/)でしています。)

### API仕様
## API 仕様書

### 1. すべての著者を取得
- **URL**: `/authors`
- **メソッド**: `GET`
- **成功時のレスポンスコード**: `200`
- **レスポンス**: 著者のリスト

---

### 2. 著者の作成
- **URL**: `/authors`
- **メソッド**: `POST`
- **リクエストボディ**: 

```json
{
   "name":"著者の名前"
}
```
- **バリデーション**: 
- `name`: 文字列、空ではない
- **成功時のレスポンス**:
- コード: `201`
- メッセージ: '著者が正常に作成されました'
- **エラーレスポンス**:
- コード: `400`
- メッセージ: 'エラー'

---

### 3. 著者による書籍の取得
- **URL**: `/authors/:authorId/books`
- **メソッド**: `GET`
- **URLパラメータ**:
- `authorId`: 著者のID
- **成功時のレスポンスコード**: `200`
- **レスポンス**: 指定された著者によって書かれた書籍のリスト

---

### 4. 書籍のバリデーションと作成
- **URL**: `/books`
- **メソッド**: `POST`
- **リクエストボディ**:

```json
{
   "title":"書籍のタイトル",
   "authorId":"著者のID"
}
```

- **バリデーション**: 
- `title`: 文字列、空ではない
- `authorId`: 整数、既存の著者に対応
- **成功時のレスポンス**:
- コード: `201`
- メッセージ: '書籍が正常に作成されました'
- **エラーレスポンス**:
- コード: `400`
- メッセージ: 'エラー'

---

### 5. すべての書籍を取得
- **URL**: `/books`
- **メソッド**: `GET`
- **成功時のレスポンスコード**: `200`
- **レスポンス**: 書籍のリスト

---

### 6. その著者とともに書籍を取得
- **URL**: `/books-authors`
- **メソッド**: `GET`
- **成功時のレスポンスコード**: `200`
- **レスポンス**: 著者とともに書籍のリスト

---

### 7. APIレスポンスの構造

#### a. 成功時のレスポンス
- **フィールド**:
- `data`: レスポンスデータ
- `message`: レスポンスメッセージ
- `status`: HTTPステータスコード

#### b. エラーレスポンス
- **フィールド**:
- `errors`: エラーオブジェクトの配列
- `message`: レスポンスメッセージ
- `status`: HTTPステータスコード


## 新しいNode.jsプロジェクトの作成:
```bash

mkdir bookshelf
cd bookshelf
npm init -y

# 依存関係のインストール:
npm install express express-validator sequelize sqlite3 ts-node typescript dotenv @types/express @types/node

```

## TypeScriptの設定:
tsconfig.json ファイルをプロジェクトルートに作成し、以下の内容をコピーして貼り付けます。
```typescript
{
    "compilerOptions": {
      "target": "ES2022",
      "module": "commonjs",
      "outDir": "./dist",
      "rootDir": "./src",
      "strict": true,
      "esModuleInterop": true,
      "noImplicitAny" : true
    }
} 
```

## データモデルの定義

1. Sequelizeインスタンスの設定:
   - src/database.ts  ファイルを作成します。
      ```typescript
      import { Sequelize } from 'sequelize';

      export const sequelize = new Sequelize({
        dialect: 'sqlite',
        storage: './database.sqlite'
      });

      ```
1. モデルの作成:
   - src/models/Author.ts
      ```typescript
      import { DataTypes, Model } from "sequelize";
      import { sequelize } from "../database";

      interface AuthorAttributes {
        id?: number;
        name: string;
      }

      class Author extends Model<AuthorAttributes> implements AuthorAttributes {
        public id!: number;
        public name!: string;
      }

      Author.init({
        name: {
          type: DataTypes.STRING,
          allowNull: false
        }
      }, { sequelize, modelName: 'Author' });
      export default Author;
      ```
   - src/models/Book.ts
      ```typescript
      import { DataTypes, Model } from "sequelize";
      import { sequelize } from "../database";
      import Author from "./Author";

      interface BookAttributes {
        id?: number;
        title: string;
        authorId: number;
      }

      class Book extends Model<BookAttributes> implements BookAttributes {
        public id!: number;
        public title!: string;
        public authorId!: number;
      }

      Book.init({
        title: {
          type: DataTypes.STRING,
          allowNull: false
        },
        authorId: {
          type: DataTypes.INTEGER,
          references: {
            model: Author,
            key: 'id'
          }
        }
      }, { sequelize, modelName: 'Book' });

      Author.hasMany(Book, {
        foreignKey: 'authorId'
      });

      Book.belongsTo(Author, {
        foreignKey: 'authorId',
        onDelete: 'CASCADE'
      });

      export default Book;
      ```
2. ルーティングとコントローラの設定:
- コントローラの作成
   - src/controllers/apiResponse.ts
      ```typescript
      import { Response } from 'express';

      interface SuccessResponse<T> {
          data: T;
          message: string;
          status: number;
      }

      interface ErrorObject {
          field: string;
          message: string;
      }

      interface ErrorResponse {
          errors: ErrorObject[];
          message: string;
          status: number;
      }

      export const sendSuccessResponse = <T>(res: Response, data: T, message: string = 'Success', statusCode: number = 200): void => {
          const apiResponse: SuccessResponse<T> = {
              data,
              message,
              status: statusCode,
          };
          res.status(statusCode).json(apiResponse);
      };

      export const sendErrorResponse = (
          res: Response,
          errors: any,
          message: string = 'Error',
          statusCode: number = 400
      ): void => {
          const errorResponse: ErrorResponse = {
              errors: errors.array().map((error: any) => ({
                  field: error.path,
                  message: error.msg,
              })),
              message,
              status: statusCode,
          };
          res.status(statusCode).json(errorResponse);
      };

      ```
   - src/controllers/authorController.ts
      ```typescript
      import { Request, Response } from 'express';
      import { body, validationResult } from 'express-validator';
      import { sendSuccessResponse, sendErrorResponse } from './apiResponse';
      import Author from '../models/Author';
      import Book from '../models/Book';

      export const getAllAuthors = async (req: Request, res: Response) => {
          const authors = await Author.findAll();
          sendSuccessResponse(res, authors);
      };

      export const validateCreateAuthor = [
          body('name').isString().notEmpty().withMessage('Name is required'),
      ];
      export const createAuthor = async (req: Request, res: Response) => {
          const errors = validationResult(req);

          if (!errors.isEmpty()) {
              console.log(errors);
              return sendErrorResponse(res, errors);
          }
          const author = await Author.create(req.body);
          sendSuccessResponse(res, author, 'Author created successfully', 201);
      };

      export const getBooksByAuthor = async (req: Request, res: Response) => {
          const authorId = req.params.authorId;
          const authorWithBooks = await Author.findOne({
              where: { id: authorId },
              include: [{ model: Book }],
          });
          sendSuccessResponse(res, authorWithBooks);
      };

      ```
   - src/controllers/bookController.ts
      ```typescript
      import { Request, Response } from 'express';
      import { body, validationResult } from 'express-validator';
      import Book from "../models/Book";
      import Author from '../models/Author';
      import { sendErrorResponse, sendSuccessResponse } from './apiResponse';

      export const validateCreateBook = [
        body('title').isString().notEmpty().withMessage('Title is required'),
        body('authorId').isInt().withMessage('Author ID must be an integer')
          .custom(async (value) => {
            const author = await Author.findByPk(value);
            if (!author) {
              throw new Error('Author does not exist'); // エラーメッセージを指定
            }
            return true;
          }),
      ];

      export const createBook = async (req: Request, res: Response) => {
        const errors = validationResult(req);

        if (!errors.isEmpty()) {
          return sendErrorResponse(res, errors);
        }

        const book = await Book.create(req.body);
        sendSuccessResponse(res, book, 'Book created successfully', 201);
      };

      export const getAllBooks = async (req: Request, res: Response) => {
        const books = await Book.findAll();
        sendSuccessResponse(res, books);
      };

      export const getBooksAndAuthors = async (req: Request, res: Response) => {
        const booksWithAuthors = await Book.findAll({
          include: [{ model: Author, as: 'Author' }]
        });
        sendSuccessResponse(res, booksWithAuthors);
      };

      ```

- middlewareの作成
   - src/middleware/asyncHandler.ts
      ```typescript
      import { Request, Response, NextFunction } from 'express';

      export const asyncHandler = (fn: (req: Request, res: Response, next: NextFunction) => Promise<void>) =>
        (req: Request, res: Response, next: NextFunction) => {
          Promise.resolve(fn(req, res, next)).catch(next);
        };

      ```
   - src/middleware/errorHandler.ts
      ```typescript
      import { NextFunction, Request, Response } from 'express';

      export const errorHandler = (error: Error, req: Request, res: Response, next: NextFunction) => {
        if (error instanceof Error) {
          res.status(500).json({
            error: {
              message: error.message,
            }
          });
        } else {
          res.status(500).json({
            error: {
              message: 'An unknown error occurred',
            }
          });
        }
      };

      ```
- ルーティングの設定
   - src/routes/authorRoutes.ts
      ```typescript
      import express from 'express';
      import * as authorController from '../controllers/authorController';
      import { asyncHandler } from '../middleware/asyncHandler';
      import { body, validationResult } from 'express-validator';
      import { validateCreateAuthor } from '../controllers/authorController';

      const router = express.Router();

      router.get('/', asyncHandler(authorController.getAllAuthors));
      router.post('/', validateCreateAuthor, asyncHandler(authorController.createAuthor));
      router.get('/:authorId/books', asyncHandler(authorController.getBooksByAuthor));

      export default router;

      ```
   - src/routes/bookRoutes.ts
      ```typescript
      import express from 'express';
      import * as bookController from '../controllers/bookController';
      import { asyncHandler } from '../middleware/asyncHandler';
      import { validateCreateBook } from '../controllers/bookController';

      const router = express.Router();

      router.get('/', asyncHandler(bookController.getAllBooks));
      router.post('/', validateCreateBook, asyncHandler(bookController.createBook));
      router.get('/authors', asyncHandler(bookController.getBooksAndAuthors));

      export default router;

      ```
- Express アプリケーションのセットアップ
   - src/app.ts
      ```typescript
      import express from 'express';
      import authorRoutes from './routes/authorRoutes';
      import bookRoutes from './routes/bookRoutes';
      import { sequelize } from './database';
      import { isProduction } from './environment';
      import dotenv from 'dotenv';
      import { errorHandler } from './middleware/errorHandler';

      dotenv.config();

      const app = express();

      app.use(express.json());
      app.use('/authors', authorRoutes);
      app.use('/books', bookRoutes);

      app.use(errorHandler);

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

      export default app;

      ```
   - src/environment.ts
      ```typescript
      export function isProduction(): boolean {
          return process.env.NODE_ENV === 'production';
      }
      ```