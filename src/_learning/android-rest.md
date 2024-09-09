---
title: "アプリ インターネットからデータを取得"
date: 2024-4-23T16:45:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
---

# REST ウェブサービス

ウェブサービスは、インターネット経由で提供されるソフトウェアベースの機能です。アプリはウェブサービスにリクエストを送信することにより、データを取得できます。

## REST アーキテクチャ

一般的なウェブサービスは **REST アーキテクチャ** を使用します。REST アーキテクチャを提供するウェブサービスを **RESTful サービス** と呼びます。RESTful ウェブサービスは、標準のウェブ コンポーネントとプロトコルを使用して構築されます。REST ウェブサービスへのリクエストは、URI を介する標準的な方法で行います。

アプリでウェブサービスを使用するには、ネットワーク接続を確立してサービスと通信する必要があります。アプリは、レスポンス データを受信して解析し、アプリが使用できる形式に変換する必要があります。

### Retrofit ライブラリ

`Retrofit` ライブラリは、アプリが REST ウェブサービスにリクエストを送信することを可能にするクライアント ライブラリです。コンバータを使用して、ウェブサービスに送信するデータとウェブサービスから返されたデータをどのように処理するかを Retrofit に伝えます。たとえば、`ScalarsConverter` は、ウェブサービスのデータを String またはその他のプリミティブとして扱います。

アプリがインターネットに接続できるようにするには、Android マニフェストに `"android.permission.INTERNET"` 権限を追加します。

## JSON 解析

多くの場合、ウェブサービスからのレスポンスは、構造化データを表す一般的な形式である JSON で書式設定されます。JSON オブジェクトは Key-Value ペアのコレクションです。JSON オブジェクトのコレクションは JSON 配列です。ウェブサービスからのレスポンスは JSON 配列として取得されます。

### kotlinx.serialization

Kotlin では、`kotlinx.serialization` でデータのシリアル化ツールを使用できます。`kotlinx.serialization` は、JSON 文字列を Kotlin オブジェクトに変換するライブラリのセットを備えています。コミュニティで開発された Retrofit 用の Kotlin Serialization Converter ライブラリとして、`retrofit2-kotlinx-serialization-converter` があります。

異なるプロパティ名をキーで使用するには、そのプロパティに `@SerialName` アノテーションを付けて JSON キー value を指定します。

### サンプルコード

<https://github.com/google-developer-training/basic-android-kotlin-compose-training-mars-photos/blob/main/app/src/main/java/com/example/marsphotos/network/MarsApiService.kt>

#### ステップ1: 依存関係の追加

まず、Androidプロジェクトのbuild.gradleファイルにRetrofitとkotlinx.serializationライブラリの依存関係を追加します。

```bash
dependencies {
    // Retrofit
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-scalars:2.9.0'

    // Kotlin Serialization
    implementation 'org.jetbrains.kotlinx:kotlinx-serialization-json:1.3.0'
    implementation 'com.jakewharton.retrofit:retrofit2-kotlinx-serialization-converter:0.8.0'
}
```

#### ステップ2: Androidマニフェストの更新

AndroidManifest.xmlファイルにインターネットアクセス権限を追加します。

```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
</manifest>
```

#### ステップ3: モデルクラスの定義

Kotlinでデータモデルを定義し、kotlinx.serializationを使用してシリアル化します。

```kotlin
import kotlinx.serialization.Serializable

@Serializable
data class User(
    val id: Int,
    val name: String,
    val email: String
)
```

#### ステップ4: Retrofit インターフェースの定義

Retrofit インターフェースを定義して、ウェブAPIとのコミュニケーションを設定します。

```kotlin
import retrofit2.http.GET
import retrofit2.Call

interface ApiService {
    @GET("users")
    fun getUsers(): Call<List<User>>
}

```

#### ステップ5: Retrofitインスタンスの作成

Retrofitインスタンスを作成し、シリアル化コンバータを設定します。

```kotlin
import retrofit2.Retrofit
import retrofit2.converter.scalars.ScalarsConverterFactory
import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import kotlinx.serialization.json.Json

val retrofit = Retrofit.Builder()
    .baseUrl("https://your.api.url/")
    .addConverterFactory(Json.asConverterFactory("application/json".toMediaType()))
    .build()

val apiService = retrofit.create(ApiService::class.java)


```

#### ステップ6: APIの呼び出しとデータ処理

APIを呼び出し、受け取ったデータを処理します。

```kotlin
apiService.getUsers().enqueue(object : Callback<List<User>> {
    override fun onResponse(call: Call<List<User>>, response: Response<List<User>>) {
        if (response.isSuccessful) {
            val users = response.body() ?: emptyList()
            // ユーザーデータの処理
        }
    }

    override fun onFailure(call: Call<List<User>>, t: Throwable) {
        // エラー処理
    }
})

```
