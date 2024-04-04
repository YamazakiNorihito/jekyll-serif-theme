---
title: "Module ngx_http_sub_moduleの日本語翻訳"
date: 2024-04-02T08:10:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
---

# Module ngx_http_sub_module
[元ページ](https://nginx.org/en/docs/http/ngx_http_sub_module.html)

- [Module ngx\_http\_sub\_module](#module-ngx_http_sub_module)
  - [Directives](#directives)
    - [sub\_filter](#sub_filter)
    - [sub\_filter\_last\_modified](#sub_filter_last_modified)
    - [sub\_filter\_once](#sub_filter_once)
    - [sub\_filter\_types](#sub_filter_types)
- [余談](#余談)



>The ngx_http_sub_module module is a filter that modifies a response by replacing one specified string by another.
This module is not built by default, it should be enabled with the --with-http_sub_module configuration parameter.


ngx_http_sub_moduleモジュールは、指定された文字列を別の文字列で置き換えることでレスポンスを修正するフィルターです。
このモジュールはデフォルトではビルドされず、--with-http_sub_module設定パラメーターで有効化する必要があります。


**Example Configuration**
```config
location / {
    sub_filter '<a href="http://127.0.0.1:8080/'  '<a href="https://$host/';
    sub_filter '<img src="http://127.0.0.1:8080/' '<img src="https://$host/';
    sub_filter_once on;
}
```

## Directives

### sub_filter

|  |  |
| ---- | ---- |
|Syntax|	sub_filter *string* *replacement*;|
|Default|	— |
|Context|	http, server, location|

>Sets a string to replace and a replacement string. The string to replace is matched ignoring the case. The string to replace (1.9.4) and replacement string can contain variables. Several sub_filter directives can be specified on the same configuration level (1.9.4). These directives are inherited from the previous configuration level if and only if there are no sub_filter directives defined on the current leve

置換対象の文字列と置換する文字列を設定します。置換対象の文字列は、大文字小文字を区別せずに一致させます。置換対象の文字列（1.9.4）と置換文字列には変数を含めることができます。同じ構成レベルで複数のsub_filterディレクティブを指定することができます（1.9.4）。これらのディレクティブは、現在のレベルでsub_filterディレクティブが定義されていない場合に限り、前の構成レベルから継承されます。


### sub_filter_last_modified

|  |  |
| ---- | ---- |
|Syntax|	sub_filter_last_modified on | off; |
|Default|	sub_filter_last_modified off; |
|Context|	http, server, location |
This directive appeared in version 1.5.1.

>Allows preserving the “Last-Modified” header field from the original response during replacement to facilitate response caching.
>
>By default, the header field is removed as contents of the response are modified during processing.

置換中に元のレスポンスから「Last-Modified」ヘッダーフィールドを保持することで、レスポンスのキャッシュを容易にすることができます。

デフォルトでは、処理中にレスポンスの内容が変更されるため、ヘッダーフィールドは削除されます。


### sub_filter_once

|  |  |
| ---- | ---- |
|Syntax|	sub_filter_once on \| off;|
|Default|	sub_filter_once on; |
|Context|	http, server, location |

>Indicates whether to look for each string to replace once or repeatedly.

置換する各文字列を一度だけ探すか繰り返し探すかを指定します。

### sub_filter_types

|  |  |
| ---- | ---- |
|Syntax|	sub_filter_types mime-type ...;|
|Default|	sub_filter_types text/html; |
|Context| http, server, location|

>Enables string replacement in responses with the specified MIME types in addition to “text/html”. The special value “*” matches any MIME type (0.8.29).

"text/html" に加えて、指定されたMIMEタイプのレスポンスで文字列置換を有効にします。特別な値 "* " は任意のMIMEタイプに一致します（0.8.29）


# 余談

正規表現での置換はできない。
ngx_http_substitutions_filter_moduleを使うと正規表現で置換ができるみたい、buildが必要みたいでオラ全然わからない
https://www.nginx.com/resources/wiki/modules/substitutions/