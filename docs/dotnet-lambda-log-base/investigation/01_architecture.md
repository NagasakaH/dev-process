# アーキテクチャ調査

## プロジェクト構成

```
dotnet-lambda-log-base/
├── DotnetLambdaLogBase.sln
├── README.md
├── src/
│   ├── DotnetLambdaLogBase/              # Lambda 関数（アプリケーション層）
│   └── DotnetLambdaLogBase.Logging/      # ログライブラリ（ライブラリ層）
├── tests/
│   └── DotnetLambdaLogBase.Logging.Tests/ # 単体テスト
├── terraform/                             # インフラ定義（IaC層）
└── e2e/                                   # E2Eテスト環境
```

## レイヤー構成

```mermaid
graph TD
    subgraph Application["アプリケーション層"]
        F[Function.cs<br/>Lambda ハンドラー]
    end
    subgraph Library["ライブラリ層"]
        P[CloudWatchLoggerProvider<br/>ILoggerProvider]
        L[CloudWatchLogger<br/>ILogger]
        B[LogBuffer<br/>ConcurrentQueue]
        FMT[JsonLogFormatter<br/>ILogFormatter]
        S[CloudWatchLogSender<br/>ILogSender]
    end
    subgraph Infrastructure["インフラ層（Terraform）"]
        CW1[CloudWatch Logs<br/>all-logs DELIVERY]
        CW2[CloudWatch Logs<br/>error-logs STANDARD]
        S3[S3 Bucket<br/>長期保管]
        SNS[SNS Topic<br/>アラーム通知]
        ALM[CloudWatch Alarm<br/>エラー監視]
    end

    F --> P
    P --> L
    L --> B
    P --> FMT
    P --> S
    S --> CW1
    S --> CW2
    CW1 -->|Subscription Filter| S3
    CW2 -->|Metric Filter| ALM
    ALM -->|通知| SNS
```

## Terraform リソース構成（課金対象調査用）

```mermaid
graph LR
    subgraph terraform/
        PV[providers.tf<br/>AWS ~5.0]
        VA[variables.tf<br/>app_name等]
        CW[cloudwatch.tf<br/>Log Groups + Alarm]
        S3F[s3.tf<br/>S3 Bucket]
        SD[s3_delivery.tf<br/>IAM + Subscription Filter]
        SN[sns.tf<br/>SNS Topic]
        OU[outputs.tf<br/>出力値]
    end
```

### Terraform リソース一覧

| リソース | ファイル | 課金発生 |
|---|---|---|
| `aws_cloudwatch_log_group.all_logs` (DELIVERY) | cloudwatch.tf | ✅ |
| `aws_cloudwatch_log_group.error_logs` (STANDARD) | cloudwatch.tf | ✅ |
| `aws_cloudwatch_log_metric_filter` | cloudwatch.tf | ❌（無料） |
| `aws_cloudwatch_metric_alarm` | cloudwatch.tf | ✅ |
| `aws_s3_bucket` + 関連設定 | s3.tf | ✅ |
| `aws_iam_role` + policy (CWL→S3) | s3_delivery.tf | ❌（無料） |
| `aws_cloudwatch_log_subscription_filter` | s3_delivery.tf | ❌（無料） |
| `aws_sns_topic` + subscription | sns.tf | ✅（条件付き） |
