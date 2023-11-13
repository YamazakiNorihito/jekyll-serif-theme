---
title: "CookieAuthenticationOptionsのDIの仕方"
date: 2023-11-07T07:00:00
weight: 4
categories:
  - tech
  - csharp
  - dotnet
---


[CookieAuthenticationOptions](https://learn.microsoft.com/ja-jp/dotnet/api/microsoft.aspnetcore.builder.cookieauthenticationoptions)の仕方のメモでごやんす

*appsettings.json*
```json
{
  "CookieAuthentication": {
    "LoginPath": "/Account/Login",
    "AccessDeniedPath": "/Account/AccessDenied",
    "ExpireTimeSpan": "00:30:00",
    "SlidingExpiration": true
  }
  // 他の設定...
}

```

*Startup.cs*

```csharp
public class Startup
{
    public Startup(IConfiguration configuration)
    {
        Configuration = configuration;
    }

    public IConfiguration Configuration { get; }

    public void ConfigureServices(IServiceCollection services)
    {
        // クッキー認証の設定を読み込む
        services.Configure<CookieAuthenticationOptions>(Configuration.GetSection("CookieAuthentication"));

        services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
                .AddCookie(options =>
                {
                    // appsettings.jsonからの設定を適用
                    var cookieSettings = Configuration.GetSection("CookieAuthentication").Get<CookieAuthenticationOptions>();
                    options.LoginPath = cookieSettings.LoginPath;
                    options.LogoutPath = "/Account/Logout";
                    options.AccessDeniedPath = cookieSettings.AccessDeniedPath;
                    options.ExpireTimeSpan = TimeSpan.Parse(cookieSettings.ExpireTimeSpan);
                    options.SlidingExpiration = cookieSettings.SlidingExpiration;
                });

        // 他のサービスの設定...
    }

    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        // 他のミドルウェア設定...

        // 認証ミドルウェアを追加
        app.UseAuthentication();

        // 他のミドルウェア設定...
    }
}
```

### ログイン機能の実装

```csharp
public class AccountController : Controller
{
    public IActionResult Login()
    {
        return View();
    }

    [HttpPost]
    public async Task<IActionResult> Login(string username, string password)
    {
        // ここでユーザー認証を行う
        // 以下は簡単な例です。実際にはデータベースなどを使用してユーザーを検証する必要があります。
        if (username == "user" && password == "password")
        {
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, username)
            };

            var claimsIdentity = new ClaimsIdentity(claims, "CookieAuth");
            var claimsPrincipal = new ClaimsPrincipal(claimsIdentity);

            await HttpContext.SignInAsync("CookieAuth", claimsPrincipal);

            return RedirectToAction("Index", "Home");
        }

        return View();
    }
}
```

### ログアウト機能の実装

```csharp
public class AccountController : Controller
{
    [HttpPost]
    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync("CookieAuth");
        return RedirectToAction("Index", "Home");
    }
}
```



参考資料
- [Use cookie authentication without ASP.NET Core Identity](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/cookie?view=aspnetcore-7.0)