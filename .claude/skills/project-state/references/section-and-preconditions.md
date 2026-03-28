# セクション構造・前提条件・ステータス値

## セクション構造

project.yaml は以下のセクションで構成される：

| セクション | 説明 | 書き込み元 |
|-----------|------|-----------|
| `meta` | プロジェクトメタ情報（ticket_id, target_repo等） | brainstorming |
| `setup` | setup.yamlからの引き継ぎ（読み取り専用） | brainstorming |
| `brainstorming` | ブレインストーミング結果・テスト戦略 | brainstorming |
| `overview` | サブモジュール概要 | submodule-overview |
| `investigation` | 調査結果 | investigation |
| `design` | 設計結果（design.review含む） | design / review-design |
| `plan` | タスク計画（plan.review含む） | plan / review-plan |
| `implement` | 実装状況 | implement |
| `verification` | 検証結果 | verification |
| `code_review` | コードレビュー結果・指摘 | code-review / code-review-fix |
| `finishing` | ブランチ完了情報 | finishing-branch |
| `human_checkpoints` | 人間チェックポイント管理 | checkpoint コマンド |

## 前提条件マップ

各ステップの実行に必要な前提条件（`preconditions.yaml` で定義）：

| ステップ | 前提条件 |
|---------|---------|
| investigation | brainstorming.status=completed, brainstorming_review=approved |
| design | investigation.status=completed |
| review-design | design.status=completed |
| plan | design.status=completed, design.review.status=approved, design_review=approved |
| review-plan | plan.status=completed |
| implement | plan.status=completed, plan.review.status=approved |
| verification | implement.status=completed |
| code-review | verification.status=completed |
| finishing-branch | code_review.status=approved |

## ステータス値

### ライフサイクルステータス
`pending` → `in_progress` → `completed` / `failed` / `skipped`

### レビューステータス
`pending` → `approved` / `conditional` / `rejected`

### チェック結果
`pass` / `fail` / `skip` / `warning`

### 指摘ステータス（code_review）
`open` → `fixed` / `disputed` → `resolved` / `wontfix`

### 人間チェックポイント
`pending` → `approved` / `revision_requested`
