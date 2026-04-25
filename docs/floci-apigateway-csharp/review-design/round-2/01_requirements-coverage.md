# 01. 要件カバレッジ（round 2）

## 概要

| 項目 | 内容 |
|------|------|
| ラウンド | 2 |
| レビュー観点 | 機能要件・非機能要件・受入基準と round2 設計成果物の対応状況 |
| 設計参照 | [../../design/](../../design/) |

## 1. round1 指摘の対応確認

| 関連 ID | round1 指摘要旨 | round2 反映先 | 状態 |
|---------|------------------|----------------|------|
| DR-001 | AC7（実 AWS 不使用）担保 | `02_interface-api-design.md §3.4`、`06_side-effect-verification.md §1.1` | ✅ resolved |
| DR-002 | id 生成責務の統一 | `02_interface-api-design.md §2.1, §4`、`03_data-structure-design.md`、`04_process-flow-design.md`、`05_test-plan.md` | ✅ resolved |
| DR-003 | CRUD スコープの明確化 | `00_design-overview.md §1`、`02_interface-api-design.md §1` | ✅ resolved |
| DR-004 | README 章構成の固定 | `05_test-plan.md` 末尾 README 章定義 | ✅ resolved |

## 2. round2 新規確認

| 受入基準 | 確認結果 | 備考 |
|----------|----------|------|
| AC1（.NET 8 Lambda 実装） | ✅ 充足 | round2 で変更なし |
| AC2（Terraform で API GW/Lambda/SFN） | ✅ 充足 | round2 で変更なし |
| AC3（xUnit 単体テスト） | ⚠️ 軽微指摘 | DR2-001: UT-11（description 正規化）が `06 §2.2` 回帰チェックリストの必須対象から漏れている |
| AC4（Lambda レベルテスト） | ✅ 充足 | round2 で変更なし |
| AC5（API GW E2E） | ⚠️ 軽微指摘 | DR2-002: E2E-5（localhost 混入検出）が `06 §2.2` の必須 E2E に含まれていない |
| AC6（README 章構成） | ✅ 充足 | round2 で変更なし |
| AC7（実 AWS 不使用） | ✅ 充足 | round1 修正済 |

## 3. 結論

要件・受入基準カバレッジは round1 比で改善済みだが、AC3 / AC5 を実運用で担保する回帰チェックリスト（`06_side-effect-verification.md §2.2`）に UT-11 / E2E-5 が反映されていないため、Minor 2 件を新規指摘（DR2-001, DR2-002）として起票。
