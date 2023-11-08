---
title: "IdentitySeverのテンプレートisuiで吐き出された内容をみていく Part1"
date: 2023-11-07T07:00:00
weight: 4
categories:
  - tech
  - oauth
  - csharp
---

/src/IdentityServer/Pages/Account/Create/Index.cshtml.cs を見ていく

```csharp
// Index.cshtml.cs
using Duende.IdentityServer;
using Duende.IdentityServer.Events;
using Duende.IdentityServer.Models;
using Duende.IdentityServer.Services;
using Duende.IdentityServer.Stores;
using Duende.IdentityServer.Test;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace IdentityServer.Pages.Create;

[SecurityHeaders]
[AllowAnonymous]
public class Index : PageModel
{
    private readonly TestUserStore _users;
    private readonly IIdentityServerInteractionService _interaction;

    [BindProperty]
    public InputModel Input { get; set; }
        
    public Index(
        IIdentityServerInteractionService interaction,
        TestUserStore users = null)
    {
        // this is where you would plug in your own custom identity management library (e.g. ASP.NET Identity)
        _users = users ?? throw new Exception("Please call 'AddTestUsers(TestUsers.Users)' on the IIdentityServerBuilder in Startup or remove the TestUserStore from the AccountController.");
            
        _interaction = interaction;
    }

    public IActionResult OnGet(string returnUrl)
    {
        Input = new InputModel { ReturnUrl = returnUrl };
        return Page();
    }
        
    public async Task<IActionResult> OnPost()
    {
        // check if we are in the context of an authorization request
        var context = await _interaction.GetAuthorizationContextAsync(Input.ReturnUrl);

        // the user clicked the "cancel" button
        if (Input.Button != "create")
        {
            if (context != null)
            {
                // if the user cancels, send a result back into IdentityServer as if they 
                // denied the consent (even if this client does not require consent).
                // this will send back an access denied OIDC error response to the client.
                await _interaction.DenyAuthorizationAsync(context, AuthorizationError.AccessDenied);

                // we can trust model.ReturnUrl since GetAuthorizationContextAsync returned non-null
                if (context.IsNativeClient())
                {
                    // The client is native, so this change in how to
                    // return the response is for better UX for the end user.
                    return this.LoadingPage(Input.ReturnUrl);
                }

                return Redirect(Input.ReturnUrl);
            }
            else
            {
                // since we don't have a valid context, then we just go back to the home page
                return Redirect("~/");
            }
        }

        if (_users.FindByUsername(Input.Username) != null)
        {
            ModelState.AddModelError("Input.Username", "Invalid username");
        }

        if (ModelState.IsValid)
        {
            var user = _users.CreateUser(Input.Username, Input.Password, Input.Name, Input.Email);

            // issue authentication cookie with subject ID and username
            var isuser = new IdentityServerUser(user.SubjectId)
            {
                DisplayName = user.Username
            };

            await HttpContext.SignInAsync(isuser);

            if (context != null)
            {
                if (context.IsNativeClient())
                {
                    // The client is native, so this change in how to
                    // return the response is for better UX for the end user.
                    return this.LoadingPage(Input.ReturnUrl);
                }

                // we can trust model.ReturnUrl since GetAuthorizationContextAsync returned non-null
                return Redirect(Input.ReturnUrl);
            }

            // request for a local page
            if (Url.IsLocalUrl(Input.ReturnUrl))
            {
                return Redirect(Input.ReturnUrl);
            }
            else if (string.IsNullOrEmpty(Input.ReturnUrl))
            {
                return Redirect("~/");
            }
            else
            {
                // user might have clicked on a malicious link - should be logged
                throw new Exception("invalid return URL");
            }
        }

        return Page();
    }
}

// InputModel.cs
using System.ComponentModel.DataAnnotations;

namespace IdentityServer.Pages.Create;

public class InputModel
{
    [Required]
    public string Username { get; set; }

    [Required]
    public string Password { get; set; }

    public string Name { get; set; }
    public string Email { get; set; }

    public string ReturnUrl { get; set; }

    public string Button { get; set; }
}
```

> var context = await _interaction.GetAuthorizationContextAsync(Input.ReturnUrl);

与えられたInput.ReturnUrlが現在の認証/認可リクエストのコンテキストの一部であるかどうかを確認している。

[HostingExtensions.cs](https://github.com/DuendeSoftware/Samples/blob/main/IdentityServer/v6/Quickstarts/2_InteractiveAspNetCore/src/IdentityServer/HostingExtensions.cs#L17C13-L17C48)で`.AddInMemoryClients(Config.Clients)`を設定しているとおもうが、Config.Clientsの[RedirectUris](https://github.com/DuendeSoftware/Samples/blob/3ac92c3ebf892e6c07fce4b47140fd525a30a7b4/IdentityServer/v6/Quickstarts/2_InteractiveAspNetCore/src/IdentityServer/Config.cs#L58) プロパティに登録されている値と検証して、一致すれば[AuthorizationRequest](https://identityserver4.readthedocs.io/en/latest/reference/interactionservice.html#authorizationrequest)オブジェクトが返却される感じだ。ReturnUrlが一致しなければ、GetAuthorizationContextAsyncの戻りはNULLになる。

> await _interaction.DenyAuthorizationAsync(context, AuthorizationError.AccessDenied);
ユーザーが認可プロセスをキャンセルした場合に、IdentityServerにその事実を通知し、結果的にクライアントに適切なエラーレスポンスを返すためのもの

> await HttpContext.SignInAsync(isuser);

ASP.NET Coreの認証システムを使用してユーザーを認証（サインイン）させています。
SignInAsyncメソッドは、指定されたユーザー情報を使用して現在のHTTPコンテキストに対してユーザーを認証します。
この操作の結果、認証されたユーザーに関する情報がクッキーなどの形でクライアントに送信され、
次回のリクエストでそのユーザーが認証されていることが認識されるようになります。
Cookieに`idsrv`で[登録](https://github.com/IdentityServer/IdentityServer4/blob/main/src/IdentityServer4/src/IdentityServerConstants.cs#L15)される。（カスタムは可能


### 元ネタ

- [github quickstart2](https://github.com/DuendeSoftware/Samples/blob/main/IdentityServer/v6/Quickstarts/2_InteractiveAspNetCore/src/IdentityServer/IdentityServer.csproj)
- [duende公式サイト][IdentityServer communityedition](https://duendesoftware.com/products/communityedition)