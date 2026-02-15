---
name: terraform
description: Terraform/Terragrunt実行・AWSプロバイダドキュメント検索・Checkovセキュリティスキャン。IaC作業時に使用。「terraform plan」「terraformドキュメント」「Checkovスキャン」などのフレーズで発動。
---

# Terraform スキル

Terraform MCP サーバーへの動的アクセスを提供するスキル。

## 利用可能なツール（7個）

### 1. `ExecuteTerraformCommand`
Terraformコマンドを実行。

**引数:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `command` | string | ✅ | `init`, `plan`, `validate`, `apply`, `destroy` のいずれか |
| `working_directory` | string | ✅ | Terraformファイルのディレクトリ |
| `variables` | object | - | Terraform変数（key-value） |
| `aws_region` | string | - | AWSリージョン |
| `strip_ansi` | boolean | - | ANSIカラーコード除去（デフォルト: true） |

### 2. `ExecuteTerragruntCommand`
Terragruntコマンドを実行。

**引数:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `command` | string | ✅ | `init`, `plan`, `validate`, `apply`, `destroy`, `output`, `run-all` |
| `working_directory` | string | ✅ | Terragruntファイルのディレクトリ |
| `variables` | object | - | Terraform変数 |
| `aws_region` | string | - | AWSリージョン |
| `run_all` | boolean | - | 全モジュール実行（デフォルト: false） |
| `include_dirs` | array[string] | - | 含めるディレクトリ |
| `exclude_dirs` | array[string] | - | 除外するディレクトリ |
| `terragrunt_config` | string | - | カスタム設定ファイルパス |
| `strip_ansi` | boolean | - | ANSIカラーコード除去（デフォルト: true） |

### 3. `SearchAwsProviderDocs`
AWS Terraformプロバイダのリソース/データソースドキュメント検索。

**引数:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `asset_name` | string | ✅ | リソース名（例: `aws_s3_bucket`, `aws_lambda_function`） |
| `asset_type` | string | - | `resource`（デフォルト）, `data_source`, `both` |

### 4. `SearchAwsccProviderDocs`
AWSCC（Cloud Control API）プロバイダのリソースドキュメント検索。

**引数:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `asset_name` | string | ✅ | リソース名（例: `awscc_s3_bucket`） |
| `asset_type` | string | - | `resource`（デフォルト）, `data_source`, `both` |

### 5. `SearchSpecificAwsIaModules`
AWS-IA Terraformモジュール検索（Bedrock, OpenSearch Serverless, SageMaker, Streamlit）。

**引数:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `query` | string | ✅ | 検索クエリ（空文字で全モジュール返却） |

### 6. `SearchUserProvidedModule`
Terraformレジストリモジュールの分析。

**引数:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `module_url` | string | ✅ | モジュールURL（例: `hashicorp/consul/aws`） |
| `version` | string | - | 特定バージョン |
| `variables` | object | - | 分析用変数 |

### 7. `RunCheckovScan`
Checkovセキュリティスキャン実行。

**引数:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `working_directory` | string | ✅ | スキャン対象ディレクトリ |
| `framework` | string | - | フレームワーク（デフォルト: `terraform`） |
| `check_ids` | array[string] | - | 実行するチェックID |
| `skip_check_ids` | array[string] | - | スキップするチェックID |
| `output_format` | string | - | 出力形式（デフォルト: `json`） |

## 使用方法

### Step 1: ツールを特定
ユーザーのリクエストに合うツールを上記リストから選択。

### Step 2: JSON コマンドを生成

```json
{
  "tool": "ExecuteTerraformCommand",
  "arguments": {
    "command": "plan",
    "working_directory": "/path/to/terraform",
    "aws_region": "ap-northeast-1"
  }
}
```

### Step 3: executor.py で実行

```bash
cd /workspaces/dev-process/.claude/skills/terraform
python executor.py --call '{"tool": "ExecuteTerraformCommand", "arguments": {"command": "plan", "working_directory": "/path/to/terraform", "aws_region": "ap-northeast-1"}}'
```

## ツール詳細の確認

```bash
cd /workspaces/dev-process/.claude/skills/terraform
python executor.py --describe ExecuteTerraformCommand
```

## エラー対応

- `mcp package not found` → `pip install mcp` を実行
- Terraform未インストール → `terraform` コマンドがPATH上にあるか確認
- Checkov未インストール → `pip install checkov` を実行

---
*mcp-to-skill-converter で生成、ツール情報は手動で追記*
