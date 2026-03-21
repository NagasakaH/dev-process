# Task 06: .env.example + 環境変数ドキュメント

## タスク情報

| 項目 | 内容 |
|------|------|
| ID | 06 |
| タスク名 | .env.example + 環境変数ドキュメント |
| 前提タスク | なし |
| 並列実行 | P2-A (03, 04, 05 と並列可) |
| 見積時間 | 5分 |

## 作業環境

- **worktree**: `/tmp/viewer-container-local-06/`
- **ブランチ**: `task/06-env-example`
- **サブモジュール**: `submodules/copilot-session-viewer/`

## 前提条件

- なし（独立タスク）

## 作業内容

### 目的

コンテナ起動時に必要な環境変数テンプレート `.env.example` を作成する。ユーザーが `.env` を作成するための参考とする。

### 設計参照

- `docs/copilot-session-viewer/design/02_interface-api-design.md` — セクション 6 (環境変数インターフェース)
- `docs/copilot-session-viewer/design/03_data-structure-design.md` — セクション 4.2 (.env ファイル構造)

### 実装ステップ

1. **.env.example を作成**
   ```bash
   # === Required ===
   GITHUB_TOKEN=ghp_your_personal_access_token_here

   # === Authentication (optional, omit to disable Basic Auth) ===
   # BASIC_AUTH_USER=admin
   # BASIC_AUTH_PASS=secret

   # === Container Settings (defaults shown, usually no change needed) ===
   # DISABLE_DOCKER_DETECTION=true
   # ENABLE_DEV_PROCESS=false
   # PORT=3000
   # PROJECT_NAME=viewer
   ```

2. **.gitignore に .env を追加** (存在しなければ)
   ```
   .env
   .env.local
   .env.*.local
   ```

### 対象ファイル

| ファイル | 操作 |
|---------|------|
| `submodules/copilot-session-viewer/.env.example` | 新規作成 |
| `submodules/copilot-session-viewer/.gitignore` | 修正 (必要に応じて) |

## TDD アプローチ

### RED (失敗するテストを書く)

このタスクは設定ファイル作成のため、テスト対象は存在確認のみ。

```typescript
// テスト不要 — 設定ファイルのみ
// .env.example の存在は Integration テスト (Task 11) で検証
```

### GREEN (最小実装)

1. `.env.example` を作成
2. `.gitignore` に `.env` が含まれていなければ追加

### REFACTOR (改善)

- 環境変数のコメントが明確で、ユーザーが迷わない記述か確認

## 期待される成果物

- `submodules/copilot-session-viewer/.env.example`
- `submodules/copilot-session-viewer/.gitignore` (修正、必要に応じて)

## 完了条件

- [ ] `.env.example` が存在し、`GITHUB_TOKEN`, `BASIC_AUTH_USER`, `BASIC_AUTH_PASS` のテンプレートが含まれる
- [ ] `.gitignore` に `.env` が含まれる
- [ ] `.env.example` が `.gitignore` で除外されていない

## コミット

```bash
git add -A
git commit -m "feat: add .env.example with auth settings template

- Add GITHUB_TOKEN, BASIC_AUTH, container settings template
- Ensure .env is gitignored

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```
