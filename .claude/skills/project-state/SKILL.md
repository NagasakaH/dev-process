---
name: project-state
description: project.yaml/setup.yamlの状態管理スキル。ワークフローの状態読み取り・セクション更新・前提条件チェックを一元管理する。「project.yaml更新」「ステータス更新」「セクション初期化」「前提条件チェック」「project-state」などのフレーズで発動。各種ワークフロースキル実行後のproject.yaml書き戻しに使用。
---

# project-state — ワークフロー状態管理スキル

project.yaml / setup.yaml の読み書きを一元管理するスキルです。
ワークフロースキル（investigation, design, plan 等）の実行前後に呼び出し、
コンテキスト取得や結果書き戻しを行います。

## 概要

- **project.yaml**: 全プロセスの SSOT（Single Source of Truth）
- **setup.yaml**: タスクの初期設定ファイル（project.yaml 生成前に使用）
- **project-yaml-helper.sh**: project.yaml 操作用 CLI ヘルパー

> **重要**: project.yaml を直接 `cat` や `view` で参照してはならない。
> 必ず `scripts/project-yaml-helper.sh` 経由でアクセスすること。

## ヘルパーコマンド一覧

```bash
HELPER="./scripts/project-yaml-helper.sh"

# ステータス確認
$HELPER status [yaml_path]

# バリデーション（スキーマ + 前提条件）
$HELPER validate [yaml_path]

# セクション雛形生成
$HELPER init-section <section> [yaml_path]

# セクション更新
$HELPER update <section> [yaml_path] --status <val> --summary <text> --artifacts <path>

# 人間チェックポイント記録
$HELPER checkpoint <name> [yaml_path] --verdict <approved|revision_requested> [--feedback text] [--rollback-to phase]

# チェックポイント解決記録
$HELPER resolve-checkpoint <name> [yaml_path] --summary <text>

# セクションスナップショット
$HELPER snapshot-section <section> <triggered_by> [yaml_path]
```

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

## 操作パターン

### パターン1: コンテキスト読み取り（スキル実行前）

ワークフロースキルに渡すコンテキストを project.yaml から抽出する。

```bash
# メタ情報
TICKET_ID=$(yq '.meta.ticket_id' project.yaml)
TARGET_REPO=$(yq '.meta.target_repo' project.yaml)

# setup情報（要件・受入基準）
BACKGROUND=$(yq '.setup.description.background' project.yaml)
REQUIREMENTS=$(yq '.setup.description.requirements' project.yaml)
ACCEPTANCE_CRITERIA=$(yq '.setup.description.acceptance_criteria' project.yaml)

# 前ステップの成果物パス
INVESTIGATION_ARTIFACTS=$(yq '.investigation.artifacts' project.yaml)
DESIGN_ARTIFACTS=$(yq '.design.artifacts' project.yaml)
PLAN_ARTIFACTS=$(yq '.plan.artifacts' project.yaml)

# テスト戦略
TEST_STRATEGY=$(yq '.brainstorming.test_strategy' project.yaml)
```

### パターン2: セクション初期化 + 更新（スキル実行後）

```bash
HELPER="./scripts/project-yaml-helper.sh"

# セクション初期化（まだない場合）
$HELPER init-section investigation

# ステータス・サマリー・成果物パス更新
$HELPER update investigation --status completed \
  --summary "対象リポジトリの調査完了" \
  --artifacts "docs/target-repo/investigation/"

# meta.updated_at を更新
yq -i ".meta.updated_at = \"$(date -Iseconds)\"" project.yaml
```

### パターン3: 前提条件チェック（スキル実行前）

```bash
# 特定セクションの前提条件を確認
$HELPER validate

# 手動チェック例（investigation実行前）
BRAINSTORM_STATUS=$(yq '.brainstorming.status' project.yaml)
HC_STATUS=$(yq '.human_checkpoints.brainstorming_review.status' project.yaml)

if [ "$BRAINSTORM_STATUS" != "completed" ] || [ "$HC_STATUS" != "approved" ]; then
  echo "前提条件を満たしていません"
  exit 1
fi
```

### パターン4: 人間チェックポイント管理

```bash
HELPER="./scripts/project-yaml-helper.sh"

# 承認
$HELPER checkpoint brainstorming_review --verdict approved

# 差し戻し
$HELPER checkpoint design_review --verdict revision_requested \
  --feedback "APIインターフェースの再設計が必要" \
  --rollback-to design

# 差し戻し対応完了
$HELPER resolve-checkpoint design_review \
  --summary "APIインターフェースをRESTful設計に変更"
```

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

## コミットルール

project.yaml の更新は以下の形式でコミット：

```bash
git add project.yaml
git commit -m "chore: {ticket_id} project.yaml {section}セクション更新

- status: {new_status}
- summary: {summary_text}"
```

## 注意事項

- project.yaml を直接 `cat`/`view` で読んではならない — `project-yaml-helper.sh` を使う
- `yq` コマンドで値を更新する際は `-i` フラグ（in-place）を使用
- `meta.updated_at` はセクション更新時に必ず更新する
- スキーマバリデーションは `$HELPER validate` で実行可能
