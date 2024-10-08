---
title: "Redisを使ってNode Jsと連携してみた"
date: 2023-10-27T09:21:00
linkedinurl: ""
weight: 7
tags:
  - Redis
  - Node.js
  - Docker
  - Database
  - JavaScript
  - Data Storage
  - Tutorial
  - Redis CLI
  - Web Development
description: ""
---

Redis初心者なのでドキュメント見ながら、データの読み書きやユーザー管理を試してみました。

## redis

### 準備

```bash
mkdir redis-and-node
cd redis-and-node
touch docker-compose.yaml
touch redis-stack.conf
touch users.acl
```

*docker-compose.yaml*
[Run Redis Stack on Docker](https://redis.io/docs/install/install-stack/docker/)

```yaml
version: "3.8"
services:
  redis:
    image: redis/redis-stack-server:7.2.0-v4
    ports:
      - "6379:6379"
      - "13333:8001"
    volumes:
      - ./redis-data:/data
      - ./redis.conf:/redis-stack.conf
      - ./users.acl:/users.acl
volumes:
  redis-data:
```

*redis-stack.conf*

```conf
# 認証のためのパスワードを設定
requirepass password
# 保護モードを有効にする
protected-mode yes
# AOFの永続化を有効
appendonly yes

aclfile /users.acl

```

*users.acl*
[Redis access control list](http://mogile.web.fc2.com/redis/docs/manual/security/acl/index.html)

```text
user admin on >adminpass +@all ~*
user read_only on >readonlypass +@read ~*
user execute_user on >executeuserpass +@all -@dangerous ~*
```

### 立ち上げ

```bash
docker-compose up -d

# 立ち上げたRedisのコンテナIDコピー
docker ps

docker exec -it [redis_docker_container_id] redis-cli

# これでログインできればOK
redis-cli>auth execute_user executeuserpass

redis-cli>quit

```

## NodeJs

### 準備

[Node.js guide](https://redis.io/docs/connect/clients/nodejs/)

```bash
npm init -y

npm i redis

touch index.js
```

*index.js*

```javascript
import { createClient } from 'redis';

/*
To connect to a different host or port, use a connection string in the format redis[s]://[[username][:password]@][host][:port][/db-number]:
await client.createClient({
  url: 'redis://alice:foobared@awesome.redis.server:6380'
});
*/
const client = createClient({
    url: 'redis://execute_user:executeuserpass@localhost:6379' // use your actual password
  });

client.on('error', err => console.log('Redis Client Error', err));

/*
    before connect(isReady):false
    before connect(isOpen):false
*/
console.log("before connect(isReady):" + client.isReady);
console.log("before connect(isOpen):" + client.isOpen);

await client.connect();

/*
    after connect(isReady):true
    after connect(isOpen):true
*/
console.log("after connect(isReady):" + client.isReady);
console.log("after connect(isOpen):" + client.isOpen);

// client.set は単一の文字列値をセットするためのものであり、client.hSet はハッシュ内の1つ以上のフィールドに値をセットするためのもの
// Store and retrieve a simple string.
await client.set('key', 'redis_value');
const value = await client.get('key');

// Store and retrieve a simple string:redis_value
console.log("Store and retrieve a simple string:" + value);

// Store and retrieve a map.
await client.hSet('user-session:123', {
    name: 'John',
    surname: 'Smith',
    company: 'Redis',
    age: 29
});
let name = await client.hGet('user-session:123', 'name');
let userSession = await client.hGetAll('user-session:123');

/*
Store and retrieve a map:{
  "name": "John",
  "surname": "Smith",
  "company": "Redis",
  "age": "29"
}
*/
console.log("Store and retrieve a map(hGet):" + name);
console.log("Store and retrieve a map(hGetAll):" + JSON.stringify(userSession, null, 2));


/*
    Database

*/
import {AggregateSteps, AggregateGroupByReducers, SchemaFieldTypes} from 'redis';
const schema = {
    '$.name': {
        type: SchemaFieldTypes.TEXT,
        SORTABLE: true
    },
    '$.city': {
        type: SchemaFieldTypes.TEXT,
        AS: 'city'
    },
    '$.age': {
        type: SchemaFieldTypes.NUMERIC,
        AS: 'age'
    }
};
try {
    await client.ft.create('idx:users', schema, {
        ON: 'JSON',
        PREFIX: 'user:'
    });
} catch (e) {
    if (e.message === 'Index already exists') {
        console.log('Index exists already, skipped creation.');
    } else {
        // Something went wrong, perhaps RediSearch isn't installed...
        console.error(e);
        process.exit(1);
    }
}
await Promise.all([
    client.json.set('user:1', '$', {
        "name": "Paul John",
        "email": "paul.john@example.com",
        "age": 42,
        "city": "London"
    }),
    client.json.set('user:2', '$', {
        "name": "Eden Zamir",
        "email": "eden.zamir@example.com",
        "age": 29,
        "city": "Tel Aviv"
    }),
    client.json.set('user:3', '$', {
        "name": "Paul Zamir",
        "email": "paul.zamir@example.com",
        "age": 35,
        "city": "Tel Aviv"
    }),
]);

let result = await client.ft.search(
    'idx:users',
    'Paul @age:[30 40]', {
        LIMIT: {
          from: 0,
          size: 10
        }
      }
);

console.log("Let's find user 'Paul` and filter the results by age:" + JSON.stringify(result, null, 2));
/*
Let's find user 'Paul` and filter the results by age:{
  "total": 1,
  "documents": [
    {
      "id": "user:3",
      "value": {
        "name": "Paul Zamir",
        "email": "paul.zamir@example.com",
        "age": 35,
        "city": "Tel Aviv"
      }
    }
  ]
}
*/
result = await client.ft.search(
    'idx:users',
    'Paul @age:[30 40]',
    {
        RETURN: ['$.city']
    }
);
/*
Return only the city field.:{
  "total": 1,
  "documents": [
    {
      "id": "user:3",
      "value": {
        "$.city": "Tel Aviv"
      }
    }
  ]
}
*/
console.log("Return only the city field.:" + JSON.stringify(result, null, 2));

result = await client.ft.aggregate('idx:users', '*', {
    STEPS: [
        {
            type: AggregateSteps.GROUPBY,
            properties: ['@city'],
            REDUCE: [
                {
                    type: AggregateGroupByReducers.COUNT,
                    AS: 'count'
                }
            ]
        }
    ]
})
/*
Count all users in the same city:{
  "total": 2,
  "results": [
    {
      "city": "London",
      "count": "1"
    },
    {
      "city": "Tel Aviv",
      "count": "2"
    }
  ]
}
*/
console.log("Count all users in the same city:" + JSON.stringify(result, null, 2));

await client.quit();
```

### 実行

```bash
node index.js
```
