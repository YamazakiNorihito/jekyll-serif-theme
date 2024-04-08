---
title: "sequelizeのfindAllちょっと調べたよ"
date: 2024-3-2T11:05:00
#image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: "Graphic Designer"
linkedinurl: ""
weight: 7
---


# 背景

Sequelizeを使用してMySQLに接続しクエリを実行していたところ、特定のDateTime型のカラムを取得しようとすると「invalid time value」というエラーに直面しました。これまで同じコードで問題なく動作していたため、何が原因でこのような問題が発生したのか、深く調査する必要がありました。

# 原因

調査の結果、[mysql2ライブラリ](https://www.npmjs.com/package/mysql2)のバージョン3.9に問題がある？(かSequelizeがv3.9に対応していない)ことが判明しました。具体的には、バージョン3.8まではDateTime型のデータの扱いで問題がなかったにも関わらず、3.9で変更された部分に不具合が存在していました。GitHub上の[差分](https://github.com/sidorares/node-mysql2/compare/v3.8.0...v3.9.0)と、関連する[プルリクエスト](https://github.com/sidorares/node-mysql2/pull/2398)を詳細に確認することで、より具体的に特定できる。（[sequelize v6.37.1とmysql2 v3.9.2の互換性に関する調査結果](/learning/sequelize-v6-37-1-mysql2-v3-9-2-compatibility/)の記事に書きました。

# 解析方法

1. `Sequelizeの設定変更`: [`dialectOptions`](https://sequelize.org/docs/v6/other-topics/dialect-specific-things/#mysql)に[`debug: true`](https://sidorares.github.io/node-mysql2/docs/examples/connections/create-pool#pooloptions)を設定し、mysql2ライブラリが生成するログを観察しました。

    <details>
    <summary>コード</summary>

      ```javascript
        const sequelize = new Sequelize(
            '[databaseName]',
            '[userId]',
            '[password]', 
            {
                host: db_host,
                dialect: 'mysql',
                timezone: '+09:00',
                benchmark: true,
                dialectOptions: {
                  debug : true
                }
          });
      ```

    </details>

2. `Raw Queriesの実行`: [Replacements](https://sequelize.org/docs/v6/core-concepts/raw-queries/#replacements)と[Bind Parameter](https://sequelize.org/docs/v6/core-concepts/raw-queries/#bind-parameter)を用いたクエリを実行し、mysql2がDateTime型のデータをどのように処理しているかを詳細に調査しました。
   1. なんでこの手法を取ったのか
      1. Replacementsは問題なくqueryが実行できたため￥

    <details>
    <summary>コード</summary>

      ```javascript
        // Replacements
        await sequelize.query(
          'SELECT callAt FROM calls WHERE status = ?',
          {
            replacements: ['active'],
            type: QueryTypes.SELECT
          }
        );

        // bind
        await sequelize.query(
          'SELECT callAt FROM calls WHERE status = $1',
          {
            bind: ['active'],
            type: QueryTypes.SELECT
          }
        );
      ```

    </details>

TextとBinaryの処理における差異が明らかになり、特にBinaryRowでDateTime型のデータを扱う際に問題が発生していることがわかりました。
<details>
<summary>Log</summary>

  ```javascript

  // Replacementsで実行した時のdatetime型の処理内容
  (function () {
    return class TextRow {
      constructor(fields) {
        const _this = this;
        for(let i=0; i<fields.length; ++i) {
          this[`wrap${i}`] = wrap(fields[i], _this);
        }
      }
      next(packet, fields, options) {
        this.packet = packet;
        const result = {};
        // "callAt": DATETIME
        result["callAt"] = options.typeCast(this.wrap0, function() { return packet.parseDateTime('+09:00') });
        return result;
      }
    };
  })()

  // bindで実行した時のdatetime型の処理内容
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
  ```

</details>

# sequelizeのコードを簡単に解説

Mysql2に不具合があるとは思っておらず、sequelizeに不具合があると思って
コードを読んでいた。ので、調査する過程で分かった内容を書いていく。

## [model.js findAll(options)](https://github.com/sequelize/sequelize/blob/48181ced0e94577f19ed838b29a953602e631888/packages/core/src/model.js#L1343)

<details>
<summary>コード</summary>

```javascript
static async findAll(options) {
  if (options !== undefined && !isPlainObject(options)) {
    throw new sequelizeErrors.QueryError(
      'The argument passed to findAll must be an options object, use findByPk if you wish to pass a single primary key value',
    );
  }

  if (
    options !== undefined &&
    options.attributes &&
    !Array.isArray(options.attributes) &&
    !isPlainObject(options.attributes)
  ) {
    throw new sequelizeErrors.QueryError(
        'The attributes option must be an array of column names or an object',
    );
  }

  // optionsパラメータで
  // 無効なOptionが指定されていないか警告を出す
  const modelDefinition = this.modelDefinition;
  this._warnOnInvalidOptions(options, Object.keys(modelDefinition.attributes));

  const tableNames = {};
  tableNames[this.table] = true;
  options = cloneDeep(options) ?? {};

  setTransactionFromCls(options, this.sequelize);

  // デフォルトオプションを設定
  // optionsでnullやundefineの場合、初期値を設定する。（設定されている項目は何もしない
  defaultsLodash(options, { hooks: true, model: this });

  options.rejectOnEmpty = Object.hasOwn(options, 'rejectOnEmpty')
    ? options.rejectOnEmpty
    : this.options.rejectOnEmpty;

  this._conformIncludes(options, this);
  this._injectScope(options);

  if (options.hooks) {
    await this.hooks.runAsync('beforeFind', options);
    this._conformIncludes(options, this);
  }

  // Attributeにexcludeやincludeに設定されている項目を精査する
  /*
  前提:
    export class User extends Model {
      @Attribute(DataTypes.INTEGER)
      @PrimaryKey
      @AutoIncrement
      id;

      @Attribute(DataTypes.STRING)
      @NotNull
      username; // 'username' 属性を追加

      @Attribute(DataTypes.STRING)
      @NotNull
      password; // 'password' 属性を追加

      @Attribute(DataTypes.STRING)
      @NotNull
      email; // 'email' 属性を追加

      @Attribute(DataTypes.DATE)
      createdAt; // 'createdAt' 属性を追加
    }
  呼び出し方:
    User.findAll(.findAll({
      attributes: {
        exclude: ['password', 'createdAt'],
        include: ['email', 'profilePicture']
      }
    }))の時_expandAttributesは動く
  input:
    let options = {
      attributes: {
        exclude: ['password', 'createdAt'],
        include: ['email', 'profilePicture']
      }
    };
  output:
    options = {
      attributes: ['id', 'username', 'email', 'profilePicture']
    };
  */
  this._expandAttributes(options);

  this._expandIncludeAll(options, options.model);

  if (options.hooks) {
    await this.hooks.runAsync('beforeFindAfterExpandIncludeAll', options);
  }

  // 仮想属性を持つAttributesが含まれる場合、対象ととなるAttributeをSelectのColumnに含める
  // 仮想属性に関連する実属性がクエリに含まれるようにする
  // https://sequelize.org/docs/v6/core-concepts/getters-setters-virtuals/#virtual-fields
  options.originalAttributes = this._injectDependentVirtualAttributes(options.attributes);

  // joinが必要な場合、設定を行う
  if (options.include) {
    options.hasJoin = true;
    _validateIncludedElements(options, tableNames);

    if (
      options.attributes &&
      !options.raw &&
      this.primaryKeyAttribute &&
      !options.attributes.includes(this.primaryKeyAttribute) &&
      (!options.group || !options.hasSingleAssociation || options.hasMultiAssociation)
    ) {
      options.attributes = [this.primaryKeyAttribute].concat(options.attributes);
    }
  }

  // attributesが未設定の場合、モデル定義から取得
  if (!options.attributes) {
    options.attributes = Array.from(modelDefinition.attributes.keys());
    options.originalAttributes = this._injectDependentVirtualAttributes(options.attributes);
  }

  mapFinderOptions(options, this);

  options = this._paranoidClause(this, options);

  if (options.hooks) {
    await this.hooks.runAsync('beforeFindAfterOptions', options);
  }

  const selectOptions = { ...options, tableNames: Object.keys(tableNames) };
  // - ModelからSQL構築および実行をしています。
  const results = await this.queryInterface.select(this, this.table, selectOptions);

  if (options.hooks) {
    await this.hooks.runAsync('afterFind', results, options);
  }

  if (isEmpty(results) && options.rejectOnEmpty) {
    if (typeof options.rejectOnEmpty === 'function') {
      throw new options.rejectOnEmpty();
    }

    if (typeof options.rejectOnEmpty === 'object') {
      throw options.rejectOnEmpty;
    }

    throw new sequelizeErrors.EmptyResultError();
  }

  // インクルード関連をいい感じにマッピングしてModelに詰める
  return await Model._findSeparate(results, options);
}

```

</details>

## [query-interface.js select(model, tableName, optionsArg)](https://github.com/sequelize/sequelize/blob/8b1f73ade0251a9ff5a9f76ddbc77dfe75003335/packages/core/src/dialects/abstract/query-interface.js#L566-L567)

<details>
<summary>コード</summary>

```javascript

  async select(model, tableName, optionsArg) {
    const minifyAliases = optionsArg.minifyAliases ?? this.sequelize.options.minifyAliases;
    const options = { ...optionsArg, type: QueryTypes.SELECT, model, minifyAliases };

  /**
   * この関数は、指定されたモデルとテーブル名を使用してSELECTクエリを実行します。
   * Sequelizeのクエリ生成機能を利用して、データベースからデータを取得します。
   * 
   * - Model Queryの例:
   *   `User.findAll()`は内部的に`SELECT id, username, email FROM Users`というSQLクエリに展開されます。
   * 
   * - Replacementsの使用例:
   *   `sequelize.query('SELECT * FROM users WHERE username = :username', {replacements: { username: 'john' }})`
   *   これにより、生成されるSQLは`SELECT * FROM Users WHERE username = 'john'`となります。
   *   Replacementsは、クエリ内のプレースホルダを安全に置換します。
   * 
   * - Bindの使用例:
   *   `sequelize.query('SELECT * FROM users WHERE username = $1', {bind: ['john']})`
   *   こちらでは、生成されるSQLは`SELECT * FROM Users WHERE username = $1`となり、
   *   `$1`は`bind`配列の最初の要素に置き換えられます。
   * 
   * replacementsはQueryGeneratorによって処理されますが、bindはQueryRawによって直接処理されます。
   */
    const sql = this.queryGenerator.selectQuery(tableName, options, model);

    // unlike bind, replacements are handled by QueryGenerator, not QueryRaw
    delete options.replacements;

    /**
     * `sequelize.queryRaw`メソッドを使用してSQLクエリを実行します。
     * 
     * `bind`の値は、クエリ実行時にプレースホルダーと置き換えられ、
     * このプロセスはデータベースドライバ（例：mysql2）によって管理されます。
     * 
     * データベースからのクエリ結果を返します。
     */
    return await this.sequelize.queryRaw(sql, options);
  }
```

</details>

## [sequelize.js queryRaw(sql, options)](https://github.com/sequelize/sequelize/blob/8b1f73ade0251a9ff5a9f76ddbc77dfe75003335/packages/core/src/sequelize.js#L638-L639)

<details>
<summary>コード</summary>

```javascript

  async queryRaw(sql, options) {
    /*省略*/

    options = { ...this.options.query, ...options, bindParameterOrder: null };

    let bindParameters;
    if (options.bind != null) {
      /*省略*/
      const mappedResult = mapBindParameters(sql, this.dialect);
      /*省略*/

      sql = mappedResult.sql;

      // used by dialects that support "INOUT" parameters to map the OUT parameters back the the name the dev used.
      options.bindParameterOrder = mappedResult.bindOrder;
      if (mappedResult.bindOrder == null) {
        bindParameters = options.bind;
      } else {
        bindParameters = mappedResult.bindOrder.map(key => {
          if (isBindArray) {
            return options.bind[key - 1];
          }

          return options.bind[key];
        });
      }
    }

    /*省略*/
    
    return await retry(async () => {
      /*省略*/

      // 実際にクエリを実行する。方言に応じたクエリ実装を使う
      // 例: MySQLならMySqlQueryをインスタンス化(https://github.com/sequelize/sequelize/blob/8b1f73ade0251a9ff5a9f76ddbc77dfe75003335/packages/core/src/dialects/mysql/query.js#L21-L22)
      // dialectをどれを使うかは、Sequelizeのインスタンス生成の時のdialectで決まります。(https://github.com/sequelize/sequelize/blob/8b1f73ade0251a9ff5a9f76ddbc77dfe75003335/packages/core/src/sequelize.js#L341-L342)
      /*
        const sequelize = new Sequelize(
            '[databaseName]',
            '[userId]',
            '[password]', 
            {
                host: db_host,
                dialect: 'mysql',
                timezone: '+09:00',
                benchmark: true,
                dialectOptions: {
                  debug : true
                }
          });
      */
      const query = new this.dialect.Query(connection, this, options);

      try {
        /*省略*/
        // クエリを走らせる
        return await query.run(sql, bindParameters, { minifyAliases: options.minifyAliases });
      } finally {
        /*省略*/
      }
    }, retryOptions);
  }

```

</details>

## [sql.ts mapBindParameters](https://github.com/sequelize/sequelize/blob/abca55ee52d959f95c98dc7ae8b8162005536d05/packages/core/src/utils/sql.ts#L316-L317)

- [MysqlDialect](https://github.com/sequelize/sequelize/blob/abca55ee52d959f95c98dc7ae8b8162005536d05/packages/core/src/dialects/mysql/index.ts#L17-L18)

<details>
<summary>コード</summary>

```javascript

export function mapBindParameters(
  sqlString: string,
  dialect: AbstractDialect, // MysqlDialectとか
): {
  sql: string;
  bindOrder: string[] | null;
  parameterSet: Set<string>;
} {
  // バインドパラメータがクエリ内で出現する順序を追跡する配列
  const parameterCollector = dialect.createBindCollector();
  // クエリに含まれるすべてのバインドパラメータの名前の集合
  const parameterSet = new Set<string>();

  const newSql = mapBindParametersAndReplacements(
    sqlString,
    dialect,
    undefined,
    foundBindParamName => {
      parameterSet.add(foundBindParamName);

      return parameterCollector.collect(foundBindParamName);
    },
  );

  return { sql: newSql, bindOrder: parameterCollector.getBindParameterOrder(), parameterSet };
}

```

</details>

## [mysql/query.js run(sql, parameters)](https://github.com/sequelize/sequelize/blob/8b1f73ade0251a9ff5a9f76ddbc77dfe75003335/packages/core/src/dialects/mysql/query.js#L26-L27)

<details>
<summary>コード</summary>

```javascript

  async run(sql, parameters) {
    this.sql = sql;
    // connectionはconnection-manager.tsでインスタンス生成されたもの
    const { connection, options } = this;

    const showWarnings = this.sequelize.options.showWarnings || options.showWarnings;

    // log出力
    const complete = this._logQuery(sql, debug, parameters);

    if (parameters) {
      debug('parameters(%j)', parameters);
    }

    let results;

    try {
      if (parameters && parameters.length > 0) {
        results = await new Promise((resolve, reject) => {
          connection
            .execute(sql, parameters, (error, result) => (error ? reject(error) : resolve(result)))
            .setMaxListeners(100);
        });
      } else {
        results = await new Promise((resolve, reject) => {
          connection
            .query({ sql }, (error, result) => (error ? reject(error) : resolve(result)))
            .setMaxListeners(100);
        });
      }
    } catch (error) {
      /*
        Exception発生したときはrollbackしてLog出力
      */
      if (options.transaction && error.errno === ER_DEADLOCK) {
        // MySQL automatically rolls-back transactions in the event of a deadlock.
        // However, we still initiate a manual rollback to ensure the connection gets released - see #13102.
        try {
          await options.transaction.rollback();
        } catch {
          // Ignore errors - since MySQL automatically rolled back, we're
          // not that worried about this redundant rollback failing.
        }
      }

      error.sql = sql;
      error.parameters = parameters;
      throw this.formatError(error);
    } finally {
      complete();
    }

    /*省略*/

    return this.formatResults(results);
  }

```

</details>

## [mysql connection-manager.ts connect(config: ConnectionOptions): Promise<MySqlConnection>](https://github.com/sequelize/sequelize/blob/8b1f73ade0251a9ff5a9f76ddbc77dfe75003335/packages/core/src/dialects/mysql/connection-manager.ts#L74-L75)

<details>
<summary>コード</summary>

```javascript
async connect(config: ConnectionOptions): Promise<MySqlConnection> {
    assert(typeof config.port === 'number', 'port has not been normalized');

    const connectionConfig: MySqlConnectionOptions = {
      bigNumberStrings: false,
      supportBigNumbers: true,
      flags: ['-FOUND_ROWS'],
      // SequelizeのdialectOptionsをそのまま設定する。つまりmysql2 MySqlConnectionOptionsを設定できる！ここ重要
      ...config.dialectOptions,
      ...(config.host == null ? null : { host: config.host }),
      port: config.port,
      ...(config.username == null ? null : { user: config.username }),
      ...(config.password == null ? null : { password: config.password }),
      ...(config.database == null ? null : { database: config.database }),
      ...(!this.sequelize.options.timezone ? null : { timezone: this.sequelize.options.timezone }),
      typeCast: (field, next) => this.#typecast(field, next),
    };

    try {
      const connection: MySqlConnection = await createConnection(this.lib, connectionConfig);

      debug('connection acquired');

      connection.on('error', (error: unknown) => {
        /*省略*/
        switch (error.code) {
          case 'ESOCKET':
          case 'ECONNRESET':
          case 'EPIPE':
          case 'PROTOCOL_CONNECTION_LOST':
            void this.pool.destroy(connection);
            break;
          default:
        }
      });

      // timezoneをConectionするつど設定しているんだねーほえー
      if (!this.sequelize.config.keepDefaultTimezone && this.sequelize.options.timezone) {
        // set timezone for this connection
        // but named timezone are not directly supported in mysql, so get its offset first
        let tzOffset = this.sequelize.options.timezone;
        tzOffset = tzOffset.includes('/') ? dayjs.tz(undefined, tzOffset).format('Z') : tzOffset;
        await promisify(cb => connection.query(`SET time_zone = '${tzOffset}'`, cb))();
      }

      return connection;
    } catch (error) {
      /*省略*/
    }
  }
```

</details>
