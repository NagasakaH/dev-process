# ワークフロー: create-mr-pr

Draft MR/PRを作成し、テンプレート付きチェックリストを設定する。

## 前提条件チェック

### DRモード（Step 5a）

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER validate  # design.status=completed, design.review.status を確認
```

### Codeモード（Step 9）

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER validate  # verification.status=completed であること
```

## コンテキスト取得

```bash
TICKET_ID=$(yq '.meta.ticket_id' project.yaml)
TARGET_REPO=$(yq '.meta.target_repo' project.yaml)
ACCEPTANCE_CRITERIA=$(yq '.setup.description.acceptance_criteria' project.yaml)
```

## 実行手順

### DRモード

1. **create-mr-pr スキル** を DRモードで実行
   - dev-processリポにdraft MR/PR作成
   - ACテストマッピングテーブル生成（設計書・テスト計画から）
   - 修正対象リポジトリ合意テーブル生成（editable/readonly構成から）

### Codeモード

1. **create-mr-pr スキル** を Codeモードで実行
   - 各submodule（editable/配下）にdraft MR/PR作成
   - 統合MR/PR要否判定（クロスリポテストの有無で判定）
   - 必要なら dev-process に統合MR/PR作成

## 完了後の状態更新

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER init-section create_mr_pr
$HELPER update create_mr_pr --status completed \
  --summary "MR/PR作成完了"

# MR/PR URLを記録
yq -i ".create_mr_pr.mr_pr_urls = [\"$MR_URL\"]" project.yaml
yq -i ".create_mr_pr.mode = \"$MODE\"" project.yaml  # "dr" or "code"
yq -i ".create_mr_pr.platform = \"$PLATFORM\"" project.yaml  # "github" or "gitlab"
yq -i ".meta.updated_at = \"$(date -Iseconds)\"" project.yaml

git add project.yaml
git commit -m "chore: {TICKET_ID} create_mr_prセクション更新"
```

## DRモード完了後の人間チェックポイント

```bash
# design_review チェックポイントが pending 状態
# ユーザーがMR/PR上でレビュー
# 承認後、MR/PRをclose（マージしない）
```

## Codeモード完了後

code-review（Step 10）に進む。
