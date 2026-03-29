# ワークフロー: verification

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

## E2Eテスト完了条件の厳格化

テスト戦略にE2Eが含まれる場合、以下のルールを適用する：

### E2E実行前チェック

```bash
# テスト戦略にE2Eが含まれるか確認
E2E_INCLUDED=$(yq '.brainstorming.test_strategy' project.yaml | grep -i 'e2e')
if [ -n "$E2E_INCLUDED" ]; then
  echo "⚠️ E2Eテストがテスト戦略に含まれています。E2E実行は必須です。"
fi
```

### E2E未実行時のワークフロー停止ルール

テスト戦略にE2Eが含まれているにも関わらずE2Eテストが未実行の場合：

1. **ワークフローを即座に停止する**（verification を completed にしない）
2. **ユーザーに以下を提示して判断を仰ぐ:**
   - E2Eテストが実行できない具体的な理由
   - 環境準備に必要な手順の提案
   - テスト戦略変更の選択肢（E2E範囲の縮小・代替案）
3. **ユーザーの応答に基づいて対応する:**
   - 環境準備を選択 → 準備完了の確認後にE2Eテストを実行し、verification を再開
   - テスト戦略変更を承認 → 変更証跡を記録してから `project.yaml` の `test_strategy` を更新し verification を続行
4. **エージェントが独断で「E2Eスキップ」を決定し verification を完了にすることは禁止**

> 🚫 E2E未実行のまま verification.status を `completed` に更新することは禁止。
> 必ずユーザーの明示的な判断を得てから次のステップに進むこと。

### 🔒 テスト戦略変更時のユーザー承認証跡（必須）

テスト戦略を変更する場合、以下の手順を**全て**実施すること：

1. **`ask_user` ツールによる明示的な承認取得（必須）**
   - 変更理由・変更前の戦略・変更後の戦略を提示し、`ask_user` で承認を得る
   - テキスト出力のみでの確認は承認とみなさない
   - `ask_user` を経ずにテスト戦略を変更することは **禁止**

2. **変更証跡を `project.yaml` に記録**

```bash
# テスト戦略変更の証跡を記録
yq -i '.verification.test_strategy_changes += [{
  "reason": "変更理由",
  "original_strategy": "変更前のテスト戦略",
  "updated_strategy": "変更後のテスト戦略",
  "user_approved": true,
  "changed_at": "'"$(date -Iseconds)"'"
}]' project.yaml
```

> ⚠️ `user_approved: true` は `ask_user` ツールで承認を得た場合にのみ設定可能。
> エージェントが独自に `user_approved: true` を設定することはバイパスとみなす。

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
