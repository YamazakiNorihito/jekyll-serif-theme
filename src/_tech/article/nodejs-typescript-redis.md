---
title: "redisclientをmockする方法"
date: 2024-4-4T14:18:00
weight: 4
categories:
  - javascript
  - nodejs
  - typescript
---

# redisclientをmockする方法

Redisクライアントのモックを作成することは、Node.js環境でのテスト戦略の重要な部分です。特に、外部の依存関係やサービスに対するテストを行う場合、その実行環境を完全にコントロール下に置くことが望ましいです。このブログ記事では、jest-mock-extendedを使用してRedisクライアントをモックする方法について説明します。これは、実際のRedisサーバーに依存しないテストを可能にする、シンプルかつ効果的な方法を紹介します。

## jest-mock-extendedの利用
jest-mock-extendedはJestのためのTypeScriptフレンドリーなモックライブラリです。これを使うことで、TypeScriptの型安全性を保ちながら、任意のオブジェクトのモックを容易に作成できます。このライブラリは、特に型情報を持つオブジェクトをモックする場合に有効です。

# test/infrastructure/database/cacheClient.test.ts
```typescript
import {RedisClientType} from 'redis';
import {DeepMockProxy, mockDeep} from 'jest-mock-extended';
import {
  ICacheClient,
  RedisCacheClient,
} from '../../../src/infrastructure/database/cacheClient';

describe('ICacheClient', () => {
  let redisClientMock: DeepMockProxy<RedisClientType>;

  beforeEach(() => {
    redisClientMock = mockDeep<RedisClientType>();
  });

  describe('set', () => {
    it('should correctly set a value with namespaced key, hashed key, and ttl', async () => {
      // Arrange
      const ttlSeconds = 3600;
      const redisCacheClient: ICacheClient = new RedisCacheClient(
        redisClientMock
      );

      // Act
      await redisCacheClient.set('testNamespace', 'testKey', 'testValue', {
        ttlSeconds,
      });

      // Assert
      expect(redisClientMock.set).toHaveBeenCalledWith(
        'testNamespace:15291f67d99ea7bc578c3544dadfbb991e66fa69cb36ff70fe30e798e111ff5f',
        'testValue',
        {
          EX: ttlSeconds,
        }
      );
    });
  });
});

```

### src/infrastructure/database/cacheClient.ts

```typescript
import {RedisClientType} from 'redis';
import {createHash} from 'crypto';
import {inject, injectable} from 'inversify';

export interface ICacheClient {
  set(
    namespace: string,
    key: string,
    value: string,
    option?: {
      ttlSeconds?: number;
    }
  ): Promise<string | null>;
}

@injectable()
export class RedisCacheClient implements ICacheClient {
  constructor(@inject('RedisClient') private redisClient: RedisClientType) {}

  public set(
    namespace: string,
    key: string,
    value: string,
    option?: {
      ttlSeconds?: number;
    }
  ): Promise<string | null> {
    const hash = this.generateHash(key);
    if (option && option.ttlSeconds !== undefined) {
      return this.redisClient.set(`${namespace}:${hash}`, value, {
        EX: option.ttlSeconds,
      });
    } else {
      return this.redisClient.set(`${namespace}:${hash}`, value);
    }
  }
  private generateHash(key: string): string {
    return createHash('sha256').update(key).digest('hex');
  }
}

```

## 結論
jest-mock-extendedを使用することで、Redisクライアントのモックを簡単に作成し、
依存関係を持つコードのテストを行うことができます。
これにより、実際の外部サービスとの通信を必要とせずに、
アプリケーションのロジックを安全にテストすることが可能になります