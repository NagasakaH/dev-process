# Task 08: cplt ラッパースクリプト

## タスク情報

| 項目 | 内容 |
|------|------|
| ID | 08 |
| タスク名 | cplt Copilot CLI ラッパースクリプト |
| 前提タスク | なし |
| 並列実行 | P3-A (07, 09 と並列可) |
| 見積時間 | 10分 |

## 作業環境

- **worktree**: `/tmp/viewer-container-local-08/`
- **ブランチ**: `task/08-cplt-wrapper`
- **サブモジュール**: `submodules/copilot-session-viewer/`

## 前提条件

- なし（独立タスク）

## 作業内容

### 目的

Copilot CLI ラッパースクリプト `cplt` を作成する。dev-process 版をベースに、tmux ペイン自動分割やウィンドウリネーム機能を提供する。

### 設計参照

- `docs/copilot-session-viewer/design/02_interface-api-design.md` — セクション 2.2 (cplt)
- `docs/copilot-session-viewer/design/01_implementation-approach.md` — セクション 5.2 (dev-process パターン流用)

### 実装ステップ

1. **dev-process の `cplt` スクリプトを参照して `scripts/cplt` を作成**

   ```bash
   #!/bin/bash
   # cplt — Copilot CLI wrapper with tmux integration
   #
   # Options:
   #   -r            Resume session (--resume)
   #   -n, --no-split  Suppress tmux pane split
   #   --debug       Enable debug logging
   #
   # Behavior:
   #   - Auto-split tmux pane if only 1 pane exists (40/60 ratio)
   #   - Rename tmux window to "copilot" during execution
   #   - Default: copilot --allow-all --agent general-purpose

   set -euo pipefail

   RESUME=""
   NO_SPLIT=""
   DEBUG=""
   EXTRA_ARGS=()

   while [[ $# -gt 0 ]]; do
     case "$1" in
       -r|--resume) RESUME="--resume"; shift ;;
       -n|--no-split) NO_SPLIT=1; shift ;;
       --debug) DEBUG=1; shift ;;
       *) EXTRA_ARGS+=("$1"); shift ;;
     esac
   done

   # Auto-split tmux pane if in tmux and only 1 pane
   if [ -n "${TMUX:-}" ] && [ -z "$NO_SPLIT" ]; then
     PANE_COUNT=$(tmux list-panes | wc -l)
     if [ "$PANE_COUNT" -eq 1 ]; then
       tmux split-window -h -l 40%
       tmux select-pane -L
     fi
   fi

   # Rename window
   if [ -n "${TMUX:-}" ]; then
     tmux rename-window "copilot"
   fi

   # Build command
   CMD=(copilot --allow-all --agent general-purpose)
   [ -n "$RESUME" ] && CMD+=("$RESUME")
   [ -n "$DEBUG" ] && CMD+=(--debug)
   CMD+=("${EXTRA_ARGS[@]}")

   # Execute
   "${CMD[@]}"
   ```

2. **実行権限を設定**
   ```bash
   chmod +x scripts/cplt
   ```

### 対象ファイル

| ファイル | 操作 |
|---------|------|
| `submodules/copilot-session-viewer/scripts/cplt` | 新規作成 |

## TDD アプローチ

### RED (失敗するテストを書く)

```bash
# bash -n でシンタックスチェック
bash -n scripts/cplt
echo $?  # 0 であること
```

### GREEN (最小実装)

1. `scripts/cplt` を作成
2. `chmod +x` で実行権限設定
3. `bash -n` でシンタックスチェック PASS

### REFACTOR (改善)

- ShellCheck 指摘事項の修正

## 期待される成果物

- `submodules/copilot-session-viewer/scripts/cplt`

## 完了条件

- [ ] `scripts/cplt` が存在し、実行権限がある
- [ ] `bash -n scripts/cplt` がエラーなし
- [ ] `--resume`, `--no-split`, `--debug` オプションが処理される
- [ ] tmux ペイン自動分割ロジックが含まれる

## コミット

```bash
git add -A
git commit -m "feat: add cplt Copilot CLI wrapper script

- Tmux pane auto-split (40/60 ratio)
- Support --resume, --no-split, --debug options
- Default: copilot --allow-all --agent general-purpose

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```
