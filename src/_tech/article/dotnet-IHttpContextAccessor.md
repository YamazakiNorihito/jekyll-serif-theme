---
title: "IHttpContextAccessorとは"
date: 2023-11-07T07:00:00
weight: 4
categories:
  - tech
  - csharp
  - dotnet
description: "IHttpContextAccessorはASP.NET CoreでHttpContextにアクセスするためのクラス。リクエストスコープ内での使用が推奨される。"
tags:
  - IHttpContextAccessor
  - ASP.NET Core
  - HttpContext
  - C#
  - .NET
---


名前の通り、HttpContextにアクセスるためのクラスである。

[IHttpContextAccessor](https://learn.microsoft.com/ja-jp/dotnet/api/microsoft.aspnetcore.http.ihttpcontextaccessor?view=aspnetcore-7.0)
[HttpContextAccessor](https://learn.microsoft.com/ja-jp/dotnet/api/microsoft.aspnetcore.http.httpcontextaccessor?view=aspnetcore-7.0)

ASP.NET Core では、`HttpContext`` はリクエストごとに存在し、リクエストに関連する情報（例えば、リクエストの詳細、認証情報、セッションデータなど）を含んでいます。
しかし、ASP.NET Core の設計において、`HttpContext`は依存注入（DI）コンテナを通じて直接注入されないため、`HttpContextAccessor` がそのギャップを埋めるために存在します。

使用上の注意

1. HttpContextAccessor は、リクエストのスコープ内でのみ使用するべきです。リクエストの外部、例えばシングルトンサービス内で使用すると、予期しない動作やリークの原因となる可能性があります。
1. すべてのシナリオで HttpContextAccessor を使用する必要はありません。例えば、コントローラのアクションメソッド内では、ControllerBase クラスから直接 HttpContext にアクセスできます。

参考資料

- [HttpContextAccessor in Asp.NET Core Web API](https://www.researchgate.net/publication/371071377_HttpContextAccessor_in_AspNET_Core_Web_API)
- [ASP.NET Core の HttpContext にアクセスする](https://learn.microsoft.com/ja-jp/aspnet/core/fundamentals/http-context?view=aspnetcore-7.0)
