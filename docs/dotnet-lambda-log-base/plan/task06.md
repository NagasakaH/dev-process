# タスク: task06 - Terraform インフラ定義

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task06 |
| タスク名 | Terraform インフラ定義 |
| 前提条件タスク | なし |
| 並列実行可否 | 可（task01 と並列） |
| 推定所要時間 | 15分 |

## 作業内容

### 目的

CloudWatch Logs グループ、CloudWatch Alarm、S3 バケット、SNS トピックの Terraform 定義を作成する。

### 設計参照

- [design/03_data-structure-design.md](../design/03_data-structure-design.md) - Terraform リソース構造

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `terraform/providers.tf` | 新規作成 | プロバイダ設定 |
| `terraform/variables.tf` | 新規作成 | 変数定義 |
| `terraform/cloudwatch.tf` | 新規作成 | CloudWatch Logs グループ + Alarm |
| `terraform/s3.tf` | 新規作成 | S3 バケット |
| `terraform/sns.tf` | 新規作成 | SNS トピック（仮実装） |
| `terraform/outputs.tf` | 新規作成 | 出力定義 |

## 実装ステップ

1. `providers.tf`: AWS プロバイダ設定
2. `variables.tf`: app_name, aws_region, error_log_retention_days, s3_bucket_prefix, alarm_email
3. `cloudwatch.tf`:
   - 全ログ用ロググループ（DELIVERY class）
   - 異常系ロググループ（STANDARD class, 保持日数設定可能）
   - CloudWatch メトリクスアラーム（仮実装）
4. `s3.tf`: ログ保存用 S3 バケット（パブリックアクセスブロック）
5. `sns.tf`: 通知用 SNS トピック（仮実装）
6. `outputs.tf`: ロググループ名、S3 バケット名、SNS トピック ARN

## テスト方針

```bash
cd terraform/
terraform init
terraform validate
```

Checkov セキュリティスキャンも実施。

## 完了条件

- [ ] `terraform validate` が成功すること
- [ ] CloudWatch Logs グループが2つ定義されていること（DELIVERY + STANDARD）
- [ ] S3 バケットがパブリックアクセスブロック付きで定義されていること
- [ ] CloudWatch Alarm が定義されていること（仮実装）
- [ ] SNS トピックが定義されていること（仮実装）
- [ ] 変数で設定をカスタマイズ可能であること
