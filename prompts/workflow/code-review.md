# ワークフロー: code-review

コード変更をチェックリストベースでレビューする。

## 前提条件チェック

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER validate  # code-review の前提条件を確認
# verification.status=completed であること
```

## コンテキスト取得

```bash
TICKET_ID=$(yq '.meta.ticket_id' project.yaml)
TARGET_REPO=$(yq '.meta.target_repo' project.yaml)
DESIGN_ARTIFACTS=$(yq '.design.artifacts' project.yaml)
VERIFICATION_STATUS=$(yq '.verification.status' project.yaml)
```

## 実行手順

1. **code-review スキル** を実行
   - ブランチのdiff、設計ドキュメントを入力として渡す
   - 成果物出力先: `docs/{TARGET_REPO}/code-review/`

## 完了後の状態更新

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER init-section code_review

# レビュー結果に応じて更新
yq -i '.code_review.status = "approved"' project.yaml  # or "conditional" / "rejected"
yq -i '.code_review.round = (.code_review.round // 0) + 1' project.yaml
yq -i ".code_review.reviewed_at = \"$(date -Iseconds)\"" project.yaml
yq -i '.code_review.artifacts = "docs/{TARGET_REPO}/code-review/"' project.yaml
yq -i ".meta.updated_at = \"$(date -Iseconds)\"" project.yaml

# 指摘がある場合は issues 配列を追加
# yq -i '.code_review.issues = [...]' project.yaml

git add project.yaml docs/
git commit -m "chore: {TICKET_ID} code_reviewセクション更新"
```
