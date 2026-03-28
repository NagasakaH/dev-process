# ワークフロー: code-review

コミット差分を意図グループごとに分割し、デュアルモデルレビュー（Opus 4.6 + Codex 5.3）で品質を担保する。
レビュー結果はMR/PRに書き込み、全指摘解消後にdraft解除。

## 前提条件チェック

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER validate  # code-review の前提条件を確認
# verification.status=completed, create_mr_pr.status=completed であること
```

## コンテキスト取得

```bash
TICKET_ID=$(yq '.meta.ticket_id' project.yaml)
TARGET_REPO=$(yq '.meta.target_repo' project.yaml)
DESIGN_ARTIFACTS=$(yq '.design.artifacts' project.yaml)
MR_PR_URLS=$(yq '.create_mr_pr.mr_pr_urls[]' project.yaml)
```

## 実行手順

1. **code-review スキル** を実行
   - コミット一覧取得 → 意図分析 → グループ化
   - MR/PRディスクリプションからレビュー要求項目を自動抽出
   - グループごとに Opus 4.6 + Codex 5.3 の並列レビュー → Opus 4.6 が統合判定
   - CI/パイプライン結果確認（TC-06）、変更コードカバレッジ検証（TC-07）
   - **AC全項目テスト必須検証（TC-08, Critical）** — 未達は自動rejected
   - **修正範囲スコープ検証（TC-09, Critical）** — DR合意外は自動rejected
   - 成果物出力先: `docs/{TARGET_REPO}/code-review/`
   - **MR/PRへの結果書き込み**:
     - `round-NN-summary.md` をMR/PRコメントとして投稿
     - descriptionチェックリスト更新（AI自動チェック項目）
     - AI+人間チェック項目にAI分析根拠追記

2. **レビュー結果の処理**:
   - **approved**: draft解除 → pr_review チェックポイント
   - **conditional / rejected**: `code-review-fix` で修正 → 再レビュー
   - テスト不足でrejectedの場合: ユーザーにリソース提供を要求

3. **全指摘解消後**:
   - MR/PRのdraft解除
   - pr_review 人間チェックポイントが pending 状態に

## 完了後の状態更新

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER init-section code_review

yq -i '.code_review.status = "approved"' project.yaml  # or "conditional" / "rejected"
yq -i '.code_review.round = (.code_review.round // 0) + 1' project.yaml
yq -i ".code_review.reviewed_at = \"$(date -Iseconds)\"" project.yaml
yq -i '.code_review.artifacts = "docs/{TARGET_REPO}/code-review/"' project.yaml
yq -i ".code_review.review_method = \"dual-model (opus-4.6 + codex-5.3)\"" project.yaml
yq -i ".meta.updated_at = \"$(date -Iseconds)\"" project.yaml

git add project.yaml docs/
git commit -m "chore: {TICKET_ID} code_reviewセクション更新"
```

## 完了後の人間チェックポイント

```bash
# draft解除後、pr_review チェックポイントが pending 状態
# 人間がMR/PR上でレビュー
# 承認後、merge実施（統合MR/PRがある場合はマージ順序に従う）
```
