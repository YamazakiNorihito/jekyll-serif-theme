---
title: "OAuth徹底入門(5)"
date: 2024-12-06T17:04:00
jobtitle: "Keycloak RestAPI"
linkedinurl: ""
weight: 7
tags:
  - OAuth
  - Keycloak
  - JWT Claims
  - REST API Security
  - Authentication
  - Authorization
  - Access Token
  - Security Best Practices
description: "Keycloak REST APIでのJWTクレーム（iss, sub, aud, exp等）の役割と構造を理解し、OAuth認証とトークン管理における実践的な使い方を学びます。"
---


## JWT クレーム

| クレーム名 | クレームの内容 |
|------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| `iss`      | トークンの発行者（Issuer）。「誰がこのトークンを発行したのか」を示すものであり、URLが使われることが多い。このクレームには文字列が設定される。 |
| `sub`      | トークンの対象者（Subject）。「このトークンが誰を表現しているのか」を示すものであり、リソース所有者を一意に識別する識別子が設定される。 |
| `aud`      | トークンの受取手（Audience）。「誰がこのトークンを受け取ることを想定しているのか」を示すものであり、トークンが送られる保護対象リソースのURLが1つまたは複数設定されることが多い。 |
| `exp`      | トークンの有効期限（Expiration Time）。トークンの有効期限を示すものであり、UNIXエポックを基準とした秒数で表す整数値が設定される。 |
| `nbf`      | トークンの発効開始時刻（Not-Before）。「いつからトークンが有効になるのか」を示すものであり、トークンが有効になる前に発行するような使い方をする場合に利用される。UNIXエポックを基準とした秒数で表す整数値が設定される。 |
| `iat`      | トークンの発行時タイムスタンプ（Issued At）。「いつトークンが生成されたのか」を示すものであり、UNIXエポックを基準とした秒数で表す整数値が設定される。 |
| `jti`      | トークンの一意識別子（JWT ID）。発行者によって生成されたトークンごとに一意となる値。リプレイ攻撃を防ぐ目的で利用される。 |

```json
{
  "iss": "https://example.com",
  "sub": "user12345",
  "aud": "https://api.example.com",
  "exp": 1712345678,
  "nbf": 1712345600,
  "iat": 1712345600,
  "jti": "abc123def456ghi789"
}
{
  "iss": "https://example.com",
  "sub": "user12345",
  "aud": ["https://api.example.com", "https://another-api.example.com"],
  "exp": 1712345678,
  "nbf": 1712345600,
  "iat": 1712345600,
  "jti": "abc123def456ghi789"
}
```

- iss (Issuer): トークンを発行した主体を表します。この例では <https://example.com。>
- sub (Subject): トークンの対象となるユーザーを表します。この例では user12345。
- aud (Audience): トークンが意図されている受信者を表します。この例では <https://api.example.com。>
- exp (Expiration Time): トークンの有効期限をUNIXタイムスタンプで指定。この例では 1712345678 (例: 2024年5月の日時)。
- nbf (Not Before): この時刻より前にトークンを使用できないことを示します。この例では 1712345600。
- iat (Issued At): トークンが発行された時刻を表します。この例では 1712345600。
- jti (JWT ID): トークンの一意識別子。リプレイ攻撃を防ぐために使用されます。この例では abc123def456ghi789。
