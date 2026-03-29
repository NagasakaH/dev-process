# ワークフロー: investigation

> ⚠️ **必須**: このステップは `investigation` スキルの `skill` ツール経由での呼び出しが必須です。
> スキルを使わない手動実行は禁止されています。

project.yaml のコンテキストを基に対象リポジトリを詳細調査する。

## 前提条件チェック

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER validate  # investigation の前提条件を確認

# 手動チェック
BRAINSTORM_STATUS=$(yq '.brainstorming.status' project.yaml)
HC_STATUS=$(yq '.human_checkpoints.brainstorming_review.status' project.yaml)
# brainstorming.status=completed かつ brainstorming_review=approved であること
```

## コンテキスト取得

```bash
TICKET_ID=$(yq '.meta.ticket_id' project.yaml)
TARGET_REPO=$(yq '.meta.target_repo' project.yaml)
BACKGROUND=$(yq '.setup.description.background' project.yaml)
OVERVIEW=$(yq '.setup.description.overview' project.yaml)
REQUIREMENTS=$(yq '.setup.description.requirements' project.yaml)
TEST_STRATEGY=$(yq '.brainstorming.test_strategy' project.yaml)
```

## 実行手順

1. **investigation スキル** を実行
   - 上記コンテキストを入力として渡す
   - 対象: サブモジュール内の `{TARGET_REPO}` ディレクトリ
   - 成果物出力先: `docs/{TARGET_REPO}/investigation/`

## 完了後の状態更新

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER init-section investigation
$HELPER update investigation --status completed \
  --summary "対象リポジトリの詳細調査完了" \
  --artifacts "docs/{TARGET_REPO}/investigation/"
yq -i ".meta.updated_at = \"$(date -Iseconds)\"" project.yaml

git add project.yaml docs/
git commit -m "chore: {TICKET_ID} investigationセクション更新"
```
