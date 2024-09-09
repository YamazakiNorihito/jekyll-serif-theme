---
title: "Amazon CloudWatch LogsによるElastic Beanstalk環境の監視とメトリクス収集"
date: 2024-8-23T07:00:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - AWS
  - Elastic Beanstalk
  - CloudWatch
  - Monitoring
  - CloudFormation
  - Docker
  - Logs
  - EC2
---


# Elastic Beanstalkで利用可能なAmazon CloudWatch Logsの監視機能

Elastic Beanstalkでは、インスタンスがデフォルトでCloudWatch Logsエージェントをインストールした状態で作成される。これにより、各Amazon EC2インスタンスは、構成したロググループに対してメトリクスデータポイントをCloudWatchサービスに公開することが可能だ。

- Elastic Beanstalkは、アプリケーション、システム、およびカスタムログファイルをAmazon EC2インスタンスから監視およびアーカイブする。
- メトリクスフィルターを使用して、特定のログストリームイベントに対応するアラームを設定できる。

## Dockerプラットフォームでのログストリーミング

インスタンスログをCloudWatch Logsにストリーミングする機能を有効にすると、Elastic BeanstalkはインスタンスからログファイルをCloudWatch Logsに送信する。Linuxプラットフォームの場合、ロググループ名はログファイルのパスに「/aws/elasticbeanstalk/environment_name」を接頭辞として追加することで決まる。例えば、「/var/log/nginx/error.log」のロググループ名は「/aws/elasticbeanstalk/environment_name/var/log/nginx/error.log」になる。

### Dockerプラットフォームのログファイルと対応するCloudWatch Logsのロググループ名

| プラットフォーム / ブランチ         | インスタンスログのパス                                     | CloudWatch Logsのロググループ名                                                     |
|-----------------------------------|---------------------------------------------------------|-----------------------------------------------------------------------------------|
| Docker / 64bit Amazon Linux 2      | `/var/log/eb-engine.log`                                 | `/aws/elasticbeanstalk/environment_name/var/log/eb-engine.log`                    |
|                                   | `/var/log/eb-hooks.log`                                  | `/aws/elasticbeanstalk/environment_name/var/log/eb-hooks.log`                     |
|                                   | `/var/log/docker`                                        | `/aws/elasticbeanstalk/environment_name/var/log/docker`                           |
|                                   | `/var/log/docker-events.log`                             | `/aws/elasticbeanstalk/environment_name/var/log/docker-events.log`                |
|                                   | `/var/log/eb-docker/containers/eb-current-app/stdouterr.log` | `/aws/elasticbeanstalk/environment_name/var/log/eb-docker/containers/eb-current-app/stdouterr.log` |
|                                   | `/var/log/nginx/access.log`                              | `/aws/elasticbeanstalk/environment_name/var/log/nginx/access.log`                 |
|                                   | `/var/log/nginx/error.log`                               | `/aws/elasticbeanstalk/environment_name/var/log/nginx/error.log`                  |

CloudWatch LogsエージェントがEC2インスタンスのログをストリーミングするためには、カスタムポリシーをEC2インスタンスプロファイルにアタッチする必要がある。設定方法については、公式ドキュメントを参照。

## LogStreamの有効化

Elastic BeanstalkのCloudFormationでLogStreamを有効にするには、`aws:elasticbeanstalk:cloudwatch:logs:StreamLogs`を`true`に設定する必要がある。

その他の有効化方法:

- [コンソールから有効化](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.cloudwatchlogs.html#AWSHowTo.cloudwatchlogs.streaming.console)
- [CLIから有効化](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.cloudwatchlogs.html#AWSHowTo.cloudwatchlogs.streaming.ebcli)
- [EBエクステンション設定ファイルを使用](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.cloudwatchlogs.html#AWSHowTo.cloudwatchlogs.files)

## EC2インスタンスのシステムメトリクス収集

EC2インスタンスのシステムメトリクスをCloudWatchに連携することが可能。連携するためには、CloudWatch Logs Agentに対して設定を追加する必要がある。

`.ebextensions/cloudwatch.config` に以下の設定を行う。

```yaml
files:
  "/opt/aws/amazon-cloudwatch-agent/bin/config.json":
    mode: "000600"
    owner: root
    group: root
    content: |
      {
        "agent": {
          "metrics_collection_interval": 60,
          "run_as_user": "root"
        },
        "metrics": {
          "namespace": "System/Linux",
          "append_dimensions": {
            "AutoScalingGroupName": "${aws:AutoScalingGroupName}"
          },
          "metrics_collected": {
            "mem": {
              "measurement": [
                "mem_used_percent"
              ]
            }
          }
        }
      }

container_commands:
  start_cloudwatch_agent:
    command: /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
```

この例では、EC2インスタンスのメモリ使用率が収集され、指定された間隔で（この場合は60秒ごとに）Amazon CloudWatchに送信される。

`metrics_collected`には収集したいメトリクスを羅列する。指定できる項目は[こちら](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/metrics-collected-by-CloudWatch-agent.html#linux-metrics-enabled-by-CloudWatch-agent)に記載されている。

また、EC2インスタンスプロファイルに、AWS管理ポリシー `CloudWatchAgentServerPolicy` をアタッチする必要がある。

## CloudWatch エージェント設定ファイル

- `agent`: エージェントの全体的な設定
- `metrics`: 収集と CloudWatch への発行に関するカスタムメトリクスを指定
- `logs`: CloudWatch Logs に発行されるログファイルを指定
- `traces`: AWS X-Ray に送信されるトレースのソースを指定

### Agent

| 項目                         | 説明 | デフォルト値 |
|-----------------------------|------|--------------|
| **metrics_collection_interval** | メトリクス収集の頻度を指定。60秒未満の場合、高解像度メトリクスとして収集。単位はsec(秒) | 60 |
| **region**                   | メトリクス送信先のAWSリージョンを指定。オンプレミスサーバーの場合は無視される。 | EC2インスタンスのリージョン |
| **credentials**              | 別のAWSアカウントにメトリクス、ログ、トレースを送信する際のIAMロールを指定。 | なし |
| **role_arn**                 | 異なるAWSアカウントにメトリクス、ログ、トレースを送信する際のIAMロールのARNを指定。 | なし |
| **debug**                    | デバッグログメッセージを使用するかどうかを指定。 | false |
| **aws_sdk_log_level**         | AWS SDKエンドポイントに対する[ログレベル](https://docs.aws.amazon.com/sdk-for-go/api/aws/#LogLevelType)を指定。バージョン1.247350.0以降でサポート。 複数のオプションは、\| 文字で区切| なし |
| **logfile**                  | CloudWatchエージェントのログ出力先を指定。ログファイルは100MBで更新、最大7日間、バックアップは5つまで保存。 | Linux: /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log |
| **omit_hostname**            | メトリクスのディメンションにホスト名を含めるかどうかを指定。 | false |
| **run_as_user**              | CloudWatchエージェントを実行するユーザーを指定。Linuxのみ有効。 | rootユーザー |
| **user_agent**               | CloudWatchエージェントがAPI呼び出しに使用するuser-agent文字列を指定。 | エージェントのバージョン、Goのバージョン、OS、アーキテクチャ、プラグインに基づく文字列 |
| **usage_data**               | Amazon CloudWatch エージェントが自身に関するヘルスおよびパフォーマンスデータをCloudWatchに送信するかどうかを指定。 | true |

### Metrics セクション

**Linux および Windows の共通のフィールド**

| 項目                         | 説明 | デフォルト値 |
|-----------------------------|------|--------------|
| **namespace**                | エージェントによって収集されるメトリクスに使用する名前空間。最大長は255文字。 | CWAgent |
| **append_dimensions**        | メトリクスにAmazon EC2メトリクスのディメンションを追加。サポートされるキーと値のペアには、以下が含まれます: "ImageId" (AMI ID), "InstanceId" (インスタンスID), "InstanceType" (インスタンスタイプ), "AutoScalingGroupName" (Auto Scalingグループ名)。これらのキーと値は変更不可。 | なし |
| **aggregation_dimensions**   | 収集されたメトリクスが集計されるディメンションを指定。複数のディメンションを指定可能。 | なし |
| **endpoint_override**        | エージェントがメトリクスを送信するエンドポイントを指定。FIPSエンドポイントやプライベートリンクを指定可能。 | なし |
| **metrics_collected**        | 収集するメトリクスを指定するセクション。必須項目。 | なし |
| **force_flush_interval**     | メトリクスがサーバーに送信されるまでにメモリバッファ内に残留する最大時間（秒単位）。 | 60秒 |
| **credentials**              | 異なるアカウントにメトリクスを送信する際に使用するIAMロールを指定。 | なし |
| **role_arn**                 | 異なるアカウントにメトリクスを送信する際の認証用IAMロールのARNを指定。 | なし |

ディメンションは、メトリクスのデータをカテゴリ別に整理するための「ラベル」のようなものです。たとえば、EC2インスタンスのメトリクスデータを見たいとき、インスタンスごとにデータを分けたい場合に使います。ディメンションを使うことで、特定の条件に基づいてメトリクスをフィルタリングしたり、異なる条件下でのメトリクスを比較したりすることができます。

#### (Linux)metrics_collected セクション

##### 1. **collectd**

- **概要**: CloudWatch エージェントにカスタムメトリクスを collectd プロトコルを使用して送信するためのオプション。
- **主要フィールド**: `collectd`に関連する[詳細設定](https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-custom-metrics-collectd.html)が記述される。

##### 2. **cpu**

- **概要**: Linux インスタンスで収集する CPU メトリクスを指定するオプション。
- **主要フィールド**:
  - **drop_original_metrics**: 指定したメトリクスの元の情報は送信されず、集計結果のみがCloudWatchに送信されます。デフォルトでは、元のメトリクスと集計メトリクスの両方が送信されます。
  - **resources**: CPUごとのメトリクスを収集するかどうかを指定。値は `*` のみ許容。
  - **totalcpu**: すべてのCPUコア間で集計されたメトリクスを報告するかを指定。デフォルトは `true`。
  - **measurement**: 収集するCPUメトリクスの配列を指定。`rename` で メトリクスに別の名前変更可能。
  - **metrics_collection_interval**: CPUメトリクスを収集する頻度を秒単位で指定。グローバル設定を上書きするために使用。
  - **append_dimensions**: 特定のCPUメトリクスに対して追加のディメンションを指定。グローバルの `append_dimensions` に追加する形で使用。

```json
{
  "cpu": {
    "drop_original_metrics": ["cpu_usage_idle", "cpu_usage_user"],
    "resources": "*",
    "totalcpu": true,
    "metrics_collection_interval": 60
  }
}
```

##### 3. **disk**

- **概要**: Linux インスタンスで収集するディスクメトリクスを指定するオプション。マウントされたボリュームのみ対象。
- **主要フィールド**:
  - **drop_original_metrics**: 指定したメトリクスの元の情報は送信されず、集計結果のみがCloudWatchに送信されます。デフォルトでは、元のメトリクスと集計メトリクスの両方が送信されます。
  - **resources**: 収集するディスクのマウントポイントを指定。値は `*` で全マウントポイント対象。デフォルトも全マウントポイント対象。
  - **measurement**: 収集するディスクメトリクスの配列を指定。`rename` でメトリクス名を変更可能。
  - **ignore_file_system_types**: 除外するファイルシステムのタイプを指定。例として `sysfs`、`devtmpfs` など。
  - **drop_device**: ディスクメトリクスのディメンションとしてデバイス名を含めないように指定。デフォルトは `false`。
  - **metrics_collection_interval**: ディスクメトリクスを収集する頻度を秒単位で指定。グローバル設定を上書きするために使用。
  - **append_dimensions**: ディスクメトリクス専用の追加ディメンションを指定。グローバルの `append_dimensions` に追加する形で使用。

##### 4. **diskio**

- **概要**: Linux インスタンスで収集するディスクI/Oメトリクスを指定するオプション。
- **主要フィールド**:
  - **drop_original_metrics**: 指定したメトリクスの元の情報は送信されず、集計結果のみがCloudWatchに送信されます。デフォルトでは、元のメトリクスと集計メトリクスの両方が送信されます。
  - **resources**: 収集するデバイスを指定。値として `*` を指定すると、すべてのデバイスからメトリクスが収集されます。デフォルトでは全デバイスが対象。
  - **measurement**: 収集するディスクI/Oメトリクスの配列を指定。`rename` でメトリクス名を変更可能。指定可能な値には `reads`、`writes`、`read_bytes`、`write_bytes`、`read_time`、`write_time`、`io_time`、`iops_in_progress` があります。
  - **metrics_collection_interval**: ディスクI/Oメトリクスを収集する頻度を秒単位で指定。グローバル設定を上書きするために使用。60秒未満に設定すると高解像度メトリクスとして収集されます。
  - **append_dimensions**: ディスクI/Oメトリクス専用の追加ディメンションを指定。グローバルの `append_dimensions` に追加する形で使用。

##### 5. **swap**

- **概要**: Linux インスタンスで収集するスワップメモリメトリクスを指定するオプション。
- **主要フィールド**:
  - **drop_original_metrics**: 指定したメトリクスの元の情報は送信されず、集計結果のみがCloudWatchに送信されます。デフォルトでは、元のメトリクスと集計メトリクスの両方が送信されます。
  - **measurement**: 収集するスワップメモリメトリクスの配列を指定。指定可能な値は `free`、`used`、`used_percent` です。`rename` でメトリクス名を変更可能。
  - **metrics_collection_interval**: スワップメモリメトリクスを収集する頻度を秒単位で指定。グローバル設定を上書きするために使用。60秒未満に設定すると高解像度メトリクスとして収集されます。
  - **append_dimensions**: スワップメモリメトリクス専用の追加ディメンションを指定。グローバルの `append_dimensions` に追加する形で使用。

##### 6. **mem**

- **概要**: Linux インスタンスで収集するメモリメトリクスを指定するオプション。
- **主要フィールド**:
  - **drop_original_metrics**: 指定したメトリクスの元の情報は送信されず、集計結果のみがCloudWatchに送信されます。デフォルトでは、元のメトリクスと集計メトリクスの両方が送信されます。
  - **measurement**: 収集するメモリメトリクスの配列を指定。指定可能な値は `active`、`available`、`available_percent`、`buffered`、`cached`、`free`、`inactive`、`total`、`used`、`used_percent` です。`rename` でメトリクス名を変更可能。
  - **metrics_collection_interval**: メモリメトリクスを収集する頻度を秒単位で指定。グローバル設定を上書きするために使用。60秒未満に設定すると高解像度メトリクスとして収集されます。
  - **append_dimensions**: メモリメトリクス専用の追加ディメンションを指定。グローバルの `append_dimensions` に追加する形で使用。

##### 7. **net**

- **概要**: Linux インスタンスで収集するネットワークメトリクスを指定するオプション。
- **主要フィールド**:
  - **drop_original_metrics**: 指定したメトリクスの元の情報は送信されず、集計結果のみがCloudWatchに送信されます。デフォルトでは、元のメトリクスと集計メトリクスの両方が送信されます。
  - **resources**: 収集するネットワークインターフェイスを指定。`*` を指定するとすべてのインターフェイスからメトリクスを収集します。
  - **measurement**: 収集するネットワークメトリクスの配列を指定。指定可能な値には `bytes_sent`、`bytes_recv`、`drop_in`、`drop_out`、`err_in`、`err_out`、`packets_sent`、`packets_recv` があります。
  - **metrics_collection_interval**: ネットワークメトリクスを収集する頻度を秒単位で指定。60秒未満に設定すると高解像度メトリクスとして収集されます。
  - **append_dimensions**: ネットワークメトリクス専用の追加ディメンションを指定。グローバルの `append_dimensions` に追加する形で使用。

##### 8. **netstat**

- **概要**: Linux インスタンスで収集するTCP接続状態およびUDP接続メトリクスを指定するオプション。
- **主要フィールド**:
  - **drop_original_metrics**: 指定したメトリクスの元の情報は送信されず、集計結果のみがCloudWatchに送信されます。
  - **measurement**: 収集するNetstatメトリクスの配列を指定。指定可能な値には `tcp_close`、`tcp_close_wait`、`tcp_closing`、`tcp_established`、`tcp_fin_wait1`、`tcp_fin_wait2`、`tcp_last_ack`、`tcp_listen`、`tcp_syn_sent`、`tcp_syn_recv`、`tcp_time_wait`、`udp_socket` があります。
  - **metrics_collection_interval**: Netstatメトリクスを収集する頻度を秒単位で指定。
  - **append_dimensions**: Netstatメトリクス専用の追加ディメンションを指定。

##### 9. **processes**

- **概要**: Linux インスタンスで収集するプロセスメトリクスを指定するオプション。
- **主要フィールド**:
  - **drop_original_metrics**: 指定したメトリクスの元の情報は送信されず、集計結果のみがCloudWatchに送信されます。
  - **measurement**: 収集するプロセスメトリクスの配列を指定。指定可能な値には `blocked`、`dead`、`idle`、`paging`、`running`、`sleeping`、`stopped`、`total`、`total_threads`、`wait`、`zombies` があります。
  - **metrics_collection_interval**: プロセスメトリクスを収集する頻度を秒単位で指定。
  - **append_dimensions**: プロセスメトリクス専用の追加ディメンションを指定。

##### 10. **nvidia_gpu**

- **概要**: NVIDIA GPU アクセラレーターを搭載した Linux インスタンスで収集するGPUメトリクスを指定するオプション。NVIDIA System Management Interface (nvidia-smi) がインストールされている必要があります。
- **主要フィールド**:
  - **drop_original_metrics**: 指定したメトリクスの元の情報は送信されず、集計結果のみがCloudWatchに送信されます。
  - **measurement**: 収集するNVIDIA GPUメトリクスの配列を指定。具体的なメトリクスについては、NVIDIA GPU メトリクスのドキュメントを参照。
  - **metrics_collection_interval**: NVIDIA GPU メトリクスを収集する頻度を秒単位で指定。

##### 11. **procstat**

- **概要**: 個別のプロセスからメトリクスを収集するオプション。
- **主要フィールド**:
  - **詳細**: 収集するプロセスメトリクスの詳細は、「[procstat プラグインでプロセスメトリクスを収集する](https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-procstat-process-metrics.html)」ドキュメントを参照。

##### 12. **statsd**

- **概要**: StatsD プロトコルを使用してカスタムメトリクスを取得するオプション。CloudWatch エージェントは StatsD デーモンとして機能します。
- **主要フィールド**:
  - **詳細**: 収集するメトリクスの詳細は、「[StatsD を使用してカスタムメトリクスを取得する](https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-custom-metrics-statsd.html)」ドキュメントを参照。

##### 13. **ethtool**

- **概要**: ethtool プラグインを使用してネットワークメトリクスを収集するオプション。標準 ethtool ユーティリティや Amazon EC2 インスタンスのネットワークパフォーマンスメトリクスを収集します。
- **主要フィールド**:
  - **詳細**: 収集するメトリクスの詳細は、「[ネットワークパフォーマンスメトリクスの収集」](https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-network-performance.html)ドキュメントを参照。

## Logs セクション

(雰囲気掴めた始めたから書かない)

## トレース セクション

(雰囲気掴めた始めたから書かない)

## 参考資料

- [Amazon CloudWatch Logs で Elastic Beanstalk を使用する](https://docs.aws.amazon.com/ja_jp/elasticbeanstalk/latest/dg/AWSHowTo.cloudwatchlogs.html)
- [Example: Using custom Amazon CloudWatch metrics](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/customize-containers-cw.html)
- [Metrics collected by the CloudWatch agent](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/metrics-collected-by-CloudWatch-agent.html)
- [CloudWatch エージェント設定ファイルを手動で作成または編集する](https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html#CloudWatch-Agent-Configuration-File-Agentsection)
