# ワークフロー: design

project.yaml のコンテキストと調査結果を基に詳細設計を行う。

## 前提条件チェック

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER validate  # design の前提条件を確認
# investigation.status=completed であること
```

## コンテキスト取得

```bash
TICKET_ID=$(yq '.meta.ticket_id' project.yaml)
TARGET_REPO=$(yq '.meta.target_repo' project.yaml)
REQUIREMENTS=$(yq '.setup.description.requirements' project.yaml)
ACCEPTANCE_CRITERIA=$(yq '.setup.description.acceptance_criteria' project.yaml)
INVESTIGATION_ARTIFACTS=$(yq '.investigation.artifacts' project.yaml)
TEST_STRATEGY=$(yq '.brainstorming.test_strategy' project.yaml)
```

## 実行手順

1. **design スキル** を実行
   - 調査結果ドキュメント（`{INVESTIGATION_ARTIFACTS}`）と要件を入力として渡す
   - 成果物出力先: `docs/{TARGET_REPO}/design/`

## 完了後の状態更新

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER init-section design
$HELPER update design --status completed \
  --summary "詳細設計完了" \
  --artifacts "docs/{TARGET_REPO}/design/"
yq -i ".meta.updated_at = \"$(date -Iseconds)\"" project.yaml

git add project.yaml docs/
git commit -m "chore: {TICKET_ID} designセクション更新"
```
