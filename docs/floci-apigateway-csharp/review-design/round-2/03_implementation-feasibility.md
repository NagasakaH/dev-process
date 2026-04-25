# 03. 実装可能性（round 2）

## 概要

| 項目 | 内容 |
|------|------|
| ラウンド | 2 |
| レビュー観点 | 詳細度・制約整合性・サンプル参照実装としての再現性 |

## 1. round1 指摘の対応確認

| 関連 ID | round1 指摘要旨 | round2 反映先 | 状態 |
|---------|------------------|----------------|------|
| DR-007 | .gitlab-ci.yml スケルトン | `01_implementation-approach.md`、`05_test-plan.md` | ✅ resolved |
| DR-008 | docker-compose 完全例 | `01_implementation-approach.md`、`05_test-plan.md` | ✅ resolved |
| DR-014 | deploy-local.sh / e2e.sh 擬似コード | `01_implementation-approach.md`、`05_test-plan.md` | ✅ resolved |
| DR-016 | var.endpoint vs FLOCI_HOSTNAME 役割分担 | `02_interface-api-design.md §6.2.1`、`06_side-effect-verification.md §1.1` | ✅ resolved |

## 2. round2 新規確認

### 2.1 partial class 宣言不整合の影響（DR2-003 連動）

`02 §3.1` の宣言と `§3.2` の宣言が partial で揃っていないため、本設計をそのまま写経実装するとビルドが失敗する。サンプル参照実装の写経再現性を阻害するため修正必須（DR2-003 として `02_technical-validity.md` 側で起票）。

### 2.2 回帰チェックリストの実行整合性（DR2-001 / DR2-002 連動）

`06_side-effect-verification.md §2.2` の必須 PASS 一覧が `05_test-plan.md` の UT/E2E 一覧（UT-1〜UT-11 / E2E-PRE-1〜E2E-5）と乖離しており、CI 実装段階で「設計上必須なのに CI から漏れる」リスクがある。Minor として `01_requirements-coverage.md` 側で起票。

## 3. 結論

具体 HCL/YAML/スクリプトは round2 で大きく拡充され、サンプルとしての再現性は十分。Minor 3 件（DR2-001/002/003）を解消すれば実装計画フェーズへ進行可能。
