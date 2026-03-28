---
name: terraform
description: Terraform/Terragrunt実行・AWSプロバイダドキュメント検索・Checkovセキュリティスキャン。IaC作業時に使用。「terraform plan」「terraformドキュメント」「Checkovスキャン」などのフレーズで発動。
---

# Terraform スキル

Terraform MCP サーバーへの動的アクセスを提供するスキル。

## 利用可能なツール（7個）

| # | ツール名 | 説明 |
|---|---------|------|
| 1 | `ExecuteTerraformCommand` | Terraformコマンド実行（init/plan/validate/apply/destroy） |
| 2 | `ExecuteTerragruntCommand` | Terragruntコマンド実行（run-all対応） |
| 3 | `SearchAwsProviderDocs` | AWSプロバイダのリソース/データソースドキュメント検索 |
| 4 | `SearchAwsccProviderDocs` | AWSCC（Cloud Control API）プロバイダドキュメント検索 |
| 5 | `SearchSpecificAwsIaModules` | AWS-IA Terraformモジュール検索 |
| 6 | `SearchUserProvidedModule` | Terraformレジストリモジュール分析 |
| 7 | `RunCheckovScan` | Checkovセキュリティスキャン実行 |

📖 各ツールの引数詳細は [references/tool-parameters.md](references/tool-parameters.md) を参照

## 使用方法

1. ユーザーのリクエストに合うツールを上記リストから選択
2. JSON コマンドを生成し `executor.py --call` で実行
3. ツール仕様の確認には `executor.py --describe <ツール名>` を使用

📖 JSON例・実行手順・エラー対応の詳細は [references/usage-examples.md](references/usage-examples.md) を参照

---
*mcp-to-skill-converter で生成、ツール情報は手動で追記*
