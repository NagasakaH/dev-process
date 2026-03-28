---
name: code-review
description: 実装完了後のコード変更をデュアルモデル（Opus 4.6 + Codex 5.3）でレビューするスキル。コミット単位で意図を分析しグループ化、MR/PRディスクリプションからレビュー要求を自動抽出、グループごとに並列レビュー→統合判定を実施し、docs/{target}/code-review/配下にグループ別レポート+統合サマリーを出力する。「コードレビュー」「実装レビュー」「code-review」「PRレビュー」「変更レビュー」「レビュー依頼」「レビューして」などのフレーズで発動。
---

# コードレビュースキル（code-review）

コミット差分を**意図グループごとに分割**し、**デュアルモデルレビュー**（Opus 4.6 + Codex 5.3）で品質を担保するスキルです。

> **責務の範囲**: 指摘と修正案の提示まで。修正は `code-review-fix` スキルで対応。

> [!CAUTION]
> **レビュー品質方針（ゼロトレランス）**
> - レビュアーは **不具合を出さないことに命が懸かっている** つもりで指摘すること
> - **Minor を含む全ての指摘は修正必須**
> - 品質劣化の入口となる軽微な問題も必ず指摘する

## ワークフロー

```
1. コミット一覧取得 → 2. MR/PR判定・ディスクリプション取得
→ 3. レビュー要求項目AI抽出 → 4. コミット意図分析・グループ化
→ 5. グループごとに順次デュアルモデルレビュー
→ 6. グループ別レポート + 統合サマリー出力
```

📖 詳細は [references/execution-procedure.md](references/execution-procedure.md) を参照

## デュアルモデルレビュー

各グループに対し **Opus 4.6** と **Codex 5.3** が並列レビュー → **Opus 4.6（第3）が統合・判定**。

📖 詳細は [references/dual-model-review.md](references/dual-model-review.md) を参照

## 入力

| 入力 | 必須 | 説明 |
|------|------|------|
| ブランチ差分 | ✅ | `BASE_SHA..HEAD_SHA` のコミット一覧 |
| MR/PRディスクリプション | 自動 | GitHub PR / GitLab MR から自動取得（なければスキップ） |
| 設計ドキュメント | 推奨 | `docs/{target}/design/` 配下 |

📖 MR/PR取得の詳細は [references/mr-description-extraction.md](references/mr-description-extraction.md) を参照

## 意図分析・グループ化

コミットメッセージ + diff概要から各コミットの意図を分析し、関連コミットをグループ化。

📖 詳細は [references/intent-analysis.md](references/intent-analysis.md) を参照

## レビューチェックリスト（8カテゴリ + MR要求項目）

| # | カテゴリ | 主なチェック観点 |
|---|----------|------------------|
| 1 | 設計準拠性 | 設計成果物・API・データ構造・処理フローとの整合性 |
| 2 | 静的解析 | .editorconfig / フォーマッター / リンター / 型チェック |
| 3 | 言語別BP | アンチパターン / エラーハンドリング / null安全性 |
| 4 | セキュリティ | シークレット漏洩 / インジェクション / 認証認可 |
| 5 | テスト・CI | テスト追加更新 / カバレッジ / 全通過 / CI結果 / 変更コードカバレッジ |
| 6 | パフォーマンス | N+1クエリ / メモリリーク / アルゴリズム効率 |
| 7 | ドキュメント | API doc / README / CHANGELOG |
| 8 | Git作法 | コミット粒度 / デバッグコード / 不要ファイル |
| 9 | MR要求項目 | MR/PRディスクリプションから抽出した項目（存在時のみ） |

📖 詳細は [references/review-checklist.md](references/review-checklist.md) を参照

## 重大度レベルと判定基準

| レベル | 説明 | 判定への影響 |
|--------|------|--------------|
| 🔴 Critical | 本番障害・セキュリティ脆弱性 | → ❌ 差し戻し |
| 🟠 Major | バグ・設計違反 | → ⚠️ 条件付き承認 |
| 🟡 Minor | スタイル・軽微な改善 | → ⚠️ 条件付き承認 |
| 🔵 Info | 提案・ベストプラクティス | → ✅ 承認（対応推奨） |

## 出力

- `round-NN-group-MM.md` — グループ別レポート
- `round-NN-summary.md` — 統合サマリー

📖 詳細は [references/output-template.md](references/output-template.md) を参照
📖 再レビューは [references/re-review-procedure.md](references/re-review-procedure.md) を参照