---

title: "NodejsでMySQL接続と同時接続する実装"
date: 2023-11-04T07:00:00
weight: 4
categories:
  - javascript
  - nodejs
---

Node.jsを使用してMySQLデータベースへの非同期接続と同時接続数の実装をします。

# Node.jsとMySQLの接続

Node.jsアプリケーションでMySQLデータベースに接続するためには、mysqlモジュールを使用します。
このモジュールは、Node.jsアプリケーションからMySQLデータベースへの接続と操作を簡単に行うための豊富なAPIを提供します。

# プール化された接続の設定

接続プールは、事前にデータベース接続のセットを作成し、アプリケーションによって必要とされる際にこれらの接続を再利用します。これにより、接続のオーバーヘッドが削減され、リソースの利用が最適化されます。

# サンプル

```javascript
const mysql = require('mysql');
const util = require('util');

// データベース接続情報
// 接続プールの作成
//  mysql.createPoolメソッドを使用して接続プールを作成しています。接続プールを作成する際には、データベースのホスト名、ユーザ名、パスワード、データベース名、および同時接続数の制限などのパラメータを指定します。
let pool = mysql.createPool({
    host: 'localhost',
    user: 'local',
    password: 'password',
    database: 'contacts',
    connectionLimit: 8,
    // debug: true, // consoleにクエリがトレースされる
});

// 非同期クエリの実行
//  util.promisifyメソッドを使用してpool.queryメソッドをプロミス化することで、async/await構文を使用してデータベースクエリを非同期に実行できます。これにより、コードが簡潔になり、読みやすくなります。
// mysqlモジュール自体はコールバックベースの非同期処理を提供しており、そのままではasync/awaitパターンと直接互換性がありません。しかし、util.promisifyを使うことで、コールバックベースの関数をプロミスベースの関数に変換し、async/await構文で簡単に扱えるようになります。
pool.query = util.promisify(pool.query);

async function executeQuery(query, params = []) {
    try {
        return await pool.query(query, params);
    } catch (error) {
        console.error('データベースクエリ実行中にエラーが発生しました:', error);
        throw error;
    }
}

(async () => {
    try {
        const createCount = 10;
        const values = Array.from({ length: createCount }, (_, i) => [333 + i, `Performance-Hospital ${i}`]);
        await executeQuery('INSERT INTO hospitals (id, hospitalCode) VALUES ?', [values]);
    } catch (error) {
        console.error('エラー: ', error);
    } finally {
        pool.end();
    }
})();
```