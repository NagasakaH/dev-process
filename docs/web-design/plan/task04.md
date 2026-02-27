# タスク: task04 - README.md作成

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task04 |
| タスク名 | README.md作成 |
| 前提条件タスク | task03 |
| 並列実行可否 | 不可 |
| 推定所要時間 | 10分 |
| 優先度 | 中 |

---

## 作業環境

- **作業ディレクトリ（worktree）**: /tmp/WEB-DESIGN-001-task04/
- **ブランチ**: WEB-DESIGN-001-task04
- **対象リポジトリ**: submodules/web-design
- **重要**: 必ず上記の作業ディレクトリ内で作業を行ってください

---

## 前提条件

### 前提タスク成果物

| タスク | 成果物パス | 参照内容 |
|--------|------------|----------|
| task01 | `.devcontainer/` | devcontainer構成の説明に使用 |
| task02-01 | `scripts/dev-container.sh` | 使用方法の説明に使用 |
| task02-02 | `scripts/build-and-push-devcontainer.sh` | ビルド手順の説明に使用 |
| task02-03 | `package.json` | npm scriptsの説明に使用 |
| task03 | `e2e/` | テスト実行方法の説明に使用 |

### 確認事項

- [ ] 全前提タスクが完了していること
- [ ] 全前提タスクのコミットがcherry-pick済みであること

---

## 作業内容

### 目的

プロジェクトの使用方法、セットアップ手順、開発ワークフロー、セキュリティガイドラインをREADME.mdに文書化する。

### 設計参照

- [design/01_implementation-approach.md](../design/01_implementation-approach.md) — 技術選定、制約事項
- [design/02_interface-api-design.md](../design/02_interface-api-design.md) — コマンド体系、セキュリティガイドライン
- [design/04_process-flow-design.md](../design/04_process-flow-design.md) — 開発ワークフロー

### 実装ステップ

1. `README.md` を作成
2. 以下のセクションを含める:
   - プロジェクト概要
   - 前提条件（Docker Engine, devcontainer CLI）
   - クイックスタート（DinD/DooDモード）
   - 開発ワークフロー（code-server → Vite dev server → ブラウザプレビュー）
   - npm scripts一覧
   - プリビルドイメージの作成方法
   - E2Eテスト実行方法
   - DooD/DinD切り替えの説明
   - 技術スタック
   - セキュリティに関する注意事項（MRD-005対応）
   - Copilot CLI利用方法（Open VSX制約の説明）

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `README.md` | 新規作成 | プロジェクトREADME |

---

## テスト方針

ドキュメントタスクのため個別テストは不要。

### 実装時の確認

```bash
# Markdownの構文確認（リンク切れ等）
cat README.md | head -5  # タイトル確認
grep -c "##" README.md   # セクション数確認
```

---

## 成果物

### 期待される出力

| 成果物 | パス | 説明 |
|--------|------|------|
| README | `README.md` | プロジェクト説明・使用方法・セキュリティガイドライン |

---

## 完了条件

### 機能的条件

- [ ] プロジェクト概要が記載されていること
- [ ] 前提条件（Docker, devcontainer CLI）が記載されていること
- [ ] クイックスタート手順（dev-container.sh up）が記載されていること
- [ ] DinD/DooDモードの切り替え方法が記載されていること
- [ ] 開発ワークフロー（code-server → npm run dev → ブラウザプレビュー）が記載されていること
- [ ] npm scripts一覧が記載されていること
- [ ] プリビルドイメージ作成方法（build-and-push-devcontainer.sh）が記載されていること
- [ ] E2Eテスト実行方法が記載されていること
- [ ] 技術スタック一覧が記載されていること
- [ ] セキュリティ注意事項が記載されていること（code-server --auth none のリスク、ローカル限定）
- [ ] Copilot CLI利用方法とOpen VSX制約の説明が記載されていること

### ドキュメント条件

- [ ] Markdown構文が正しいこと
- [ ] コマンド例がコードブロックで囲まれていること

---

## コミット

```bash
cd /tmp/WEB-DESIGN-001-task04/
git add -A
git status
git diff --staged

git commit -m "docs: README.mdを作成

- プロジェクト概要・技術スタック
- クイックスタート・開発ワークフロー
- DooD/DinD切り替え説明
- E2Eテスト実行方法
- セキュリティガイドライン

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"

git rev-parse HEAD
```

---

## 注意事項

- MRD-005: セキュリティガイドラインセクションを必ず含める（`--auth none` はローカル限定、公開ネットワーク禁止）
- Copilot拡張の代わりにCopilot CLIを使用する理由（Open VSX制約）を明記
- dev-processからの移植であることを記載（開発者が背景を理解できるように）
