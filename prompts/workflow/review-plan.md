# ワークフロー: review-plan

タスク計画の妥当性をレビューする。

## 前提条件チェック

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER validate  # review-plan の前提条件を確認
# plan.status=completed であること
```

## コンテキスト取得

```bash
TICKET_ID=$(yq '.meta.ticket_id' project.yaml)
TARGET_REPO=$(yq '.meta.target_repo' project.yaml)
ACCEPTANCE_CRITERIA=$(yq '.setup.description.acceptance_criteria' project.yaml)
PLAN_ARTIFACTS=$(yq '.plan.artifacts' project.yaml)
DESIGN_ARTIFACTS=$(yq '.design.artifacts' project.yaml)
```

## 実行手順

1. **review-plan スキル** を実行
   - 計画ドキュメント（`{PLAN_ARTIFACTS}`）と設計・受入基準を入力として渡す
   - 成果物出力先: `docs/{TARGET_REPO}/review-plan/`

## 完了後の状態更新

```bash
# plan.review サブセクション更新
yq -i '.plan.review.status = "approved"' project.yaml  # or "conditional" / "rejected"
yq -i '.plan.review.round = (.plan.review.round // 0) + 1' project.yaml
yq -i ".plan.review.reviewed_at = \"$(date -Iseconds)\"" project.yaml
yq -i '.plan.review.artifacts = "docs/{TARGET_REPO}/review-plan/"' project.yaml
yq -i ".meta.updated_at = \"$(date -Iseconds)\"" project.yaml

git add project.yaml docs/
git commit -m "chore: {TICKET_ID} plan reviewセクション更新"
```
