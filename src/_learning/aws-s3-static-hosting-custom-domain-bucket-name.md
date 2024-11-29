---
title: "Amazon S3で静的ウェブサイトをホスティングする際のCustom DomainとBucket Nameのなぜ一致させるのか考えてみた"
date: 2024-11-29T05:33:00
mermaid: true
weight: 7
tags:
  - AWS
description: ""
---

Amazon S3を利用して静的なWebサイトを公開する際、Custom Domain（例: `www.example.com`）を使いたいことが多いでしょう。この場合、Route 53の特有の機能である`Alias`レコードを使って、Custom DomainからS3の公開エンドポイントに名前解決を設定することが多いと思います。

公式ドキュメントでは、「バケット名をCustom Domain名と一致させるべき」と書かれています。その理由について私が理解した内容と推測を交え、このブログで詳しく解説します。

## **結論: バケット解決の鍵はHost Header**

S3の静的ウェブサイトホスティングは、HTTPリクエストの**Host Header**を基にバケットを解決します。

- **S3の公開IPアドレスはリージョン内で共有されている**  
  S3で公開される静的ウェブサイトは、特定のリージョン内で共有IPアドレスを使用していると考えられます。これにより、複数のバケットが同じIPアドレスを使ってホスティングされます。

- **Host Headerを使ったリソース解決の流れ**  
  1. リクエストがS3の共有IPアドレスに到達します。
  2. リクエスト内のHost Header（例: `Host: www.example.com`）が解析されます。
  3. Host Headerがバケット名として解釈され、対応するバケットが選択されます。

つまり、**Custom Domain名とバケット名が一致していないと、S3はどのバケットに対応するリクエストかを正しく判断できません**。

---

## **S3のCustom DomainとBucket Nameの関係**

S3の静的ウェブサイトホスティングでCustom Domainを設定する際、ドキュメントにも以下の記述があります。

1. **Aliasレコードとバケット名の一致**
   > For example, you can create an alias record named `acme.example.com` that redirects queries to an Amazon S3 bucket that is also named `acme.example.com`.  
   ([Choosing between alias and non-alias records](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/resource-record-sets-choosing-alias-non-alias.html))

   この記述は、Aliasレコードを使う場合にバケット名とドメイン名の一致が必要であることを明確に述べています。

2. **ウェブサイトエンドポイントのフォーマット**
   > If you registered the domain `www.example-bucket.com`, you could create a bucket `www.example-bucket.com`, and add a DNS CNAME record that points to `www.example-bucket.com.s3-website.Region.amazonaws.com`.  
   ([Website endpoints](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteEndpoints.html))

   Custom Domainを登録した場合、そのドメイン名と一致するバケットを作成し、公開エンドポイントとして設定する方法が推奨されています。

---

## **S3のホスティング構造（推測）**

上記の記述を基に、S3のホスティング構造を推測すると次のような流れになります：

1. **DNS解決**  
   Custom Domain（例: `www.example.com`）からAliasレコードを使い、S3の公開エンドポイント（例: `www.example.com.s3-website-ap-northeast-1.amazonaws.com`）に解決します。

2. **共有IPアドレスへの到達**  
   リクエストはS3のリージョン内の共有IPアドレスに到達します。このIPアドレスは複数のS3バケットで共有されています。

3. **Host Headerによるバケット解決**  
   リクエスト内のHost Header（例: `Host: www.example.com`）が参照され、S3が適切なバケットを選択して応答します。

---

## **実際のドメイン設定例**

以下は、Custom Domain（`www.example.com`）を使ってS3バケットを公開する具体例です。

### **1. バケット作成**

バケット名を`www.example.com`と設定して作成します。バケット名はCustom Domain名と完全に一致させる必要があります。

### **2. バケットポリシーの設定**

S3で静的ウェブサイトをホストするには、公開アクセスを許可するバケットポリシーを設定します。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::www.example.com/*"
    }
  ]
}
```

### **3. Route 53のAliasレコードを設定**

1. Route 53でホストゾーンを作成。
2. エイリアスレコードを次のように設定：
   - **名前**: `www.example.com`
   - **タイプ**: `A`
   - **ターゲット**: `www.example.com.s3-website-ap-northeast-1.amazonaws.com`

---

## **まとめ**

S3で静的ウェブサイトをCustom Domainでホスティングする場合、バケット名とドメイン名を一致させる必要があります。その理由は、S3がHTTPリクエストのHost Headerを使用してバケットを解決しているためです。この設計は、共有IPアドレス上で複数のバケットを効率的に運用するためのものであり、S3のホスティング環境における基盤的な仕組みと言えます。

Custom Domainを利用した静的ウェブサイトホスティングを設定する際は、この要件を理解した上で正確に構築しましょう。
