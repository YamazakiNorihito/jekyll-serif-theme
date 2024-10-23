---
title: "アプリ Room を使用してローカル データベース"
date: 2024-4-24T07:00:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
description: "AndroidアプリでRoomライブラリを使用してローカルデータベースにデータを保存する方法を解説。エンティティ、DAO、データベースクラスの作成方法と、Database Inspectorを使ったデータの検査と管理についての実践的な手順を紹介します。"
---


[Room を使用してローカル データベースにデータを保存する](https://developer.android.com/training/data-storage/room?hl=ja)

Room の 3 つのコンポーネントを使用すると、こうしたワークフローがシームレスになります。

1. Room エンティティは、アプリのデータベースのテーブルを表します。テーブルの行に格納されているデータの更新や、挿入するための新しい行の作成に使用します。
1. Room DAO は、データベース内のデータを取得、更新、挿入、削除するためにアプリで使用するメソッドを提供します。
1. Room Database クラスは、データベースに関連付けられている DAO のインスタンスをアプリに提供するデータベース クラスです。

公式からは`SQLite API を直接使用するのではなく、Room を使用することを強くおすすめ`されています。

## コードサンプル

```kotlin
// entity
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity
data class Item(
    @PrimaryKey val id: Int,
    val name: String,
    val price: Double,
    val quantity: Int
)


// dao
import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import androidx.room.Delete

@Dao
interface ItemDao {
    @Query("SELECT * FROM Item")
    fun getAllItems(): List<Item>

    @Query("SELECT * FROM Item WHERE id = :id")
    fun getItemById(id: Int): Item

    @Insert
    fun insertItem(item: Item)

    @Update
    fun updateItem(item: Item)

    @Delete
    fun deleteItem(item: Item)
}

// databse
import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

/**
 * Database class with a singleton Instance object.
 * このクラスは、Roomデータベースを表し、シングルトンパターンを使用してデータベースのインスタンスを管理します。
 * シングルトンパターンは、インスタンスがアプリケーション中で一つだけ存在することを保証します。
 */
@Database(entities = [Item::class], version = 1, exportSchema = false) // データベースアノテーション
abstract class InventoryDatabase : RoomDatabase() {
    // itemDao() はデータベース操作のためのDAOを提供するメソッドです。
    abstract fun itemDao(): ItemDao

    companion object {
        @Volatile // このキーワードは、Instance変数が複数のスレッドによって共有されることを示します。
        private var Instance: InventoryDatabase? = null

        // getDatabase() メソッドは、データベースインスタンスを提供または生成します。
        fun getDatabase(context: Context): InventoryDatabase {
            // Instanceが非nullの場合はそれを返し、nullの場合は新しいデータベースインスタンスを生成します。
            return Instance ?: synchronized(this) {
                // RoomのdatabaseBuilderを使用して新しいデータベースインスタンスを生成します。
                Room.databaseBuilder(context, InventoryDatabase::class.java, "item_database")
                    .build() // データベースをビルドする
                    .also { Instance = it } // 生成されたインスタンスをInstanceに格納します。
            }
        }
    }
}
```

## Database Inspector

<https://developer.android.com/studio/inspect/database>
アプリを動作させながらアプリのデータベースの検査、クエリ、変更を行えます。

[手順](https://developer.android.com/codelabs/basic-android-kotlin-compose-persisting-data-room?hl=ja&continue=https%3A%2F%2Fdeveloper.android.com%2Fcourses%2Fpathways%2Fandroid-basics-compose-unit-6-pathway-2%3Fhl%3Dja%23codelab-https%3A%2F%2Fdeveloper.android.com%2Fcodelabs%2Fbasic-android-kotlin-compose-persisting-data-room#9)

1. API レベル 26 以降を搭載した接続済みデバイスまたはエミュレータでアプリを実行します。
1. Android Studio で、メニューバーから [View] > [Tool Windows] > [App Inspection] を選択します。
1. [Database Inspector] タブを選択します。
1. [Database Inspector] ペインのプルダウン メニューから com.example.inventory を選択します（選択されていない場合）。Inventory アプリの item_database が [Databases] ペインに表示されます。
1. [Databases] ペインで item_database のノードを開き、[Item] を選択して調べます。[Databases] ペインが空の場合はエミュレータを使用し、[Add Item] 画面からデータベースにアイテムを追加します。
1. Database Inspector の [Live updates] チェックボックスをオンにすると、エミュレータまたはデバイス上で実行中のアプリを操作したときに、表示されるデータが自動的に更新されます。
