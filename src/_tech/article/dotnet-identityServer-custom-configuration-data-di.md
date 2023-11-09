---
title: "IdentitySeverのRegistering Custom Storesを簡易実装した"
date: 2023-11-09T08:15:00
weight: 4
categories:
  - tech
  - oauth
  - csharp
---

## やったこと
[Registering Custom Stores](https://docs.duendesoftware.com/identityserver/v6/data/configuration/#registering-custom-stores)の
記載通り、下記をInterfaceを実装してDIしてみた。
- [IClientStore](https://github.dev/DuendeSoftware/IdentityServer/blob/8acc6f5446192028fbc304e9bcd8985b32d4a6e9/src/Storage/Stores/IClientStore.cs#L15-L16)
- [ICorsPolicyService](https://github.dev/DuendeSoftware/IdentityServer/blob/8acc6f5446192028fbc304e9bcd8985b32d4a6e9/src/Storage/Services/ICorsPolicyService.cs#L14-L15)
- [IResourceStore](https://github.dev/DuendeSoftware/IdentityServer/blob/8acc6f5446192028fbc304e9bcd8985b32d4a6e9/src/Storage/Stores/IResourceStore.cs#L16-L17)
- [IIdentityProviderStore](https://github.dev/DuendeSoftware/IdentityServer/blob/8acc6f5446192028fbc304e9bcd8985b32d4a6e9/src/Storage/Stores/IIdentityProviderStore.cs#L16-L17)


## なんで
`Duende.IdentityServer.EntityFramework`を使うと個人で運用するには[Table数](https://github.dev/DuendeSoftware/IdentityServer/blob/8acc6f5446192028fbc304e9bcd8985b32d4a6e9/src/EntityFramework.Storage/Entities)が多すぎるなので、
必要最低限でできないかなと考えた。
チュートリアルでDIしている数が、４つしかなかったので、たぶん`Duende.IdentityServer.EntityFramework`を使わなくても
永続ストレージに保存しながらAuthServerが実装できるんじゃないかとおもった。

```csharp
builder.Services.AddIdentityServer()
    .AddInMemoryIdentityResources(Config.IdentityResources)
    .AddInMemoryApiScopes(Config.ApiScopes)
    .AddInMemoryClients(Config.Clients)
```

## 実装

*IClientStore*
```csharp
using Duende.IdentityServer;
using Duende.IdentityServer.Models;
using Duende.IdentityServer.Stores;

namespace IdentityServer.Configrations;

public class ClientStore : IClientStore
{
    private static IEnumerable<Client> Clients =>
        new List<Client>
        {
            new Client
            {
                ClientId = "client",
                ClientSecrets = { new Secret("secret".Sha256()) },
                AllowedGrantTypes = GrantTypes.ClientCredentials,
                AllowedScopes = { "api1" }
            },
            new Client
            {
                ClientId = "web",
                ClientSecrets = { new Secret("secret".Sha256()) },

                AllowedGrantTypes = GrantTypes.Code,
                RedirectUris = { "https://localhost:5002/signin-oidc" },
                PostLogoutRedirectUris = { "https://localhost:5002/signout-callback-oidc" },
                AllowedScopes = new List<string>
                {
                    IdentityServerConstants.StandardScopes.OpenId,
                    IdentityServerConstants.StandardScopes.Profile,
                    "verification"
                }
            }
        };

    private ILogger<ClientStore> _logger;

    public ClientStore(ILogger<ClientStore> logger)
    {
        this._logger = logger;
    }

    public Task<Client> FindClientByIdAsync(string clientId)
    {
        var clinet = Clients.SingleOrDefault(c => c.ClientId == clientId);
        this._logger.LogInformation($"FindClientByIdAsync:{clientId} isFind:{clinet is not null}");
        return Task.FromResult(clinet);
    }
}
```

*ICorsPolicyService*
```csharp
using Duende.IdentityServer.Services;

namespace IdentityServer.Configurations;

// https://github.com/DuendeSoftware/IdentityServer/blob/8acc6f5446192028fbc304e9bcd8985b32d4a6e9/src/IdentityServer/Hosting/CorsPolicyProvider.cs#L52-L53
// httpRequestのHeaderにOriginが設定されていないとこのクラスは動作しない
public class CorsPolicyService : ICorsPolicyService
{
    private readonly HashSet<string> _allowedOrigins;

    public CorsPolicyService()
    {
        _allowedOrigins = new HashSet<string>
        {
            "https://example.com",
            "https://api.example.com"
        };
    }

    public Task<bool> IsOriginAllowedAsync(string origin)
    {
        var isAllowed = _allowedOrigins.Contains(origin);
        return Task.FromResult(isAllowed);
    }
}
```

*IResourceStore*
```csharp
using Duende.IdentityServer.Models;
using Duende.IdentityServer.Stores;
using IdentityModel;
using IdentityServer.Configurations;

namespace IdentityServer.Configrations;

public class ResourceStore : IResourceStore
{
    public static IEnumerable<IdentityResource> IdentityResources =>
        new List<IdentityResource>
        {
            new IdentityResources.OpenId(),
            new IdentityResources.Profile(),
            new IdentityResource()
            {
                Name = "verification",
                UserClaims = new List<string>
                {
                    JwtClaimTypes.Email,
                    JwtClaimTypes.EmailVerified
                }
            }
        };


    private ILogger<ResourceStore> _logger;

    public ResourceStore(ILogger<ResourceStore> logger)
    {
        this._logger = logger;
    }

    public static IEnumerable<ApiScope> ApiScopes =>
        new List<ApiScope>
        {
            new ApiScope("api1", "MyAPI")
        };

    public static IEnumerable<ApiResource> ApiResources =>
        new List<ApiResource>
        {
        };

    public Task<IEnumerable<ApiResource>> FindApiResourcesByNameAsync(IEnumerable<string> apiResourceNames)
    {
        var result = ApiResources.Where(apiResource => apiResourceNames.Contains(apiResource.Name));
        return Task.FromResult(result);
    }

    public Task<IEnumerable<ApiResource>> FindApiResourcesByScopeNameAsync(IEnumerable<string> scopeNames)
    {
        var result = ApiResources.Where(apiResource => apiResource.Scopes.Any(scope => scopeNames.Contains(scope)));
        return Task.FromResult(result);
    }

    public Task<IEnumerable<ApiScope>> FindApiScopesByNameAsync(IEnumerable<string> scopeNames)
    {
        var result = ApiScopes.Where(scope => scopeNames.Contains(scope.Name));
        return Task.FromResult(result);
    }

    public Task<IEnumerable<IdentityResource>> FindIdentityResourcesByScopeNameAsync(IEnumerable<string> scopeNames)
    {
        var result = IdentityResources.Where(identityResource => scopeNames.Contains(identityResource.Name));
        return Task.FromResult(result);
    }

    public Task<Resources> GetAllResourcesAsync()
    {
        var result = new Resources(IdentityResources, ApiResources, ApiScopes);
        return Task.FromResult(result);
    }
}
```

*IIdentityProviderStore*
```csharp
using Duende.IdentityServer.Models;
using Duende.IdentityServer.Stores;

namespace IdentityServer.Configurations;

// このクラスの使い方はこれだ
// https://github.com/DuendeSoftware/IdentityServer/blob/8eb790cfe5480fb43b1ed770cee8d34545d07adb/hosts/AspNetIdentity/Pages/Account/Login/Index.cshtml.cs#L155-L156
public class IdentityProviderStore : IIdentityProviderStore
{
    private readonly List<IdentityProvider> _providers = new List<IdentityProvider>
    {
        // Freeeプロバイダーを追加
        new IdentityProvider("OAuth")
        {
            Scheme = "Freee",
            DisplayName = "Freee",
            Enabled = false,
            Properties =
            {
                { "ClientId", "freee-client-id" },
                { "ClientSecret", "freee-client-secret" },
                { "AuthorizationEndpoint", "https://example.com/auth" },
                { "TokenEndpoint", "https://example.com/token" },
                { "UserInfoEndpoint", "https://example.com/userinfo" },
                { "Scope", "openid email profile" }
            }
        }
    };

    private ILogger<IdentityProviderStore> _logger;

    public IdentityProviderStore(ILogger<IdentityProviderStore> logger)
    {
        this._logger = logger;
    }

    public Task<IEnumerable<IdentityProviderName>> GetAllSchemeNamesAsync()
    {
        var result = _providers.Select(x => new IdentityProviderName
        {
            Scheme = x.Scheme,
            DisplayName = x.DisplayName,
            Enabled = x.Enabled
        });

        this._logger.LogInformation($"GetAllSchemeNamesAsync:{result.Count()}");

        return Task.FromResult(result);
    }

    public Task<IdentityProvider> GetBySchemeAsync(string scheme)
    {
        var provider = _providers.FirstOrDefault(x => x.Scheme.Equals(scheme, StringComparison.OrdinalIgnoreCase));
        this._logger.LogInformation($"GetBySchemeAsync:{provider.Scheme}");
        return Task.FromResult(provider);
    }
}
```

*HostingExtensions*
```csharp
using Duende.IdentityServer;
using IdentityServer.Configrations;
using IdentityServer.Configurations;
using Microsoft.IdentityModel.Tokens;
using Serilog;

namespace IdentityServer;

internal static class HostingExtensions
{
    public static WebApplication ConfigureServices(this WebApplicationBuilder builder)
    {
        builder.Services.AddRazorPages();

        // https://github.dev/DuendeSoftware/IdentityServer/blob/8acc6f5446192028fbc304e9bcd8985b32d4a6e9/src/EntityFramework/IdentityServerEntityFrameworkBuilderExtensions.cs#L65-L66
        builder.Services.AddIdentityServer()
            //.AddInMemoryIdentityResources(Config.IdentityResources)
            //.AddInMemoryApiScopes(Config.ApiScopes)
            .AddResourceStore<ResourceStore>()
            //.AddInMemoryClients(Config.Clients)
            .AddClientStore<ClientStore>()
            .AddIdentityProviderStore<IdentityProviderStore>()
            .AddCorsPolicyService<CorsPolicyService>()
            .AddTestUsers(TestUsers.Users);

        builder.Services.AddAuthentication()
            .AddGoogle("Google", options =>
            {
                options.SignInScheme = IdentityServerConstants.ExternalCookieAuthenticationScheme;

                options.ClientId = builder.Configuration["Authentication:Google:ClientId"];
                options.ClientSecret = builder.Configuration["Authentication:Google:ClientSecret"];
            })
            .AddOpenIdConnect("oidc", "Demo IdentityServer", options =>
            {
                options.SignInScheme = IdentityServerConstants.ExternalCookieAuthenticationScheme;
                options.SignOutScheme = IdentityServerConstants.SignoutScheme;
                options.SaveTokens = true;

                options.Authority = "https://demo.duendesoftware.com";
                options.ClientId = "interactive.confidential";
                options.ClientSecret = "secret";
                options.ResponseType = "code";

                options.TokenValidationParameters = new TokenValidationParameters
                {
                    NameClaimType = "name",
                    RoleClaimType = "role"
                };
            });

        return builder.Build();
    }

    public static WebApplication ConfigurePipeline(this WebApplication app)
    {
        app.UseSerilogRequestLogging();
        if (app.Environment.IsDevelopment())
        {
            app.UseDeveloperExceptionPage();
        }

        app.UseStaticFiles();
        app.UseRouting();

        app.UseIdentityServer();

        app.UseAuthorization();
        app.MapRazorPages().RequireAuthorization();

        return app;
    }
}
```

## わかったこと

- ICorsPolicyServiceについて
CorsPolicyServiceをDIするだけでは簡単にはうごいてくれない。（個人の感想です
CorsPolicyServiceの実装が有効になるのは２つの条件を満たす必要がある。

1. httpRequestのHeaderにOriginが設定されていること
   1. [実装をみたら](https://github.com/DuendeSoftware/IdentityServer/blob/8acc6f5446192028fbc304e9bcd8985b32d4a6e9/src/IdentityServer/Hosting/CorsPolicyProvider.cs#L52-L53)`request.Headers["Origin"].FirstOrDefault();`に値がない場合は`ICorsPolicyService`が呼び出されない実装になっている
2. [ASP.NET CoreのCORS](https://learn.microsoft.com/ja-jp/aspnet/core/security/cors?view=aspnetcore-7.0)機能と競合しないようにする必要がある。
   1. [IdentityServer4](https://identityserver4.readthedocs.io/en/latest/topics/cors.html#mixing-identityserver-s-cors-policy-with-asp-net-core-s-cors-policies)なので今回実装したVersionとはちがうものの記事には”ICorsPolicyProviderをカスタム実装することを選択した場合、ASP.NET CoreのCORSサービスとIdentityServerの使用との間に競合が生じる可能性があります。”なので気を付けましょう。

DynamicにCrosを登録する場合`CorsPolicyBuilder`を使えばいいんだとさらなる[学び](https://github.com/DuendeSoftware/IdentityServer/blob/8acc6f5446192028fbc304e9bcd8985b32d4a6e9/src/IdentityServer/Hosting/CorsPolicyProvider.cs#L85C1-L98C6)があった。
  - [CorsPolicyBuilder クラス](https://learn.microsoft.com/ja-jp/dotnet/api/microsoft.aspnetcore.cors.infrastructure.corspolicybuilder?view=aspnetcore-7.0)
  - [ICorsPolicyProvider](https://learn.microsoft.com/ja-jp/aspnet/web-api/overview/security/enabling-cross-origin-requests-in-web-api#custom-cors-policy-providers) も実装しないといけないね

- IdentityProviderStoreについて

この子の扱いが一番わからなかった。
呼び出し元からDynamicに連携先を設定できるようにしたいから
IdentityProviderStoreがあるんじゃないのかと私の結論付けた。
根拠は、IdentityServerでの[実装](https://github.com/DuendeSoftware/IdentityServer/blob/8eb790cfe5480fb43b1ed770cee8d34545d07adb/hosts/AspNetIdentity/Pages/Account/Login/Index.cshtml.cs#L155-L156)だ。

なので、デフォルトで外部の認証先を表示したい場合は、` builder.Services.AddAuthentication()`のあとにつらつらと
認証先の設定をすればいいじゃないかと思った。