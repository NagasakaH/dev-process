# ワークフロー: code-review-fix

> ⚠️ **必須**: このステップは `code-review-fix` スキルの `skill` ツール経由での呼び出しが必須です。
> スキルを使わない手動実行は禁止されています。

コードレビュー指摘を技術的に検証し、修正を実施する。

## 前提条件チェック

```bash
# code_review.status が conditional / rejected であること
REVIEW_STATUS=$(yq '.code_review.status' project.yaml)
if [ "$REVIEW_STATUS" != "conditional" ] && [ "$REVIEW_STATUS" != "rejected" ]; then
  echo "Error: code_review.status が conditional / rejected ではありません"
  exit 1
fi
```

## コンテキスト取得

```bash
TICKET_ID=$(yq '.meta.ticket_id' project.yaml)
TARGET_REPO=$(yq '.meta.target_repo' project.yaml)
CURRENT_ROUND=$(yq '.code_review.round' project.yaml)

# 未解決の指摘事項を取得
yq '.code_review.issues[] | select(.status == "open")' project.yaml
```

## 実行手順

1. **code-review-fix スキル** を実行
   - 指摘事項リストとレビュードキュメントを入力として渡す
   - レビュー結果: `docs/{TARGET_REPO}/code-review/round-{CURRENT_ROUND}.md`

## 完了後の状態更新

```bash
# 各指摘のステータス更新
yq -i '(.code_review.issues[] | select(.id == "CR-001")).status = "fixed"' project.yaml
yq -i '(.code_review.issues[] | select(.id == "CR-001")).fixed_description = "修正内容"' project.yaml

# 反論の場合
yq -i '(.code_review.issues[] | select(.id == "CR-002")).status = "disputed"' project.yaml
yq -i '(.code_review.issues[] | select(.id == "CR-002")).dispute_reason = "技術的理由"' project.yaml

yq -i ".meta.updated_at = \"$(date -Iseconds)\"" project.yaml

git add -A
git commit -m "fix: {TICKET_ID} コードレビュー指摘を修正 (round {CURRENT_ROUND})"
```
