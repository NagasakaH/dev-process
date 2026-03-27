# 実行ガイド

## 実行手順

### 1. 入力情報の確認

レビューに必要な以下の情報を確認する：

- **要件・受入基準**: 機能要件、非機能要件、受入基準
- **対象リポジトリ**: レビュー対象となるリポジトリ名
- **レビューラウンド**: 初回か再レビューか（再レビューの場合は前回の指摘を確認）

### 2. design/ 確認

```bash
DESIGN_DIR="docs/${TARGET}/design"
test -d "$DESIGN_DIR" || { echo "Error: $DESIGN_DIR not found"; exit 1; }
```

### 3. investigation/ 確認

```bash
INVESTIGATION_DIR="docs/${TARGET}/investigation"
test -d "$INVESTIGATION_DIR" || { echo "Warning: $INVESTIGATION_DIR not found. 調査結果との整合性チェックをスキップします。"; }
```

### 4. レビューの実施

各設計ファイルについて、レビュー項目に従い検証を実施：

1. **要件カバレッジレビュー**: 要件 vs 設計内容の対応確認
2. **技術的妥当性レビュー**: アーキテクチャ・技術選定の適切性
3. **実装可能性レビュー**: 設計の詳細度・明確さ
4. **テスト可能性レビュー**: テスト計画の網羅性
5. **リスク・懸念事項**: リスク分析と対応確認
6. **レビューサマリー**: 総合判定と指摘事項一覧

### 5. review-design/ 配下にファイル生成

```bash
REVIEW_DIR="docs/${TARGET}/review-design"
mkdir -p "$REVIEW_DIR"
```

### 6. コミット

```bash
git add docs/
git commit -m "docs: 設計レビュー結果を追加 (round {round})

- docs/{target}/review-design/ 配下にレビュー結果を出力"
```

## 出力ファイル構成

レビュー結果は `docs/{target}/review-design/` に出力：

```
docs/
└── {target}/
    └── review-design/
        ├── 01_requirements-coverage.md     # 要件カバレッジレビュー
        ├── 02_technical-validity.md        # 技術的妥当性レビュー
        ├── 03_implementation-feasibility.md # 実装可能性レビュー
        ├── 04_testability.md               # テスト可能性レビュー
        ├── 05_risks-and-concerns.md        # リスク・懸念事項
        └── 06_review-summary.md            # レビューサマリー
```

## 完了レポート

```markdown
## 設計レビュー完了 ✅

### レビュー対象
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
- docs/{target}/review-design/01_requirements-coverage.md
- docs/{target}/review-design/02_technical-validity.md
- docs/{target}/review-design/03_implementation-feasibility.md
- docs/{target}/review-design/04_testability.md
- docs/{target}/review-design/05_risks-and-concerns.md
- docs/{target}/review-design/06_review-summary.md

### 次のステップ
1. ✅ 承認の場合: 実装計画を作成
2. ⚠️ 条件付き承認の場合: 指摘事項を修正後、再レビュー
3. ❌ 差し戻しの場合: 設計を再実施
```

## エラーハンドリング

### design/ が見つからない

```
エラー: 設計結果が見つかりません
ディレクトリ: docs/{target}/design/

設計を完了してからレビューを実行してください。
```

### 要件が提供されていない

```
エラー: レビューの判断基準となる要件が提供されていません

レビューを実行するには、機能要件・非機能要件・受入基準を提供してください。
```
