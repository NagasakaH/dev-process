---
name: code-review-fix
description: コードレビュー指摘を受けて技術的に検証し、修正を実施するスキル。code-reviewスキルの指摘事項を確認し、技術的妥当性を検証した上で修正コードを実装する。「レビュー修正」「指摘対応」「code-review-fix」「レビューフィードバック対応」などのフレーズで発動。code-reviewスキルで指摘があった場合に使用。
---

# コードレビュー修正スキル（code-review-fix）

code-review スキルの指摘事項を受けて、技術的に検証した上で修正を実施します。

> **SSOT**: `project.yaml` を全プロセスの Single Source of Truth として使用します。
> - レビュー指摘の参照: `code_review` セクション
> - 修正結果の記録: `code_review` セクション（同セクション更新）
>
> **技術的厳密さ**: 指摘を盲目的に受け入れず、必ず技術的に検証してから修正します。

## 概要

このスキルは以下を実現します：

1. **project.yaml** の `code_review.issues` から未解決の指摘事項を取得
2. **レビュー結果ドキュメント** (`docs/{target_repo}/code-review/round-{NN}.md`) を参照
3. **各指摘を技術的に検証** — コードベースの現実と照合
4. **妥当な指摘に対して修正を実施**
5. **不適切な指摘に対して技術的理由を付けて反論を記録**
6. **修正後にテスト・リント・型チェックを実行して確認**
7. **project.yaml の code_review セクション** を更新してコミット

## レスポンスパターン

各指摘に対して以下の手順で対応します：

1. **READ**: 指摘内容を正確に理解する
2. **VERIFY**: コードベースの現実と照合する
3. **EVALUATE**: この指摘は技術的に正しいか？
4. **IMPLEMENT/DISPUTE**: 修正を実施、または技術的理由で反論

### 反論すべきケース

- 提案が既存機能を壊す場合
- 指摘がコードの完全なコンテキストを欠いている場合
- YAGNI違反（未使用機能の追加要求）の場合
- この技術スタックで技術的に不正確な場合

## 入力

### 1. project.yaml（必須・SSOT）

```bash
# 前提条件の確認
REVIEW_STATUS=$(yq '.code_review.status' project.yaml)
if [ "$REVIEW_STATUS" != "conditional" ] && [ "$REVIEW_STATUS" != "rejected" ]; then
    echo "Error: code_review.status が conditional / rejected ではありません（現在: $REVIEW_STATUS）"
    exit 1
fi

# メタ情報の取得
TICKET_ID=$(yq '.meta.ticket_id' project.yaml)
TARGET_REPO=$(yq '.meta.target_repo' project.yaml)
CURRENT_ROUND=$(yq '.code_review.round' project.yaml)

# 未解決の指摘事項を取得
yq '.code_review.issues[] | select(.status == "open")' project.yaml
```

### 2. レビュー結果ドキュメント

`docs/{target_repo}/code-review/round-{NN}.md` — 指摘の詳細コンテキスト。

## 処理フロー

```mermaid
flowchart TD
    A[project.yaml読み込み] --> B[code_review.issues から open 指摘取得]
    B --> C[レビュー結果ドキュメント読み込み]
    C --> D[各指摘を技術的に検証]
    D --> E{指摘は妥当?}
    E -->|✅ 妥当| F[修正を実施]
    E -->|❌ 不適切| G[技術的理由で反論を記録]
    F --> H[テスト・リント・型チェック実行]
    G --> H
    H --> I{全て通過?}
    I -->|✅| J[project.yaml 更新]
    I -->|❌| K[修正を調整]
    K --> H
    J --> L[コミット]
    L --> M[完了レポート → code-review 再レビューへ]
```

## project.yaml 更新内容

修正完了後、`code_review` セクションの `issues` を yq で更新：

```bash
# 修正済み指摘のステータス更新
yq -i '(.code_review.issues[] | select(.id == "CR-001")).status = "fixed"' project.yaml
yq -i '(.code_review.issues[] | select(.id == "CR-001")).fixed_description = "APIレスポンスを { data, error } 形式に修正"' project.yaml

yq -i '(.code_review.issues[] | select(.id == "CR-002")).status = "fixed"' project.yaml
yq -i '(.code_review.issues[] | select(.id == "CR-002")).fixed_description = "console.log を削除"' project.yaml

# 反論の場合
yq -i '(.code_review.issues[] | select(.id == "CR-003")).status = "disputed"' project.yaml
yq -i '(.code_review.issues[] | select(.id == "CR-003")).dispute_reason = "YAGNI違反のため対応不要"' project.yaml

# meta.updated_at を更新
yq -i ".meta.updated_at = \"$(date -Iseconds)\"" project.yaml
```

### issues の status 遷移

| status     | 説明                                       |
| ---------- | ------------------------------------------ |
| `open`     | 未対応（code-review が設定）               |
| `fixed`    | 修正済み（code-review-fix が設定）         |
| `disputed` | 技術的理由で反論（code-review-fix が設定） |
| `resolved` | 再レビューで解決確認（code-review が設定） |
| `wontfix`  | 再レビューで反論承認（code-review が設定） |

## コミット

```bash
git add -A
git commit -m "fix: {ticket_id} コードレビュー指摘を修正 (round {round})

- 修正: {fixed_count}件
- 反論: {disputed_count}件
- 対象: {file_list}"
```

## 完了レポート

```markdown
## コードレビュー修正完了

### 対応結果
- **修正**: {fixed_count}件
- **反論**: {disputed_count}件

### 修正内容
| ID     | 重大度 | 対応 | 説明                                  |
| ------ | ------ | ---- | ------------------------------------- |
| CR-001 | Major  | 修正 | APIレスポンス形式を設計に合わせて修正 |
| CR-002 | Minor  | 修正 | console.log を削除                    |
| CR-003 | Minor  | 反論 | YAGNI違反のため対応不要               |

### 検証結果
- テスト: ✅ 全通過
- リント: ✅ エラーなし
- 型チェック: ✅ エラーなし

### 次のステップ
code-review スキルで再レビューを実施してください。
```

## 注意事項

- **技術的検証が最優先**: 指摘を盲目的に受け入れない
- **テスト確認必須**: 修正後に既存テストが壊れていないか確認
- **反論は具体的に**: 技術的理由を明確に記載
- **1指摘ずつ対応**: まとめて修正せず、各指摘を個別に検証・対応

## 関連スキル

- 前提スキル: `code-review` - コードレビュー（指摘を生成）
- 後続スキル: `code-review` - 再レビュー（修正結果を検証）
- 品質ルール: `verification-before-completion` - 修正後の検証
- 品質ルール: `test-driven-development` - テストファーストの修正

## SSOT参照

| project.yaml フィールド              | 用途                    |
| ------------------------------------ | ----------------------- |
| `code_review.issues`                 | 未解決指摘事項の取得    |
| `code_review.round`                  | 現在のレビューラウンド  |
| `code_review.issues[].status` (出力) | fixed / disputed に更新 |
