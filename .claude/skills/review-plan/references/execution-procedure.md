# 実行手順・完了レポート

## 実行手順

### 1. 入力情報の収集

以下の情報を収集します：

- **タスク識別情報**: チケットID、タスク名、対象リポジトリ名
- **受入基準**: タスク計画が満たすべき基準の一覧
- **タスク計画ドキュメント**: plan/ 配下のタスク計画ファイル群
- **設計ドキュメント**: design/ 配下の設計ファイル群（任意）
- **前回レビュー結果**: 再レビューの場合、前ラウンドの指摘事項

### 2. レビュー実施・出力

「レビュー実施項目」に従い検証を実施し、`docs/{target}/review-plan/` に出力。

### 3. コミット

```bash
git add docs/
git commit -m "docs: {ticket_id} 計画レビュー結果を追加 (round {round})

- docs/{target}/review-plan/配下にレビュー結果を出力"
```

## 完了レポート

```markdown
## 計画レビュー完了 ✅

### レビュー対象
- チケット: {ticket_id}
- タスク: {task_name}
- リポジトリ: {target}

### 総合判定
- **判定**: {✅ 承認 / ⚠️ 条件付き承認 / ❌ 差し戻し}

### 指摘事項サマリー
- 🔴 Critical: {count}件
- 🟠 Major: {count}件
- 🟡 Minor: {count}件
- 🔵 Info: {count}件

### 生成されたファイル
- docs/{target}/review-plan/01_task-decomposition.md
- docs/{target}/review-plan/02_dependency-accuracy.md
- docs/{target}/review-plan/03_estimation-validity.md
- docs/{target}/review-plan/04_tdd-approach.md
- docs/{target}/review-plan/05_acceptance-coverage.md
- docs/{target}/review-plan/06_review-summary.md

### 次のステップ
1. ✅ 承認の場合: 実装フェーズを開始
2. ⚠️ 条件付き承認の場合: 指摘事項を修正後、再レビュー
3. ❌ 差し戻しの場合: タスク計画を再作成
```

## 典型的なワークフロー

```
[入力情報の収集] --> 受入基準・タスク情報を確認
        |
[再レビュー確認] --> 再レビューの場合、前回指摘を読み込み
        |
[タスク計画読み込み] --> タスク計画ドキュメントの読み込み
        |
[設計読み込み] --> 設計ドキュメントの読み込み（任意）
        |
[レビュー実施] --> タスク分割・依存関係・見積もり・TDD・受入基準
        |
[review-plan/生成] --> レビュー結果ファイルを生成
        |
[コミット] --> 変更をコミット
        |
[判定分岐] --> ✅承認→implement / ⚠️条件付き→plan再修正 / ❌差し戻し→plan再実施
```
