# 実行手順・完了レポート・エラーハンドリング

---

## 実行手順

### 1. 入力情報の確認

呼び出し元から以下の情報を受け取り、調査の方針を決定します：

- **対象リポジトリパス**: 調査するリポジトリのディレクトリ
- **対象リポジトリ名**: 出力先ディレクトリ名（`docs/{name}/investigation/`）
- **背景コンテキスト**: なぜこの調査が必要か
- **調査目的**: 何を明らかにしたいか

### 2. 対象リポジトリの調査

対象リポジトリに対して調査を実施：

```bash
REPO_PATH="{対象リポジトリパス}"
TARGET_REPO="{対象リポジトリ名}"
OUTPUT_DIR="docs/${TARGET_REPO}/investigation"

cd "$REPO_PATH"

# investigation ディレクトリ作成
mkdir -p "$OUTPUT_DIR"

# 各調査を実施し、結果をファイルに出力
# ... (調査処理)
```

### 3. コミット

```bash
git add docs/
git commit -m "docs: investigation 完了

- docs/{target_repo}/investigation/ に詳細調査結果を出力"
```

---

## 完了レポート

```markdown
## 調査完了 ✅

### 調査対象
- リポジトリ: {target_repo}
- 調査目的: {調査目的の要約}

### 調査結果サマリ

- **要約**: {調査結果の要約}
- **重要な発見**:
  - {発見1}
  - {発見2}
- **リスク**:
  - {リスク}
- **成果物**: docs/{target_repo}/investigation/

### 生成されたファイル

#### 詳細調査結果
- docs/{target_repo}/investigation/01_architecture.md
- docs/{target_repo}/investigation/02_data-structure.md
- docs/{target_repo}/investigation/03_dependencies.md
- docs/{target_repo}/investigation/04_existing-patterns.md
- docs/{target_repo}/investigation/05_integration-points.md
- docs/{target_repo}/investigation/06_risks-and-constraints.md

### 次のステップ
1. 調査結果をレビュー
2. 設計スキル（design）を使用して詳細設計を開始
3. タスク計画スキル（plan）でタスク分割を実施
```

---

## エラーハンドリング

### 対象リポジトリが指定されていない
```
エラー: 対象リポジトリパスが指定されていません

呼び出し元から対象リポジトリパスと調査目的を提供してください。
```

### 対象リポジトリにアクセスできない
```
警告: リポジトリにアクセスできません
リポジトリ: {repo_path}

リポジトリのパスが正しいか確認してください。
```
