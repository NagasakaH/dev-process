# 04. テスト可能性（round 2）

## 概要

| 項目 | 内容 |
|------|------|
| ラウンド | 2 |
| レビュー観点 | テスト計画の網羅性・自動化整合性 |

## 1. round1 指摘の対応確認

| 関連 ID | round1 指摘要旨 | round2 反映先 | 状態 |
|---------|------------------|----------------|------|
| DR-013 | description 正規化 + UT 追加 | `05_test-plan.md` UT-11、`02_interface-api-design.md §2.1` | ✅ resolved（UT 追加済み） |
| DR-015 | Integration fixture 確定 | `05_test-plan.md` IT fixture | ✅ resolved |

## 2. round2 新規確認

### 2.1 回帰チェックリストとの整合性

`05_test-plan.md` 上は UT-1〜UT-11 / E2E-PRE-1〜E2E-5 が定義されているが、`06_side-effect-verification.md §2.2` の回帰必須対象は UT-1〜UT-10 / E2E-PRE-1〜E2E-3 に留まっている：

- **UT-11（description 正規化）が必須回帰実行対象から漏れている**（DR2-001、Minor）
- **E2E-5（localhost 混入検出）が必須 E2E から漏れている**（DR2-002、Minor）

両者とも DR-013/DR-016 で round2 設計に追加した検証であり、回帰チェックリストから外れていると CI で実行されなくなり実質的に round1 指摘の効果を失う。修正必須。

### 2.2 その他

- IT fixture が `AWSSDK.DynamoDBv2 CreateTableAsync` の冪等実行に確定したことで Integration テストの再現性は十分。
- E2E-PRE-1 で floci 起動確認、E2E-5 で localhost 混入検出と、サンプル参照実装に必要な自動アサーションが網羅されている（必須対象に追加すれば完了）。

## 3. 結論

テスト網羅性自体は round1 比で大幅改善。回帰チェックリストへの UT-11 / E2E-5 追加（DR2-001/002）が完了すれば、テスト可能性面の Critical/Major 指摘なし。
