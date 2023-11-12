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


### [AddRequiredPlatformServices](https://github.dev/DuendeSoftware/IdentityServer/blob/4ac7e461091b549ab0a79eb037c68f59a94e74a9/src/IdentityServer/Configuration/DependencyInjection/BuilderExtensions/Core.cs#L50-L51)

