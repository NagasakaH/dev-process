# ワークフロー: code-review

コミット差分を意図グループごとに分割し、デュアルモデルレビュー（Opus 4.6 + Codex 5.3）で品質を担保する。

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
   - コミット一覧取得 → 意図分析 → グループ化
   - MR/PRディスクリプションからレビュー要求項目を自動抽出（存在する場合）
   - グループごとに Opus 4.6 + Codex 5.3 の並列レビュー → Opus 4.6 が統合判定
   - CI/パイプライン結果確認（TC-06）、変更コードカバレッジ検証（TC-07）
   - 成果物出力先: `docs/{TARGET_REPO}/code-review/`
     - `round-NN-group-MM.md` — グループ別レポート
     - `round-NN-summary.md` — 統合サマリー

## 完了後の状態更新

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER init-section code_review

# レビュー結果に応じて更新（統合サマリーの総合判定に基づく）
yq -i '.code_review.status = "approved"' project.yaml  # or "conditional" / "rejected"
yq -i '.code_review.round = (.code_review.round // 0) + 1' project.yaml
yq -i ".code_review.reviewed_at = \"$(date -Iseconds)\"" project.yaml
yq -i '.code_review.artifacts = "docs/{TARGET_REPO}/code-review/"' project.yaml
yq -i ".code_review.review_method = \"dual-model (opus-4.6 + codex-5.3)\"" project.yaml
yq -i ".meta.updated_at = \"$(date -Iseconds)\"" project.yaml

# 指摘がある場合は issues 配列を追加
# yq -i '.code_review.issues = [...]' project.yaml

git add project.yaml docs/
git commit -m "chore: {TICKET_ID} code_reviewセクション更新"
```
