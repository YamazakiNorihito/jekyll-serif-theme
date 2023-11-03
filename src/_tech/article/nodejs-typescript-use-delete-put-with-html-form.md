---
title: "HTML FormからDELETEやPUTメソッドを使ってリクエストを送る方法"
date: 2023-11-04T07:42:00
weight: 4
categories:
  - javascript
  - nodejs
  - typescript

---

## 目的や背景

HTMLのフォームは、基本的にGETまたはPOSTメソッドしかサポートしていません。
そのためDELETEやPUTと同じ振る舞いをするURIをPOSTまたはGETでActionを用意する必要があります。
しかし、~~URIを考えるのがめんどくさくて~~なんとかWebAPI風にURIを構築し、 URIを考える時間をなくしたいと
思い、そこでmethod-overrideというライブラリを使います。

使うライブラリーは[method-override](https://github.com/expressjs/method-override#method-override)

### headerのmethodを書き換える設定をする

```typescript
// app.ts
// ↓下記の設定をする
// override with the X-HTTP-Method-Override header in the request
// https://github.com/expressjs/method-override
app.use(methodOverride('_method'))

app.listen(3000, () => {
    console.log('Server is running on port 3000');
});

export default app;
```

### delete methodの Actionを設定

```typescript
// routes.ts
const router = express.Router();

const freeeController = container.resolve(FreeeController);
router.delete('/freee/work-records', asyncHandler((req, res) => freeeController.deleteWorkRecords(req, res)));

export default router;
```

### HTML FormでDeleteを指定する

methodOverride関数にクエリストリングのキーを文字列として指定することで、クエリストリングの値を使用してHTTPメソッドを上書きできます。
```html

    <div id="attendance-input">
        <h2>勤怠削除</h2>
        <form id="attendance-form" action="/freee/work-records?_method=DELETE" method="POST">
            <div class="day-group">
                <!-- 勤務日のFromとToの入力 -->
                <div class="input-group">
                    <label for="work-from-date">勤務日:</label>
                    <input type="date" id="work-from-date" name="workFromDate" required />

                    <label for="work-to-date">〜</label>
                    <input type="date" id="work-to-date" name="workToDate" required />
                </div>
            </div>
            <button type="submit">登録</button>
        </form>
    </div>

```