---
title: "ValidationExceptionについて考える(工事中)"
date: 2023-10-25T06:14:00
##image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: ""
linkedinurl: ""
weight: 7
tags:
description: ""
---

 Exceptionは適切にThrowする必要がある。
 この記事は完成していません。

###### ここから学んでいく

 今わかっていることを書いていく。

- [例外と例外処理 (Microsoft Learn)](https://learn.microsoft.com/ja-jp/dotnet/csharp/fundamentals/exceptions/)
- [Error (Mozilla Developer Network)](https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/Error)

以下のリンクは見つけただけで読んでない。

- [Exception Handling Middleware In .NET Core Web API](https://thecodeblogger.com/2021/05/30/exception-handling-middleware-in-net-core-web-api/##)
- [Handle errors in ASP.NET Core web APIs](https://learn.microsoft.com/en-us/aspnet/core/web-api/handle-errors?view=aspnetcore-7.0)
- [Error handling and validation architecture in .NET Core](https://dev.to/boriszn/error-handling-and-validation-architecture-in-net-core-3lhe##:~:text=The%20validation%20and%20error%20handling,logic%20out%20from%20API%20controller)
- [.NET 6.0 - Global Error Handler Tutorial with Example](https://jasonwatmore.com/post/2022/01/17/net-6-global-error-handler-tutorial-with-example##:~:text=Program.cs%20,by%20the%20global%20error%20handler)
- [Error Handling and Validation Architecture in .NET Core](https://dzone.com/articles/error-handling-and-validation-architecture-in-net##:~:text=In%20the%20example%20below%20I’ve,and%20build%20an)

###### 読んでみて

Microsoft先生のドキュメントを読み込む。
ど頭に”例外処理機能は、プログラムの実行時に発生する予期しない状況や例外的な状況を扱うのに役立ちます。成功しない可能性があるアクションを試行し、適切な場合はエラーを処理して、後からリソースをクリーンアップします。”と書いてあります。

###### エラーバリデーション vs 例外処理

- *エラーバリデーション:*
  - エラーバリデーションは、主に入力データが期待されるフォーマットや条件を満たしているかどうかを確認するプロセスです。これは通常、エラーが発生する前に行われ、ユーザーに適切なフィードバックを提供することで、エラーを修正する機会を与えます。
- *例外処理:*
  - 例外処理は、プログラムの実行中に予期せぬエラーや問題が発生した場合に使用されます。例外は、通常、プログラムの正常な流れを中断し、エラーをキャッチして処理するメカニズムを提供します。

## 例外処理によるエラーハンドリングアーキテクチャについて

ユーザー入力のバリデーションがエラーであった場合に例外を投げ、ミドルウェアでキャッチしてレスポンスを返すアーキテクチャには、いくつかの利点と欠点

#### 利点

1. **集中化されたエラーハンドリング**:
    - エラーハンドリングのロジックを集中化し、アプリケーション全体で一貫したエラーレスポンスを提供できます。
2. **カスタマイズ可能なエラーレスポンス**:
    - エラーコード、エラーメッセージ、および他のレスポンスパラメータをカスタマイズし、ユーザーに適切なフィードバックを提供できます。

#### 欠点

1. **パフォーマンスオーバーヘッド**:
    - 例外の投げとキャッチは、エラーコードを返すよりもコストがかかる可能性があります。
2. **エラートラッキングの困難**:
    - 大規模なアプリケーションでは、どこで例外が投げられ、どのミドルウェアがそれをキャッチするのかを追跡することが困難になる可能性があります。

#### 結論

 ExceptionはExceptionとするか、エラーハンドリングアーキテクチャとするか
 結局、プロジェクトの方針や人それぞれである。
