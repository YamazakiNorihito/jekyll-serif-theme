---
title: "悪どいぞ翻訳API無料公開する方法"
date: 2023-10-18T13:37:00
#image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: "悪どいぞ翻訳API無料公開する方法"
linkedinurl: ""
weight: 7
---

参考サイトはGETメソッドで作っていましたが、
GETだと送信できるTEXTの量に制限があるのでPOSTにしたZ！

```javascript
function doPost(e) {
    // リクエストボディを取得し、JSONとしてパースする
    var p = JSON.parse(e.postData.contents);
    // LanguageAppクラスを用いて翻訳を実行
    var translatedText = LanguageApp.translate(p.text, p.source, p.target);
    // レスポンスボディの作成
    var body;
    if (translatedText) {
        body = {
          code: 200,
          text: translatedText
        };
    } else {
        body = {
          code: 400,
          text: "Bad Request"
        };
    }
    // レスポンスの作成
    var response = ContentService.createTextOutput();
    // Mime TypeをJSONに設定
    response.setMimeType(ContentService.MimeType.JSON);
    // JSONテキストをセットする
    response.setContent(JSON.stringify(body));

    return response;
}
```

参考サイト
[Google翻訳APIを無料で作る方法](https://qiita.com/satto_sann/items/be4177360a0bc3691fdf)