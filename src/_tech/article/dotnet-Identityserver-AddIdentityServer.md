---
title: "IdentitySeverのAddIdentityServerなにやっているのか？（工事中"
date: 2023-11-11T07:15:00
weight: 4
mermaid: true
categories:
  - tech
  - oauth
  - csharp
  - dotnet
description: ""
---


[AddIdentityServer](https://github.dev/DuendeSoftware/IdentityServer/blob/4ac7e461091b549ab0a79eb037c68f59a94e74a9/src/IdentityServer/Configuration/DependencyInjection/IdentityServerServiceCollectionExtensions.cs#L35-L36)

```csharp
public static IIdentityServerBuilder AddIdentityServer(this IServiceCollection services)
{
    var builder = services.AddIdentityServerBuilder();

    builder
        .AddRequiredPlatformServices()
        .AddCookieAuthentication()
        .AddCoreServices()
        .AddDefaultEndpoints()
        .AddPluggableServices()
        .AddKeyManagement()
        .AddDynamicProvidersCore()
        .AddOidcDynamicProvider()
        .AddValidators()
        .AddResponseGenerators()
        .AddDefaultSecretParsers()
        .AddDefaultSecretValidators();

    // provide default in-memory implementations, not suitable for most production scenarios
    builder.AddInMemoryPersistedGrants();
    builder.AddInMemoryPushedAuthorizationRequests();

    return builder;
}
```

## [AddRequiredPlatformServices](https://github.dev/DuendeSoftware/IdentityServer/blob/4ac7e461091b549ab0a79eb037c68f59a94e74a9/src/IdentityServer/Configuration/DependencyInjection/BuilderExtensions/Core.cs#L50-L51)

[やっていること]

- HttpClient/[IHttpContextAccessor](/tech/article/dotnet-IHttpContextAccessor/)[IdentityServerOptions](https://docs.duendesoftware.com/identityserver/v6/reference/options/)（IdentityServerの最上位設定）を準備している。

## [AddCookieAuthentication](https://github.com/DuendeSoftware/IdentityServer/blob/4ac7e461091b549ab0a79eb037c68f59a94e74a9/src/IdentityServer/Configuration/DependencyInjection/BuilderExtensions/Core.cs#L68-L69)

[やっていること]

- IdentityServerでの認証用のCookie名を[idsrv](https://github.com/DuendeSoftware/IdentityServer/blob/4ac7e461091b549ab0a79eb037c68f59a94e74a9/src/IdentityServer/IdentityServerConstants.cs#L15-L16)でデフォルト名として設定
- IdentityServerでの外部認証用のCookie名を[idsrv.external](https://github.com/DuendeSoftware/IdentityServer/blob/4ac7e461091b549ab0a79eb037c68f59a94e74a9/src/IdentityServer/IdentityServerConstants.cs#L17-L18)でデフォルト名として設定
- [CookieAuthenticationOptions](/tech/article/dotnet-CookieAuthenticationOptions/)の設定反映:
- [PostConfigureCookieAuthenticationOptions](https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.authentication.cookies.postconfigurecookieauthenticationoptions?view=aspnetcore-7.0)の設定
  - ログイン/ログアウトクッキー認証オプションの設定
    - LoginPath
      - 認証が必要なリソースに未認証のユーザーがアクセスした場合にリダイレクトされるログインページのパスを指定します。
    - LoginReturnUrlParameter
      - CallBackするときのクエリパラメータを指定します。
    - LogoutUrl
      - ログアウトページのパスを指定します。
- ユーザーのサインインとサインアウトを追跡し、Identity Serverの機能をサポートするため[の認証サービスを設定](https://github.com/DuendeSoftware/IdentityServer/blob/4ac7e461091b549ab0a79eb037c68f59a94e74a9/src/IdentityServer/Configuration/DependencyInjection/BuilderExtensions/Core.cs#L98-L99)

- [フェデレーテッドサインアウト](https://github.com/DuendeSoftware/IdentityServer/blob/4ac7e461091b549ab0a79eb037c68f59a94e74a9/src/IdentityServer/Configuration/DependencyInjection/BuilderExtensions/Core.cs#L99-L100)（複数の異なるシステムやアプリケーション間での一括ログアウト）を管理設定
  -

[内部的に呼び出しているメソッド]

- [AddDefaultCookieHandlers](https://github.com/DuendeSoftware/IdentityServer/blob/4ac7e461091b549ab0a79eb037c68f59a94e74a9/src/IdentityServer/Configuration/DependencyInjection/BuilderExtensions/Core.cs#L80-L81)
- [AddCookieAuthenticationExtensions](https://github.com/DuendeSoftware/IdentityServer/blob/4ac7e461091b549ab0a79eb037c68f59a94e74a9/src/IdentityServer/Configuration/DependencyInjection/BuilderExtensions/Core.cs#L95-L96)
