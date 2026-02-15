---
name: aws-documentation
description: AWSドキュメントページの読み取り・検索・推奨取得。AWSサービスの詳細ドキュメントを参照する際に使用。「AWSドキュメントを読んで」「AWSページを取得」などのフレーズで発動。
---

# AWS Documentation スキル

AWS Documentation MCP サーバーへの動的アクセスを提供するスキル。

## 利用可能なツール（3個）

### 1. `read_documentation`
AWSドキュメントページを取得しMarkdownに変換。

**引数:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `url` | string | ✅ | AWSドキュメントURL（docs.aws.amazon.com ドメイン、.html で終わる） |
| `max_length` | integer | - | 最大文字数（デフォルト5000、最大20000） |
| `start_index` | integer | - | 読み取り開始位置（ページネーション用） |

### 2. `search_documentation`
AWSドキュメント全体を検索。

**引数:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `search_phrase` | string | ✅ | 検索フレーズ |
| `search_intent` | string | - | 検索意図の説明（PII含めないこと） |
| `limit` | integer | - | 最大結果数（デフォルト10、最大50） |
| `product_types` | array[string] | - | AWSサービスフィルター（例: `["Amazon Simple Storage Service"]`） |
| `guide_types` | array[string] | - | ガイド種別フィルター（例: `["User Guide", "API Reference"]`） |

### 3. `recommend`
AWSドキュメントページの関連コンテンツを推奨。

**引数:**
| パラメータ | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `url` | string | ✅ | 推奨元のAWSドキュメントURL |

**推奨タイプ:** Highly Rated（人気）、New（新着）、Similar（類似）、Journey（次に見られるページ）

## 使用方法

### Step 1: ツールを特定
ユーザーのリクエストに合うツールを上記リストから選択。

### Step 2: JSON コマンドを生成

```json
{
  "tool": "search_documentation",
  "arguments": {
    "search_phrase": "S3 bucket versioning",
    "limit": 5
  }
}
```

### Step 3: executor.py で実行

```bash
cd /workspaces/dev-process/.claude/skills/aws-documentation
python executor.py --call '{"tool": "search_documentation", "arguments": {"search_phrase": "S3 bucket versioning", "limit": 5}}'
```

## エラー対応

- `mcp package not found` → `pip install mcp` を実行
- URL要件 → docs.aws.amazon.com ドメイン、`.html` で終わること

---
*mcp-to-skill-converter で生成、ツール情報は手動で追記*
