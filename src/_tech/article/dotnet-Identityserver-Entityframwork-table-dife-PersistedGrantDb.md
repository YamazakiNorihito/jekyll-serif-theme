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
description: ""
---

[Table定義](DuendeSoftware/IdentityServer/migrations/IdentityServerDb/Migrations/PersistedGrantDb/PersistedGrantDbContextModelSnapshot.cs)を書き起こしてみた

### DeviceCodes テーブル

| 列名          | データ型        | 必須 | 説明          |
|---------------|-----------------|------|---------------|
| UserCode      | nvarchar(200)   | Yes  | ユーザーコード  |
| DeviceCode    | nvarchar(200)   | Yes  | デバイスコード  |
| SubjectId     | nvarchar(200)   | No   | 主題ID        |
| SessionId     | nvarchar(100)   | No   | セッションID   |
| ClientId      | nvarchar(200)   | Yes  | クライアントID |
| Description   | nvarchar(200)   | No   | 説明          |
| CreationTime  | datetime2       | Yes  | 作成時間      |
| Expiration    | datetime2       | Yes  | 有効期限      |
| Data          | nvarchar(max)   | Yes  | データ        |

主キー制約: PK_DeviceCodes (UserCode)

| インデックス名                            | 列          | 説明                          |
|------------------------------------------|-------------|-------------------------------|
| IX_DeviceCodes_DeviceCode                | [DeviceCode]| デバイスコードに関するユニークインデックス |
| IX_DeviceCodes_Expiration                | [Expiration]| 有効期限に関するインデックス           |

### Keys テーブル

| 列名             | データ型         | 必須 | 説明        |
|------------------|------------------|------|-------------|
| Id               | nvarchar(450)    | Yes  | ID          |
| Version          | int              | Yes  | バージョン   |
| Created          | datetime2        | Yes  | 作成日      |
| Use              | nvarchar(450)    | No   | 用途        |
| Algorithm        | nvarchar(100)    | Yes  | アルゴリズム |
| IsX509Certificate| bit              | Yes  | X509証明書  |
| DataProtected    | bit              | Yes  | データ保護   |
| Data             | nvarchar(max)    | Yes  | データ      |

主キー制約: PK_Keys (Id)

| インデックス名                          | 列      | 説明                    |
|----------------------------------------|---------|-------------------------|
| IX_Keys_Use                            | [Use]   | 用途に関するインデックス |

### PersistedGrants テーブル

| 列名          | データ型         | 必須 | 説明          |
|---------------|------------------|------|---------------|
| Id            | bigint           | Yes  | ID            |
| Key           | nvarchar(200)    | No   | キー          |
| Type          | nvarchar(50)     | Yes  | タイプ        |
| SubjectId     | nvarchar(200)    | No   | 主題ID        |
| SessionId     | nvarchar(100)    | No   | セッションID   |
| ClientId      | nvarchar(200)    | Yes  | クライアントID |
| Description   | nvarchar(200)    | No   | 説明          |
| CreationTime  | datetime2        | Yes  | 作成時間      |
| Expiration    | datetime2        | No   | 有効期限      |
| ConsumedTime  | datetime2        | No   | 使用時間      |
| Data          | nvarchar(max)    | Yes  | データ        |

主キー制約: PK_PersistedGrants (Id)

|-------------------------------------------------|------------------------------|---------------------------------------------|
| IX_PersistedGrants_ConsumedTime                 | ConsumedTime                 | 消費時間に関するインデックス                    |
| IX_PersistedGrants_Expiration                   | Expiration                   | 有効期限に関するインデックス                    |
| IX_PersistedGrants_Key                          | Key                          | キーに関する一意のインデックス（Key IS NOT NULL） |
| IX_PersistedGrants_SubjectId_ClientId_Type      | SubjectId, ClientId, Type    | 主題ID、クライアントID、タイプに関するインデックス  |
| IX_PersistedGrants_SubjectId_SessionId_Type     | SubjectId, SessionId, Type   | 主題ID、セッションID、タイプに関するインデックス   |

### PushedAuthorizationRequests  テーブル

| 列名                | データ型        | 必須 | 説明               |
|---------------------|-----------------|------|--------------------|
| Id                  | bigint          | Yes  | ユニークな識別子   |
| ReferenceValueHash  | nvarchar(64)    | Yes  | 参照値ハッシュ     |
| ExpiresAtUtc        | datetime2       | Yes  | 有効期限 (UTC)     |
| Parameters          | nvarchar(max)   | Yes  | パラメータ         |

主キー制約: PK_PushedAuthorizationRequests (Id)

| インデックス名                                      | 列                    | 説明                                   |
|----------------------------------------------------|-----------------------|----------------------------------------|
| IX_PushedAuthorizationRequests_ReferenceValueHash  | ReferenceValueHash    | 参照値ハッシュに関する一意のインデックス |

### ServerSideSessions テーブル

| 列名          | データ型        | 必須 | 説明               |
|---------------|-----------------|------|--------------------|
| Id            | bigint          | Yes  | ユニークな識別子   |
| Key           | nvarchar(100)   | Yes  | キー               |
| Scheme        | nvarchar(100)   | Yes  | スキーム           |
| SubjectId     | nvarchar(100)   | Yes  | 主題ID             |
| SessionId     | nvarchar(100)   | No   | セッションID       |
| DisplayName   | nvarchar(100)   | No   | 表示名             |
| Created       | datetime2       | Yes  | 作成日             |
| Renewed       | datetime2       | Yes  | 更新日             |
| Expires       | datetime2       | No   | 有効期限           |
| Data          | nvarchar(max)   | Yes  | データ             |

主キー制約: PK_ServerSideSessions (Id)

| インデックス名                              | 列            | 説明                              |
|--------------------------------------------|---------------|-----------------------------------|
| IX_ServerSideSessions_DisplayName          | DisplayName   | 表示名に関するインデックス          |
| IX_ServerSideSessions_Expires              | Expires       | 有効期限に関するインデックス        |
| IX_ServerSideSessions_Key                  | Key           | キーに関する一意のインデックス      |
| IX_ServerSideSessions_SessionId            | SessionId     | セッションIDに関するインデックス    |
| IX_ServerSideSessions_SubjectId            | SubjectId     | 主題IDに関するインデックス          |
