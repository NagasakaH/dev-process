# 出力テンプレート

## 出力ファイル構成

レビュー結果は `docs/{target}/code-review/` に出力：

```
docs/
└── {target}/
    └── code-review/
        ├── round-01.md                    # 第1ラウンド レビュー結果
        ├── round-02.md                    # 第2ラウンド レビュー結果（再レビュー時）
        └── ...
```

## ラウンドレポート構成（round-NN.md）

各ラウンドのレポートには以下を含みます：

```markdown
# レビュー結果 - Round {N}

## レビュー情報
- リポジトリ: {target}
- ベースSHA: {base_sha}
- ヘッドSHA: {head_sha}
- レビュー日時: {timestamp}

## チェックリスト結果

### 1. 設計準拠性
- [x] DC-01: 設計成果物との整合性 — ✅ OK
- [ ] DC-02: API/インターフェース互換性 — 🟠 指摘あり（CR-001）
...

### 2. 静的解析・フォーマット
- [x] SA-01: .editorconfig 準拠 — ✅ OK
...

（8カテゴリ全て）

## 指摘事項

### 🔴 Critical
（なし）

### 🟠 Major
- **CR-001**: API/インターフェース互換性
  - カテゴリ: 設計準拠性
  - 説明: {問題の詳細}
  - 該当ファイル: {file_path}:{line_number}
  - 修正提案: {具体的な修正内容}

### 🟡 Minor
...

### 🔵 Info
...

## 静的解析ツール実行結果
- editorconfig-checker: ✅ PASS
- prettier: ⚠️ 2 files need formatting
- eslint: ✅ PASS
- tsc: ✅ PASS
- npm audit: ✅ 0 vulnerabilities
- npm test: ✅ All tests passed

## 総合判定
- **判定**: {✅ 承認 / ⚠️ 条件付き承認 / ❌ 差し戻し}
- **理由**: {判定理由}

## 前ラウンドからの変化（round > 1 の場合）
- 解決済み: {count}件
- 新規指摘: {count}件
- 未解決: {count}件
```

## 完了レポート

```markdown
## 実装レビュー完了 ✅

### レビュー対象
- リポジトリ: {target}
- コミット範囲: {base_sha}..{head_sha}
- ラウンド: {round}

### 総合判定
- **判定**: {✅ 承認 / ⚠️ 条件付き承認 / ❌ 差し戻し}

### チェックリスト結果
- ✅ Pass: {count}項目
- ⚠️ Warn: {count}項目
- ❌ Fail: {count}項目
- ⏭️ Skip: {count}項目

### 指摘事項サマリー
- 🔴 Critical: {count}件
- 🟠 Major: {count}件
- 🟡 Minor: {count}件
- 🔵 Info: {count}件

### 静的解析ツール実行結果
{ツール名: 結果}

### 生成されたファイル
- docs/{target}/code-review/round-{NN}.md

### 次のステップ
1. ✅ 承認の場合: レビュー完了
2. ⚠️ 条件付き承認の場合: 指摘事項を修正後、再レビュー
3. ❌ 差し戻しの場合: 指摘事項を修正後、再レビュー
```

## コミットメッセージテンプレート

```bash
git add docs/
git commit -m "docs: 実装レビュー結果を追加 (round {round})

- docs/{target}/code-review/round-{NN}.md にレビュー結果を出力
- チェックリスト: {pass_count}/{total_count} 通過
- 指摘: Critical {c}件 / Major {m}件 / Minor {mi}件 / Info {i}件"
```
