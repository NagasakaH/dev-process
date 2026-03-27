# 実行手順の詳細

## 1. 入力情報の確認

設計に必要な入力情報を確認します：

- **要件**: 機能要件・非機能要件・受入基準が明確であること
- **調査結果**: 事前調査が完了しており、調査ドキュメントが存在すること

```bash
# 調査ドキュメントの存在確認
for repo in "${target_repositories[@]}"; do
    INVESTIGATION_DIR="docs/${repo}/investigation"
    test -d "$INVESTIGATION_DIR" || { echo "Error: $INVESTIGATION_DIR not found"; exit 1; }
done
```

## 2. 設計ドキュメント確認（任意）

```bash
# 既存の設計ドキュメントがあれば更新対象とする
DESIGN_DOC="docs/${ticket_id}.md"
if [ -f "$DESIGN_DOC" ]; then
    echo "設計ドキュメントを発見: $DESIGN_DOC"
fi
```

## 3. 調査結果の読み込みと分析

調査ドキュメントから以下を読み込みます：

- アーキテクチャ情報
- データ構造情報
- 依存関係情報
- 既存パターン情報
- 統合ポイント情報
- リスク・制約情報

## 4. 設計の実施

各設計項目について、調査結果・要件・決定事項を基に詳細設計を実施：

1. 実装方針の決定（技術的決定事項を反映）
2. インターフェース/API設計
3. データ構造設計
4. 処理フロー設計（シーケンス図の修正前/修正後対比）
5. テスト計画策定
6. 弊害検証計画策定（調査で特定されたリスクを反映）

## 5. design/ 配下にファイル生成

```bash
for repo in "${target_repositories[@]}"; do
    DESIGN_DIR="docs/${repo}/design"
    mkdir -p "$DESIGN_DIR"
    
    # 各設計ファイルを生成
    # 01_implementation-approach.md
    # 02_interface-api-design.md
    # 03_data-structure-design.md
    # 04_process-flow-design.md
    # 05_test-plan.md
    # 06_side-effect-verification.md
done
```

## 6. 設計ドキュメント更新（存在する場合）

既存の設計ドキュメントの「2. 設計」セクションと完了条件セクションを更新します。

## 7. コミット

```bash
# 設計結果をコミット
git add docs/
git commit -m "docs: design 完了

- docs/{target}/design/ に詳細設計を出力"
```

## 完了レポート

```markdown
## 設計完了 ✅

### 設計対象
- チケット: {ticket_id}
- タスク: {task_name}
- リポジトリ: {target_repositories}

### 生成されたファイル

#### 詳細設計結果
- docs/{target}/design/01_implementation-approach.md
- docs/{target}/design/02_interface-api-design.md
- docs/{target}/design/03_data-structure-design.md
- docs/{target}/design/04_process-flow-design.md
- docs/{target}/design/05_test-plan.md
- docs/{target}/design/06_side-effect-verification.md

### 設計サマリー
- 実装方針: {approach_summary}
- 変更ファイル数: {file_count}
- 新規テストケース数: {test_case_count}
- 弊害検証項目数: {verification_item_count}

### 次のステップ
1. 設計レビューを実施（review-design）
2. タスク計画（plan）でタスク分割を実施
3. 実装（implement）を開始
```

## エラーハンドリング

### 調査結果が見つからない

```
エラー: 調査結果が見つかりません

docs/{target}/investigation/ ディレクトリが存在しません。
事前に調査（investigation）を完了してください。
```

### 設計ドキュメントが見つからない

```
警告: 設計ドキュメントが見つかりません
ファイル: docs/{ticket_id}.md

設計ドキュメントの更新はスキップします。
design/ 配下のファイルは生成されます。
```
