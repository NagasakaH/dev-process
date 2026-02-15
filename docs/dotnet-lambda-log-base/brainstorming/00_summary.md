# ブレインストーミング結果: AWS Lambda (.NET) ログ管理テンプレート

## 対話サマリー

.NET 8 Lambda 用のログ管理テンプレートプロジェクトについて、以下の要件を確定した。

## 決定事項

### 1. ログライブラリ構成
- **ILogger インターフェース** を実装したカスタムログプロバイダーを自作
- AWS SDK (`Amazon.CloudWatchLogs`) で CloudWatch Logs に送信
- **JSON 構造化ログ** 形式

### 2. CloudWatch Logs グループ構成

| グループ | 用途 | スコープ | 保持期間 | 保存先 |
|----------|------|----------|----------|--------|
| 全ログ用 | 全レベルのログ | Lambda アプリごと | Delivery Class | S3 |
| 異常系用 | Error/Critical のみ | 複数 Lambda 共通 | 数日 | CloudWatch |

### 3. 通知構成
- CloudWatch Alarm で異常系ロググループを監視
- SNS トピックへの通知（仮実装）

### 4. ランタイム
- .NET 8 Managed Runtime

### 5. インフラ管理
- Terraform で全リソース管理
  - CloudWatch Logs グループ（2種）
  - CloudWatch Alarm
  - S3 バケット（ログ保存先）
  - SNS トピック（仮実装）

### 6. テスト
- xUnit 単体テスト

## アーキテクチャ概要

```
Lambda Function (.NET 8)
  │
  ├─ ILogger<T>
  │    │
  │    └─ CustomLogProvider
  │         │
  │         ├─ LogBuffer (バッファリング)
  │         │
  │         ├─ CloudWatch Logs (全ログ用 - Delivery Class)
  │         │    └─ S3 (自動エクスポート)
  │         │
  │         └─ CloudWatch Logs (異常系用)
  │              └─ CloudWatch Alarm → SNS → 通知
  │
  └─ Flush on Lambda completion
```

## スコープ外
- 結合テスト・E2Eテスト
- CI/CD パイプライン
- ログ分析・可視化ダッシュボード
- 本番環境向け Alarm 詳細設定
