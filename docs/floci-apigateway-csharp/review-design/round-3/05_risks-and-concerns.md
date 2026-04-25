# 05. リスク・懸念事項（round 3）

## 概要

| 項目 | 内容 |
|------|------|
| ラウンド | 3 |
| レビュー観点 | round3 設計に残存するリスク・将来課題 |

## 1. round2 起票リスクの状態更新

| ID | リスク | round3 状態 |
|----|--------|--------------|
| R-1 | UT-11 が回帰必須から漏れる | ✅ closed（DR2-001 resolved） |
| R-2 | E2E-5 が回帰必須から漏れる | ✅ closed（DR2-002 resolved） |
| R-3 | Function partial 宣言不整合による写経ビルド失敗 | ✅ closed（DR2-003 resolved） |

## 2. round3 新規リスク

なし。Critical/Major/Minor 指摘なし。

## 3. Info（任意記録、修正不要）

| ID | 内容 | round3 状態 |
|----|------|--------------|
| INFO-1 | ASL の Lambda ARN を Terraform `jsonencode` 例で動的参照する | ✅ 設計に反映済（`02_interface-api-design.md §5`、変更履歴 行 659） |
| INFO-2 | CI イメージで Alpine edge リポジトリ依存を避けると CI の安定性が向上 | ✅ 設計に反映済（実装フェーズで CI 安定性を担保する方針） |
| INFO-3 (任意) | Opus 側レビューにて CI 安定性に関する追加 Info あり。実装時の運用品質向上として参考にする（必須ではない） | 任意 |

## 4. 結論

新規 Critical/Major/Minor リスクなし。Info 群は実装フェーズで参照する形式で記録のみ。
