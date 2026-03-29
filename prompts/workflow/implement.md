# ワークフロー: implement

> ⚠️ **必須**: このステップは `implement` スキルの `skill` ツール経由での呼び出しが必須です。
> スキルを使わない手動実行は禁止されています。

タスク計画に従って実装を実行する。

## 前提条件チェック

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER validate  # implement の前提条件を確認
# plan.status=completed, plan.review.status=approved であること
```

## コンテキスト取得

```bash
TICKET_ID=$(yq '.meta.ticket_id' project.yaml)
TARGET_REPO=$(yq '.meta.target_repo' project.yaml)
PLAN_ARTIFACTS=$(yq '.plan.artifacts' project.yaml)
DESIGN_ARTIFACTS=$(yq '.design.artifacts' project.yaml)
TEST_STRATEGY=$(yq '.brainstorming.test_strategy' project.yaml)

# タスク一覧を取得（plan成果物から）
```

## 実行手順

1. **implement スキル** を実行
   - 計画ドキュメント（`{PLAN_ARTIFACTS}`）のタスク一覧に従って実装
   - TDD: テストファーストで各タスクを実装
   - 並列化: 独立タスクは並列実行

## 完了後の状態更新

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER init-section implement
$HELPER update implement --status completed \
  --summary "全タスク実装完了"
yq -i ".meta.updated_at = \"$(date -Iseconds)\"" project.yaml

git add project.yaml
git commit -m "chore: {TICKET_ID} implementセクション更新"
```
