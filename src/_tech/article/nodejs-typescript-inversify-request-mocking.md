---

title: "Inversifyを使ったユニットテスト: Requestのモック作成"
date: 2024-4-1T13:04:00
weight: 4
categories:
  - javascript
  - nodejs
  - typescript

---

# InversifyでRequestをモックする

## 概要

`inversify-express-utils`を使ったテストで直面するかもしれない一つの課題、すなわち`BaseHttpController`からHTTPリクエスト情報を取得する際にアクセスできないプロパティをモックする方法について説明します。

## 解決策

`Object.defineProperty`を使用すると、オブジェクトに新しいプロパティを安全に追加したり、
既存のプロパティを変更することができます。
この方法を利用して`httpContext`プロパティをモックに置き換えることで、テスト中に任意のHTTPリクエストとレスポンスをシミュレートできます。

## 実践

実際のテストケースでは、まず`jest-mock-extended`を使用して`express.Request`と`express.Response`のモックを作成します。
次に、これらのモックを用いて`HttpContext`を構成し、`Object.defineProperty`を使ってテスト対象のコントローラの`httpContext`を上書きします。

<detail>
<summary>TokenController.test.ts</summary>

```typescript
import {mockDeep, mockReset} from 'jest-mock-extended';
import * as express from 'express';
import {HttpContext} from 'inversify-express-utils';

describe('TokenController', () => {
  const requestMock = mockDeep<express.Request>();
  const responseMock = mockDeep<express.Response>();
  let mockHttpContext: HttpContext;
  let userInformationController: TokenController;

  beforeEach(() => {
    [
      requestMock,
      responseMock,
    ].forEach(mockReset);

    mockHttpContext = mockDeep<HttpContext>({
      request: requestMock,
      response: responseMock,
    });

    Object.defineProperty(TokenController, 'httpContext', {
      value: mockHttpContext,
    });
  });

  it('should return enriched user information on success', async () => {
    // Arrange
    requestMock.headers.authorization = 'Bearer testToken';

    // Act
    const result = await TokenController.get();

    // Assert
    const responseMessage = await result.executeAsync();
    expect(responseMessage.statusCode).toEqual(200);

    const content = await responseMessage.content.readAsStringAsync();
    expect(JSON.parse(content)).toEqual('testToken');
  });
});

```

</detail>

<detail>
<summary>TokenController.ts</summary>

```typescript
import {inject} from 'inversify';
import express from 'express';
import {controller, httpGet} from 'inversify-express-utils';
import {BaseHttpController} from 'inversify-express-utils';

@controller('/api')
export class TokenController extends BaseHttpController {

  @httpGet('/token')
  public async get() {
    const token = this.getToken(this.httpContext.request);
    if (!token) {
      logger?.warn('Authorization token is missing in the request header.');
      return this.statusCode(401);
    }  
    return this.json(token, 200);
  }

  private getToken(req: express.Request): string | undefined | null {
    const authorizationHeader = req.headers['authorization'];
    if (!authorizationHeader) return undefined;
    const tokenArray = authorizationHeader.split('Bearer ');
    if (tokenArray.length === 2) {
      return tokenArray[1].trim();
    }
    return null;
  }
}

```

</detail>

<detail>
<summary>package.json</summary>

```json
{
  "name": "myapp",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "jest",
    "start": "node build/index.js",
    "lint": "gts lint",
    "clean": "gts clean",
    "compile": "tsc",
    "fix": "gts fix",
    "prepare": "npm run compile",
    "pretest": "npm run compile",
    "posttest": "npm run lint"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "engines": {
    "node": "20.x"
  },
  "devDependencies": {
    "@types/config": "^3.3.4",
    "@types/express": "^4.17.21",
    "@types/jest": "^29.5.12",
    "@types/node": "20.8.2",
    "@types/prettyjson": "^0.0.33",
    "@types/uuid": "^9.0.8",
    "gts": "^5.2.0",
    "jest": "^29.7.0",
    "jest-mock-extended": "^3.0.5",
    "nodemon": "^3.1.0",
    "ts-jest": "^29.1.2",
    "typescript": "~5.1.6"
  },
  "dependencies": {
    "axios": "^1.6.7",
    "config": "^3.3.11",
    "dayjs": "^1.11.10",
    "express": "^4.19.2",
    "inversify": "^6.0.2",
    "inversify-express-utils": "^6.4.6",
    "jose": "^5.2.3",
    "mysql2": "^3.9.2",
    "prettyjson": "^1.2.5",
    "redis": "^4.6.13",
    "reflect-metadata": "^0.2.1",
    "uuid": "^9.0.1"
  }
}


```

</detail>
