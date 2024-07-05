---
title: "自分用go-playgroundのドキュメント必要そうな部分だけ日本語にした"
date: 2024-7-5T16:07:00
#image: "images/team/nonsap-visuals-kMJp7620W6U-unsplash.jpg"
jobtitle: "jekyll-sitemap"
linkedinurl: ""
weight: 7
---

[github.com/go-playground/validator/v10](https://pkg.go.dev/github.com/go-playground/validator/v10@v10.22.0#section-readme)

## Baked-in Validations（組み込みバリデーション）

### 特記事項

バリデータを初めて使用する場合、v11+でデフォルト動作となる新しい動作にオプトインする `WithRequiredStructEnabled` オプションを使用して初期化することを強くお勧めします。詳細はドキュメントを参照してください。

```go
validate := validator.New(validator.WithRequiredStructEnabled())
```

### Fields

| タグ            | 説明                                                      | 使用例                                                                 |
|-----------------|-----------------------------------------------------------|----------------------------------------------------------------------|
| `eqcsfield`     | フィールドが別の相対フィールドと等しいかどうかをチェックする | パスワードとその確認が同じ値を持つ必要がある場合                       |
| `eqfield`       | フィールドが別のフィールドと等しいかどうかをチェックする   | 新しいメールアドレスとメールアドレスの確認が一致することを確認したい場合 |
| `fieldcontains` | 指定された文字がフィールドに含まれているかどうかをチェックする | ユーザー名フィールドが特定の文字（例えば、@）を含む必要がある場合      |
| `fieldexcludes` | 指定された文字がフィールドに含まれていないかどうかをチェックする | ユーザー名フィールドが特定の禁止文字（例えば、スペース）を含まないことを確認したい場合 |
| `gtcsfield`     | フィールドが別の相対フィールドより大きいかどうかをチェックする | 「開始日」が「終了日」より前であることを確認する場合                   |
| `gtecsfield`    | フィールドが別の相対フィールド以上であるかどうかをチェックする | ある数値フィールドが別のフィールドの値以上である必要がある場合         |
| `gtefield`      | フィールドが別のフィールド以上であるかどうかをチェックする | 価格の最低値が最大値よりも大きくないことを確認する場合                 |
| `gtfield`       | フィールドが別のフィールドより大きいかどうかをチェックする | ある数値フィールドが別のフィールドの値より大きい必要がある場合         |
| `ltcsfield`     | フィールドが別の相対フィールドより小さいかどうかをチェックする | 「終了日」が「開始日」より後であることを確認する場合                   |
| `ltecsfield`    | フィールドが別の相対フィールド以下であるかどうかをチェックする | ある数値フィールドが別のフィールドの値以下である必要がある場合         |
| `ltefield`      | フィールドが別のフィールド以下であるかどうかをチェックする | 価格の最大値が最低値よりも小さくないことを確認する場合                 |
| `ltfield`       | フィールドが別のフィールドより小さいかどうかをチェックする | ある数値フィールドが別のフィールドの値より小さい必要がある場合         |
| `necsfield`     | フィールドが別の相対フィールドと等しくないかどうかをチェックする | 現在のパスワードと新しいパスワードが同じでないことを確認する場合       |
| `nefield`       | フィールドが別のフィールドと等しくないかどうかをチェックする | 2つの異なるフィールドが同じ値を持っていないことを確認したい場合         |

### Network

| タグ             | 説明                                                         | 使用例                                                                                  |
|------------------|--------------------------------------------------------------|---------------------------------------------------------------------------------------|
| `cidr`           | クラスレスドメイン間ルーティング（CIDR）形式                 | `192.168.0.0/16`のようなIPアドレス範囲を検証する場合                                    |
| `cidrv4`         | クラスレスドメイン間ルーティング（CIDR）IPv4形式              | `192.168.0.0/16`のようなIPv4アドレス範囲を検証する場合                                 |
| `cidrv6`         | クラスレスドメイン間ルーティング（CIDR）IPv6形式              | `2001:db8::/32`のようなIPv6アドレス範囲を検証する場合                                  |
| `datauri`        | データURL                                                    | `data:image/png;base64,iVBORw0KGgoAAAANSUhEUg...`のようなデータURIを検証する場合        |
| `fqdn`           | 完全修飾ドメイン名（FQDN）                                    | `www.example.com`のようなFQDNを検証する場合                                            |
| `hostname`       | ホスト名（RFC 952）                                           | `example`のようなホスト名を検証する場合                                                |
| `hostname_port`  | ホストポート                                                  | `example.com:80`のようなホストとポートの組み合わせを検証する場合                       |
| `hostname_rfc1123` | ホスト名（RFC 1123）                                        | `example.com`のようなホスト名を検証する場合（RFC 1123に準拠）                           |
| `ip`             | インターネットプロトコルアドレス（IP）                        | `192.168.0.1`や`2001:db8::1`のようなIPアドレスを検証する場合                           |
| `ip4_addr`       | インターネットプロトコルアドレス（IPv4）                      | `192.168.0.1`のようなIPv4アドレスを検証する場合                                        |
| `ip6_addr`       | インターネットプロトコルアドレス（IPv6）                      | `2001:db8::1`のようなIPv6アドレスを検証する場合                                        |
| `ip_addr`        | インターネットプロトコルアドレス（IP）                        | `192.168.0.1`や`2001:db8::1`のようなIPアドレスを検証する場合                           |
| `ipv4`           | インターネットプロトコルアドレス（IPv4）                      | `192.168.0.1`のようなIPv4アドレスを検証する場合                                        |
| `ipv6`           | インターネットプロトコルアドレス（IPv6）                      | `2001:db8::1`のようなIPv6アドレスを検証する場合                                        |
| `mac`            | メディアアクセス制御（MAC）アドレス                           | `00:1A:2B:3C:4D:5E`のようなMACアドレスを検証する場合                                   |
| `tcp4_addr`      | トランスミッションコントロールプロトコルアドレス（TCPv4）      | `192.168.0.1:80`のようなTCPv4アドレスを検証する場合                                    |
| `tcp6_addr`      | トランスミッションコントロールプロトコルアドレス（TCPv6）      | `[2001:db8::1]:80`のようなTCPv6アドレスを検証する場合                                  |
| `tcp_addr`       | トランスミッションコントロールプロトコルアドレス（TCP）        | `192.168.0.1:80`や`[2001:db8::1]:80`のようなTCPアドレスを検証する場合                  |
| `udp4_addr`      | ユーザーデータグラムプロトコルアドレス（UDPv4）               | `192.168.0.1:1234`のようなUDPv4アドレスを検証する場合                                  |
| `udp6_addr`      | ユーザーデータグラムプロトコルアドレス（UDPv6）               | `[2001:db8::1]:1234`のようなUDPv6アドレスを検証する場合                                |
| `udp_addr`       | ユーザーデータグラムプロトコルアドレス（UDP）                 | `192.168.0.1:1234`や`[2001:db8::1]:1234`のようなUDPアドレスを検証する場合              |
| `unix_addr`      | Unixドメインソケットエンドポイントアドレス                    | `/var/run/docker.sock`のようなUnixドメインソケットアドレスを検証する場合               |
| `uri`            | URI文字列                                                    | `https://example.com/path?query=string`のようなURIを検証する場合                        |
| `url`            | URL文字列                                                    | `https://example.com`のようなURLを検証する場合                                         |
| `http_url`       | HTTP URL文字列                                               | `http://example.com`のようなHTTP URLを検証する場合                                     |
| `url_encoded`    | URLエンコードされた文字列                                     | `Hello%20World%21`のようなURLエンコードされた文字列を検証する場合                      |
| `urn_rfc2141`    | URN（RFC 2141形式）                                          | `urn:example:animal:ferret:nose`のようなURNを検証する場合                              |

### Strings

| タグ              | 説明                                                      | 使用例                                                                                  |
|-------------------|-----------------------------------------------------------|---------------------------------------------------------------------------------------|
| `alpha`           | アルファベットのみ                                         | ユーザー名がアルファベットのみで構成されていることを確認する場合                         |
| `alphanum`        | 英数字のみ                                                 | パスワードが英数字のみで構成されていることを確認する場合                                 |
| `alphanumunicode` | 英数字（ユニコードを含む）                                 | 国際化されたユーザー名が英数字のみで構成されていることを確認する場合                     |
| `alphaunicode`    | アルファベット（ユニコードを含む）                         | 国際化された名前がアルファベットのみで構成されていることを確認する場合                   |
| `ascii`           | ASCII文字                                                  | ユーザー名やパスワードがASCII文字のみで構成されていることを確認する場合                  |
| `boolean`         | 真偽値                                                     | フィールドが真偽値（trueまたはfalse）であることを確認する場合                           |
| `contains`        | 特定の文字列を含む                                         | 説明フィールドが特定のキーワードを含むことを確認する場合                                 |
| `containsany`     | 特定のいずれかの文字を含む                                 | 説明フィールドが特定のいずれかの文字を含むことを確認する場合                             |
| `containsrune`    | 特定のルーンを含む                                         | 説明フィールドが特定のルーン文字を含むことを確認する場合                                 |
| `endsnotwith`     | 特定の文字列で終わらない                                   | フィールドが特定の文字列で終わらないことを確認する場合                                   |
| `endswith`        | 特定の文字列で終わる                                       | フィールドが特定の文字列で終わることを確認する場合                                       |
| `excludes`        | 特定の文字列を含まない                                     | フィールドが特定の禁止文字列を含まないことを確認する場合                                 |
| `excludesall`     | 特定のいずれかの文字を含まない                             | フィールドが特定のいずれかの禁止文字を含まないことを確認する場合                         |
| `excludesrune`    | 特定のルーンを含まない                                     | フィールドが特定の禁止ルーン文字を含まないことを確認する場合                             |
| `lowercase`       | 小文字                                                     | フィールドが全て小文字で構成されていることを確認する場合                                 |
| `multibyte`       | マルチバイト文字                                           | フィールドがマルチバイト文字（例：日本語、中国語など）を含むことを確認する場合           |
| `number`          | 数字                                                       | フィールドが数字のみで構成されていることを確認する場合                                   |
| `numeric`         | 数値                                                       | フィールドが数値（整数や浮動小数点数）であることを確認する場合                           |
| `printascii`      | 印刷可能なASCII文字                                        | フィールドが印刷可能なASCII文字のみで構成されていることを確認する場合                     |
| `startsnotwith`   | 特定の文字列で始まらない                                   | フィールドが特定の文字列で始まらないことを確認する場合                                   |
| `startswith`      | 特定の文字列で始まる                                       | フィールドが特定の文字列で始まることを確認する場合                                       |
| `uppercase`       | 大文字                                                     | フィールドが全て大文字で構成されていることを確認する場合                                 |

### Format

以下に、各バリデーションタグの説明と使用例を表形式でまとめました。

| タグ                             | 説明                                                                 | 使用例                                                                                  |
|----------------------------------|----------------------------------------------------------------------|---------------------------------------------------------------------------------------|
| `base64`                         | Base64エンコードされた文字列                                          | ファイルのBase64エンコードされたコンテンツを検証する場合                                  |
| `base64url`                      | Base64URLエンコードされた文字列                                        | URLセーフなBase64エンコード文字列を検証する場合                                         |
| `base64rawurl`                   | Base64RawURLエンコードされた文字列                                     | パディングのないURLセーフなBase64エンコード文字列を検証する場合                          |
| `bic`                            | 事業識別コード（ISO 9362）                                            | 銀行のBICコードを検証する合                                                           |
| `bcp47_language_tag`             | 言語タグ（BCP 47）                                                    | 言語タグがBCP 47規格に準拠しているかを検証する場合                                       |
| `btc_addr`                       | ビットコインアドレス                                                  | ビットコインのウォレットアドレスを検証する場合                                          |
| `btc_addr_bech32`                | ビットコインBech32アドレス（SegWit）                                  | Bech32形式のビットコインSegWitアドレスを検証する場合                                    |
| `credit_card`                    | クレジットカード番号                                                  | クレジットカード番号が有効かどうかを検証する場合                                        |
| `mongodb`                        | MongoDB ObjectID                                                     | MongoDBのObjectIDを検証す合                                                        |
| `mongodb_connection_string`      | MongoDB接続文字列                                                    | MongoDBの接続文字列が有効かどうかを検証する場合                                         |
| `cron`                           | Cron式                                                               | Cron式の形式が正しいかどうかを検証する合                                              |
| `spicedb`                        | SpiceDb ObjectID/Permission/Type                                      | SpiceDbのObjectIDやパーミッション、タイプを検証する合                                 |
| `datetime`                       | 日付時刻                                                             | 日付時刻形式を検証する合                                                              |
| `e164`                           | E.164形式の電話番号                                                  | 国際電話番号がE.164形式に準拠しているかを検証する場合                                    |
| `email`                          | メールアドレス                                                       | メールアドレス形式を検証する場合                                                        |
| `eth_addr`                       | イーサリアムアドレス                                                  | イーサリアムのウォレットアドレスを検証する場合                                          |
| `hexadecimal`                    | 16進文字列                                                           | 16進数形式の文字列を検証する合                                                        |
| `hexcolor`                       | 16進カラーコード                                                     | HTMLやCSSで使用される16進カラーコードを検証する場合                                      |
| `hsl`                            | HSLカラーコード                                                      | HSL（色相・彩度・輝度）カラーコードを検証する場合                                       |
| `hsla`                           | HSLAカラーコード                                                     | HSLA（色相・彩度・輝度・透明度）カラーコードを検証する場合                              |
| `html`                           | HTMLタグ                                                             | フィールドに含まれるHTMLタグを検証する場合                                              |
| `html_encoded`                   | HTMLエンコードされた文字列                                            | HTMLエンコードされた文字列を検証する場合                                                |
| `isbn`                           | 国際標準図書番号（ISBN）                                             | ISBNを検証する合                                                                      |
| `isbn10`                         | 10桁の国際標準図書番号（ISBN-10）                                     | 10桁のISBNを検証する場合                                                               |
| `isbn13`                         | 13桁の国際標準図書番号（ISBN-13）                                     | 13桁のISBNを検証する場合                                                               |
| `issn`                           | 国際標準逐次刊行物番号（ISSN）                                        | ISSNを検証する合                                                                      |
| `iso3166_1_alpha2`               | 2文字の国コード（ISO 3166-1 alpha-2）                                 | 2文字の国コードを検証する合                                                           |
| `iso3166_1_alpha3`               | 3文字の国コード（ISO 3166-1 alpha-3）                                 | 3文字の国コードを検証する合                                                           |
| `iso3166_1_alpha_numeric`        | 数字の国コード（ISO 3166-1 numeric）                                  | 数字の国コードを検証する合                                                            |
| `iso3166_2`                      | 国の地方コード（ISO 3166-2）                                          | 国の地方コードを検証する合                                                            |
| `iso4217`                        | 通貨コード（ISO 4217）                                               | 通貨コードを検証する合                                                                |
| `json`                           | JSON形式                                                             | フィールドが有効なJSON形式であることを検証する場合                                       |
| `jwt`                            | JSON Webトークン（JWT）                                               | フィールドが有効なJWTであることを検証する場合                                           |
| `latitude`                       | 緯度                                                                 | フィールドが有効な緯度（-90から90の範囲）であることを検証する場合                       |
| `longitude`                      | 経度                                                                 | フィールドが有効な経度（-180から180の範囲）であることを検証する場合                     |
| `luhn_checksum`                  | ルーンアルゴリズムチェックサム（文字列および(u)int用）               | クレジットカード番号などのチェックサムを検証する場合                                     |
| `postcode_iso3166_alpha2`        | 郵便番号                                                             | フィールドがISO 3166-1 alpha-2形式の郵便番号であることを検証する場合                     |
| `postcode_iso3166_alpha2_field`  | 郵便番号                                                             | フィールドがISO 3166-1 alpha-2形式の郵便番号であることを検証する場合                     |
| `rgb`                            | RGBカラーコード                                                      | RGB（赤・緑・青）カラーコードを検証する場合                                             |
| `rgba`                           | RGBAカラーコード                                                     | RGBA（赤・緑・青・透明度）カラーコードを検証する場合                                    |
| `ssn`                            | 社会保障番号（SSN）                                                  | アメリカの社会保障番号を検証する場合                                                    |
| `timezone`                       | タイムゾーン                                                         | フィールドが有効なタイムゾーンであることを検証する場合                                   |
| `uuid`                           | ユニバーサリー一意識別子（UUID）                                      | フィールドが有効なUUIDであることを検証する場合                                          |
| `uuid3`                          | ユニバーサリー一意識別子（UUID v3）                                   | フィールドが有効なUUID v3であることを検証する場合                                       |
| `uuid3_rfc4122`                  | ユニバーサリー一意識別子（UUID v3 RFC4122）                           | フィールドが有効なUUID v3 RFC4122であることを検証する場合                               |
| `uuid4`                          | ユニバーサリー一意識別子（UUID v4）                                   | フィールドが有効なUUID v4であることを検証する場合                                       |
| `uuid4_rfc4122`                  | ユニバーサリー一意識別子（UUID v4 RFC4122）                           | フィールドが有効なUUID v4 RFC4122であることを検証する場合                               |
| `uuid5`                          | ユニバーサリー一意識別子（UUID v5）                                   | フィールドが有効なUUID v5であることを検証する場合                                       |
| `uuid5_rfc4122`                  | ユニバーサリー一意識別子（UUID v5 RFC4122）                           | フィールドが有効なUUID v5 RFC4122であることを検証する場合                               |
| `uuid_rfc4122`                   | ユニバーサリー一意識別子（UUID RFC4122）                              | フィールドが有効なUUID RFC4122であることを検証する場合                                  |
| `md4`                            | MD4ハッシュ                                                          | フィールドが有効なMD4ハッシュであることを検証する場合                                   |
| `md5`                            | MD5ハッシュ                                                          | フィールドが有効なMD5ハッシュであることを検証する場合                                   |
| `sha256`                         | SHA256ハッシュ                                                       | フィールドが有効なSHA256ハッシュであることを検証する場合                                |
| `sha384`                         | SHA384ハッシュ                                                       | フィールドが有効なSHA384ハッシュであることを検証する場合                                |
| `sha512`                         | SHA512ハッシュ                                                       | フィールドが有効なSHA512ハッシュであることを検証する場合                                |
| `ripemd128`                      | RIPEMD-128ハッシュ                                                   | フィールドが有効なRIPEMD-128ハッシュであることを検証する場合                            |
| `ripemd160`                      | RIPEMD-160ハッシュ                                                   | フィールドが有効なRIPEMD-160ハッシュであることを検証する場合                            |
| `tiger128`                       | TIGER128ハッシュ                                                     | フィールドが有効なTIGER128ハッシュであることを検証する場合                              |
| `tiger160`                       | TIGER160ハッシュ                                                     | フィールドが有効なTIGER160ハッシュであることを検証する場合                              |
| `tiger192`                       | TIGER192ハッシュ                                                     | フィールドが有効なTIGER192ハッシュであることを検証する場合                              |
| `semver`                         | セマンティックバージョニング2.0.0                                    | フィールドが有効なセマンティックバージョン（例：1.0.0）であることを検証する場合          |
| `ulid`                           | ユニバーサリー一意の辞書順に並べ替え可能な識別子（ULID）               | フィールドが有効なULIDであることを検証する場合                                          |
| `cve`                            | 共通脆弱性識別子（CVE ID）                                           | フィールドが有効なCVE識別子であることを検証する場合                                     |

### Comparisons

| タグ               | 説明                                | 使用例                                                                            |
|--------------------|-------------------------------------|-----------------------------------------------------------------------------------|
| `eq`               | 等しいかどうかをチェック             | 数値フィールドが特定の値に等しいことを確認する場合                                |
| `eq_ignore_case`   | 大文字小文字を無視して等しいかどうか | 文字列フィールドが大文字小文字を無視して特定の値に等しいことを確認する場合        |
| `gt`               | より大きいかどうかをチェック         | 数値フィールドが特定の値より大きいことを確認する場合                              |
| `gte`              | 以上かどうかをチェック               | 数値フィールドが特定の値以上であることを確認する場合                              |
| `lt`               | より小さいかどうかをチェック         | 数値フィールドが特定の値より小さいことを確認する場合                              |
| `lte`              | 以下かどうかをチェック               | 数値フィールドが特定の値以下であることを確認する場合                              |
| `ne`               | 等しくないかどうかをチェック         | 数値フィールドが特定の値に等しくないことを確認する場合                            |
| `ne_ignore_case`   | 大文字小文字を無視して等しくないか   | 文字列フィールドが大文字小文字を無視して特定の値に等しくないことを確認する場合    |

### Other

以下に、各バリデーションタグの説明と使用例を表形式でまとめました。

| タグ                     | 説明                                      | 使用例                                                                                  |
|--------------------------|-------------------------------------------|---------------------------------------------------------------------------------------|
| `dir`                    | 存在するディレクトリ                       | フィールドが存在するディレクトリであることを確認する場合                                 |
| `dirpath`                | ディレクトリパス                           | フィールドがディレクトリパスであることを確認する場合                                     |
| `file`                   | 存在するファイル                           | フィールドが存在するファイルであることを確認する場合                                     |
| `filepath`               | ファイルパス                               | フィールドがファイルパスであることを確認する場合                                         |
| `image`                  | 画像                                       | フィールドが画像であることを確認する場合（例：JPEG、PNG）                                 |
| `isdefault`              | デフォルト値である                         | フィールドがデフォルト値であることを確認する場合                                         |
| `len`                    | 長さ                                       | フィールドの長さが特定の値であることを確認する場合（例：文字列や配列の長さ）             |
| `max`                    | 最大値                                     | フィールドの値が特定の最大値以下であることを確認する場合                                 |
| `min`                    | 最小値                                     | フィールドの値が特定の最小値以上であることを確認する場合                                 |
| `oneof`                  | 指定された値のいずれか                     | フィールドの値が指定された値のいずれかであることを確認する場合                           |
| `required`               | 必須                                       | フィールドが必須であることを確認する場合                                                 |
| `required_if`            | 特定の条件が真の場合に必須                 | 他のフィールドの値が特定の値の場合にフィールドが必須であることを確認する場合             |
| `required_unless`        | 特定の条件が偽の場合に必須                 | 他のフィールドの値が特定の値でない場合にフィールドが必須であることを確認する場合         |
| `required_with`          | 他の特定のフィールドが存在する場合に必須   | 他の特定のフィールドが存在する場合にフィールドが必須であることを確認する場合             |
| `required_with_all`      | 全ての特定のフィールドが存在する場合に必須 | 全ての特定のフィールドが存在する場合にフィールドが必須であることを確認する場合           |
| `required_without`       | 他の特定のフィールドが存在しない場合に必須 | 他の特定のフィールドが存在しない場合にフィールドが必須であることを確認する場合           |
| `required_without_all`   | 全ての特定のフィールドが存在しない場合に必須 | 全ての特定のフィールドが存在しない場合にフィールドが必須であることを確認する場合         |
| `excluded_if`            | 特定の条件が真の場合に除外                 | 他のフィールドの値が特定の値の場合にフィールドが除外されることを確認する場合             |
| `excluded_unless`        | 特定の条件が偽の場合に除外                 | 他のフィールドの値が特定の値でない場合にフィールドが除外されることを確認する場合         |
| `excluded_with`          | 他の特定のフィールドが存在する場合に除外   | 他の特定のフィールドが存在する場合にフィールドが除外されることを確認する場合             |
| `excluded_with_all`      | 全ての特定のフィールドが存在する場合に除外 | 全ての特定のフィールドが存在する場合にフィールドが除外されることを確認する場合           |
| `excluded_without`       | 他の特定のフィールドが存在しない場合に除外 | 他の特定のフィールドが存在しない場合にフィールドが除外されることを確認する場合           |
| `excluded_without_all`   | 全ての特定のフィールドが存在しない場合に除外 | 全ての特定のフィールドが存在しない場合にフィールドが除外されることを確認する場合         |
| `unique`                 | 一意                                       | 配列やスライス内の値が一意であることを確認する場合                                      |