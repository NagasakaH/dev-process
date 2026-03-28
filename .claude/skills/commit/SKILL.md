---
name: commit
description: ステージされた変更を確認し、MCP連携でチケット情報を取得してコミットメッセージを生成・実行する。ブランチ名からチケットIDを自動抽出し、GitHub/GitLab/Jira/Redmineと連携可能。「コミット」「git commit」「コミットメッセージ作成」「変更をコミット」などのフレーズで発動。
---

# Git Commit スキル

MCP連携を活用してチケット情報を取得し、適切なコミットメッセージを生成してコミットを実行します。

## このスキルの目的

1. **チケット情報の自動取得** - ブランチ名からチケットIDを抽出し、MCPでチケット詳細を取得
2. **コミットメッセージの生成** - チケット情報と変更内容から日本語コミットメッセージを自動生成
3. **コミット実行** - ユーザー確認なしにコミットを実行

## 処理フロー

### 1. ブランチ名を取得しチケットIDを抽出

```bash
git branch --show-current
```

`feature/`, `issue/`, `bugfix/`, `hotfix/`, `fix/` プレフィックスからチケットIDを抽出する。

📖 詳細は [references/ticket-id-extraction.md](references/ticket-id-extraction.md) を参照

### 2. MCP連携でチケット情報を取得

チケットIDのフォーマットに応じて GitHub/GitLab/Jira/Redmine の MCP でチケット情報を取得する。MCPが利用できない場合はブランチ名から情報を推測する。

📖 詳細は [references/mcp-ticket-retrieval.md](references/mcp-ticket-retrieval.md) を参照

### 3. 変更内容を確認

```bash
git status && git diff --cached --stat && git diff --cached
```

ステージングされていない変更がある場合は、ユーザーに確認する。

### 4. 日本語コミットメッセージを生成

**🚨 コミットメッセージは必ず日本語で生成すること（英語は禁止）🚨**

チケット情報と変更内容から日本語コミットメッセージを生成する。チケットIDがある場合は `refs #{ID}` を付与する。

📖 フォーマット・テンプレート・例示は [references/commit-message-format.md](references/commit-message-format.md) を参照

### 5. コミット実行

```bash
git commit -m "{生成したコミットメッセージ}"
```

## 注意事項

- ステージングされた変更がない場合は、何をステージングするか確認する
- MCPが利用できなくてもブランチ名から最低限の情報を抽出して処理を継続する
- 複数チケットに関連する変更の場合は、ユーザーに確認して適切なチケットIDを選択する
- **すべてのエージェント・子エージェントも日本語コミットメッセージを生成すること**

## 関連スキル

- `finishing-branch` — コミット後のブランチ完了処理（マージ / PR / 保持 / 破棄）
- `verification-before-completion` — コミット前の検証ゲート
