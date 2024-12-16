---
title: "AWS Lambdaでtmpディレクトリ使う"
date: 2023-10-18T07:00:00
weight: 4
categories:
  - aws
  - cloud-service
description: "AWS Lambdaで/tmpディレクトリを使用する方法。S3からファイルをダウンロードし、ローカルに保存して処理する例を示します。注意点として、/tmpのサイズ制限は512MBです。"
tags:
  - AWS Lambda
  - tmp directory
  - S3
  - File Handling
  - Ephemeral Storage
  - Node.js
  - Cloud Functions
  - AWS SDK
---

/tmp はデフォルトサイズが512MBなので気をつけるように

*nodejs v20*

```javascript
import { S3Client, GetObjectCommand } from "@aws-sdk/client-s3";
import { writeFile, readFile, access } from 'fs/promises';
import { constants } from 'fs';

const s3Client = new S3Client({ region: "ap-northeast-1" });
const filePath = "/tmp/[filename].json";
const bucketName = "credentials-bucket";
const objectKey = "[filename].json";

export async function handler(event) {
    try {
        // /tmpにファイルが存在するか確認
        try {
            await access(filePath, constants.R_OK);
            console.log("File exists in /tmp. Using cached version.");
        } catch {
            console.log("File does not exist in /tmp. Downloading from S3.");
            // S3からファイルをダウンロード
            const command = new GetObjectCommand({
                Bucket: bucketName,
                Key: objectKey,
            });
            const { Body } = await s3Client.send(command);
            const data = await streamToString(Body);
            
            // /tmpにファイルを保存
            await writeFile(filePath, data);
            console.log("File downloaded and saved to /tmp.");
        }

        // /tmpからファイルを読み込む
        const fileContent = await readFile(filePath, 'utf8');
        console.log("File content:", fileContent);

        // 必要な処理をここに追加

        return {
            statusCode: 200,
            body: "Process completed successfully.",
        };
    } catch (err) {
        console.log(err);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: "Error processing your request" }),
        };
    }
}

// ストリームを文字列に変換するヘルパー関数
function streamToString(stream) {
    return new Promise((resolve, reject) => {
        const chunks = [];
        stream.on('data', (chunk) => chunks.push(chunk));
        stream.on('error', reject);
        stream.on('end', () => resolve(Buffer.concat(chunks).toString('utf-8')));
    });
}

```

### 参考

- [ストレージと状態](https://docs.aws.amazon.com/ja_jp/whitepapers/latest/security-overview-aws-lambda/lambda-isolation-technologies.html#storagestate)
- [Lambdaの/tmpにファイルを置く前に](https://as-dev-null.netlify.app/where-does-the-file-placed-in-lambdas-tmp-disappear/)
- [【AWS Lambdaの基本コード その1】 S3からのファイル取得とローカル保存](https://recipe.kc-cloud.jp/archives/10035/)
- [EphemeralStorage](https://docs.aws.amazon.com/ja_jp/lambda/latest/api/API_EphemeralStorage.html)
