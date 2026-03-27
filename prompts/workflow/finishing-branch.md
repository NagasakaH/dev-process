# ワークフロー: finishing-branch

実装完了後の統合作業（マージ/PR/クリーンアップ）を行う。

## 前提条件チェック

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER validate  # finishing-branch の前提条件を確認
# code_review.status=approved であること
```

## コンテキスト取得

```bash
TICKET_ID=$(yq '.meta.ticket_id' project.yaml)
TARGET_REPO=$(yq '.meta.target_repo' project.yaml)
```

## 実行手順

1. **finishing-branch スキル** を実行
   - マージ/PR/keep/discard の選択肢をユーザーに提示
   - 選択に応じた作業を実行

## 完了後の状態更新

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER init-section finishing
$HELPER update finishing --status completed \
  --summary "ブランチ統合完了"

# アクション記録
yq -i '.finishing.action = "pr"' project.yaml  # or "merge" / "keep" / "discard"
yq -i ".meta.updated_at = \"$(date -Iseconds)\"" project.yaml

git add project.yaml
git commit -m "chore: {TICKET_ID} finishingセクション更新"
```

## 完了後の人間チェックポイント

```bash
# PR作成の場合、pr_review チェックポイントが pending 状態になる
# ユーザーの承認を待つ
```
