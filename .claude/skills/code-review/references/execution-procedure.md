# 実行手順詳細

## 1. コミット範囲の特定

```bash
# ベースブランチとの差分を特定
BASE_SHA=$(git merge-base HEAD origin/main)
HEAD_SHA=$(git rev-parse HEAD)

# 変更ファイル一覧
git diff --name-only "$BASE_SHA..$HEAD_SHA"

# 変更統計
git diff --stat "$BASE_SHA..$HEAD_SHA"
```

## 2. 静的解析ツールの検出と実行

プロジェクト内で利用可能なツールを検出し実行します。

**検出対象:**
- `.editorconfig` → editorconfig-checker
- `package.json` → prettier / eslint / tsc / npm audit / npm test
- `pyproject.toml` / `setup.py` → black / flake8 / mypy / pytest / pip-audit
- `go.mod` → gofmt / golangci-lint / go test / govulncheck
- `Cargo.toml` → rustfmt / clippy / cargo test / cargo audit
- `*.csproj` / `*.sln` → dotnet format / dotnet build / dotnet test
- `Makefile` → make lint / make test
- `.github/workflows/` → CI設定の確認

**実行結果はラウンドレポートの各チェック項目に記録します。**

## 3. チェックリストベースレビュー

8カテゴリのチェック項目について、差分内容・静的解析結果を基にレビューを実施：

1. **設計準拠性**: design/ の各ドキュメントと実装の対応を検証
2. **静的解析・フォーマット**: ツール実行結果の確認
3. **言語別ベストプラクティス**: 変更ファイルの言語に応じたアンチパターン検出
4. **セキュリティ**: セキュリティチェックリストに基づく検証
5. **テスト・CI**: テスト実行結果・カバレッジの確認
6. **パフォーマンス**: 差分内のパフォーマンス問題検出
7. **ドキュメント**: ドキュメント更新の確認
8. **Git作法**: コミット履歴・デバッグコード残留の確認

## 4. レビュー結果ファイル生成

```bash
REVIEW_DIR="docs/${TARGET}/code-review"
mkdir -p "$REVIEW_DIR"
```

`docs/{target}/code-review/round-{NN}.md` にラウンドレポートを生成。

## 5. コミット

📖 コミットメッセージテンプレートは [output-template.md](output-template.md) を参照

## エラーハンドリング

### コミット範囲が特定できない

```
警告: コミット範囲が自動検出できません。
手動でBASE_SHAとHEAD_SHAを指定してください。

例: BASE_SHA=$(git merge-base HEAD origin/main)
    HEAD_SHA=$(git rev-parse HEAD)
```
