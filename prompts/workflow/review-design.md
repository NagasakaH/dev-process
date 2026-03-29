# ワークフロー: review-design

> ⚠️ **必須**: このステップは `review-design` スキルの `skill` ツール経由での呼び出しが必須です。
> スキルを使わない手動実行は禁止されています。

設計結果の妥当性をレビューする。

## 前提条件チェック

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER validate  # review-design の前提条件を確認
# design.status=completed であること
```

## コンテキスト取得

```bash
TICKET_ID=$(yq '.meta.ticket_id' project.yaml)
TARGET_REPO=$(yq '.meta.target_repo' project.yaml)
REQUIREMENTS=$(yq '.setup.description.requirements' project.yaml)
ACCEPTANCE_CRITERIA=$(yq '.setup.description.acceptance_criteria' project.yaml)
DESIGN_ARTIFACTS=$(yq '.design.artifacts' project.yaml)
DESIGN_SUMMARY=$(yq '.design.summary' project.yaml)
```

## 実行手順

1. **review-design スキル** を実行
   - 設計ドキュメント（`{DESIGN_ARTIFACTS}`）と要件を入力として渡す
   - 成果物出力先: `docs/{TARGET_REPO}/review-design/`

## 完了後の状態更新

```bash
HELPER="./scripts/project-yaml-helper.sh"

# design.review サブセクション更新
yq -i '.design.review.status = "approved"' project.yaml  # or "conditional" / "rejected"
yq -i '.design.review.round = (.design.review.round // 0) + 1' project.yaml
yq -i ".design.review.reviewed_at = \"$(date -Iseconds)\"" project.yaml
yq -i '.design.review.artifacts = "docs/{TARGET_REPO}/review-design/"' project.yaml
yq -i ".meta.updated_at = \"$(date -Iseconds)\"" project.yaml

git add project.yaml docs/
git commit -m "chore: {TICKET_ID} design reviewセクション更新"
```

## 完了後の人間チェックポイント

```bash
# design_review チェックポイントが pending 状態になる
# ユーザーの承認を待つ
```
