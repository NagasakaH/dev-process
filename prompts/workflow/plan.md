# ワークフロー: plan

設計結果からタスク計画を作成する。

## 前提条件チェック

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER validate  # plan の前提条件を確認
# design.status=completed, design.review.status=approved, design_review=approved
```

## コンテキスト取得

```bash
TICKET_ID=$(yq '.meta.ticket_id' project.yaml)
TARGET_REPO=$(yq '.meta.target_repo' project.yaml)
ACCEPTANCE_CRITERIA=$(yq '.setup.description.acceptance_criteria' project.yaml)
DESIGN_ARTIFACTS=$(yq '.design.artifacts' project.yaml)
TEST_STRATEGY=$(yq '.brainstorming.test_strategy' project.yaml)
```

## 実行手順

1. **plan スキル** を実行
   - 設計ドキュメント（`{DESIGN_ARTIFACTS}`）と受入基準を入力として渡す
   - 成果物出力先: `docs/{TARGET_REPO}/plan/`

## 完了後の状態更新

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER init-section plan
$HELPER update plan --status completed \
  --summary "タスク計画作成完了" \
  --artifacts "docs/{TARGET_REPO}/plan/"
yq -i ".meta.updated_at = \"$(date -Iseconds)\"" project.yaml

git add project.yaml docs/
git commit -m "chore: {TICKET_ID} planセクション更新"
```
