---
title: "TypeScriptを使ったExpressアプリケーションでのリクエストごとのロギング"
date: 2024-4-4T14:18:00
weight: 4
categories:
  - javascript
  - nodejs
  - typescript
---

# TypeScriptを使ったExpressアプリケーションでのリクエストごとのロギング

現代のWebアプリケーションにおいて、ロギングはモニタリングとデバッグの重要な部分です。
この記事では、TypeScriptを使用したExpressアプリケーションでのリクエストごとのロギングを実装する方法を紹介します。
これは、InversifyJSでの依存性注入とUUIDを利用して一意のリクエスト識別子を生成することに基づいています。

## ミドルウェアの設定

まず、一意のリクエスト識別子を生成して、それをリクエストオブジェクトとレスポンスオブジェクトの両方に添付するためのミドルウェアを設定します。
この識別子は、アプリケーション全体の特定のリクエストに関連するログを追跡するために重要です。

### src/middlewares.ts

```typescript
import 'reflect-metadata';
import express from 'express';
import {container} from './inversify.config';
import {LoggerFactory} from './infrastructure/logger/loggerFactory';
import {v4} from 'uuid';

export const requestIdMiddleware = (
  req: express.Request,
  res: express.Response,
  next: express.NextFunction
) => {
  const requestId = v4();
  req.headers['requestId'] = requestId;
  res.setHeader('X-Request-Id', requestId);
  next();
};

export const loggerMiddleware = (
  req: express.Request,
  res: express.Response,
  next: express.NextFunction
) => {
  const loggerFactory = container.get<LoggerFactory>(LoggerFactory);
  loggerFactory.createLogger(req);

  res.on('finish', () => {
    const loggerFactory = container.get<LoggerFactory>(LoggerFactory);
    loggerFactory.destroyLogger(req);
  });

  next();
};
```

## Expressへのミドルウェアの統合

次に、ミドルウェア関数を含むようにExpressアプリケーションのメインサーバーファイルを変更して、ミドルウェアをアプリケーションに統合します。

### src/index.ts

```typescript
import 'reflect-metadata';
import express from 'express';
import {InversifyExpressServer, getRouteInfo} from 'inversify-express-utils';
import {container, setupAsyncDependencies} from './inversify.config';
import {LoggerFactory} from './infrastructure/logger/loggerFactory';
import {requestIdMiddleware, loggerMiddleware} from './middlewares';
import * as prettyjson from 'prettyjson';
import config from 'config';

const port = config.get<number>('port');

const configFn = (app: express.Application) => {
  app.use(express.json());
  app.use(express.urlencoded({extended: true}));
  app.use(requestIdMiddleware);
  app.use(loggerMiddleware);
};

const errorConfigFn = (app: express.Application) => {
  app.use(
    (
      err: Error,
      req: express.Request,
      res: express.Response,
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      next: express.NextFunction
    ) => {
      try {
        const loggerFactory = container.get<LoggerFactory>(LoggerFactory);
        const logger = loggerFactory.getLogger(req);
        logger?.error(err, `Unhandled exception: ${err.message}`);
      } catch (loggingError) {
        console.error('Logging failed', loggingError);
      }
      res.status(500).send({
        error: 'internal_server_error',
        error_description:
          'An unexpected error occurred. Please try again later.',
      });
    }
  );
};

const callback = () => {
  console.info(`Server running on http://localhost:${port}`);
  console.info(`NODE_ENV:${process.env.NODE_ENV}`);
  if (
    process.env.NODE_ENV === 'development' ||
    process.env.NODE_ENV === 'myhost'
  ) {
    const routeInfo = getRouteInfo(container);
    console.info(prettyjson.render({routes: routeInfo}));
  }
};

async function startServer() {
  await setupAsyncDependencies();

  const server = new InversifyExpressServer(container, null, {
    rootPath: '/api/v1',
  });

  server
    .setConfig(configFn)
    .setErrorConfig(errorConfigFn)
    .build()
    .listen(port, callback);
}

startServer().catch(error => {
  console.error('Failed to start the server:', error);
});
```

## ロガーの実装

ロガーの実装では、メッセージをロギングするためにリクエスト識別子を利用します。これにより、アプリケーション全体でリクエストごとのログを追跡することができます。

`src/infrastructure/logger/loggerFactory.ts`と`src/infrastructure/logger/logger.ts`は、LoggerFactoryクラスとLoggerクラスの実装の詳細を示しています。

### src/infrastructure/logger/loggerFactory.ts

```typescript
import {injectable} from 'inversify';
import {Request} from 'express';
import {ILogger, Logger} from './logger';

@injectable()
export class LoggerFactory {
  private loggerCache: Map<string, ILogger> = new Map();

  constructor() {}

  createLogger(req: Request): void {
    const requestId = this.getRequestId(req);
    if (!requestId) return;
    if (!this.loggerCache.has(requestId)) {
      const logger = new Logger(
        this.getIp(req),
        requestId,
        req.method,
        req.path
      );
      this.loggerCache.set(requestId, logger);
    }
  }

  getLogger(req: Request): ILogger | undefined {
    const requestId = this.getRequestId(req);
    if (!requestId) return undefined;
    if (this.loggerCache.has(requestId)) {
      return this.loggerCache.get(requestId)!;
    }
    return undefined;
  }

  destroyLogger(request: Request): void {
    const requestId = this.getRequestId(request);
    if (!requestId) return;
    this.loggerCache.delete(requestId);
  }

  private getRequestId(req: Request): string | undefined {
    const requestId = req.headers['requestId'];
    if (Array.isArray(requestId)) {
      return requestId[0];
    } else {
      return requestId;
    }
  }

  private getIp(req: Request): string {
    const forwarded = req.headers['x-forwarded-for'];
    let ip: string;
    if (typeof forwarded === 'string') {
      ip = forwarded.split(',')[0];
    } else if (Array.isArray(forwarded)) {
      ip = forwarded[0];
    } else {
      ip = req.socket.remoteAddress || '';
    }
    return ip;
  }
}
```

### src/infrastructure/logger/logger.ts

```typescript
/* eslint-disable @typescript-eslint/no-explicit-any */
import * as prettyjson from 'prettyjson';
interface LogContext {
  ipAddress?: string;
  requestId?: string;
  method?: string;
  url?: string;
}
export interface ILogger {
  info(message?: string): void;
  error(error?: Error, message?: string): void;
  warn(message?: string): void;
}

export class Logger implements ILogger {
  private context: LogContext;

  constructor(
    ipAddress: string,
    requestId: string,
    httpMethod: string,
    uri: string
  ) {
    this.context = {
      ipAddress: ipAddress,
      requestId: requestId,
      method: httpMethod,
      url: uri,
    };
  }

  info(message?: string): void {
    console.info(`${this.getLogScope()} ${message}`);
  }

  error(error?: Error, message?: string): void {
    console.error(`${this.getLogScope()} ${message}`);
    if (error) {
      console.error(`${this.getLogScope()} ${prettyjson.render(error)}`);
    }
  }

  warn(message?: string): void {
    console.warn(`${this.getLogScope()} ${message}`);
  }

  // Arranging to facilitate quick searching of related logs
  private getLogScope = () =>
    `[${this.context.requestId} - ${this.context.ipAddress} - ${this.context.method} ${this.context.url}]`;
}
```

## 使用例

コントローラーやアプリケーションの任意の部分でロガーをどのように使用するかの例です：

```typescript
import {Request, Response} from 'express';
import {container} from '../inversify.config';
import {LoggerFactory} from '../infrastructure/logger/loggerFactory';

export async function someControllerFunction(req: Request, res: Response) {
  const loggerFactory = container.get<LoggerFactory>(LoggerFactory);
  const logger = loggerFactory.getLogger(req);
  
  logger?.info('Some message');
}
```
