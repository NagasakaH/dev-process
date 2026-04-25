# 出力テンプレート

## 出力ファイル構成

```
docs/
└── {target}/
    └── code-review/
        ├── round-01-group-01.md    # グループ1 レビュー結果
        ├── round-01-group-02.md    # グループ2 レビュー結果
        ├── round-01-summary.md     # 統合サマリー
        ├── round-02-group-01.md    # 再レビュー グループ1
        ├── round-02-summary.md     # 再レビュー統合サマリー
        └── ...
```

## グループ別レポート（round-NN-group-MM.md）

```markdown
# レビュー結果 - Round {N} / Group {M}: {グループ名}

## レビュー情報
- リポジトリ: {target}
- ベースSHA: {base_sha}
- ヘッドSHA: {head_sha}
- レビュー日時: {timestamp}
- レビュアー: Opus 4.6 + GPT-5.5 → Opus 4.6 統合

## 意図グループ情報
- グループ名: {group_name}
- カテゴリ: {category}
- 対象コミット:
  - {sha1}: {message1}
  - {sha2}: {message2}

## チェックリスト結果

### 1. 設計準拠性
- [x] DC-01: 設計成果物との整合性 — ✅ OK
- [ ] DC-02: API/インターフェース互換性 — 🟠 指摘あり（CR-001）
...

### 9. MR要求項目（MR/PR存在時のみ）
- [ ] MR-001: {項目名} — 🟠 指摘あり（CR-010）
...

## 指摘事項

### 🔴 Critical
（なし）

### 🟠 Major
- **CR-001**: API/インターフェース互換性
  - カテゴリ: 設計準拠性
  - 出典: Both（Opus 4.6 + GPT-5.5）
  - 説明: {問題の詳細}
  - 該当ファイル: {file_path}:{line_number}
  - 修正提案: {具体的な修正内容}

### 🟡 Minor
...

### 🔵 Info
...

## 棄却された指摘（統合時に除外）
- {指摘内容} — 棄却理由: {理由}、出典: {A or B}

## 静的解析ツール実行結果
- eslint: ✅ PASS
- tsc: ✅ PASS
...

## グループ判定
- **判定**: {✅ 承認 / ⚠️ 条件付き承認 / ❌ 差し戻し}
- **理由**: {判定理由}
```

## 統合サマリー（round-NN-summary.md）

```markdown
# レビュー統合サマリー - Round {N}

## レビュー情報
- リポジトリ: {target}
- コミット範囲: {base_sha}..{head_sha}
- MR/PR: {PR/MR URL or "未検出（ローカルブランチのみ）"}
- レビュー日時: {timestamp}

## 意図分析結果

| グループ | カテゴリ | コミット数 | 変更ファイル数 |
|----------|----------|-----------|---------------|
| Group 1: {名前} | {cat} | {n} | {n} |
| Group 2: {名前} | {cat} | {n} | {n} |

## グループ別判定

| グループ | 判定 | Critical | Major | Minor | Info |
|----------|------|----------|-------|-------|------|
| Group 1 | ✅ | 0 | 0 | 0 | 1 |
| Group 2 | ⚠️ | 0 | 1 | 2 | 0 |

## グループ横断的な問題
- {グループ間の一貫性、相互影響に関する指摘}

## MR/PR要求項目の充足状況（MR/PR存在時のみ）
| 項目 | ステータス | 関連グループ |
|------|-----------|-------------|
| MR-001: {項目名} | ✅ 充足 / ❌ 未充足 | Group 1 |

## 総合判定
- **判定**: {✅ 承認 / ⚠️ 条件付き承認 / ❌ 差し戻し}
- **指摘合計**: Critical {c}件 / Major {m}件 / Minor {mi}件 / Info {i}件
- **理由**: {判定理由}

## 生成されたファイル
- docs/{target}/code-review/round-{NN}-group-01.md
- docs/{target}/code-review/round-{NN}-group-02.md
- docs/{target}/code-review/round-{NN}-summary.md
```

## コミットメッセージテンプレート

```bash
git add docs/
git commit -m "docs: 実装レビュー結果を追加 (round {round})

- {group_count}グループに分割してデュアルモデルレビューを実施
- チェックリスト: {pass_count}/{total_count} 通過
- 指摘: Critical {c}件 / Major {m}件 / Minor {mi}件 / Info {i}件"
```
