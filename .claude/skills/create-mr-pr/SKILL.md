---
name: create-mr-pr
description: Draft MR/PRを作成しテンプレート付きチェックリストを設定するスキル。DRモード（設計レビュー用、dev-processリポ、close運用）とCodeモード（コードレビュー用、各submoduleリポ、merge運用）の2モードを持つ。「MR作成」「PR作成」「create-mr-pr」「ドラフトPR」「レビュー用MR」などのフレーズで発動。
---

# MR/PR作成スキル（create-mr-pr）

Draft MR/PRを作成し、テンプレート付きチェックリストをdescriptionに設定するスキルです。

## 2つのモード

| モード | 対象リポ | 運用 | 用途 |
|--------|----------|------|------|
| **DR** | dev-process | close（マージしない） | 設計レビュー |
| **Code** | 各submodule | merge | コードレビュー |

## 入力

| 入力 | 必須 | 説明 |
|------|------|------|
| モード | ✅ | `dr` または `code` |
| ブランチ名 | ✅ | `git branch --show-current` で取得 |
| ベースブランチ | ✅ | マージ先（通常 main/master） |
| チケットID | 推奨 | ブランチ名やコミットメッセージから推測 |

## ワークフロー

```
1. プラットフォーム検出（GitHub/GitLab）
2. モード判定 → テンプレート選択
3. テンプレート内容を生成（ACマッピング等を動的構築）
4. draft MR/PR作成
5. [Codeモード] 統合MR/PR要否判定 → 必要なら作成
```

📖 プラットフォーム検出: [references/platform-detection.md](references/platform-detection.md)

## DRモード

設計レビュー用MR/PRをdev-processリポに作成。

テンプレート内容:
- 設計概要 + 設計資料リンク
- ACテストマッピングテーブル（必須）
- 修正対象リポジトリ合意テーブル（必須）
- テスト戦略チェックリスト（拡充版）

📖 DRテンプレート詳細: [references/dr-template.md](references/dr-template.md)

## Codeモード

コードレビュー用MR/PRを各submodule（`submodules/editable/`配下）のリポに作成。

テンプレート内容:
- AI自動チェック（7項目）
- AI+人間チェック（8項目）

📖 Codeテンプレート詳細: [references/code-template.md](references/code-template.md)

### 統合MR/PR

複数submodule修正時、またはクロスリポ結合テストがある場合、dev-processリポに統合MR/PRを追加作成。

📖 統合MR/PR手順: [references/integration-mr-pr.md](references/integration-mr-pr.md)

## レッドフラグ

**絶対にしない:**
- draft以外でMR/PRを作成する
- テンプレートのチェックリストを省略する
- ACテストマッピングテーブルを空のまま作成する（DRモード）
- 修正対象リポジトリ合意テーブルを省略する（DRモード）

## 完了報告

| モード | 報告内容 |
|--------|----------|
| DR | MR/PR URL、テンプレート設定完了 |
| Code | 各submodule MR/PR URL（+ 統合MR/PR URL） |
