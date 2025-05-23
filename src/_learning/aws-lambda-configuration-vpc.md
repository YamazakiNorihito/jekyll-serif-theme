---
title: "AWS Lambda を VPC に接続する構成とベストプラクティスまとめ"
date: 2025-03-03T15:00:00
mermaid: false
weight: 7
tags:
  - AWS
  - Lambda
  - VPC
  - IAM
  - セキュリティ
  - ベストプラクティス
description: "AWS Lambda を自作 VPC に接続する際の構成方法、必要な IAM 権限、ENI の仕組み、ベストプラクティスをまとめたノート。将来的な応用や安全な設計に役立てるための整理。"
---

[Giving Lambda functions access to resources in an Amazon VPC](https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html)を読むので
見返してわかるようにいい感じにまとめていく。

自身が持つVPC内にlaunchしたサービス(EC2,RDB,ElastiCache)に対してlambdaをアクセスさせる方法が書かれている。

## Required IAM Permissions

Lambdaに対して、VPCへアタッチするためのIAM permissionsが必須です。

Lambdaは **Hyperplane Elastic Network Interfaces (ENI)** をVPCのSubnetに作成し、それにアタッチされます。

詳細は後日確認：
[Understanding Hyperplane Elastic Network Interfaces (ENIs)](https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html#configuration-vpc-enis)

---

### 必須マネージドポリシー

Lambda関数に下記のAWSマネージドポリシーをアタッチします：

* `AWSLambdaBasicExecutionRole`
* `AWSLambdaVPCAccessExecutionRole`

```yaml
Role:
  Type: AWS::IAM::Role
  Properties:
    RoleName: !Sub "${EnvironmentName}-lambda-role"
    AssumeRolePolicyDocument:
      Version: '2012-10-17'
      Statement:
        - Effect: 'Allow'
          Principal:
            Service: 
              - 'lambda.amazonaws.com'
          Action: 'sts:AssumeRole'
    ManagedPolicyArns:
      - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
      - arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole
```

---

### 個別Permissionを設定する場合

`AWSLambdaVPCAccessExecutionRole`を使わずに個別で権限を設定することも可能ですが、明確な理由がない限り推奨されません。

必要なアクション一覧：

* `ec2:CreateNetworkInterface`
* `ec2:DescribeNetworkInterfaces` ※全リソース対象でないと機能しません（"Resource": "\*"）
* `ec2:DescribeSubnets`
* `ec2:DeleteNetworkInterface`
* `ec2:AssignPrivateIpAddresses`
* `ec2:UnassignPrivateIpAddresses`

これらは初回のLambda実行時にVPCリソースを作成するための権限であり、関数の「実行」には不要です。
一度セットアップが完了すれば、これらの権限はExecution Roleから削除しても動作に問題はありません。

---

### AWSLambdaVPCAccessExecutionRoleの中身

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSLambdaVPCAccessExecutionPermissions",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeSubnets",
        "ec2:DeleteNetworkInterface",
        "ec2:AssignPrivateIpAddresses",
        "ec2:UnassignPrivateIpAddresses"
      ],
      "Resource": "*"
    }
  ]
}
```

ログ出力を制限したいなどの特別な理由がなければ、このマネージドポリシーを使うのが簡単かつ安全です。

---

### LambdaをVPCにアタッチする操作に必要なIAMユーザーの権限

* `ec2:DescribeSecurityGroups`
* `ec2:DescribeSubnets`
* `ec2:DescribeVpcs`
* `ec2:getSecurityGroupsForVpc`

---

### 注意

Lambdaの実行ロールに与えた権限は、Lambda関数のコードからも呼び出せてしまいます。
したがって、**最小権限の原則（Least Privilege）** に従って設定することが重要です。

参考：
[Security best practices](https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html#configuration-vpc-best-practice-security)

## Attaching Lambda functions to an Amazon VPC in your AWS account

ドキュメント見る方が[早い](https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html#configuration-vpc-attaching)

[api-gateway-vpc-lambda-authorizer](https://github.com/YamazakiNorihito/AWS-CloudFormation/tree/main/api-gateway-vpc-lambda-authorizer)おTemplateを見れば良い。

## Internet access when attached to a VPC

defaultでは、lambdaはpublic internetへのアクセスが可能です。
自身で作成したVPCにアタッチしたlambdaの場合は、VPC 側でネットアクセス（通常は NAT Gateway）を整えてね。
[api-gateway-vpc-lambda-authorizer](https://github.com/YamazakiNorihito/AWS-CloudFormation/tree/main/api-gateway-vpc-lambda-authorizer)ではNATgatewayを作成してinternetに出れるようにしている。

## [IPv6 support](https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html#configuration-vpc-ipv6)

サポートしているみたい。今は、必要ない理解なのでSkip

## Best practices for using Lambda with Amazon VPCs

1. Security best practices  
   1. Lambdaの実行ロールには、VPC接続に必要な`ec2:CreateNetworkInterface`などの権限を付与するが、**関数コードからの実行を防ぐためにDenyポリシーを追加する**。
2. Performance best practices  
   1. 複数のLambda関数を**同じVPC・同じサブネット・同じセキュリティグループ**で構成すると、**Hyperplane ENIを共有**できるため、**新しいENIの作成が不要になり起動時間が短縮される。また、ENIの数も節約できる。**

## Understanding Hyperplane Elastic Network Interfaces (ENIs)

Hyperplane ENI は、Lambda 関数と VPC 内のアクセスしたいリソースとの間のネットワークインターフェースとして機能する、管理されたリソースです。
Lambda を VPC に接続すると、自動的に Hyperplane ENI が作成・管理され、Lambda 関数にアタッチされます。
ユーザーが直接この ENI を確認・設定することはできません。

Lambda は、特定のサブネットとセキュリティグループの組み合わせで関数を VPC に初めて接続する際に、Hyperplane ENI を作成します。
同じアカウント内の他の関数でも、同じサブネットとセキュリティグループの組み合わせを使っていれば、この ENI を共有・再利用します。
Lambda は、リソースの最適化と新規 ENI の作成を最小限に抑えるため、可能な限り既存の Hyperplane ENI を再利用します。

1つの Hyperplane ENI は 最大 65,000 の接続（ポート） をサポートしており、その範囲内で Lambda 関数はネットワークリソースにアクセスできます。
この上限を超える接続が必要になる場合、Lambda はネットワークトラフィックや並列実行数に応じて ENI の数を自動的にスケーリングします。

Hyperplane ENI の作成が完了するまで（＝Pending の間）に起きる制限：

* Lambda 関数を初めて作成する際は、Hyperplane ENI が Pending 状態になるため、Lambda 関数は 実行できません。
  * Hyperplane ENI が Active になれば、関数の実行が可能になります。
* 既存の Lambda 関数に関しては、以前のバージョンの関数は引き続き実行可能ですが、creating versions や updating the function’s code などの関数操作はできません。

## Using IAM condition keys for VPC settings

IAMポリシーでLambda関数に対して、**特定のVPC、サブネット（SubnetIds）、セキュリティグループ（SecurityGroupIds）のみを許可または拒否**することができます。

この制限は、`lambda:CreateFunction` および `lambda:UpdateFunctionConfiguration` アクションに対して有効で、以下のLambda専用の条件キーを使用します：

* `lambda:VpcIds`
* `lambda:SubnetIds`
* `lambda:SecurityGroupIds`

サンプル(詳しくは"[Example policies with condition keys for VPC settings](https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html#vpc-condition-examples)")

```yaml
- PolicyName: AllowOnlySpecificVPCConfig
  PolicyDocument:
    Version: "2012-10-17"
    Statement:
      - Effect: "Allow"
        Action:
          - lambda:CreateFunction
          - lambda:UpdateFunctionConfiguration
        Resource: "*"
        Condition:
          StringEquals:
            lambda:VpcIds: "vpc-0123456789abcdef0"
            lambda:SubnetIds:
              - "subnet-aaa11111"
              - "subnet-bbb22222"
            lambda:SecurityGroupIds:
              - "sg-333ccc44"
```
