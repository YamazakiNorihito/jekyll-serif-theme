---
title: "RedisClientをDIする方法"
date: 2023-11-04T08:00:00
weight: 4
categories:
  - javascript
  - nodejs
  - typescript
description: ""
---

RedisClientをDIする方法と呼び出し方を紹介します。

dependency injection containerは[TSyringe](https://github.com/microsoft/tsyringe#tsyringe)を使います。

### Dependency Injection

```typescript
import 'reflect-metadata';
import { container } from 'tsyringe';
import { RedisClientType, createClient } from 'redis';
import dotenv from 'dotenv';

dotenv.config();

const redisClient: RedisClientType = createClient({
    url: process.env.REDIS_URL!
});
redisClient.on('error', err => { throw err });
(async () => {
    await redisClient.connect();
})();
// add singleton
container.registerInstance<RedisClientType>("RedisClient", redisClient);

```

### Resolving Dependencies

```typescript
import { SchemaFieldTypes, RedisClientType } from 'redis';
import { inject, singleton } from "tsyringe";

@singleton()
export class FreeeUserRepository {
    constructor(
        @inject("RedisClient") private readonly redisClient: RedisClientType
    ) {
        (async () => {
            await this.createIndex();
        })();
    }

    public isReady(): boolean {
        return this.redisClient.isReady;
    }

    public async save(userId: string, user: User): Promise<void> {
        const userKey = `freeeuser:${userId}`;
        let userJsonString = JSON.stringify(user);
        const result = await this.redisClient.set(userKey, userJsonString);
    }

    public async get(userId: string): Promise<User | null> {
        const userKey = `freeeuser:${userId}`;
        const userJsonString = await this.redisClient.get(userKey);

        if (!userJsonString) {
            return null;
        }
        return JSON.parse(userJsonString) as User;
    }

    private async createIndex(): Promise<void> {
        try {
            await this.redisClient.ft.create('idx:freeeusers', {
                '$.id': {
                    type: SchemaFieldTypes.NUMERIC,
                    SORTABLE: true
                },
                '$.updated_at': {
                    type: SchemaFieldTypes.NUMERIC,
                    SORTABLE: true
                },
                '$.companies[*].id': {
                    type: SchemaFieldTypes.NUMERIC
                },
                '$.companies[*].name': {
                    type: SchemaFieldTypes.TEXT
                },
                '$.companies[*].role': {
                    type: SchemaFieldTypes.TEXT
                },
                '$.companies[*].external_cid': {
                    type: SchemaFieldTypes.NUMERIC
                },
                '$.companies[*].employee_id': {
                    type: SchemaFieldTypes.NUMERIC
                },
                '$.companies[*].display_name': {
                    type: SchemaFieldTypes.TEXT
                },
                '$.oauth.access_token': {
                    type: SchemaFieldTypes.TEXT
                },
                '$.oauth.token_type': {
                    type: SchemaFieldTypes.TEXT
                },
                '$.oauth.expires_in': {
                    type: SchemaFieldTypes.NUMERIC,
                    SORTABLE: true
                },
                '$.oauth.refresh_token': {
                    type: SchemaFieldTypes.TEXT
                },
                '$.oauth.scope': {
                    type: SchemaFieldTypes.TEXT
                },
                '$.oauth.created_at': {
                    type: SchemaFieldTypes.NUMERIC,
                    SORTABLE: true
                },
                '$.oauth.company_id': {
                    type: SchemaFieldTypes.NUMERIC
                }
            }, {
                ON: 'JSON',
                PREFIX: 'freeeuser:'
            });
        } catch (e: any) {
            if (e.message === 'Index already exists') {
                //console.log('Index exists already, skipped creation.');
            } else {
                throw e;
            }
        }
    }
}

export interface OAuth {
    access_token: string;
    token_type: string;
    expires_in: number;
    refresh_token: string;
    scope: string;
    created_at: number;
    company_id: number;
}

export interface Company {
    id: number;
    name: string;
    role: string;
    external_cid: number;
    employee_id?: number | null;
    display_name?: string | null;
}

export interface User {
    id: number;
    companies: Company[];
    oauth: OAuth;
    updated_at: number;
}

```

### 環境情報

```json
// package.json
{
  "name": "workday",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "start": "ts-node ./src/app.ts",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "@types/express": "^4.17.20",
    "@types/node": "^20.8.9",
    "axios": "^1.6.0",
    "dotenv": "^16.3.1",
    "ejs": "^3.1.9",
    "express": "^4.18.2",
    "express-validator": "^7.0.1",
    "method-override": "^3.0.0",
    "polly-js": "^1.8.3",
    "redis": "^4.6.10",
    "reflect-metadata": "^0.1.13",
    "sequelize": "^6.33.0",
    "sqlite3": "^5.1.6",
    "ts-node": "^10.9.1",
    "tsyringe": "^4.8.0",
    "typescript": "^5.2.2"
  },
  "devDependencies": {
    "@types/ejs": "^3.1.4",
    "@types/method-override": "^0.0.34"
  }
}

```

```json
// tsconfig.json
{
    "compilerOptions": {
      "target": "ES2022",
      "module": "commonjs",
      "outDir": "./dist",
      "rootDir": "./src",
      "strict": true,
      "esModuleInterop": true,
      "noImplicitAny" : true,
      "sourceMap": true,
      "emitDecoratorMetadata": true,
      "experimentalDecorators": true,
    }
}
```
