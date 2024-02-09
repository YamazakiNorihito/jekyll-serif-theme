---
title: "AWS S3　To　EC2　Download"
date: 2023-10-18T07:00:00
weight: 4
categories:
  - aws
  - cloud-service
---

1. IAMロールの作成
   1. AWS管理コンソールにログインします。
   2. 「IAM」サービスに移動し、「ロール」を選択して「ロールを作成」をクリックします。
   3. 「AWSサービス」を選択し、「EC2」を選択して「次のステップ: アクセス権限」をクリックします。
   4. 「AmazonS3ReadOnlyAccess」ポリシーを検索し、選択します（もしくは、必要に応じてカスタムポリシーを作成します）。
   5. 「次のステップ: タグ」をクリックし、「次のステップ: 確認」に進みます。
   6. ロールに名前を付け、「ロールを作成」をクリックします。
      1. ロール名:S3ToEC2DownloadRole
      2. 許可ポリシー:AmazonS3ReadOnlyAccess
         
         ```json
            {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Action": [
                            "s3:Get*",
                            "s3:List*",
                            "s3:Describe*",
                            "s3-object-lambda:Get*",
                            "s3-object-lambda:List*"
                        ],
                        "Resource": "*"
                    }
                ]
            }
         ``` 
      3. 信頼ポリシー

         ```json
            {
              "Version": "2012-10-17",
              "Statement": [
                {
                  "Effect": "Allow",
                  "Principal": {
                    "Service": "ec2.amazonaws.com"
                  },
                  "Action": "sts:AssumeRole"
                }
              ]
            }
          ```

インスタンス起動毎UserDataを実行する
```bash
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/cloud-config; charset="us-ascii"

#cloud-config
cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
mkdir -p /yamazaki
cd /yamazaki
aws s3 cp s3://nyamazaki-credentials-bucket/ff-api-server-firebase-adminsdk-nki15-5a868d3dda.json /yamazaki/

aws s3 cp s3://nyamazaki-credentials-bucket/ff-api-server-firebase-adminsdk-nki15-5a868d3dda.json /yamazaki/
--//--
```

```bash
cat /var/log/cloud-init-output.log
```
        

aws s3 cp s3://nyamazaki-credentials-bucket/ff-api-server-firebase-adminsdk-nki15-5a868d3dda.json /home/ec2-user/.credentials/ff-api-server-firebase-adminsdk-nki15-5a868d3dda.json

```bash
/opt/aws/bin/cfn-init -v --stack S3ToEC2DownloadCloudformation --resource S3ToEC2DownloadCloudformation --region ap-northeast-1
```

- [EC2用にIAMロールを作ったのに、EC2へ割り当てられない！](https://dev.classmethod.jp/articles/how-to-create-iam-instance-profile-using-amc/)
- [Amazon EC2 Linux インスタンスを再起動するたびに、ユーザーデータを利用してスクリプトを自動的に実行するにはどうすればよいですか?](https://repost.aws/ja/knowledge-center/execute-user-data-ec2)
