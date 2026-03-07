# インターフェース/API設計

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | GIT-SVN-001 |
| タスク名 | Git→SVN一方向同期の検証環境構築 |
| 作成日 | 2026-03-07 |

本プロジェクトはWeb APIではなく、CLIスクリプト（Bash）を中心とした設計。
同期スクリプト・E2Eテストスクリプトのインターフェースを定義する。

---

## 1. sync-to-svn.sh（メイン同期スクリプト）

### 1.1 コマンドインターフェース

```bash
# 基本実行（環境変数から設定を取得）
./sync-to-svn.sh

# 同期モード指定（将来拡張: 現在は merge-unit 固定）
./sync-to-svn.sh [--mode <merge-unit|daily-batch>]

# ドライラン（SVNへの書き込みを行わない）
./sync-to-svn.sh [--dry-run]

# 初回同期（全履歴を強制同期）
./sync-to-svn.sh [--full-sync]

# ヘルプ表示
./sync-to-svn.sh --help
```

### 1.2 引数定義

| 引数 | 短縮 | 必須 | デフォルト | 説明 |
|------|------|------|------------|------|
| `--mode` | `-m` | No | `merge-unit` | 同期方式（`merge-unit` / `daily-batch`）。現在は `merge-unit` 固定。将来拡張用 |
| `--dry-run` | `-n` | No | false | 実際のdcommit/pushを行わない |
| `--full-sync` | `-f` | No | false | .sync-state.yml を無視して全履歴を同期 |
| `--help` | `-h` | No | - | ヘルプ表示 |

### 1.3 環境変数

| 変数名 | 必須 | デフォルト | 説明 |
|--------|------|------------|------|
| `SVN_URL` | Yes | - | SVN リポジトリURL（例: `svn://localhost:3690/repos`） |
| `SVN_USERNAME` | Yes | - | SVN 認証ユーザー名 |
| `SVN_PASSWORD` | Yes | - | SVN 認証パスワード |
| `GIT_REMOTE` | No | `origin` | Git リモート名 |
| `GIT_MAIN_BRANCH` | No | `main` | 同期元ブランチ名 |
| `SYNC_STATE_FILE` | No | `.sync-state.yml` | 同期状態ファイルパス |

### 1.4 終了コード

| コード | 意味 | 説明 |
|--------|------|------|
| 0 | 成功 | 同期完了（変更なしの場合も0） |
| 1 | 一般エラー | 予期しないエラー |
| 2 | 環境変数未設定 | 必須環境変数が不足 |
| 3 | SVN接続エラー | SVNサーバーに接続できない |
| 4 | Git操作エラー | ブランチ操作・コミット失敗 |
| 5 | dcommitエラー | git svn dcommit 失敗 |

### 1.5 ログ出力

```bash
# ログフォーマット
# [TIMESTAMP] [LEVEL] MESSAGE
# 例:
# [2024-01-15T10:30:00Z] [INFO] Starting sync (mode: merge-unit)
# [2024-01-15T10:30:01Z] [INFO] Last synced commit: abc123
# [2024-01-15T10:30:02Z] [INFO] Found 3 new commits to sync
# [2024-01-15T10:30:05Z] [ERROR] dcommit failed: SVN connection refused

log_info()  { echo "[$(date -Iseconds)] [INFO] $*"; }
log_warn()  { echo "[$(date -Iseconds)] [WARN] $*" >&2; }
log_error() { echo "[$(date -Iseconds)] [ERROR] $*" >&2; }
```

---

## 2. e2e-test.sh（E2Eテストスクリプト）

### 2.1 コマンドインターフェース

```bash
# 全テスト実行
./e2e-test.sh

# 特定テスト実行
./e2e-test.sh [--test <test-name>]

# SVNサーバーの起動・停止を含む
./e2e-test.sh [--with-server]
```

### 2.2 引数定義

| 引数 | 短縮 | 必須 | デフォルト | 説明 |
|------|------|------|------------|------|
| `--test` | `-t` | No | 全テスト | 特定テストのみ実行 |
| `--with-server` | `-s` | No | false | compose up/down を自動実行 |
| `--help` | `-h` | No | - | ヘルプ表示 |

### 2.3 テスト関数

| 関数名 | テスト内容 |
|--------|------------|
| `test_svn_server_access` | SVNサーバーへの接続確認 |
| `test_initial_sync` | 初回同期の正常動作 |
| `test_incremental_sync` | 増分同期の正常動作 |
| `test_merge_commit_sync` | マージコミットの変換と同期 |
| `test_idempotency` | 同期の再実行がべき等である |
| `test_ci_rebuild` | 環境再構築後の増分同期 |

### 2.4 終了コード

| コード | 意味 |
|--------|------|
| 0 | 全テスト合格 |
| 1 | テスト失敗あり |

---

## 3. 内部関数シグネチャ（sync-to-svn.sh）

### 3.1 初期化・検証関数

```bash
# 環境変数の存在チェック。不足時は exit 2
validate_env()

# コマンド（git, git-svn, svn, yq）の存在チェック
check_dependencies()

# SVN サーバーへの接続テスト。失敗時は exit 3
test_svn_connection()
```

### 3.2 Git 操作関数

```bash
# 全ブランチ情報を取得（main, svn）
# GIT_DEPTH=0 で全履歴取得を保証
fetch_branches()

# svn ブランチが存在しない場合は orphan ブランチとして作成
ensure_svn_branch()

# svn ブランチ上で git svn init + fetch を実行
# git-svn-id から .rev_map を自動再構築
# 初期化済み判定: git config --get svn-remote.svn.url で確認し、未設定時のみ init を実行
# SVN認証キャッシュの事前投入（~/.subversion/auth/に保存）: svn info --username $SVN_USERNAME --password $SVN_PASSWORD --non-interactive $SVN_URL
setup_git_svn()
```

### 3.3 同期コア関数

```bash
# .sync-state.yml から最終同期コミットSHA を読み取り
# ブランチ切り替えなしに sync ブランチから読み取る: git show sync:.sync-state.yml
# 初回（ファイルなし）の場合は空文字を返す
# 戻り値: last_synced_commit（stdout）
get_last_synced_commit()

# 方式A: --first-parent でコミット一覧を取得し、各コミットをリニア化してsvnブランチにコミット
# 引数: last_synced_commit（空の場合は全履歴）
# 戻り値: 処理したコミット数（stdout）
# 注意: 内部のgitコマンド出力は >/dev/null 2>&1 または >&2 にリダイレクトし、stdout汚染を防ぐ
sync_merge_unit() { local last_synced="$1"; }

# 方式B: 日付グループ化し、各日の最終コミットの状態をsvnブランチにコミット
# 引数: last_synced_commit（空の場合は全履歴）
# 戻り値: 処理したコミット数（stdout）
sync_daily_batch() { local last_synced="$1"; }

# git svn dcommit を実行
# --username $SVN_USERNAME フラグを使用してSVN認証を行う
# --dry-run の場合はスキップ
# 失敗時は exit 5
# 戻り値: 最新SVNリビジョン番号（stdout）
#   取得方法: svn info $SVN_URL | grep 'Revision:' | awk '{print $2}'
execute_dcommit()

# svn ブランチを force push
# --dry-run の場合はスキップ
push_svn_branch()
```

### 3.4 状態管理関数

```bash
# .sync-state.yml を更新
# 引数: git_commit, svn_revision, commits_synced
update_sync_state() {
  local git_commit="$1"
  local svn_revision="$2"
  local commits_synced="$3"
}

# sync ブランチに状態ファイルをコミット＆push
commit_sync_state()
```

### 3.5 メインフロー

```bash
main() {
  parse_args "$@"
  validate_env
  check_dependencies
  test_svn_connection

  fetch_branches
  ensure_svn_branch

  # svn ブランチに切り替え
  git checkout svn
  setup_git_svn

  # sync ブランチから状態読み取り（ブランチ切り替えなし）
  local last_synced
  last_synced=$(get_last_synced_commit)

  # dcommit部分失敗時のリカバリ: SVNと同期済みの状態にリセット
  git reset --hard refs/remotes/origin/trunk

  # 同期実行（モードに応じて分岐）
  local synced_count
  case "$MODE" in
    merge-unit)  synced_count=$(sync_merge_unit "$last_synced") ;;
    daily-batch) synced_count=$(sync_daily_batch "$last_synced") ;;
  esac

  if [ "$synced_count" -eq 0 ]; then
    log_info "No new commits to sync"
    exit 0
  fi

  local svn_revision
  svn_revision=$(execute_dcommit)
  push_svn_branch

  # 状態更新（sync ブランチに切り替えて更新）
  git checkout sync
  update_sync_state "$(git rev-parse origin/main)" "$svn_revision" "$synced_count"
  commit_sync_state

  log_info "Sync completed: ${synced_count} commits synced"
}
```

---

## 4. compose.yaml インターフェース

### 4.1 サービス定義

```yaml
# SVN サーバーの操作
docker compose up -d        # SVNサーバー起動
docker compose down          # 停止
docker compose down -v       # 停止 + ボリューム削除
```

### 4.2 SVN リポジトリ初期化

```bash
# リポジトリ作成（コンテナ起動後に1回実行）
docker compose exec svn-server svnadmin create /var/opt/svn/repos

# 認証設定
docker compose exec svn-server sh -c 'cat > /var/opt/svn/repos/conf/svnserve.conf << EOF
[general]
anon-access = none
auth-access = write
password-db = passwd
realm = Git-SVN Sync Repository
EOF'

docker compose exec svn-server sh -c 'cat > /var/opt/svn/repos/conf/passwd << EOF
[users]
svnuser = svnpass
EOF'
```

---

## 5. .gitlab-ci.yml インターフェース

### 5.1 ジョブ定義

| ジョブ名 | ステージ | トリガー | 説明 |
|----------|----------|----------|------|
| `sync-to-svn` | sync | schedule / web | 本番同期ジョブ |
| `e2e-test` | test | merge_request / web | E2Eテストジョブ |

### 5.2 CI/CD Variables

| 変数名 | 種別 | Protected | Masked | 説明 |
|--------|------|-----------|--------|------|
| `SVN_URL` | Variable | No | No | SVN リポジトリURL |
| `SVN_USERNAME` | Variable | No | No | SVN ユーザー名 |
| `SVN_PASSWORD` | Variable | No | Yes | SVN パスワード |

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-03-07 | 1.0 | 初版作成 | Copilot |
| 2026-03-07 | 1.1 | 設計レビュー指摘対応（RD-001,002,004,006,007,009,010） | Copilot |
| 2026-03-07 | 1.2 | 設計レビュー Round 2 指摘対応（RD-014, RD-015） | Copilot |
