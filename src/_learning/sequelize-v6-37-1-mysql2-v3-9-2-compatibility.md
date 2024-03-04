---
title: "sequelize v6.37.1とmysql2 v3.9.2の互換性に関する調査結果"
date: 2024-3-4T15:13:00
#image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: "Graphic Designer"
linkedinurl: ""
weight: 7
---

# 概要
sequelize v6.37.1とmysql2 v3.9.2の間には相性問題があります。
解決先は、今の所mysql2 v3.8.0までに止めるか、sequelizeのTypeCastを自前実装してください。

```bash
npm i sequelize@6.37.1
npm i mysql2@3.9.2
```

```json
{
  "name": "simplecodes",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "ISC",
  "dependencies": {
    "mysql2": "3.9.2",
    "sequelize": "6.37.1",
  }
}

```

##　背景

[sequelizeのfindAllちょっと調べたよ](/learning/sequelize-findall-datetime-issue/)で書いたけど、
sequelizeのBindパラメータを使った queryでDatetime型をSelectでColumn指定すると
「invalid time value」となり、困っていた。

のでちゃんと調べてみた

## Mysql v3.9に関連するPR

- [sidorares/node-mysql2/ #2398](https://github.com/sidorares/node-mysql2/pull/2398)
  - (v3.8とv.3.9との[差分](https://github.com/sidorares/node-mysql2/compare/v3.8.0...v3.9.0))

## #2398　の変更とは?

`mysql2`で`execute`で取得した内容をTypeCast機能を導入した.

### typeCast機能とは？

`typeCast`は、データベースからのデータをアプリケーションで使用する前に、特定の形式や型に変換するための機能.
例えば、データベースから日付が文字列として返される場合、typeCastを使用してその文字列をJavaScriptのDateオブジェクトに変換することができます。

## 早速差分を見ようじゃないか

<details>
<summary>executeをつかったコードでLogを出力する</summary>

```javascript
const mysql = require('mysql2/promise');
const globalTimeZone = '+09:00';

async function queryDatabase() {
  const connection = await mysql.createConnection({
    host: 'localhost',
    user: 'local',
    password: 'password',
    database: 'contacts',
    debug: true,
    timezone: globalTimeZone,
    typeCast: function (field, next) {
      console.log(field);
      return next();
    }
  });

  try {
    const sql = 'SELECT callAt FROM calls WHERE type = ? ORDER BY callAt DESC LIMIT 1;';
    const values = [1];

    const [rows, fields] = await connection.execute(sql, values);

    console.log(rows);
  } catch (error) {
    console.error('Error during the database query:', error);
  } finally {
    await connection.end();
  }
}

queryDatabase();

```

</details>

<details>
<summary>v3.9のLog</summary>

```bash
  ~/Documents/mystady/simple-codes$ node index.js
  Add command: ClientHandshake
  raw: 0a382e302e333300750000003f0578765a2e2e5900ffff2d0200ffdf1500000000000000000000404c432a0926797e2e7d5044006d7973716c5f6e61746976655f70617373776f726400
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 undefined ==> ClientHandshake#unknown name(0,,78)
  Server hello packet: capability flags:3758096383=(long password, found rows, long flag, connect with db, no schema, compress, odbc, local files, ignore space, protocol 41, interactive, ssl, ignore sigpipe, transactions, reserved, secure connection, multi statements, multi results, ps multi results, plugin auth, connect attrs, plugin auth lenenc client data, can handle expired passwords, session track, deprecate eof, ssl verify server cert, remember options, multi factor authentication)
  Sending handshake packet: flags:280687567=(long password, found rows, long flag, connect with db, odbc, local files, ignore space, protocol 41, ignore sigpipe, transactions, reserved, secure connection, multi results, plugin auth, connect attrs, plugin auth lenenc client data, session track, multi factor authentication)
  0 117 <== ClientHandshake#unknown name(1,,143)
  0 117 <== 8b000001cff3ba1000000000e000000000000000000000000000000000000000000000006c6f63616c00144380a0b110a9015340449dc54f209400b37ded25636f6e7461637473006d7973716c5f6e61746976655f70617373776f726400300c5f636c69656e745f6e616d650c4e6f64652d4d7953514c2d320f5f636c69656e745f76657273696f6e05332e392e32
  raw: 00000002400000000b010908636f6e7461637473
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 117 ==> ClientHandshake#unknown name(2,maybeOK,24)
  Add command: Prepare
  0 117 <== Prepare#unknown name(0,,74)
  0 117 <== 460000001653454c4543542063616c6c41742046524f4d2063616c6c732057484552452074797065203d203f204f524445522042592063616c6c41742044455343204c494d495420313b
  Add command: Execute
  raw: 00010000000100010000000017000002
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 117 ==> Prepare#unknown name(1,maybeOK,16)
  raw: 03646566000000013f000c3f001500000008800000000005000003
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 117 ==> Prepare#unknown name(2,,27)
  raw: fe0000020034000004
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 117 ==> Prepare#unknown name(3,EOF,9)
  raw: 0364656608636f6e74616374730563616c6c730563616c6c730663616c6c41740663616c6c41740c3f00130000000c800000000005000005
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 117 ==> Prepare#unknown name(4,,56)
  raw: fe00000200
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 117 ==> Prepare#unknown name(5,EOF,9)
  0 117 <== Execute#unknown name(0,,26)
  0 117 <== 160000001701000000000100000000010500000000000000f03f
  raw: 0134000002
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 117 ==> Execute#resultsetHeader(1,,5)
          Resultset header received, expecting 1 column definition packets
  raw: 0364656608636f6e74616374730563616c6c730563616c6c730663616c6c41740663616c6c41740c3f00130000000c800000000005000003
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 117 ==> Execute#unknown name(2,,56)
  raw: fe000022000a000004
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 117 ==> Execute#unknown name(3,EOF,9)


  Compiled binary protocol row parser:

  For nicer debug output consider install cardinal@^2.0.0
  (function(){
    return class BinaryRow {
      constructor() {
      }
      next(packet, fields, options) {
        const result = {};
        packet.readInt8();
        const nullBitmaskByte0 = packet.readInt8();
        // "callAt": DATETIME
        const fieldWrapper0 = wrap(fields[0], packet);
        if (nullBitmaskByte0 & 4)
        result["callAt"] = null;
        else {
          result["callAt"] = options.typeCast(fieldWrapper0, function() { return packet.readDateTime('+09:00'); });
        }
        return result;
      }
    };
  })()

  raw: 000007e807021503050d05000005
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 117 ==> Execute#row(4,maybeOK,14)
  {
    type: 'DATETIME',
    length: 19,
    db: 'contacts',
    table: 'calls',
    name: 'callAt',
    string: [Function: string],
    buffer: [Function: buffer],
    geometry: [Function: geometry]
  }
  raw: fe00002208
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 117 ==> Execute#row(5,EOF,9)
  [ { callAt: 2024-02-20T18:05:13.000Z } ]
  Add command: Quit
  0 117 <== Quit#unknown name(0,,5)
  0 117 <== 0100000001
  ~/Documents/mystady/simple-codes$ 
```

</details>



<details>
<summary>v3.8のLog</summary>

```bash
  ~/Documents/mystady/simple-codes$ node index.js
  Add command: ClientHandshake
  raw: 0a382e302e333300760000000967603b5830105a00ffff2d0200ffdf1500000000000000000000196920147f392239732e196a006d7973716c5f6e61746976655f70617373776f726400
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 undefined ==> ClientHandshake#unknown name(0,,78)
  Server hello packet: capability flags:3758096383=(long password, found rows, long flag, connect with db, no schema, compress, odbc, local files, ignore space, protocol 41, interactive, ssl, ignore sigpipe, transactions, reserved, secure connection, multi statements, multi results, ps multi results, plugin auth, connect attrs, plugin auth lenenc client data, can handle expired passwords, session track, deprecate eof, ssl verify server cert, remember options, multi factor authentication)
  Sending handshake packet: flags:280687567=(long password, found rows, long flag, connect with db, odbc, local files, ignore space, protocol 41, ignore sigpipe, transactions, reserved, secure connection, multi results, plugin auth, connect attrs, plugin auth lenenc client data, session track, multi factor authentication)
  0 118 <== ClientHandshake#unknown name(1,,143)
  0 118 <== 8b000001cff3ba1000000000e000000000000000000000000000000000000000000000006c6f63616c0014b22b02aa249c46567efef62d365ef784b848d391636f6e7461637473006d7973716c5f6e61746976655f70617373776f726400300c5f636c69656e745f6e616d650c4e6f64652d4d7953514c2d320f5f636c69656e745f76657273696f6e05332e382e30
  raw: 00000002400000000b010908636f6e7461637473
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 118 ==> ClientHandshake#unknown name(2,maybeOK,24)
  Add command: Prepare
  0 118 <== Prepare#unknown name(0,,74)
  0 118 <== 460000001653454c4543542063616c6c41742046524f4d2063616c6c732057484552452074797065203d203f204f524445522042592063616c6c41742044455343204c494d495420313b
  Add command: Execute
  raw: 00010000000100010000000017000002
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 118 ==> Prepare#unknown name(1,maybeOK,16)
  raw: 03646566000000013f000c3f001500000008800000000005000003
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 118 ==> Prepare#unknown name(2,,27)
  raw: fe0000020034000004
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 118 ==> Prepare#unknown name(3,EOF,9)
  raw: 0364656608636f6e74616374730563616c6c730563616c6c730663616c6c41740663616c6c41740c3f00130000000c800000000005000005
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 118 ==> Prepare#unknown name(4,,56)
  raw: fe00000200
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 118 ==> Prepare#unknown name(5,EOF,9)
  0 118 <== Execute#unknown name(0,,26)
  0 118 <== 160000001701000000000100000000010500000000000000f03f
  raw: 0134000002
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 118 ==> Execute#resultsetHeader(1,,5)
          Resultset header received, expecting 1 column definition packets
  raw: 0364656608636f6e74616374730563616c6c730563616c6c730663616c6c41740663616c6c41740c3f00130000000c800000000005000003
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 118 ==> Execute#unknown name(2,,56)
  raw: fe000022000a000004
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 118 ==> Execute#unknown name(3,EOF,9)


  Compiled binary protocol row parser:

  For nicer debug output consider install cardinal@^2.0.0
  (function(){
    return class BinaryRow {
      constructor() {
      }
      next(packet, fields, options) {
        const result = {};
        packet.readInt8();
        const nullBitmaskByte0 = packet.readInt8();
        // "callAt": DATETIME
        if (nullBitmaskByte0 & 4)
        result["callAt"] = null;
        else
        result["callAt"] = packet.readDateTime('+09:00');
        return result;
      }
    };
  })()

  raw: 000007e807021503050d05000005
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 118 ==> Execute#row(4,maybeOK,14)
  raw: fe00002208
  Trace
      at Connection.handlePacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:433:17)
      at PacketParser.onPacket (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:97:12)
      at PacketParser.executeStart (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/packet_parser.js:75:16)
      at Socket.<anonymous> (/Users/{useName}/Documents/mystady/simple-codes/node_modules/mysql2/lib/connection.js:104:25)
      at Socket.emit (node:events:513:28)
      at addChunk (node:internal/streams/readable:315:12)
      at readableAddChunk (node:internal/streams/readable:289:9)
      at Socket.Readable.push (node:internal/streams/readable:228:10)
      at TCP.onStreamRead (node:internal/stream_base_commons:190:23)
  0 118 ==> Execute#row(5,EOF,9)
  [ { callAt: 2024-02-20T18:05:13.000Z } ]
  Add command: Quit
  0 118 <== Quit#unknown name(0,,5)
  0 118 <== 0100000001
  ~/Documents/mystady/simple-codes$ 

```
</details>


ほんとだTypeCastの処理変わっている

```diff_javascript
  function(){
    return class BinaryRow {
      constructor() {
      }
      next(packet, fields, options) {
        const result = {};
        packet.readInt8();
        const nullBitmaskByte0 = packet.readInt8();
        // "callAt": DATETIME
  +      const fieldWrapper0 = wrap(fields[0], packet);
        if (nullBitmaskByte0 & 4)
        result["callAt"] = null;
        else {
  +        result["callAt"] = options.typeCast(fieldWrapper0, function() { return packet.readDateTime('+09:00'); });
  -        result["callAt"] = packet.readDateTime('+09:00');
        }
        return result;
      }
    };
  }()
```


## じゃあなんでsequelizeのv6.37.1でエラーになんのよ

MySQL2ライブラリのバージョン3.9で導入された`TypeCast`機能に関して、Sequelizeとの互換性に問題が発生しています。
具体的には、MySQL2の`execute`メソッドを使用する際に、Sequelizeが実装している[`TypeCast`](https://github.com/sequelize/sequelize/blob/3a08dc387da094661a1e08de68fac27454548fce/packages/core/src/dialects/mysql/data-types.db.ts#L18-L19)機能が意図せずに働き、期待される動作をしない問題があります。

Sequelizeの`TypeCast`機能は、本来MySQL2の`query`メソッド実行時にのみ適用されることを想定していますが、`execute`メソッドにも適用されてしまうため、`DATETIME`型のデータを処理する際に「invalid time value」エラーが発生してしまいます。

### 実際に見てみる

Sequelizeでは、`registerDataTypeParser`の引数として渡される`value: Field`に、MySQL2の[`fieldWrapper`](https://github.com/sidorares/node-mysql2/blob/68cc3358121a88f955c0adab95a2d5f3d2b4ecb4/lib/parsers/binary_parser.js#L85)が渡されます。
Sequelize側の`const valueStr = value.string();`としていますので、`string()`が実際にどんな値を返すのか確認してみる.
callAtの値が`è`と表示されました。
```bash
{
  type: 'DATETIME',
  length: 19,
  db: 'contacts',
  table: 'calls',
  name: 'callAt',
  string: [Function: string],
  buffer: [Function: buffer],
  geometry: [Function: geometry]
}
callAtの値:->  è
[ { callAt: Invalid Date } ]
```

<details>
<summary>debug code</summary>

```javascript
  const mysql = require('mysql2/promise');
  const globalTimeZone = '+09:00';

  async function queryDatabase() {
    const connection = await mysql.createConnection({
      host: 'localhost',
      user: 'local',
      password: 'password',
      database: 'contacts',
      //debug: true,
      timezone: globalTimeZone,
      typeCast: function (field, next) {
        console.log(field);
        if (field.type === 'DATETIME') {
          try{
            const stringValue = field.string();
            console.log(`${field.name}の値:-> `,stringValue);
            new Date(stringValue)
          }catch(e)
          {
            console.error(e);
          }
          return next();
        }
        return next();
      }
    });

    try {
      const sql = 'SELECT callAt FROM calls WHERE type = ? ORDER BY callAt DESC LIMIT 1;';
      const values = [1];

      const [rows, fields] = await connection.execute(sql, values);

      console.log(rows);
    } catch (error) {
      console.error('Error during the database query:', error);
    } finally {
      await connection.end();
    }
  }

  queryDatabase();

```

</details>


MySQL2のfieldWrapperの[String Function](https://github.com/sidorares/node-mysql2/blob/68cc3358121a88f955c0adab95a2d5f3d2b4ecb4/lib/parsers/binary_parser.js#L92-L93)は、DATETIMEには対応してないみたいです。


### んじゃどうすればいいのよ、
結論、`field.buffer()`を呼ぼうぜ！
`buffer()`を使って直接バイナリデータから日時情報を解析することで日時が期待通り表示されました。

```bash
callAtの値:->  2024-02-20T18:05:13.000Z
[ { callAt: 2024-02-20T18:05:13.000Z } ]
```

<details>
<summary>update code</summary>

```javascript
const mysql = require('mysql2/promise');
const globalTimeZone = '+09:00';

async function queryDatabase() {
  const connection = await mysql.createConnection({
    host: 'localhost',
    user: 'local',
    password: 'password',
    database: 'contacts',
    timezone: globalTimeZone,
    typeCast: function (field, next) {
      if (field.type === 'DATETIME') {
        // バッファとしてDATETIME値を取得
        const buffer = field.buffer();
        // バッファから日時情報を解析（この例は仮のものです）
        if (buffer) {
          // 仮の解析方法です。実際のバッファ形式に応じて調整してください。
          let year = buffer.readUInt16LE(0); // 年
          let month = buffer[2] - 1; // 月（0から始まるため1を引く）
          let day = buffer[3]; // 日
          let hour = buffer[4]; // 時
          let minute = buffer[5]; // 分
          let second = buffer[6]; // 秒
          // Dateオブジェクトを生成
          let date = new Date(year, month, day, hour, minute, second);
          console.log(`${field.name}の値:-> `, date);
          return date;
        }
      }
      return next();
    }
  });

  try {
    const sql = 'SELECT callAt FROM calls WHERE type = ? ORDER BY callAt DESC LIMIT 1;';
    const values = [1];
    const [rows, fields] = await connection.execute(sql, values);
    console.log(rows);
  } catch (error) {
    console.error('Error during the database query:', error);
  } finally {
    await connection.end();
  }
}

queryDatabase();

```
</details>