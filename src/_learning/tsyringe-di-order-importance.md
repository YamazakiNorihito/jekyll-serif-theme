---
title: "TypeScriptとmicrosoft/tsyringeを用いた依存注入の順序の重要性"
date: 2023-10-28T20:47:00
weight: 7
---


TypeScriptでWebアプリを使っていて、DI (Dependency injection)が
必要だったので、[`microsoft/tsyringe`](https://github.com/microsoft/tsyringe)を使った見たのだが、
どうも依存注入の順番がすごく大事らしい。


依存注入される`controllers/freee.ts`よりも先に`services/freeeHrService.ts`を
ContainerにRegisrしないと実行時に`Error: Cannot inject the dependency "freeeService" at position #0 of "FreeeController" constructor. Reason:`という大エラーになる。



### 依存注入するクラスとされるクラスの実装
```typescript
// controllers/freee.ts
import ejs from 'ejs';
import { Request, Response } from 'express';
import path from 'path';
import { inject, injectable, singleton } from 'tsyringe';
import { FreeeService } from '../services/freeeHrService';

@singleton()
export class FreeeController {
    constructor(@inject(FreeeService) private readonly freeeService: FreeeService) { }

    public async get(req: Request, res: Response): Promise<void> {
        // サービスを利用するロジックを記述します。

        const getValue = this.freeeService.get();
        const indexPath = path.join(__dirname, './../views/freee/index.ejs')
        const renderedBody = await ejs.renderFile(indexPath, { contents: getValue });
        res.render('layout', {
            title: 'Top',
            body: renderedBody
        });
    }
}
```

```typescript
// services/freeeHrService.ts
import { inject, injectable, singleton } from "tsyringe";
import { FreeeHrHttpApiClient, FreeeHttpOAuthClient } from "../httpClients/freeeHttpClient";

@singleton()
export class FreeeService {
    constructor(
        @inject(FreeeHttpOAuthClient) private oauthClient: FreeeHttpOAuthClient,
        @inject(FreeeHrHttpApiClient) private apiClient: FreeeHrHttpApiClient
    ) { }

    public get(): string {
        // Check if both oauthClient and apiClient instances are present
        if (this.oauthClient && this.apiClient) {
            return "Both instances are present";
        }
        return "One or both instances are missing";
    }
}
```


### エラーが発生するDI設定

```typescript
// routes/index.ts
import 'reflect-metadata';
import { container } from 'tsyringe';
import express from 'express';
import { asyncHandler } from '../middlewares/asyncHandler';
import { FreeeHttpOAuthClient } from '../httpClients/freeeHttpClient';
import { TopController } from '../controllers/top';
import { FreeeController } from '../controllers/freee';

// controller
const router = express.Router();

const topController = container.resolve(TopController);
const freeeController = container.resolve(FreeeController);

router.get('/', asyncHandler((req, res) => topController.get(req, res)));
router.get('/freee', asyncHandler((req, res) => freeeController.get(req, res)));

// services
container.register<FreeeHttpOAuthClient>(FreeeHttpOAuthClient, { useValue: new FreeeHttpOAuthClient("YourClientId", "YourClientSecret") });


export default router;
```

エラーメッセージ
```typescript
node_modules/tsyringe/dist/cjs/dependency-container.js:297
        })();
          ^
Error: Cannot inject the dependency "freeeService" at position #0 of "FreeeController" constructor. Reason:
    Cannot inject the dependency "oauthClient" at position #0 of "FreeeService" constructor. Reason:
        Cannot inject the dependency "clientId" at position #0 of "FreeeHttpOAuthClient" constructor. Reason:
            TypeInfo not known for "String"
```

原因は、servicesがcontroller後に書かれているからダメらしい
msドキュメントに[書いて](https://github.com/microsoft/tsyringe#register)あった。。

> You can also mark up any class with the @registry() decorator to have the given providers registered upon importing the marked up class. @registry() takes an array of providers like so:

これを実現する通常の方法は、*最初の装飾クラスがインスタンス化される前に*、プログラムのどこかにDependencyContainer.register()ステートメントを追加することです。
<br>~~→んなもん、文章から読み解けるかこっちはIQ３０やぞ、約２時間くらい悩んだわ~~

### 正しいDI

```typescript
import 'reflect-metadata';
import { container } from 'tsyringe';
import express from 'express';
import { asyncHandler } from '../middlewares/asyncHandler';
import { FreeeHttpOAuthClient } from '../httpClients/freeeHttpClient';
import { TopController } from '../controllers/top';
import { FreeeController } from '../controllers/freee';


// services
container.register<FreeeHttpOAuthClient>(FreeeHttpOAuthClient, { useValue: new FreeeHttpOAuthClient("YourClientId", "YourClientSecret") });


// controller
const router = express.Router();

const topController = container.resolve(TopController);
const freeeController = container.resolve(FreeeController);

router.get('/', asyncHandler((req, res) => topController.get(req, res)));
router.get('/freee', asyncHandler((req, res) => freeeController.get(req, res)));


export default router;
```