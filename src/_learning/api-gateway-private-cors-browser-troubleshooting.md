---
title: "ブラウザからAPI Gateway（Private）へリクエスト時のCORSとHostヘッダ制約の対処法"
date: 2025-6-13T10:00:00
mermaid: true
weight: 7
tags:
  - AWS
  - API Gateway
  - CORS
  - VPC
  - ALB
  - PrivateLink
  - Direct Connect
description: "AWS環境でPrivate API Gatewayを利用する際に直面するCORSとHostヘッダ制約の問題とその対処法について解説します。モバイルとブラウザクライアント両対応の構成例を紹介。"
---

AWS環境でプライベートなAPI Gatewayを構成し、オンプレミス環境からのアクセスをDirect Connect経由で実現している中で、モバイルやブラウザクライアントとの連携において `CORS` や `Host` ヘッダに関する問題に直面しました。本記事では、その問題と対応方法についてまとめます。

---

## システム構成

構成は以下の通りです：

```
(on-premises) Client 
  ↓
Direct Connect
  ↓
VPC
  ↓
ALB（Internal）
  ↓
PrivateLink (VPCe)
  ↓
API Gateway（Private）
  ↓
Lambda
```

当初、モバイルアプリからの利用のみを前提としており、Client は API Gateway に対して `Host` ヘッダを明示的に付与していました。

```bash
curl -H 'host: {private-api-gateway-domain}' \
  https://{ALB-Domain}/{path}
```

ここで `{private-api-gateway-domain}` は `https://{api-gateway-id}.execute-api.{region}.amazonaws.com` の形式です。

---

## 問題：ブラウザではHostヘッダが拒否される

この構成でモバイルからは問題なくアクセスできていましたが、ブラウザから同様のリクエストを行うと、以下のようなエラーが発生しました。

```
Refused to set unsafe header "Host"
```

ブラウザはセキュリティ上の制約により `Host` ヘッダの上書きを禁止しています。このため、ALBを経由して `Host` を書き換える方式ではブラウザ対応ができません。

---

## 解決を試みた別アプローチ：ALBを経由せずに直接API Gatewayへ

AWS公式ドキュメント（[How do I connect to a private API Gateway over a Direct Connect connection?](https://repost.aws/knowledge-center/direct-connect-private-api-gateway)）を参考に、ALBを経由せずにPrivate API Gatewayへアクセスする方法を試しました。

```bash
curl https://{apigateway-id}.execute-api.{region}.amazonaws.com/{path}

# または

curl -H 'x-apigw-api-id: {apigateway-id}' \
  https://vpce-{vpce-dns}.execute-api.{region}.vpce.amazonaws.com/{path}
```

この方式でCURLなどからのリクエストは成功します。

---

## 問題：CORSエラーが発生

ただし、ブラウザで上記のようにリクエストを送ると次のような CORS エラーが発生しました。

```
Access to fetch at 'https://api.example.com/data' from origin 'https://frontend.example.com' 
has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

プライベートAPI Gatewayのエンドポイントはブラウザにとって外部ドメインであるため、CORS制約が発生します。

---

## 最終的な解決策

そこで最終的に以下のような構成に変更しました：

* ALB を経由する
* `Host` ヘッダは使わず
* 代わりに `x-apigw-api-id` を付与する

```bash
curl -H 'x-apigw-api-id: {apigateway-id}' \
  https://{ALB-Domain}/{path}
```

これにより：

* ブラウザが拒否する `Host` ヘッダの設定が不要
* リクエストドメインが同一であるため CORS が発生しない

という2つの課題を同時に解決できました。

---

## 学びと振り返り

普段あまり意識せずに `Host` ヘッダを指定していたのですが、ブラウザの制約を受けることは知りませんでした。また、Private API GatewayとCORSの相性の悪さにも改めて気づかされました。

結果として、`x-apigw-api-id` を使う方式とALBの組み合わせが、モバイルとブラウザ両方に対応可能なベストプラクティスのひとつだと感じました。

---

## おわりに

Private API Gateway + Direct Connect + PrivateLink という構成で、Client がブラウザの場合の落とし穴と、その回避策を紹介しました。同様の構成を検討している方の参考になれば幸いです。
