# 統合MR/PR手順

複数submoduleに跨る変更、またはクロスリポ結合テストがある場合にdev-processリポに作成する統合MR/PR。

## 作成条件

統合MR/PRが**必要**な場合:
1. 複数の `submodules/editable/` 配下リポに変更がある
2. 単一submoduleでも、他リポとの結合テストが定義されている
3. テストが単一リポジトリ内で完結しない

統合MR/PRが**不要**な場合:
- 単一submoduleのみ変更 かつ テストがそのリポ内で完結

## テンプレート構造

```markdown
## 統合レビュー: {タイトル}

### 概要

{複数リポにまたがる変更の全体像}

### 関連MR/PR

| # | リポジトリ | MR/PR URL | ステータス |
|---|---|---|---|
| 1 | {repo_1} | {url_1} | ⬜ Draft |
| 2 | {repo_2} | {url_2} | ⬜ Draft |

### マージ順序

| 順序 | リポジトリ | 理由 |
|---|---|---|
| 1 | {repo_1} | {依存関係の説明: 例「ライブラリ側を先にマージ」} |
| 2 | {repo_2} | {「利用側はライブラリ更新後にマージ」} |

### クロスリポテスト

| # | テスト内容 | 対象リポ | テスト種別 | 状態 |
|---|---|---|---|---|
| 1 | {結合テスト内容} | repo_1 + repo_2 | 結合/E2E | ⬜ |

### チェックリスト

- [ ] 全サブMR/PRのcode-review完了
- [ ] クロスリポ結合テスト全パス
- [ ] マージ順序の妥当性確認
- [ ] 各リポのAPI互換性確認
- [ ] データスキーマ互換性確認（該当する場合）
```

## 運用フロー

```
1. 各submodule MR/PR作成（draft）
2. 統合MR/PR作成（draft）— 上記テンプレートで
3. 各submodule MR/PR → 個別code-review
4. 統合MR/PR → クロスリポレビュー
5. 全レビュー完了 → 各submodule MR/PR undraft
6. マージ順序に従ってマージ実施
7. 統合MR/PR close
```

## 判定ルール

- 1つでもsubmodule MR/PRが rejected → 統合MR/PR も rejected
- 全submodule MR/PR approved + クロスリポテスト全パス → 統合MR/PR approved
