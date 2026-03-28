---
name: design
description: 調査結果を基に詳細設計を行う汎用スキル。要件・調査結果・設計制約を入力として、実装方針決定、インターフェース/API設計、データ構造設計、処理フロー設計、テスト計画を実施し、docs/{target}/design/ディレクトリに詳細設計を出力する。「design」「設計して」「詳細設計」「アーキテクチャ設計」「インターフェース設計」「API設計」「データ構造設計」「処理フロー設計」「テスト戦略」などのフレーズで発動。調査プロセス完了後、実装前に使用。
---

# 開発設計スキル

要件・調査結果・設計制約を入力として、詳細設計を行い、docs/{target}/design/ ディレクトリに設計ドキュメントを出力します。

> **再設計時**: 設計レビューで指摘がある場合、未解決（`status: open`）の指摘を優先的に対応してください。

## 入力情報

| 種別 | 必須 | 内容 |
| ---- | ---- | ---- |
| 要件 | ✅ | 機能要件・非機能要件・受入基準 |
| 調査結果 | ✅ | docs/{target}/investigation/ 配下の調査ドキュメント |
| 設計制約・決定事項 | - | 技術的決定・深掘り要件・制約条件 |
| 設計ドキュメント | - | 既存の設計ドキュメント（存在すれば更新） |

📖 詳細は references/input-information.md を参照

## 処理フロー

```
入力確認 → 調査結果読込 → 設計実施 → design/生成 → ドキュメント更新 → コミット → 完了レポート
```

📖 詳細は references/execution-steps.md を参照

## 設計実施項目と出力ファイル

| No | 設計項目 | 出力ファイル |
| -- | -------- | ------------ |
| 1 | 実装方針決定 | 01_implementation-approach-template.md |
| 2 | インターフェース/API設計 | 02_interface-api-design-template.md |
| 3 | データ構造設計 | 03_data-structure-design-template.md |
| 4 | 処理フロー設計 | 04_process-flow-design-template.md |
| 5 | テスト計画 | 05_test-plan-template.md |
| 6 | 弊害検証計画 | 06_side-effect-verification-template.md |

出力先: `docs/{target_repository}/design/`

📖 各項目の詳細は references/design-categories.md を参照

## 重要ルール

- シーケンス図は必ず**修正前/修正後を対比**させる
- テスト計画では**事前決定のテスト戦略を必ず参照**し、全テスト範囲を含める
- **acceptance_criteria との対応表**を明記（単体/結合/E2E）
- E2Eテストがスコープ内の場合、具体的な実行手順・判定基準を記載
- 調査で特定されたリスクがある場合、**リスク軽減策を設計に組み込む**
- 設計は対象リポジトリのみ対象、調査未完了ならエラー終了

📖 ガイドライン詳細は references/diagram-guidelines.md を参照

## 設計ドキュメント更新・完了条件

既存の設計ドキュメントがある場合、「2. 設計」セクションと完了条件セクションを更新します。
完了条件は「実装レビュー完了」「テスト完了」「弊害検証完了」の3カテゴリで構造化します。

📖 詳細は references/document-update-and-criteria.md を参照

## 参照スキル

- 前提スキル: `investigation` - 開発タスク用詳細調査
- 後続スキル: `review-design` - 設計レビュー
- 後続スキル: `plan` - タスク計画
- 後続スキル: `implement` - 実装
