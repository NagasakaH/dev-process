# 操作パターン詳細

project.yaml の読み書きにおける4つの操作パターンと、コミットルールのコード例。

## パターン1: コンテキスト読み取り（スキル実行前）

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

## パターン2: セクション初期化 + 更新（スキル実行後）

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

## パターン3: 前提条件チェック（スキル実行前）

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

## パターン4: 人間チェックポイント管理

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

## コミットルール

project.yaml の更新は以下の形式でコミット：

```bash
git add project.yaml
git commit -m "chore: {ticket_id} project.yaml {section}セクション更新

- status: {new_status}
- summary: {summary_text}"
```
