# dotnet-lambda-log-base

> 最終更新: 2026-02-15

## 概要

.NET 8 AWS Lambda 向けの ILogger ベース CloudWatch Logs カスタムプロバイダーテンプレート。
ログを 2 つの CloudWatch Logs グループ（all-logs / error-logs）に自動振り分けし、全ログの長期保管とエラーログのリアルタイム監視を両立する。

---

## 優先度A（必須情報）

### 1. プロジェクト構成

```
dotnet-lambda-log-base/
├── DotnetLambdaLogBase.sln
├── README.md
├── src/
│   ├── DotnetLambdaLogBase/              # Lambda 関数プロジェクト
│   │   ├── Function.cs
│   │   ├── DotnetLambdaLogBase.csproj
│   │   └── aws-lambda-tools-defaults.json
│   └── DotnetLambdaLogBase.Logging/      # ログライブラリ
│       ├── CloudWatchLogger.cs
│       ├── CloudWatchLoggerProvider.cs
│       ├── CloudWatchLoggerOptions.cs
│       ├── CloudWatchLogSender.cs
│       ├── LogBuffer.cs
│       ├── LogEntry.cs
│       ├── JsonLogFormatter.cs
│       ├── ILogFormatter.cs
│       ├── ILogSender.cs
│       └── LoggingServiceCollectionExtensions.cs
├── tests/
│   └── DotnetLambdaLogBase.Logging.Tests/ # xUnit テスト（28テスト）
├── terraform/                             # インフラ定義
│   ├── providers.tf
│   ├── variables.tf
│   ├── cloudwatch.tf
│   ├── s3.tf
│   ├── s3_delivery.tf
│   ├── sns.tf
│   └── outputs.tf
└── e2e/                                   # E2E テスト
    ├── main.tf
    ├── run-e2e-tests.sh
    └── test-report.md
```

**主要ファイル:**

| ファイル | 役割 |
|---|---|
| `src/DotnetLambdaLogBase/Function.cs` | Lambda ハンドラーテンプレート |
| `src/DotnetLambdaLogBase.Logging/CloudWatchLoggerProvider.cs` | ILoggerProvider 実装（ログ振り分け・Flush） |
| `src/DotnetLambdaLogBase.Logging/CloudWatchLogSender.cs` | PutLogEvents API 送信（バッチ分割・256KB切り詰め） |
| `src/DotnetLambdaLogBase.Logging/LoggingServiceCollectionExtensions.cs` | DI 拡張メソッド |
| `terraform/cloudwatch.tf` | CloudWatch Logs グループ・アラーム定義 |
| `e2e/run-e2e-tests.sh` | E2E テストスクリプト（13テスト） |

### 2. 外部公開インターフェース/API

**DI 拡張メソッド（エントリポイント）:**

```csharp
// ILoggingBuilder.AddCloudWatchLogger(Action<CloudWatchLoggerOptions> configure)
services.AddLogging(builder => builder.AddCloudWatchLogger(options => {
    options.AllLogsGroupName = "/lambda/my-app/all-logs";
    options.ErrorLogsGroupName = "/lambda/shared/error-logs";
    options.FunctionName = "MyFunction";
}));
```

**公開クラス/インターフェース:**

| クラス/インターフェース | 用途 |
|---|---|
| `CloudWatchLoggerOptions` | 設定オプション（ロググループ名、最小レベル、バッファサイズ等） |
| `CloudWatchLoggerProvider` | ILoggerProvider 実装。`FlushAsync()` でログ送信 |
| `CloudWatchLogger` | ILogger 実装（内部利用） |
| `CloudWatchLogSender` | ILogSender 実装。PutLogEvents API 呼び出し |
| `LogBuffer` | スレッドセーフ循環バッファ |
| `LogEntry` | ログエントリデータモデル |
| `JsonLogFormatter` | ILogFormatter 実装。JSON フォーマット |
| `ILogFormatter` | フォーマッターインターフェース |
| `ILogSender` | 送信インターフェース |

### 3. テスト実行方法

```bash
dotnet test
```

- フレームワーク: xUnit 2.5.3
- モック: Moq 4.20.72
- カバレッジ: coverlet.collector 6.0.0
- テスト数: 28 単体テスト + 13 E2E テスト

**E2E テスト実行:**

```bash
cd e2e
./run-e2e-tests.sh
```

※ E2E テストは実 AWS 環境が必要（Terraform apply → Lambda デプロイ → テスト → Terraform destroy）

### 4. ビルド実行方法

```bash
dotnet build
```

**Lambda パッケージ作成:**

```bash
cd src/DotnetLambdaLogBase
dotnet publish -c Release -r linux-x64 --self-contained false -o publish
```

### 5. 依存関係

#### 本番依存

| パッケージ | バージョン | 用途 |
|---|---|---|
| AWSSDK.CloudWatchLogs | 3.7.408.2 | CloudWatch Logs API |
| Microsoft.Extensions.Logging.Abstractions | 8.0.2 | ILogger/ILoggerProvider |
| Microsoft.Extensions.DependencyInjection.Abstractions | 8.0.2 | DI 拡張 |
| Amazon.Lambda.Core | 2.8.1 | Lambda ランタイム |
| Amazon.Lambda.Serialization.SystemTextJson | 2.4.5 | JSON シリアライザ |
| Microsoft.Extensions.DependencyInjection | 8.0.1 | DI コンテナ |
| Microsoft.Extensions.Logging | 8.0.1 | ロギングフレームワーク |

#### 開発依存

| パッケージ | バージョン | 用途 |
|---|---|---|
| xunit | 2.5.3 | テストフレームワーク |
| xunit.runner.visualstudio | 2.5.3 | テストランナー |
| Microsoft.NET.Test.Sdk | 17.8.0 | テスト基盤 |
| Moq | 4.20.72 | モックライブラリ |
| coverlet.collector | 6.0.0 | カバレッジ収集 |

### 6. 技術スタック

| カテゴリ | 技術 |
|---|---|
| 言語 | C# 12 / .NET 8.0 |
| フレームワーク | AWS Lambda (.NET 8), Microsoft.Extensions.Logging |
| ビルドツール | dotnet CLI |
| テストフレームワーク | xUnit + Moq |
| IaC | Terraform (AWS Provider ~5.0) |
| リージョン | ap-northeast-1 (東京) |

---

## 優先度B（オプション情報）

### 7. 利用方法/Getting Started

1. `dotnet build` でビルド
2. `dotnet test` でテスト実行
3. `cd terraform && terraform apply -var="app_name=my-app"` でインフラ構築
4. `dotnet lambda deploy-function` で Lambda デプロイ

### 8. 環境変数/設定

| 変数名 | 説明 | デフォルト値 |
|---|---|---|
| `ALL_LOGS_GROUP` | 全ログ用ロググループ名 | `/lambda/app/all-logs` |
| `ERROR_LOGS_GROUP` | エラー用ロググループ名 | `/lambda/shared/error-logs` |
| `AWS_LAMBDA_FUNCTION_NAME` | 関数名（AWS自動設定） | — |

### 10. 既知の制約・制限事項

- **DELIVERY class ロググループ**: 保持期間 2 日固定、GetLogEvents/FilterLogEvents 不可
- **PutLogEvents API**: バッチ 1MB / 10,000 件上限、個別イベント 256KB 上限
- **Lambda コンテナ再利用**: ServiceProvider.DisposeAsync() 禁止（FlushAsync パターン必須）

### 14. ライセンス情報

MIT
