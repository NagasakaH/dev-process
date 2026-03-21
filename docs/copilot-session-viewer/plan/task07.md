# Task 07: start-viewer.sh エントリポイントスクリプト

## タスク情報

| 項目 | 内容 |
|------|------|
| ID | 07 |
| タスク名 | start-viewer.sh エントリポイントスクリプト |
| 前提タスク | なし |
| 並列実行 | P3-A (08, 09 と並列可) |
| 見積時間 | 20分 |

## 作業環境

- **worktree**: `/tmp/viewer-container-local-07/`
- **ブランチ**: `task/07-start-viewer-sh`
- **サブモジュール**: `submodules/copilot-session-viewer/`

## 前提条件

- なし（独立タスク）

## 作業内容

### 目的

コンテナエントリポイントスクリプト `start-viewer.sh` を作成する。tini (PID 1) から呼び出され、tmux セッション（3ウィンドウ: viewer/copilot/bash）を起動し、Next.js standalone サーバーを viewer ウィンドウで実行する。

### 設計参照

- `docs/copilot-session-viewer/design/02_interface-api-design.md` — セクション 2.1 (start-viewer.sh)
- `docs/copilot-session-viewer/design/04_process-flow-design.md` — セクション 2 (start-viewer.sh 詳細フロー)
- `docs/copilot-session-viewer/design/01_implementation-approach.md` — セクション 5.2 (dev-process パターン流用)

### 実装ステップ

1. **`scripts/start-viewer.sh` を作成**

   ```bash
   #!/bin/bash
   set -euo pipefail

   # === 環境変数デフォルト ===
   PROJECT_NAME="${PROJECT_NAME:-viewer}"
   NODE_ENV="${NODE_ENV:-production}"
   PORT="${PORT:-3000}"
   HOSTNAME="${HOSTNAME:-0.0.0.0}"

   # === UID/GID 同期 (root で実行された場合) ===
   if [ "$(id -u)" = "0" ]; then
     # usermod/groupmod で UID/GID を同期
     if [ -n "${LOCAL_UID:-}" ] && [ "$(id -u node)" != "$LOCAL_UID" ]; then
       usermod -u "$LOCAL_UID" node 2>/dev/null || true
     fi
     if [ -n "${LOCAL_GID:-}" ] && [ "$(id -g node)" != "$LOCAL_GID" ]; then
       groupmod -g "$LOCAL_GID" node 2>/dev/null || true
     fi
     # node ユーザーで再実行
     exec su -l node -c "$0"
   fi

   # === tmux セッション作成 ===
   if tmux has-session -t "$PROJECT_NAME" 2>/dev/null; then
     echo "tmux session '$PROJECT_NAME' already exists, reusing."
   else
     # Window 0: viewer (Next.js standalone server)
     tmux new-session -d -s "$PROJECT_NAME" -n viewer
     tmux send-keys -t "${PROJECT_NAME}:viewer" \
       "HOSTNAME=${HOSTNAME} PORT=${PORT} cd /app && node server.js" Enter

     # Window 1: copilot (interactive shell for Copilot CLI)
     tmux new-window -t "$PROJECT_NAME" -n copilot

     # Window 2: bash (general purpose shell)
     tmux new-window -t "$PROJECT_NAME" -n bash

     # Focus on viewer window
     tmux select-window -t "${PROJECT_NAME}:viewer"
   fi

   echo "tmux session '$PROJECT_NAME' started with 3 windows."

   # === Keep-alive loop ===
   while true; do
     wait -n 2>/dev/null || true
     sleep 60
   done
   ```

2. **実行権限を設定**
   ```bash
   chmod +x scripts/start-viewer.sh
   ```

3. **ShellCheck (可能であれば) でリント**

### 対象ファイル

| ファイル | 操作 |
|---------|------|
| `submodules/copilot-session-viewer/scripts/start-viewer.sh` | 新規作成 |

## TDD アプローチ

### RED (失敗するテストを書く)

シェルスクリプトの単体テストは直接 Vitest で行えないため、以下で検証:

```bash
# bash -n でシンタックスチェック
bash -n scripts/start-viewer.sh
echo $?  # 0 であること

# shellcheck (利用可能な場合)
shellcheck scripts/start-viewer.sh
```

### GREEN (最小実装)

1. `scripts/start-viewer.sh` を作成
2. `chmod +x` で実行権限設定
3. `bash -n` でシンタックスチェック PASS

### REFACTOR (改善)

- ShellCheck 指摘事項の修正
- エラーハンドリングの改善 (tmux 未インストール時の明確なエラーメッセージ)

## 期待される成果物

- `submodules/copilot-session-viewer/scripts/start-viewer.sh`

## 完了条件

- [ ] `scripts/start-viewer.sh` が存在し、実行権限がある
- [ ] `bash -n scripts/start-viewer.sh` がエラーなし (構文チェック)
- [ ] tmux セッション名、ウィンドウ構成 (viewer/copilot/bash) が設計通り
- [ ] キープアライブループが含まれる
- [ ] UID/GID 同期ロジックが含まれる

## コミット

```bash
git add -A
git commit -m "feat: add start-viewer.sh container entrypoint script

- Create tmux session with 3 windows (viewer/copilot/bash)
- Start Next.js standalone server in viewer window
- Add UID/GID sync for root execution
- Add keep-alive loop for container persistence

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```
