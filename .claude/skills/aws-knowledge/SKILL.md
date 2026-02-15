---
name: aws-knowledge
description: AWSドキュメント検索・リージョン情報取得・ドキュメント読み取り・推奨ページ取得。AWS関連の調査・設計時に使用。「AWSドキュメント検索」「リージョン確認」「AWSの情報を調べて」などのフレーズで発動。
---

# AWS Knowledge スキル

AWS Knowledge MCP サーバーへの動的アクセスを提供するスキル。MCPサーバーをプロセスとして起動し、JSON-RPCで通信する。

## 利用可能なツール（5個）

### 1. `aws___search_documentation`
AWS公式ドキュメントを検索する（最も使用頻度が高い）。

**引数:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `search_phrase` | string | ✅ | 検索クエリ |
| `topics` | array[string] | - | 検索トピック（最大3つ）。`general`, `reference_documentation`, `current_awareness`, `troubleshooting`, `amplify_docs`, `cdk_docs`, `cdk_constructs`, `cloudformation` |
| `limit` | integer | - | 最大結果数（デフォルト10） |

### 2. `aws___read_documentation`
AWSドキュメントページのMarkdown変換取得。

**引数:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `url` | string | ✅ | AWSドキュメントURL |
| `max_length` | integer | - | 最大文字数 |
| `start_index` | integer | - | 読み取り開始位置（ページネーション用） |

### 3. `aws___recommend`
AWSドキュメントページの関連コンテンツ推奨。

**引数:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `url` | string | ✅ | 推奨元のAWSドキュメントURL |

### 4. `aws___get_regional_availability`
AWSリージョンでのサービス・API・CloudFormationリソースの利用可能状況を確認。

**引数:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `region` | string | ✅ | AWSリージョンコード（例: `us-east-1`） |
| `resource_type` | string | ✅ | `product`, `api`, `cfn` のいずれか |
| `filters` | array[string] | - | リソース名フィルター |
| `next_token` | string | - | ページネーショントークン |

### 5. `aws___list_regions`
全AWSリージョン一覧を取得。

**引数:** なし

## 使用方法

### Step 1: ツールを特定
ユーザーのリクエストに合うツールを上記リストから選択。

### Step 2: JSON コマンドを生成

```json
{
  "tool": "aws___search_documentation",
  "arguments": {
    "search_phrase": "Lambda function URLs",
    "topics": ["reference_documentation"],
    "limit": 5
  }
}
```

### Step 3: executor.py で実行

```bash
cd /workspaces/dev-process/.claude/skills/aws-knowledge
python executor.py --call '{"tool": "aws___search_documentation", "arguments": {"search_phrase": "Lambda function URLs", "topics": ["reference_documentation"], "limit": 5}}'
```

## ツール詳細の確認

```bash
cd /workspaces/dev-process/.claude/skills/aws-knowledge
python executor.py --describe aws___search_documentation
```

## エラー対応

- `mcp package not found` → `pip install mcp` を実行
- サーバー応答なし → `uvx` が利用可能か確認
- ツール名エラー → `python executor.py --list` でツール一覧確認

---
*mcp-to-skill-converter で生成、ツール情報は手動で追記*
