---
title: "RFC 7516 JWE の主要なところを読んでみた。"
date: 2024-10-29T10:34:00
jobtitle: "Graphic Designer"
linkedinurl: ""
weight: 7
tags:
   - RFC 7516
   - JWE
   - JSON Web Encryption
   - セキュリティ
   - 暗号化
   - AEAD
   - ヘッダー
   - シリアライゼーション
description: "RFC 7516 JWE の内容を簡単にまとめたメモです。"
---

## 用語

Authenticated Encryption with Associated Data (AEAD):  
AEADは、暗号化とデータの改ざんチェックを同時に行う仕組みです。  
平文（plaintext）と付加認証データ（AAD）を入力し、暗号文(ciphertext)と認証タグ(Authentication Tag)を出力します。  
これにより、データの機密性と完全性が一体化して保証されます。

**例え話**  
手紙を暗号化して人に送るための手順

AEADはこうなる：  

- 手紙を暗号化して封筒に入れる。  
- 封筒に「改ざんチェック用のシール」を貼る。  
- 誰かが封筒を開けたり中身を変えると、シールが破れて「改ざんされた！」とわかる。

Additional Authenticated Data (AAD):
AEAD 操作において「暗号化はしないが、改ざん防止のために認証処理で使用されるデータ項目」

Authentication Tag:

AEAD 操作の出力として生成されるタグです。暗号文（ciphertext）と追加認証データ（AAD）が改ざんされていないことを保証するための情報です。
一部のアルゴリズムでは Authentication Tag を使用しない場合があり,その場合、空のデータ

 Content Encryption Key (CEK):
 AEADアルゴリズムで平文を暗号化し、認証タグを生成するために使われる対称鍵

JWE Encrypted Key:
CEKを暗号化した値

JWE Initialization Vector:

平文を暗号化する際に使用される値で、同じ平文から同じ暗号文が生成されるのを防ぐために使われます。

## JWEのシリアライゼーション形式

### シリアライゼーション形式

1. **JWE Compact Serialization**
   - URL安全なシリアライゼーション形式
2. **JWE JSON Serialization**
   - JSON形式のシリアライゼーション

## JWE Compact Serialization

### 特徴

- JWE Compact Serializationでは以下のヘッダーは使用されません：
  - **JWE Shared Unprotected Header**
  - **JWE Per-Recipient Unprotected Header**
- [JOSE Header](https://datatracker.ietf.org/doc/html/rfc7515#section-4)と`JWE Protected Header`は同一のものとして扱われます。
- 暗号化コンテンツをコンパクトでURL安全な文字列として表現します。
- **一つの受信者**のみサポートします。

### 表現形式

JWE Compact Serializationは次の形式で表現されます：

```txt
  BASE64URL(UTF8(JWE Protected Header)) || '.' ||
  BASE64URL(JWE Encrypted Key) || '.' ||
  BASE64URL(JWE Initialization Vector) || '.' ||
  BASE64URL(JWE Ciphertext) || '.' ||
  BASE64URL(JWE Authentication Tag)
```

## JWE JSON Serialization

### 特徴

- **1つ以上**の以下のヘッダーが必須です：
  - **JWE Protected Header**
  - **JWE Shared Unprotected Header**
  - **JWE Per-Recipient Unprotected Header**
- `JOSE Header`は以下のヘッダーのメンバーの和集合として定義されます：
  - JWE Protected Header
  - JWE Shared Unprotected Header
  - JWE Per-Recipient Unprotected Header
- **複数受信者**をサポートしており、複数の受信者に暗号文を送ることができます。

### 表現形式

JWE JSON SerializationはJSONオブジェクトで表現され、以下のメンバーを含む場合があります（すべて必須ではありません）：

| メンバー名          | 値の内容                                                |
|---------------------|--------------------------------------------------------|
| `"protected"`       | `BASE64URL(UTF8(JWE Protected Header))`               |
| `"unprotected"`     | `JWE Shared Unprotected Header`                        |
| `"header"`          | `JWE Per-Recipient Unprotected Header`                |
| `"encrypted_key"`   | `BASE64URL(JWE Encrypted Key)`                         |
| `"iv"`              | `BASE64URL(JWE Initialization Vector)`                |
| `"ciphertext"`      | `BASE64URL(JWE Ciphertext)`                            |
| `"tag"`             | `BASE64URL(JWE Authentication Tag)`                   |
| `"aad"`             | `BASE64URL(JWE AAD)`                                  |

## JOSE Header for JWE

JWEのJose Headerは以下の項目がある。(パラメータ名は一意でなければならない)

- alg
  - Algorithm
  - CEK（Content Encryption Key）の暗号化アルゴリズムを指定。
  - サポートされていないアルゴリズムは利用不可。
    - アルゴリズムの値はIANAの「[JSON Web Signature and Encryption Algorithms](https://datatracker.ietf.org/doc/html/rfc7518#section-3.1)」レジストリで定義。
- enc
  - Encryption Algorithm
  - plaintextを暗号化して`ciphertext`と`Authentication Tag`を生成するためのコンテンツ暗号化アルゴリズムを指定。
  - サポートされていないアルゴリズムは利用不可。
    - 値はIANAの「[JSON Web Signature and Encryption Algorithms](https://datatracker.ietf.org/doc/html/rfc7518#section-5.1)」レジストリで定義されているか、Collision-Resistant Nameでなければならない。
      - Collision-Resistant Nameとは、他の名前と衝突しない一意な名前であり、通常はURL形式（例: example.com/custom-enc）を用いて定義される。
  - このパラメータは必須
- zip
  - Compression Algorithm
  - 暗号化前に平文（plaintext）に適用される圧縮アルゴリズムを指定。
    - 例: "DEF"（DEFLATEアルゴリズム）
  - 値はIANAの「[JSON Web Encryption Compression Algorithms](https://datatracker.ietf.org/doc/html/rfc7518#section-7.3.2)」レジストリで定義。
  - zipが指定されていない場合、圧縮は行われない。
  - このパラメータは任意だが、圧縮を使用する場合はJWE Protected Header内で定義し、完全性を保護する必要がある。
- jku
  - JWK Set URL
  - `CKE`の暗号化に使用された公開鍵を含むJWK（JSON Web Key）セットのURLを指定。
  - このURLにアクセスすることで、`CKE`の暗号化に使用された公開鍵を取得し、復号に必要な秘密鍵を特定可能。
- jwk
  - JSON Web Key
  - CKEに暗号化された公開鍵を指定するためのパラメータ。
  - 復号に必要な秘密鍵を特定するために使用。
- kid
  - Key ID
  - CKE（Client Key Exchange）に暗号化された公開鍵を一意に識別するためのパラメータ。
  - 秘密鍵を保持する側が鍵を変更した場合、その変更を明示的に公開鍵を使用する側（受信者）に通知する手段を提供する。
- x5u
  - 現状必要性がないため理解をSkip
- x5c
  - 現状必要性がないため理解をSkip
- x5t
  - 現状必要性がないため理解をSkip
- type
  - Type
  - JWEを使う場合は"JWE"で固定
- cty
  - Content Type
  - plaintextのContentTypeを表します。
- crit
  - Critical
  - JWSのためのヘッダーパラメータで、拡張項目に関するパラメータを指定するために使用されます。
  - 受信者が理解・処理できない値が設定されている場合、そのJWSは**無効（invalid）**と見なされます。
    - 詳細については[rfc7515#section-4.1.11](https://datatracker.ietf.org/doc/html/rfc7515#section-4.1.11)を参照

## Producing and Consuming JWEs

### Message Encryption Steps

1. CKE を暗号化するアルゴリズムを決定
   1. アルゴリズムは、JWE ヘッダーの "alg" パラメータで指定されます。
   2. サポートされるアルゴリズムは[rfc7518#section-4.1](https://datatracker.ietf.org/doc/html/rfc7518#section-4.1)を参照
2. CEK の生成
   1. Key Wrapping、Key Encryption、または Key Agreement with Key Wrapping を使用する場合：
      1. CEK はランダムな値として生成されます。
      2. CEK の長さは、JWE ヘッダーの "enc" パラメータで指定されたコンテンツ暗号化アルゴリズムの要件に従います。
   2. Direct Key Agreement の場合:
      1. 共通鍵（agreed upon key）を CEK として直接使用する。
3. CEKの暗号化
   1. Key Wrapping、Key Encryption、または Key Agreement with Key Wrapping を使用する場合：
      1. 鍵を使ってCEKを暗号化してJWE Encrypted Key を生成
   2. Direct Key Agreement または Direct Encryption を使用する場合:
      1. JWE Encrypted Key を空文字とする。
4. JWE Encrypted Key のエンコード
   1. JWE Encrypted Key を BASE64URL エンコードして、エンコード値を生成。
5. JWE Initialization Vectorの生成
   1. ランダムな値
   2. 長さは、JWE ヘッダーの "enc" パラメータで指定されたコンテンツ暗号化アルゴリズムの要件に従います。
6. JWE Initialization Vector のエンコード
   1. BASE64URL エンコードして、エンコード値を生成。
7. plaintextの圧縮（任意）
    1. "zip" パラメータがある場合、そのアルゴリズムで平文を圧縮し、結果を `M` とする。
    2. "zip" パラメータがない場合、`M` は平文そのままとする。
8. JOSE ヘッダの作成
   1. JWE Protected Header、JWE Shared Unprotected Header、JWE Per-Recipient Unprotected Header に含めるパラメータを設定し、JSON オブジェクトを作成する。
9. JWE Protected Header のエンコード(Encoded Protected Header)
   1. JWE Protected Header を BASE64URL エンコードして、エンコード値を生成。
10. Additional Authenticated Data (AAD) の設定
    1. Compact Serializationの場合
       1. AAD=ASCII(Encoded Protected Header)として設定する。
    2. JSON Serializationの場合
       1. JWE AAD値が存在しない場合
          1. AAD=ASCII(Encoded Protected Header)として設定する。
       2. JWE AAD値が存在する場合
          1. AAD=ASCII(BASE64URL(UTF8(JWE Protected Header)) || '.' || BASE64URL(UTF8(JWE AAD)))
          2. ユーザーがaadフィールドに値を設定することはできますが、最終的にAADはProtected Headerとaadの値を結合した形で生成されます
11. コンテンツ暗号化
    1. CEK、JWE Initialization Vector、および AAD を用いて、コンテンツ暗号化アルゴリズムで M を暗号化し、JWE Ciphertext と JWE Authentication Tag（認証タグ）を得る。
12. JWE Ciphertext のエンコード
    1. JWE Ciphertext を BASE64URL エンコードする。
13. JWE Authentication Tag のエンコード
    1. JWE Authentication Tag を BASE64URL エンコードする。
14. AAD のエンコード(ある場合)
    1. AAD がある場合
    2. JWE AAD を BASE64URL エンコードする。
15. シリアライゼーション出力の生成
    1. Compact Serialization: BASE64URL(UTF8(JWE Protected Header)) || '.' || BASE64URL(JWE Encrypted Key) || '.' || BASE64URL(JWE Initialization Vector) || '.' || BASE64URL(JWE Ciphertext) || '.' || BASE64URL(JWE Authentication Tag)
    2. JWE JSON Serialization: Section 7.2 を参照。

**補足**

- JWE JSON Serialization の場合:
  - 各受信者に対して、上記プロセス（ステップ 1～4）を繰り返す。

### Message Decryption Steps

1. Parse the JWE
   1. Compact Serializationの場合
      1. エンコードされたコンポーネントをピリオド（.）区切りで抽出します。順序は以下の通りです：
         1. BASE64URL(UTF8(JWE Protected Header))
         2. BASE64URL(JWE Encrypted Key)
         3. BASE64URL(JWE Initialization Vector)
         4. BASE64URL(JWE Ciphertext)
         5. BASE64URL(JWE Authentication Tag)
   2. JSON Serializationの場合
      1. json形式は以下のように構成されて送られてくるはず
         1. BASE64URL(UTF8(JWE Protected Header))
         2. JWE Shared Unprotected Header
         3. JWE Per-Recipient Unprotected Header
         4. BASE64URL(JWE Encrypted Key)
         5. BASE64URL(JWE Initialization Vector)
         6. BASE64URL(JWE Ciphertext)
         7. BASE64URL(JWE Authentication Tag)
         8. BASE64URL(JWE AAD)
2. Base64url decode
   1. step1のBASE64URLを全てDecodeする
3. Verify JOSE Header
   1. 有効なJSONオブジェクトであることを検証
   2. JOSE Headerに重複した`Header Parameter name`が含まれていないことを確認する
   3. Compact Serializationの場合
      1. JOSE Header=JWE Protected Header
   4. JSON Serializationの場合
      1. JOSE Header=JWE Protected Header + JWE Shared Unprotected Header + JWE Per-Recipient Unprotected Header
4. Verify Required Fields and Algorithm Support
   1. 実装がサポートすべきすべてのフィールドを理解し処理できることを確認する。
   2. "crit" Header Parameter の値もサポートされていることを確認する。
5. CEK復号アルゴリズムを決定
   1. JOSEヘッダーの "alg" (algorithm) パラメーターに基づいてCEK（Content Encryption Key）の管理アルゴリズムを決定する。
6. Determine and Validate CEK
   1. JWE Encrypted Keyを使用してCEKを取得
      1. 適切な鍵を使い、JWE Encrypted Keyを復号してCEKを取得する。
   2. Direct Key Agreement
      1. 合意された秘密鍵がそのままCEKとなる
      2. JWE Encrypted Keyは空でなければならない。
   3. Key Agreement with Key Wrapping
      1. 共有鍵で生成された秘密鍵を使用して、JWE Encrypted Keyを復号しCEKを取得する。
   4. Key WrappingまたはKey Encryption
      1. 公開鍵に対応する秘密鍵を使い、JWE Encrypted Keyを復号してCEKを取得する。
7. Additional Authenticated Data (AAD) の設定
   1. AAD を Encoded Protected Header の ASCII 値とする。
   2. JWE AAD が存在する場合、AAD = ASCII(Encoded Protected Header || '.' || BASE64URL(JWE AAD)) とする。
8. Ciphertextの復号
   1. `CEK`,`JWE Initialization Vector`,`Additional Authenticated Data`,`Authentication Tag`を使用してplaintextに復号化
   2. 認証タグを検証する。不正な場合は復号した文字列の出力をrejectする。
9. uncompress
   1. JOSEヘッダーに`zip`が含まれる場合
      1. compression algorithmに従って、文字を元に戻す
10. 復号結果の判定
    1. 全受信者に対する復号処理がいずれも成功しなかった場合、JWEを無効とみなす
    2. 少なくとも一つの受信者に対して復号が成功した場合は、その平文を出力する。
    3. JWE JSON Serializationの場合には、復号が成功した受信者と失敗した受信者情報もアプリケーションへ返す
