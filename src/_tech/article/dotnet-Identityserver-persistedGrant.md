---
title: "IdentitySeverのER図PersistedGrantDb編"
date: 2023-11-11T07:15:00
weight: 4
mermaid: true
categories:
  - tech
  - oauth
  - csharp
  - dotnet
---

[Persisted Grant Store](https://docs.duendesoftware.com/identityserver/v6/reference/stores/persisted_grant_store/)

## IPersistedGrantStoreについて

### IPersistedGrantStoreとは何か？

IPersistedGrantStoreは、特定の認証情報（グラント）を管理するためのシステムの一部です。ここでの「グラント」とは、ユーザーやアプリケーションが特定の操作を行うための許可証のようなものです。

### どのように機能するか？

このインターフェースは、グラントの保存、取得、削除を行う方法を定義しています。具体的には、ユーザーがログインしたり、アプリがデータにアクセスするために必要な「トークン」のようなものを管理します。

### さまざまなタイプのグラント

IPersistedGrantStoreは、さまざまな種類のグラントをサポートしています。これには、ログイン時に使用される「認可コード」や、セッションの継続に使用される「リフレッシュトークン」、さらにはユーザーの同意情報やリファレンストークンなどが含まれます。

### 実装の種類

IdentityServerでは、二つの主要なIPersistedGrantStoreの実装があります。

1. **InMemoryPersistedGrantStore**：これはメモリ内にグラントを保存します。主にテストやデモのために使用され、実際の運用環境では使われません。
2. **Duende.IdentityServer.EntityFramework.Stores.PersistedGrantStore**：これはEntityFrameworkを使ってデータベースにグラントを保存します。実際の運用環境での使用に適しています。

### カスタマイズ可能性

自分自身でIPersistedGrantStoreの実装を作ることもできます。これにより、特定のデータストアをサポートしたり、環境やニーズに合わせてデータアクセスを最適化することが可能になります。

## Duende.IdentityServer.Stores.IPersistedGrantStore

Duendeの実装は[こちら](https://github.dev/DuendeSoftware/IdentityServer/blob/4ac7e461091b549ab0a79eb037c68f59a94e74a9/src/EntityFramework.Storage/Stores/PersistedGrantStore.cs#L24-L25)

`IPersistedGrantStore`は、特定のグラント（認証情報）を管理するインターフェースです。以下はその主要なメソッドです。

- **StoreAsync(PersistedGrant grant)**: グラントを保存します。
- **GetAsync(string key)**: キーに基づいてグラントを取得します。
- **GetAllAsync(PersistedGrantFilter filter)**: 特定のフィルター条件に合致するすべてのグラントを取得します。
- **RemoveAsync(string key)**: キーに基づいてグラントを削除します。
- **RemoveAllAsync(PersistedGrantFilter filter)**: 特定のフィルター条件に合致するすべてのグラントを削除します。

## Duende.IdentityServer.Models.PersistedGrant

`PersistedGrant`は、グラントの情報を格納するモデルです。以下はその主要なプロパティです。

- **Key**: グラントを一意に識別する文字列。
- **Type**: グラントのタイプを指定する文字列。`PersistedGrantTypes`クラスの定数が使用されます。
- **SubjectId**: 認証を与えた主体の識別子。
- **SessionId**: グラントが作成されたセッションの識別子（該当する場合）。
- **ClientId**: 認証を受けたクライアントの識別子。
- **Description**: 認証されるデバイスにユーザーが割り当てた説明。
- **CreationTime**: グラントが作成された時間。
- **Expiration**: グラントの有効期限。
- **ConsumedTime**: グラントが使用された時間。
- **Data**: グラントのシリアライズされ、データ保護された表現。

## PersistedGrantFilter

`PersistedGrantFilter`クラスは、永続的なグラントストアへのアクセス時に使用されるフィルタリング条件を定義します。

```csharp
public class PersistedGrantFilter
{
    /// <summary>
    /// ユーザーのSubject id。
    /// </summary>
    public string SubjectId { get; set; }
    
    /// <summary>
    /// グラントに使用されたSession id。
    /// </summary>
    public string SessionId { get; set; }
    
    /// <summary>
    /// グラントが発行されたClient id。
    /// </summary>
    public string ClientId { get; set; }

    /// <summary>
    /// グラントが発行されたClient ids。
    /// </summary>
    public IEnumerable<string> ClientIds { get; set; }

    /// <summary>
    /// グラントのタイプ。
    /// </summary>
    public string Type { get; set; }

    /// <summary>
    /// グラントのタイプ。
    /// </summary>
    public IEnumerable<string> Types { get; set; }
}
```

## PersistedGrantTypes

`PersistedGrantTypes`クラスは、IdentityServerで定義されている永続的なグラントのタイプを指定します。

```csharp
public static class PersistedGrantTypes
{
    public const string AuthorizationCode = "authorization_code";
    public const string BackChannelAuthenticationRequest = "ciba";
    public const string ReferenceToken = "reference_token";
    public const string RefreshToken = "refresh_token";
    public const string UserConsent = "user_consent";
    public const string DeviceCode = "device_code";
    public const string UserCode = "user_code";
}
```
