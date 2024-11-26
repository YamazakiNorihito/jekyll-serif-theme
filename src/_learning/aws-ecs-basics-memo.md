---
title: "Amazon Elastic Container Serviceの基礎知識のメモ"
date: 2024-11-1T07:15:00
mermaid: true
weight: 7
tags:
  - AWS
  - DynamoDB
  - NoSQL
description: "自分用のメモとして、ECSについて整理。設計に役立つベストプラクティスも含む"
---

[What is Amazon Elastic Container Service?](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html)を順番に読んでいく

## Amazon Elastic Container Service

Amazon Elastic Container Service (Amazon ECS) は、AWSが提供するコンテナ管理サービス。
コンテナアプリケーションのdeploy, manage, scale を簡単に行えるよう設計されており、
AWSの各種サービスやサードパーティツール（ECRやDocker）とも統合されています。

そのため、環境構築から運用までの作業をECSに任せることができ、開発者はアプリケーション開発に集中できるのが特徴です。

## ECS components

Amazon ECSは３つのlayerで構成される

1. **Capacity**: コンテナを実行するために必ず設定が必要なインフラストラクチャ
   1. 設定する選択肢（以下の3つのいずれか）
      1. Amazon EC2 instances
      2. AWS Fargate
      3. On-premises
2. **Controller**:ECS上で動作するアプリケーションの配置や管理を行うソフトウェア
3. **Provisioning**:ECSのリソースをセットアップ・管理できる手段
   1. AWS Management Console
   2. [AWS Command Line Interface (AWS CLI)](https://aws.amazon.com/cli/)
   3. [AWS SDKs](https://aws.amazon.com/developer/tools/#SDKs)
   4. [Copilot](https://github.com/aws/copilot-cli)
   5. [AWS CDK](https://docs.aws.amazon.com/ja_jp/cdk/v2/guide/home.html)

## Application lifecycle

![ECS Lifecycle](https://docs.aws.amazon.com/images/AmazonECS/latest/developerguide/images/ecs-lifecycle.png)

### 1. イメージのビルドと登録

1. **Dockerfile**: 各アプリケーション用にDockerfileを作成します。これには、必要なコード、ライブラリ、ツールが含まれます。
2. **Build Image**: Dockerfileをもとにコンテナイメージをビルドします。
3. **Amazon ECR**: 作成したイメージをAmazon ECRなどのコンテナレジストリに保存します。これにより、必要なときにイメージをダウンロードしてデプロイできます。

### 2. タスク定義

**ECS Task Definition**は、コンテナアプリケーションの設計図です。JSON形式のファイルで、アプリケーションを構成する1つ以上のコンテナとその設定を指定します。主な設定項目には以下が含まれます。

- **Image**: Amazon ECRなどのレジストリに保存されたコンテナイメージ。
- **Ports**: 開放するポートを指定します。
- **Data Volumes**: データの永続化やコンテナ間で共有するストレージを指定します。

### 3. クラスターにServiceまたはTaskとしてデプロイ

1. **Task**:
   - クラスター内で実行されるタスク定義のインスタンスです。
   - スタンドアロンで実行することも、サービスの一部として実行することも可能です。
   - タスクは一度実行されると完了するタイプと、常時稼働するタイプがあります。

2. **Service**:
   - クラスター内で指定した数のタスクを常に稼働させたい場合に使用します。
   - **Service Scheduler**がタスク数を維持するよう管理しており、タスクが失敗や停止した場合、タスク定義に基づいて新しいタスクを起動し、指定したタスク数を保ちます。

3. **Cluster**:
   - **Capacity Infrastructure**（例: EC2やFargate）上で実行されるTaskやServiceの論理的なグループです。

4. **Container Agent**:
   - Amazon ECSクラスター内の各**Container Instance**上で稼働します。
   - 実行中のタスクの状態やリソース使用量をAmazon ECSに送信します。
   - Amazon ECSからのリクエストに基づいてタスクの開始や停止を行います。

## getting-started

Amazon ECSを使ってコンテナのデプロイを試してみました。今回は、Amazon ECRにコンテナイメージを登録し、
それを使用してAmazon ECS上で実行するまでの手順をまとめました。

### Amazon ECRにコンテナイメージを登録

[create-container-image](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-container-image.html)

```bash
# create Dockerfile
touch Dockerfile # File content reference `ecs/Dockerfile`
docker build -t hello-world .
docker run -t -i -p 80:80 hello-world

# For cross-platform builds targeting Linux x86_64 (amd64) for Fargate
docker buildx build --platform linux/amd64 -t hello-world .

# create private repository
## aws ecr create-repository --repository-name hello-repository --region {region}
aws ecr create-repository --repository-name hello-repository --region ap-northeast-1 --profile workday

## Example output
###{
###    "repository": {
###        "repositoryArn": "arn:aws:ecr:ap-northeast-1:[aws_account_id]:repository/hello-repository",
###        "registryId": "[aws_account_id]",
###        "repositoryName": "hello-repository",
###        "repositoryUri": "[aws_account_id].dkr.ecr.ap-northeast-1.amazonaws.com/hello-repository",
###        "createdAt": "2024-11-12T06:39:19.706000+09:00",
###        "imageTagMutability": "MUTABLE",
###        "imageScanningConfiguration": {
###            "scanOnPush": false
###        },
###        "encryptionConfiguration": {
###            "encryptionType": "AES256"
###        }
###    }
###}

# To create a public repository
## aws ecr-public create-repository --repository-name hello-repository --region us-east-1 --profile workday

# image push
## docker tag hello-world {aws_account_id}.dkr.ecr.{region}.amazonaws.com/hello-repository
docker tag hello-world [aws_account_id].dkr.ecr.ap-northeast-1.amazonaws.com/hello-repository

## aws ecr get-login-password --region {region} | docker login --username AWS --password-stdin {aws_account_id}.dkr.ecr.{region}.amazonaws.com
aws ecr get-login-password --region ap-northeast-1 --profile workday | docker login --username AWS --password-stdin [aws_account_id].dkr.ecr.ap-northeast-1.amazonaws.com

## Expected output
### Login Succeeded

## docker push {aws_account_id}.dkr.ecr.{region}.amazonaws.com/hello-repository
docker push [aws_account_id].dkr.ecr.ap-northeast-1.amazonaws.com/hello-repository

```

### Amazon ECSにデプロイする

```bash
aws cloudformation create-stack --stack-name ecs-stack --template-body file://template.yaml --parameters file://parameters.json --region ap-northeast-1 --profile workday --capabilities CAPABILITY_NAMED_IAM
```

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: ECS Fargate Sample Template (without ALB, uses default VPC)

Parameters:
  VPCId:
    Type: AWS::EC2::VPC::Id
    Description: VPC ID to use (default VPC)
    Default: default
  SubnetIds:
    Type: List<AWS::EC2::Subnet::Id>
    Description: List of subnet IDs (comma-separated)
  AssignPublicIp:
    Type: String
    Default: ENABLED
    AllowedValues:
      - ENABLED
      - DISABLED
    Description: Assign public IP to ECS task

Resources:
  ECSCluster:
    Type: AWS::ECS::Cluster
    Properties:
      ClusterName: !Sub '${AWS::StackName}-cluster'

  ECSLogGroup:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: ecs/hello-container
      RetentionInDays: 7

  ECSTaskExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Sub '${AWS::StackName}-ecsTaskExecutionRole'
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - ecs-tasks.amazonaws.com
            Action:
              - sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

  TaskDefinition:
    Type: AWS::ECS::TaskDefinition
    Properties:
      Family: !Sub '${AWS::StackName}-task'
      Cpu: '256'
      Memory: '512'
      NetworkMode: awsvpc
      RequiresCompatibilities:
        - FARGATE
      RuntimePlatform:
        OperatingSystemFamily: LINUX
      ExecutionRoleArn: !GetAtt ECSTaskExecutionRole.Arn
      ContainerDefinitions:
        - Name: hello-container
          Image: [aws_account_id].dkr.ecr.ap-northeast-1.amazonaws.com/hello-repository
          LogConfiguration:
            LogDriver: awslogs
            Options:
              awslogs-group: !Ref ECSLogGroup
              awslogs-region: !Ref "AWS::Region"
              awslogs-stream-prefix: ecs
          Essential: true
          PortMappings:
            - ContainerPort: 80
              Protocol: tcp

  ECSSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: "ECS Task Security Group"
      VpcId: !Ref VPCId
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0

  Service:
    Type: AWS::ECS::Service
    Properties:
      Cluster: !Ref ECSCluster
      ServiceName: !Sub '${AWS::StackName}-service'
      TaskDefinition: !Ref TaskDefinition
      LaunchType: FARGATE
      DesiredCount: 1
      NetworkConfiguration:
        AwsvpcConfiguration:
          AssignPublicIp: !Ref AssignPublicIp
          SecurityGroups:
            - !Ref ECSSecurityGroup
          Subnets: !Ref SubnetIds
```

parameters.json

```json
[
  {
    "ParameterKey": "VPCId",
    "ParameterValue": "vpc-xxxxxxxxxxxxxxxxx"
  },
  {
    "ParameterKey": "SubnetIds",
    "ParameterValue": "subnet-xxxxxxxxxxxxxxxxx"
  },
  {
    "ParameterKey": "AssignPublicIp",
    "ParameterValue": "ENABLED"
  }
]

```

## [Amazon ECS best practices](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-best-practices.html)

### [Connect Amazon ECS applications to the internet](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/networking-outbound.html)

containerized applicationsをoutbound access to the internetするarchitectureは２つある

1. Public subnet and internet gateway
   1. ECSサービス作成時にpublic subnetsを指定
      - Amazon ECSサービスを作成する際、ネットワーキング設定でpublic subnetsを選択します。
   2. public IPアドレスの割り当て設定
      - “Assign public IP address” オプションを利用し、各Fargateタスクにpublic IPアドレスを割り当てます。
   3. 各タスクが個別のpublic IPアドレスを持つ
      - Fargateタスクはそれぞれ独自のpublic IPアドレスを持ち、インターネットと直接通信が可能です。
2. Private subnet and NAT gateway
   1. ECSサービスの設定
      - Amazon ECSサービスを作成する際、ネットワーキング設定でprivate subnetsを指定します。
   2. パブリックIPアドレスの割り当ては無効化
      - 「Assign public IP address」オプションを有効にせず、タスクが直接public IPアドレスを持たないように設定します。
   3. NAT Gatewayを介したアウトバウンドトラフィックのルーティング
      - private subnet内の各Fargateタスクは、そのsubnetに関連付けられたNAT gatewayを通じてインターネットへのアウトバウンドトラフィックを処理します。

### [Best practices for receiving inbound connections to Amazon ECS from the internet](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/networking-inbound.html)

全ての前提としてECSはprivate subnetにlaunchさせた前提です。

#### Application Load Balancer

ALBはapplication層（OSIモデルの第7層）で動作するロードバランサーです。特にHTTPサービスを公開する場合に最適です。

1. SSL/TLS termination: Application Load Balancer(ALB)はHTTPS通信と証明書を維持します。オプションとして、SSL接続をALBで終了させることで、application側で証明書を管理する必要がなくなります。
2. 高度なルーティング: ALBは複数のDNSホスト名を持ち、リクエストのホスト名やパスに基づいて異なる宛先にリクエストをルーティングできます。これにより、1つのALBで複数の内部サービスやREST APIのマイクロサービスを処理可能です。
3. gRPCとWebSocketのサポート: ALBはHTTPだけでなく、gRPCやWebSocketベースのサービスも処理可能で、HTTP/2にも対応しています。
4. セキュリティ: ALBは悪意のあるトラフィックからアプリケーションを保護します。HTTP非同期ミティゲーションやAWS WAFとの統合により、SQLインジェクションやクロスサイトスクリプティングなどの攻撃パターンをフィルタリングします。

#### Network Load Balancer

NLBはtransport層（OSIモデルの第4層）で動作するロードバランサーです。HTTPを使用しないアプリケーションに最適です。

1. エンドツーエンド暗号化:ネットワークロードバランサー（NLB）はOSIモデルの第4層で動作し、パケットの内容を解析しないため、エンドツーエンド暗号化された通信を負荷分散するのに適しています。
2. TLS暗号化:NLBはTLS接続の終端も可能で、バックエンドアプリケーションで独自のTLS実装が不要になる。
3. UDPサポート:第4層で動作するため、非HTTPワークロードやTCP以外のプロトコルに適している。

#### Amazon API Gateway HTTP API

Amazon API Gatewayは、要求量の突然の急増や低い要求量があるHTTPアプリケーションに適しています。
リクエストが少ない場合やリクエストが少ない期間がある場合、API Gatewayの方がロードバランサー（ALB/NLB）よりコストを抑えることができる。

1. API Gateway は、クライアント認証、使用量の階層、およびリクエスト/レスポンスの変更に関する追加機能を提供します。
2. API Gateway は、エッジ、リージョナル、およびプライベートの API ゲートウェイエンドポイントをサポート
3. SSL/TLS termination
4. 異なる HTTP パスを異なるバックエンドのマイクロサービスにルーティング

### [Best practices for connecting Amazon ECS to AWS services from inside your VPC](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/networking-connecting-vpc.html)

AWS Serviceと通知する手段は２つある。それを紹介します。

#### NAT gateway

private subnetに`Application container`を配置して、public subnetに`NAT`を配置するアプローチ
NATを通じてAWS Serviceのリソースと通信する

![natgateway](https://docs.aws.amazon.com/images/AmazonECS/latest/developerguide/images/natgateway.png)

このアプローチのデメリット

1. NATゲートウェイの制約
   1. NATゲートウェイ自体には通信先をフィルタリングする機能がない。
      1. プライベートサブネットのリソースがNATゲートウェイを通じて通信できる先を直接制限することはできません。
      2. バックエンド層（Backend tier）のみ通信を制限することは難しく、VPC全体のアウトバウンド通信に影響を与える可能性がある。
2. NATゲートウェイの料金体系
   1. NATゲートウェイは、データ転送量に応じて1GBごとに課金されます。
   2. 次の操作でも課金対象になります:
      1. Amazon S3からの大容量ファイルダウンロード
      2. DynamoDBへの大量のデータベースクエリ
      3. Amazon ECRからのイメージ取得
3. NATゲートウェイの帯域幅
   1. 5 Gbpsの帯域幅をサポートし、最大で45 Gbpsまで自動的にスケールします。
   2. 単一のNATゲートウェイを経由する場合、非常に高い帯域幅を必要とするアプリケーションではネットワークの制約が発生する可能性があります。
      1. ワークロードを複数のサブネットに分散し、それぞれに個別のNATゲートウェイを割り当てることで、帯域幅の制約を回避できます。

#### AWS PrivateLink

AWS PrivateLinkはサブネット内にElastic Network Interfaces（ENI）をプロビジョニングし、VPCのルーティングルールを使用して、サービスのホスト名への通信をENIを通じて直接目的のAWSサービスに送信します。
[AWS PrivateLinkとVPCエンドポイントの整理](https://blog.nybeyond.com/learning/aws-privatelink-memo/)に書かれているので詳しく書くことは避ける。

![endpointaccess-multiple](https://docs.aws.amazon.com/images/AmazonECS/lates…developerguide/images/endpointaccess-multiple.png)

### [Fargate security best practices in Amazon ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security-fargate.html)

- `AWS KMS` または `Customer Managed Keys (CMK)` を使用して `Fargate` の `ephemeral storage` を暗号化可能。  
- Platform version 1.4.0 以降のタスクは `20 GiB` の `ephemeral storage` を使用。
  - `ephemeralStorage` パラメータで最大 `200 GiB` まで拡張可能。
- 2020/5/28 以降に起動したタスクでは、`Fargate` で管理されている管理キーで `AES-256` による暗号化が適用される
- AWS Fargateでは、SYS_PTRACE以外のLinux Capabilityはすべて無効化されます。
- [Amazon GuardDuty](https://aws.amazon.com/jp/guardduty/)は脅威検出サービス
  - AWS環境ないのaccounts, containers, workloads, dataを保護するのを助ける

### [Fargate security considerations for Amazon ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-security-considerations.html)

- Fargateの特性
  - Fargateで実行されるコンテナは、isolationされた仮想環境で実行される。
    - そのため、リソース（network interfaces, ephemeral storage, CPU, memoryなど）は他のタスクと共有されず、完全に独立している。
  - Task内のコンテナ
    - 1つのタスクには複数のコンテナ（application containerとsidecar container）を含むことができる。
    - 同一タスク内のコンテナは、リソースや network namespaces(IP address and network ports)を共有する
    - 同一タスク内のコンテナは、localhost経由で通信可能。
- 特権containersやaccessはない
  - Docker in Dockerを実行するユースケースに影響を与える
- Linux capabilitiesは強く制限されている
  - サポートされているのは CAP_SYS_PTRACE のみ
    - コンテナ化されたアプリケーションをモニタリングするための観測ツールやセキュリティツールをタスク内で使用する際に利用できる
- 基盤ホストへのアクセス制限
  - 顧客も AWS オペレーターも、ワークロードを実行しているホストに直接接続することはできない。
  - Fargate は、コンテナがホストのリソース（ファイルシステム、デバイス、ネットワーク、コンテナランタイムなど）にアクセスするのを防ぐ。
  - デバッグ時の操作
    - [ECS exec](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html)を使えば、コンテナ内部に入り込み、デバッグのための診断情報を取得したり、コマンドを実行したりできる。
- Networking
  - Security groups と network ACLs を使用して、inbound および outbound traffic を制御できます。
  - Fargate tasks は、VPC内の設定された サブネット からIPアドレスを受け取ります。

### [Linux containers on Fargate container image pull behavior for Amazon ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-pull-behavior.html)

Linux containers on Fargateでは、container imageやそのcontainer image layersのキャッシュは行われません。
そのため、Fargateタスクが起動されるたびに、タスク定義で指定されたイメージをRegistryから毎回pullし、コンテナを起動します。
このため、コンテナの起動時間にはpullの時間も含まれ、直接的に影響を与えます。

**imageのpull時間を最適化するには、次の点を考慮してください。**

1. Container image proximity(近接)
   1. Internet経由や異なるAWSリージョンからPullすると、ダウンロード時間が増加する可能性がある。
      1. そのため、compute（Fargateタスク）とRegistry（コンテナイメージの保存場所）は、なるべく近い場所に配置するのが望ましい。
   2. 推奨
      1. RegistryとFargateタスクを同じリージョンで実行する。
      2. Amazon ECRを使用する場合、VPC interface endpointを利用するとPull時間を短縮できる。
2. Container image size reduction
   1. container imageのSizeはダイレクトにダウンロード時間に直接影響する。
      1. そのためcontainer imageのSizeまたはlayers数を減らすことで、ダウンロード時間を短縮できる。
   2. 推奨
      1. 軽量なベースイメージを使用する。
         1. 例えば、 [minimal Amazon Linux 2023 container image](https://docs.aws.amazon.com/linux/al2023/ug/minimal-container.html)
3. Alternative compression algorithms
   1. コンテナイメージのレイヤーは、レジストリにプッシュされる際に圧縮される。
      1. 圧縮により、転送データ量が削減され、ネットワークとレジストリの負荷が軽減される。
   2. 圧縮されたレイヤーは、container runtimeによってインスタンスにダウンロードされた後に解凍される。
      1. 解凍時間には、使用される圧縮アルゴリズムとタスクに割り当てられたvCPUの数が影響する。
   3. 推奨
      1. タスクサイズを増やすことで解凍速度を向上させる
      2. より高性能なzstd圧縮アルゴリズムを活用し、解凍時間を短縮する。
         1. [zstd](https://github.com/facebook/zstd)
         2. [Reducing AWS Fargate Startup Times with zstd Compressed Container Images.](https://aws.amazon.com/jp/blogs/containers/reducing-aws-fargate-startup-times-with-zstd-compressed-container-images/)
4. Lazy Loading container images
   1. 大きなコンテナイメージ（250MB以上）の場合、すべてをダウンロードするのではなく、lazy loadingを利用する方が効率的な場合がある
   2. 推奨
      1. Seekable OCI (SOCI) を使用して、コンテナイメージをレジストリから必要な部分だけをロードする。
         1. [soci-snapshotter](https://github.com/awslabs/soci-snapshotter)
         2. [Lazy loading container images using Seekable OCI (SOCI)](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-tasks-services.html#fargate-tasks-soci-images)

### [Fargate task retirement](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-maintenance.html)

**Task Retirementとは？**

- AWS Fargateでは、Platform Versionのリビジョンを定期的に更新します。
  - 更新内容にはFargate Runtime Software、Operating System、Container Runtimeなどの依存関係の改善が含まれる。
- 新しいPlatform Versionのリビジョンが導入されると、古いリビジョンはリタイア（廃止）されます。
- リビジョンがリタイアされる際、AWSは通知を送信し、該当リビジョン上で動作しているすべてのタスクが停止します。

**Task Retirementへの対応**

1. Service Tasksの場合
   - 対応不要。
   - Amazon ECS Schedulerが自動でリタイア対象タスクを新しいタスクに置き換える。
2. Standalone Tasksの場合
   - 対応が必要。
   - 自動的に処理されないため、手動で新しいタスクをデプロイする必要がある。

**ECSにおける`maximumPercent`の挙動**

`maximumPercent`は、Serviceタスクが新旧タスクの移行時に同時に許容されるタスクの割合を制御します。

1. `maximumPercent=200%`（デフォルト設定）
   - 1. 新しいタスクを起動:
     - リタイア対象タスクを停止する前に、新しいタスクをスケジュールし、起動。
     - 新しいタスクが`RUNNING`状態になるまで待機。
   - 2. 古いタスクを終了:
     - 新しいタスクが正常に起動後、古いタスクを停止。

2. `maximumPercent=100%`
   - 1. 既存のタスクを停止:
     - まずリタイア対象のタスクを停止。
     - この時点で`desiredCount`が一時的に減少する。
   - 2. 新しいタスクを起動:
     - 停止後に新しいタスクをスケジュールして起動。

**Task retirement notice overview**

通知方法:

1. AWS Health Dashboard
2. 登録済みメールアドレス (AWS アカウントに関連付けられたメール)

通知に含まれる内容:

- リタイア日付:
  - タスクが停止する予定の日付。
- タスクの識別情報:
  - スタンドアロンタスクの場合: タスクID。
  - サービスタスクの場合: クラスターIDとサービスID。
- 次のステップ:
  - 必要な対応や準備手順。

通知頻度:

- 通常、各AWSリージョンごとに1つの通知が送信されます（サービスタスクとスタンドアロンタスクそれぞれ）。
- ただし、タスク数が多い場合は複数回通知される場合があります。

Amazon EventBridgeを活用した通知連携:

- The AWS Health Dashboard
  - AWS Healthの通知をEventBridge経由でさまざまなサービスと連携可能([Monitoring AWS Health events with Amazon EventBridge](https://docs.aws.amazon.com/health/latest/ug/cloudwatch-events-health.html)):
    - アーカイブストレージ： Amazon S3 に保存。
    - 自動アクション： AWS Lambda 関数を実行。
    - 通知システム： Amazon SNS 経由で通知を配信。
  - チーム連携ツールへの通知
    - 以下のツールに通知を送る設定が可能（サンプル設定は[AWS Health Aware](https://github.com/aws-samples/aws-health-aware)リポジトリを参照）：
      - Amazon Chime
      - Slack
      - Microsoft Teams

### [Storage options for Amazon ECS tasks](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_data_volumes.html)

| Data volume | Supported launch types | Supported operating systems | Storage persistence | Features| Use cases | Link |
| :---------- | :--------------------- | :-------------------------- | :------------------ | :-------- |:-------- |:-------- |
| Amazon Elastic Block Store (Amazon EBS) |  Fargate, Amazon EC2 | Linux | - `Standalone Task`にattachした場合`Persisted`</br>-`Service`が管理する`Task`にattachした場合`Ephemeral` | cost-effective, durable, high-performance block storage for data-intensive|- Transactional workloads: Databases, virtual desktops, root volumes</br>- Throughput-intensive workloads: Log processing, ETL workloads | [Use Amazon EBS volumes with Amazon ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ebs-volumes.html) |
| Amazon Elastic File System (Amazon EFS) | Fargate, Amazon EC2  | Linux | Persistent | simple, scalable,  persistent shared file storage ,Concurrency support,Low latency|Data analytics, Media processing ,Content management,Web serving |[Use Amazon EFS volumes with Amazon ECS.](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/efs-volumes.html)|
| Bind mounts |  Fargate, Amazon EC2 | Windows, Linux | Ephemeral | - Uses files or directories from the host</br> | - Volume sharing in a task.</br> |[Use bind mounts with Amazon ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/bind-mounts.html)|
