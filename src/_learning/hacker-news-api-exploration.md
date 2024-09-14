---
title: "HackerNewsAPIExploration探索"
date: 2023-11-21T17:26:00
#image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: ""
linkedinurl: ""
weight: 7
tags:
  - Hacker News
  - API
  - Web Development
  - Firebase
  - REST API
  - Vscode
  - Data Retrieval
  - JavaScript
---

Hacker NewsがAPIを公開してました。<https://hackernews.api-docs.io>
firebaseを使ってAPIを構築しているみたいです。

公開されているAPIを叩いたので、各EndPointを紹介します。（全部じゃないよ

VscodeのRestClientを使いました。

```bash

@base = https://hacker-news.firebaseio.com/v0

### トップストーリー（Top Stories）の取得
# このエンドポイントは、Hacker News上で最も人気のあるストーリーの一覧を返します。
# これは、現在最も話題となっているストーリーを表示するのに役立ちます。
GET {{base}}/topstories.json?print=pretty

### 新着ストーリー（New Stories）の取得
# 新着ストーリーのエンドポイントは、Hacker Newsに最近投稿されたストーリーの一覧を提供します。
# この一覧は、新しいコンテンツや最新の話題を探すのに適しています。
GET {{base}}/newstories.json?print=pretty

### ベストストーリー（Best Stories）の取得
# ベストストーリーエンドポイントは、Hacker News上で最も高い評価を得たストーリーの一覧を返します。
# この一覧は、過去に最も価値があると評価されたコンテンツを見つけるのに役立ちます。
GET {{base}}/beststories.json?print=pretty

### アスクHNストーリー（Ask HN Stories）の取得
# 「Ask HN」ストーリーは、ユーザーがコミュニティに質問を投稿する形式のストーリーです。
# このエンドポイントは、そのような質問の一覧を提供します。
GET {{base}}/askstories.json?print=pretty

### ショーHNストーリー（Show HN Stories）の取得
# Show HN」は、ユーザーが何かを作成したり、発見したりしたものを共有するストーリーです。
# このエンドポイントは、そうしたストーリーの一覧を提供します。
GET {{base}}/showstories.json?print=pretty

### ジョブストーリー（Job Stories）の取得
# ジョブストーリーエンドポイントは、雇用機会やキャリア関連の情報を含むストーリーの一覧を返します。
# これは、仕事探しやキャリアの機会に関心があるユーザーにとって有用です。
GET {{base}}/jobstories.json?print=pretty

### ジョブストーリー（Job Stories）の取得
# このエンドポイントは、Hacker Newsで利用可能なアイテムの中で最新（最大）のIDを返します。
# これは、データセットの最新状態を知るのに役立ちます。
GET {{base}}/maxitem.json?print=pretty

### 特定のアイテム詳細（Item Details）の取得
# このエンドポイントは、指定されたIDのアイテム（ストーリー、コメント、ポーリングなど）の詳細を返します。
# 特定の話題やコメントについての詳細情報を取得するのに使われます。
@item_id =38276515
GET {{base}}/item/{{item_id}}.json?print=pretty

```
