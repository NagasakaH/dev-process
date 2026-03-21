# Task 09: devcontainer.json ベースイメージ定義

## タスク情報

| 項目 | 内容 |
|------|------|
| ID | 09 |
| タスク名 | devcontainer.json ベースイメージ定義 |
| 前提タスク | なし |
| 並列実行 | P3-B (07, 08 と並列可) |
| 見積時間 | 10分 |

## 作業環境

- **worktree**: `/tmp/viewer-container-local-09/`
- **ブランチ**: `task/09-devcontainer-json`
- **サブモジュール**: `submodules/copilot-session-viewer/`

## 前提条件

- なし（独立タスク）

## 作業内容

### 目的

devcontainer features を使って Layer 1 ベースイメージ `copilot-session-viewer:base` を定義する `.devcontainer/devcontainer.json` を作成する。

### 設計参照

- `docs/copilot-session-viewer/design/02_interface-api-design.md` — セクション 4 (devcontainer.json インターフェース)
- `docs/copilot-session-viewer/design/01_implementation-approach.md` — セクション 3.1, 3.2 (2層イメージ構成, ベースイメージ)

### 実装ステップ

1. **`.devcontainer/` ディレクトリ作成**

2. **`.devcontainer/devcontainer.json` 作成**
   ```json
   {
     "name": "Copilot Session Viewer Base",
     "image": "mcr.microsoft.com/devcontainers/javascript-node:22",
     "features": {
       "ghcr.io/devcontainers/features/git:1": {},
       "ghcr.io/devcontainers/features/github-cli:1": {},
       "ghcr.io/devcontainers/features/copilot-cli:1": {},
       "ghcr.io/schlich/devcontainer-features/playwright:0": {},
       "ghcr.io/devcontainers-extra/features/tmux-apt-get:1": {},
       "ghcr.io/jungaretti/features/ripgrep:1": {}
     }
   }
   ```

3. **ベースイメージビルドコマンドを README 等に記載検討**
   ```bash
   devcontainer build --workspace-folder . --image-name copilot-session-viewer:base
   ```

### Features 一覧と用途

| Feature | 用途 | 必須/推奨 |
|---------|------|----------|
| `git:1` | セッション情報取得 | 推奨 |
| `github-cli:1` | GitHub 認証、API アクセス | 推奨 |
| `copilot-cli:1` | Copilot CLI セッション実行 | 必須 |
| `playwright:0` | E2E テストブラウザ依存 | 推奨 |
| `tmux-apt-get:1` | tmux 基本インストール | 必須 |
| `ripgrep:1` | テキスト検索 (Copilot CLI 使用) | 推奨 |

### 対象ファイル

| ファイル | 操作 |
|---------|------|
| `submodules/copilot-session-viewer/.devcontainer/devcontainer.json` | 新規作成 |

## TDD アプローチ

### RED (失敗するテストを書く)

JSON バリデーション:

```bash
# devcontainer.json が valid JSON であること
python3 -m json.tool .devcontainer/devcontainer.json > /dev/null
echo $?  # 0 であること
```

### GREEN (最小実装)

1. `.devcontainer/` ディレクトリ作成
2. `devcontainer.json` を作成
3. JSON 構文チェック PASS

### REFACTOR (改善)

- features のバージョン固定検討
- 不要な features の削除検討

## 期待される成果物

- `submodules/copilot-session-viewer/.devcontainer/devcontainer.json`

## 完了条件

- [ ] `.devcontainer/devcontainer.json` が存在し、valid JSON
- [ ] ベースイメージが `mcr.microsoft.com/devcontainers/javascript-node:22`
- [ ] 6 つの features が定義されている (git, github-cli, copilot-cli, playwright, tmux-apt-get, ripgrep)

## コミット

```bash
git add -A
git commit -m "feat: add devcontainer.json for base image definition

- Use javascript-node:22 as base
- Add features: git, github-cli, copilot-cli, playwright, tmux, ripgrep

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```
