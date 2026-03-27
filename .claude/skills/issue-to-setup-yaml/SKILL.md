---
name: issue-to-setup-yaml
description: GitHub issueからsetup.yamlを自動生成するスキル。issue URL または (owner, repo, issue_number) を入力として、チケット情報を抽出し、setup.yamlのスケルトンを生成する。「issueからsetup.yamlを作成」「issue-to-setup-yaml」「issueからセットアップ」「setup.yamlを生成」「チケットからYAMLを作成」などのフレーズで発動。
---

# GitHub Issue to Setup YAML スキル

GitHub issueの情報を解析し、階層化された setup.yaml（SSOT）を自動生成する。

## 入力形式

- **URL形式**: `https://github.com/{owner}/{repo}/issues/{number}`
- **引数形式**: `owner`, `repo`, `issue_number` の3つ

## ワークフロー

1. GitHub MCP Server または `gh` CLI で issue 情報（タイトル・本文・ラベル）を取得
2. Issue本文のセクションヘッダーを検出し、description の各フィールドにマッピング
3. リポジトリリンク・ラベルから `target_repositories` / `related_repositories` を抽出
4. `setup-{ticket_id}.yaml` を生成・出力
5. 完了レポートで抽出結果の成否・警告を表示

📖 詳細は `references/execution-steps.md` を参照

## 情報抽出ルール

### 必須情報

| フィールド | 抽出元 | 説明 |
|------------|--------|------|
| `ticket_id` | issue番号 | `#123` → `123` |
| `task_name` | issueタイトル | そのまま使用 |

### description 階層化マッピング

| フィールド | 検出キーワード例 |
|------------|------------------|
| `overview` | `## 概要`, `## Overview`, `## Summary` |
| `purpose` | `## 目的`, `## Purpose`, `## Goal` |
| `background` | `## 背景`, `## Background`, `## Context` |
| `requirements.functional` | `## 機能要件`, `## Functional`, `## 要件` |
| `requirements.non_functional` | `## 非機能要件`, `## Non-functional` |
| `acceptance_criteria` | `## 受け入れ条件`, `## Acceptance`, `## AC` |
| `scope` / `out_of_scope` | `## スコープ`, `## Scope` / `## スコープ外` |
| `notes` | `## 備考`, `## Notes`, `## 補足` |

📖 詳細は `references/extraction-patterns.md` を参照

### フォールバック

- セクション未検出 → 本文全体を `overview` に使用
- `purpose` 未検出 → タイトルから `{title} を実現する` を生成
- チェックボックス → `acceptance_criteria` として抽出
- リスト項目 → `requirements.functional` として推測

## バリデーション

- **必須**: `ticket_id`, `task_name`, `target_repositories`（1件以上）
- **構造**: `description` がオブジェクト形式、`description.overview` が存在
- **警告**: `related_repositories` 空、description 不完全、フォールバック使用時

📖 詳細は `references/validation-rules.md` を参照

## 出力

- **ファイル名**: `setup-{ticket_id}.yaml`（カレントディレクトリ）
- **フォーマット**: 階層化 description を含む SSOT 形式

📖 詳細は `references/setup-yaml-schema.md` を参照

## エラーハンドリング

- Issue未発見・アクセス権限エラー・URL解析エラー・抽出失敗に対応
- フォールバック使用時は警告付きで生成し、手動補完を促す

📖 詳細は `references/error-handling.md` を参照

## 注意事項

- 自動抽出結果は必ず確認・修正すること
- プライベートリポジトリには適切な認証が必要
- **フォールバック使用時は手動補完必須**
- 生成YAMLは手動編集を想定したスケルトン

## 参照ファイル

| ファイル | 内容 |
|----------|------|
| `references/extraction-patterns.md` | 情報抽出パターン定義 |
| `references/validation-rules.md` | バリデーションルール |
| `references/setup-yaml-schema.md` | YAMLテンプレート・出力形式 |
| `references/execution-steps.md` | 処理フロー・実行手順詳細 |
| `references/error-handling.md` | エラーパターン・完了レポート |
| `/setup-template.yaml` | setup.yamlテンプレート（プロジェクトルート） |

## 関連スキル

- `init-work-branch` - 生成したYAMLを入力として作業ブランチ初期化
- `investigation` - `description.background` を参照して詳細調査
- `design` - `description.requirements` を参照して設計
- `plan` - `description.acceptance_criteria` を参照してタスク計画
