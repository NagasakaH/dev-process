# 調査手法リファレンス

各調査カテゴリで使用する具体的な調査コマンドと手法。

---

## アーキテクチャ調査

```bash
# ディレクトリ構造の確認
find . -type d -maxdepth 3 | head -50

# 設定ファイルの確認
find . -name "*.config.*" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" | head -30

# エントリーポイントの確認
grep -r "main\|index\|app" --include="*.ts" --include="*.js" --include="*.py" -l | head -20
```

## データ構造調査

```bash
# 型定義・インターフェースの検索
grep -r "interface\|type\|class\|entity\|model\|schema" --include="*.ts" --include="*.py" -l | head -30

# ORM/DBスキーマの検索
find . -name "*entity*" -o -name "*model*" -o -name "*schema*" | head -20
```

## 依存関係調査

```bash
# パッケージ依存関係
cat package.json 2>/dev/null || cat pyproject.toml 2>/dev/null || cat requirements.txt 2>/dev/null

# インポート文の分析
grep -r "^import\|^from" --include="*.ts" --include="*.py" | head -50
```

## 既存パターン調査

```bash
# コーディングスタイル設定
cat .eslintrc* .prettierrc* .editorconfig pyproject.toml setup.cfg 2>/dev/null

# テストファイルの構成
find . -name "*.test.*" -o -name "*.spec.*" -o -name "test_*" | head -20
```

## 統合ポイント調査

```bash
# API定義・エンドポイント
grep -r "router\|endpoint\|@Get\|@Post\|api\|route" --include="*.ts" --include="*.py" -l | head -20

# イベント・メッセージング
grep -r "emit\|publish\|subscribe\|event\|listener" --include="*.ts" --include="*.py" -l | head -20
```
