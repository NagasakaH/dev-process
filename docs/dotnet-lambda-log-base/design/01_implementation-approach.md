# 実装方針

## 方針概要

ILogger インターフェースを実装したカスタム CloudWatch Logs プロバイダーを構築する。
ログは2つの CloudWatch Logs グループに振り分け、バッファリング + バッチ送信で効率化する。

## アプローチ比較

| アプローチ | メリット | デメリット | 採用 |
|------------|----------|------------|------|
| カスタム ILoggerProvider | ILogger 標準に準拠、DI 対応、テスタブル | 実装コスト | ✅ |
| Serilog + CloudWatch Sink | 既存エコシステム活用 | 2グループ振り分けが困難、依存増 | ❌ |
| Console.WriteLine + Lambda 自動連携 | 実装簡単 | 構造化困難、振り分け不可 | ❌ |

## 採用方針

### 1. ログライブラリ層の分離

- `DotnetLambdaLogBase.Logging` プロジェクトとして独立
- Lambda プロジェクトから NuGet パッケージとして参照可能な構成
- `ILoggerProvider` / `ILogger` 標準インターフェースに準拠

### 2. バッファリング戦略

- `ConcurrentQueue<LogEntry>` でスレッドセーフなバッファ管理
- Lambda はリクエスト単位で実行されるため、タイマーによる定期 Flush は不要
- **Flush タイミング**: Lambda ハンドラーの finally ブロックで明示的に呼び出し

### 3. CloudWatch Logs 送信

- AWS SDK `AmazonCloudWatchLogsClient` を使用
- ログストリーム名: `{yyyy/MM/dd}/{FunctionName}/{Guid}` で一意性確保
- PutLogEvents でバッチ送信（最大1MB / 10,000件の制約に準拠）
- 送信失敗時はコンソールにフォールバック（アプリを停止しない）

### 4. Terraform インフラ

- モジュール化せず、フラットな構成でシンプルに保つ
- 変数でアプリ名やリージョンをカスタマイズ可能に

## 技術選定根拠

| 技術 | 選定理由 |
|------|----------|
| .NET 8 Managed Runtime | LTS、Lambda 公式サポート |
| ILogger / ILoggerProvider | .NET 標準、DI 統合容易 |
| System.Text.Json | .NET 組み込み、高速、AOT 互換 |
| AWSSDK.CloudWatchLogs | 公式 SDK、PutLogEvents 直接制御 |
| ConcurrentQueue | スレッドセーフ、ロックフリー |
| xUnit + Moq | .NET 標準テストスタック |
