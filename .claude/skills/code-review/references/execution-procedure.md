# 実行手順詳細

## 全体フロー

```
1. コミット範囲特定
2. MR/PR判定・ディスクリプション取得
3. レビュー要求項目AI抽出
4. コミット意図分析・グループ化
5. グループごとに順次デュアルモデルレビュー
6. グループ別レポート出力
7. 統合サマリー出力・コミット
8. MR/PRへの結果書き込み
9. [全指摘解消時] Draft解除
```

## 1. コミット範囲の特定

```bash
BASE_SHA=$(git merge-base HEAD origin/main)
HEAD_SHA=$(git rev-parse HEAD)
git log --oneline "$BASE_SHA..$HEAD_SHA"
git diff --stat "$BASE_SHA..$HEAD_SHA"
```

## 2. MR/PR判定・ディスクリプション取得

📖 詳細は [mr-description-extraction.md](mr-description-extraction.md) を参照

## 3. コミット意図分析・グループ化

📖 詳細は [intent-analysis.md](intent-analysis.md) を参照

## 4. グループごとのデュアルモデルレビュー

各グループについて以下を順次実行:

1. グループ対象コミットの差分を取得
2. 静的解析ツールの検出・実行（グループ対象ファイルに限定）
3. **Opus 4.6 + Codex 5.3 の並列レビュー起動**（task ツール background モード）
4. 両レビュー結果を **Opus 4.6（統合担当）** に入力して統合判定
5. `round-NN-group-MM.md` 出力

📖 デュアルモデルの詳細は [dual-model-review.md](dual-model-review.md) を参照

### 静的解析ツールの検出

**検出対象:**
- `.editorconfig` → editorconfig-checker
- `package.json` → prettier / eslint / tsc / npm audit / npm test
- `pyproject.toml` / `setup.py` → black / flake8 / mypy / pytest / pip-audit
- `go.mod` → gofmt / golangci-lint / go test / govulncheck
- `Cargo.toml` → rustfmt / clippy / cargo test / cargo audit
- `*.csproj` / `*.sln` → dotnet format / dotnet build / dotnet test
- `Makefile` → make lint / make test

## 5. 統合サマリー出力

全グループのレビュー完了後、`round-NN-summary.md` を生成:
- 意図分析結果（グループ一覧）
- 全グループの指摘集計
- グループ横断的な問題（相互影響・一貫性）
- 総合判定

## 6. コミット

📖 コミットメッセージテンプレートは [output-template.md](output-template.md) を参照

## 7. MR/PRへの結果書き込み

レビュー結果をMR/PRに反映:

1. `round-NN-summary.md` をMR/PRコメントとして投稿
2. MR/PR descriptionのチェックリストを検証結果に基づき更新
3. AI+人間チェック項目にAI分析結果と根拠を追記

📖 詳細は [mr-pr-result-writing.md](mr-pr-result-writing.md) を参照

## 8. Draft解除（全指摘解消時のみ）

全てのcode-review-fixループが完了し、指摘がゼロになった場合:

1. 最終ラウンドのレビューが `approved` であることを確認
2. 全ACに対応するテストがpassしていることを確認
3. MR/PRのdraftを解除

📖 Draft解除コマンドは [mr-pr-result-writing.md](mr-pr-result-writing.md) を参照

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| コミット範囲が特定できない | 手動でBASE_SHA/HEAD_SHAを指定させる |
| MR/PRが見つからない | スキップして標準レビュー（エラーにしない） |
| レビュアーモデルがタイムアウト | リトライ1回、それでも失敗なら片方のみで続行 |
