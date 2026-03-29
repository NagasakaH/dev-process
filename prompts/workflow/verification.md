# ワークフロー: verification

> ⚠️ **必須**: このステップは `verification` スキルの `skill` ツール経由での呼び出しが必須です。
> スキルを使わない手動実行は禁止されています。

実装完了後にテスト・ビルド・リントの実行結果を確認する。

## 前提条件チェック

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER validate  # verification の前提条件を確認
# implement.status=completed であること
```

## コンテキスト取得

```bash
TICKET_ID=$(yq '.meta.ticket_id' project.yaml)
TARGET_REPO=$(yq '.meta.target_repo' project.yaml)
IMPL_STATUS=$(yq '.implement.status' project.yaml)
TEST_STRATEGY=$(yq '.brainstorming.test_strategy' project.yaml)
ACCEPTANCE_CRITERIA=$(yq '.setup.description.acceptance_criteria' project.yaml)
```

## 実行手順

1. **verification スキル** を実行
   - テスト戦略（`{TEST_STRATEGY}`）に基づいて検証
   - 受入基準（`{ACCEPTANCE_CRITERIA}`）との照合
   - テスト・ビルド・リント・E2Eテスト実行

## 完了後の状態更新

```bash
HELPER="./scripts/project-yaml-helper.sh"
$HELPER init-section verification
$HELPER update verification --status completed \
  --summary "全検証項目パス"
yq -i ".meta.updated_at = \"$(date -Iseconds)\"" project.yaml

git add project.yaml
git commit -m "chore: {TICKET_ID} verificationセクション更新"
```
