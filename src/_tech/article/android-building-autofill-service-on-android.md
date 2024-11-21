---
title: "Building an Autofill Service on Android"
date: 2024-11-21T14:00:00
weight: 4
categories:
  - tech
  - android
description: "Step-by-step guide to creating an Android autofill service."
---

I've created a sample code for building [autofill services](https://developer.android.com/identity/autofill/autofill-services). This guide walks you through the implementation and provides an overview of the necessary changes.

For setup instructions, please refer to this document: [Chrome on Android to support third-party autofill services natively](https://developers.googleblog.com/en/chrome-3p-autofill-services/).

The implementation presented here simply shows autofill suggestions for the `username` text field.

Below are the modifications and newly created files from this project in Android Studio:

```txt
app
  |---manifests
  |      |---- AndroidManifest.xml
  |
  |---kotlin+java
  |      |---- com.example.myautofillapplication
  |                     |----- MyAutofillService.kt
  |
  |------res
  |      |---- values
  |      |       |---- string.xml
  |      |       
  |      |---- xml
  |      |       |---- autofill_service_config.xml
```

### AndroidManifest.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools" >

    <application
        android:allowBackup="true"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="@xml/backup_rules"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.MyAutofillApplication"
        tools:targetApi="31" >
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:label="@string/app_name"
            android:theme="@style/Theme.MyAutofillApplication" >
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <!-- Added autofill service element -->
        <service
            android:name=".MyAutofillService"
            android:exported="true"
            android:label="My Autofill Service"
            android:permission="android.permission.BIND_AUTOFILL_SERVICE">
            <intent-filter>
                <action android:name="android.service.autofill.AutofillService" />
            </intent-filter>
            <meta-data
                android:name="android.autofill"
                android:resource="@xml/autofill_service_config" />
        </service>
    </application>

</manifest>
```

### MyAutofillService.kt

The core of the autofill functionality is implemented in `MyAutofillService.kt`. This new file provides the logic for processing autofill requests and suggesting autofill data.

```kotlin
package com.example.myautofillapplication

import android.app.assist.AssistStructure
import android.os.CancellationSignal
import android.service.autofill.*
import android.util.Log
import android.view.autofill.AutofillId
import android.view.autofill.AutofillValue
import android.widget.RemoteViews

class MyAutofillService : AutofillService() {

    override fun onFillRequest(
        request: FillRequest,
        cancellationSignal: CancellationSignal,
        callback: FillCallback
    ) {
        Log.d(TAG, "onFillRequest called")

        val structure = request.fillContexts.last().structure
        Log.d(TAG, "AssistStructure: windowNodeCount = ${structure.windowNodeCount}")

        val targetFields = extractAutofillIds(structure)

        if (targetFields.isEmpty()) {
            Log.d(TAG, "No username fields found")
            callback.onFailure("No fields to autofill")
            return
        }

        callback.onSuccess(
            FillResponse.Builder()
                .addDataset(buildDataset(targetFields, "example_user"))
                .build()
        )
    }

    private fun extractAutofillIds(structure: AssistStructure): List<AutofillId> {
        return (0 until structure.windowNodeCount).flatMap { index ->
            val windowNode = structure.getWindowNodeAt(index)
            Log.d(TAG, "Traversing windowNode $index: title = ${windowNode.title}")
            findUsernameFields(windowNode.rootViewNode)
        }
    }

    private fun findUsernameFields(node: AssistStructure.ViewNode): List<AutofillId> {
        val matches = mutableListOf<AutofillId>()

        node.htmlInfo?.attributes?.forEach { attribute ->
            val key = attribute.first
            val value = attribute.second
            if (key == "name" && value == "username") {
                Log.d(TAG, "Match found: idEntry=${node.idEntry}, hint=${node.hint}")
                node.autofillId?.let { matches.add(it) }
            }
        }

        repeat(node.childCount) { index ->
            Log.d(TAG, "Traversing child $index of node: idEntry=${node.idEntry}")
            matches += findUsernameFields(node.getChildAt(index))
        }

        return matches
    }

    private fun buildDataset(fields: List<AutofillId>, username: String): Dataset {
        val presentation = RemoteViews(packageName, android.R.layout.simple_list_item_1).apply {
            setTextViewText(android.R.id.text1, "Autofill Username")
        }

        return Dataset.Builder().apply {
            fields.forEach { autofillId ->
                setValue(
                    autofillId,
                    AutofillValue.forText(username),
                    presentation
                )
            }
        }.build()
    }

    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
        // Saving user input data if required
    }

    companion object {
        private const val TAG = "MyAutofillService"
    }
}
```

### string.xml

Updated `string.xml` to include a description for the autofill service.

```xml
<resources>
    <string name="app_name">MyAutofillApplication</string>
    <!-- Added service description -->
    <string name="service_description">MyAutofillApplicationTestApplication</string>
</resources>
```

### autofill_service_config.xml

Added a new configuration file for the autofill service.

```xml
<?xml version="1.0" encoding="utf-8"?>
<autofill-service
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:settingsActivity="com.example.myautofillapplication.SettingsActivity"
    android:description="@string/service_description" />
```
