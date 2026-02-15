# データ構造設計

本タスクはドキュメント作成のみのため、データ構造の変更はなし。

## ドキュメントに記載するデータ構造

### README に追加する Mermaid 図のデータ

Terraform リソース間の関係を以下の構造で表現:

- CloudWatch Log Groups (2つ: DELIVERY / STANDARD)
- S3 Bucket (ログ長期保管)
- IAM Role + Policy (CWL→S3 配信)
- Subscription Filter (all-logs → S3)
- Metric Filter (error-logs → アラーム)
- CloudWatch Alarm
- SNS Topic (条件付き)

### 課金要素テーブルの構造

| カラム | 内容 |
|---|---|
| サービス | AWS サービス名 |
| リソース | Terraform リソース名 |
| 課金モデル | 従量/固定/条件付き |
| 無料枠 | 有無と内容 |
| コスト目安 | 月額概算 |
