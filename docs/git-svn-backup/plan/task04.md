# タスク: task04 - 同期スクリプト実装（TDD GREEN）

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task04 |
| タスク名 | 同期スクリプト実装（sync-to-svn.sh）- TDD GREEN フェーズ |
| 前提条件タスク | task03 |
| 並列実行可否 | 不可 |
| 推定所要時間 | 20分 |
| 優先度 | 高 |

---

## 作業環境

- **作業ディレクトリ（worktree）**: /tmp/GIT-SVN-001-task04/
- **ブランチ**: GIT-SVN-001-task04
- **ターゲットリポジトリ**: submodules/git-svn-backup
- **作業ブランチ**: sync（orphan ブランチ）
- **重要**: sync ブランチ上で作業すること

---

## 前提条件

### 前提タスク成果物

| タスク | 成果物パス | 参照内容 |
|--------|------------|----------|
| task01 | `compose.yaml` | SVNサーバー起動 |
| task01 | `.sync-state.yml` | 同期状態テンプレート |
| task03 | `e2e-test.sh` | E2Eテストスクリプト（GREEN にするターゲット） |

### 確認事項

- [ ] task01, task03 が完了していること
- [ ] task01, task03 のコミットが cherry-pick 済みであること
- [ ] e2e-test.sh が存在し実行可能であること

---

## 作業内容

### 目的

TDD の GREEN フェーズとして、e2e-test.sh のテストを通過するメイン同期スクリプト sync-to-svn.sh を実装する。方式A（マージ単位コミット方式）で実装する。

### 設計参照

- [design/01_implementation-approach.md](../design/01_implementation-approach.md) - リニア化アルゴリズム（方式A）
- [design/02_interface-api-design.md](../design/02_interface-api-design.md) - CLI インターフェース・内部関数シグネチャ
- [design/03_data-structure-design.md](../design/03_data-structure-design.md) - .sync-state.yml 操作
- [design/04_process-flow-design.md](../design/04_process-flow-design.md) - メインフロー・状態遷移

### 実装ステップ

1. sync-to-svn.sh のスケルトン作成（shebang, set -euo pipefail）
2. ログ関数の実装（log_info, log_warn, log_error）
3. 引数パース関数の実装（--mode, --dry-run, --full-sync, --help）
4. 初期化・検証関数の実装
   - validate_env(): 環境変数チェック（SVN_URL, SVN_USERNAME, SVN_PASSWORD）
   - check_dependencies(): コマンド存在チェック（git, git-svn, svn, yq）
   - test_svn_connection(): SVN接続テスト
5. Git 操作関数の実装
   - fetch_branches(): ブランチ情報取得
   - ensure_svn_branch(): svn ブランチ確認/orphan作成
   - setup_git_svn(): git svn init + fetch + SVN認証キャッシュ投入
6. 同期コア関数の実装
   - get_last_synced_commit(): .sync-state.yml から最終同期コミット読み取り
   - sync_merge_unit(): 方式A リニア化ロジック
   - execute_dcommit(): git svn dcommit
   - push_svn_branch(): force push
7. 状態管理関数の実装
   - update_sync_state(): .sync-state.yml 更新（yq）
   - commit_sync_state(): sync ブランチにcommit + push
8. main() 関数の実装（メインフロー）
9. E2Eテスト実行（全テスト通過を確認 = GREEN）

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `sync-to-svn.sh` | 新規作成 | メイン同期スクリプト（方式A実装） |

---

## テスト方針（TDD: RED-GREEN-REFACTOR）

### RED: 確認（task03 で完了済み）

```bash
cd /tmp/GIT-SVN-001-task04/
docker compose up -d && sleep 3
./e2e-test.sh
# 結果: E2E-2 以降が FAIL（sync-to-svn.sh 未実装）
docker compose down -v
```

### GREEN: 最小限の実装

**実装ファイル**: `sync-to-svn.sh`

**主要な実装関数**:

```bash
#!/usr/bin/env bash
set -euo pipefail

# === ログ関数 ===
log_info()  { echo "[$(date -Iseconds)] [INFO] $*"; }
log_warn()  { echo "[$(date -Iseconds)] [WARN] $*" >&2; }
log_error() { echo "[$(date -Iseconds)] [ERROR] $*" >&2; }

# === 引数パース ===
MODE="merge-unit"
DRY_RUN=false
FULL_SYNC=false

parse_args() { ... }

# === 初期化・検証 ===
validate_env() { ... }       # exit 2 if missing
check_dependencies() { ... } # exit 1 if missing
test_svn_connection() { ... } # exit 3 if fail

# === Git 操作 ===
fetch_branches() { ... }
ensure_svn_branch() { ... }
setup_git_svn() { ... }      # git svn init + fetch + SVN認証キャッシュ

# === 同期コア ===
get_last_synced_commit() { ... }  # stdout: last_synced_commit
sync_merge_unit() { ... }         # stdout: synced_count
execute_dcommit() { ... }         # stdout: svn_revision
push_svn_branch() { ... }

# === 状態管理 ===
update_sync_state() { ... }
commit_sync_state() { ... }

# === メインフロー ===
main() {
  parse_args "$@"
  validate_env
  check_dependencies
  test_svn_connection
  fetch_branches
  ensure_svn_branch
  git checkout svn
  setup_git_svn
  local last_synced=$(get_last_synced_commit)
  git reset --hard refs/remotes/origin/trunk 2>/dev/null || true
  local synced_count
  case "$MODE" in
    merge-unit)  synced_count=$(sync_merge_unit "$last_synced") ;;
  esac
  if [ "$synced_count" -eq 0 ]; then
    log_info "No new commits to sync"
    exit 0
  fi
  local svn_revision=$(execute_dcommit)
  push_svn_branch
  git checkout sync
  update_sync_state "$(git rev-parse origin/main)" "$svn_revision" "$synced_count"
  commit_sync_state
  log_info "Sync completed: ${synced_count} commits synced"
}

main "$@"
```

**確認コマンド**:

```bash
cd /tmp/GIT-SVN-001-task04/
docker compose up -d && sleep 3
./e2e-test.sh
# 結果: 全テスト PASS（GREEN）
docker compose down -v
```

### REFACTOR: （task06 で実施）

- コード整理、エラーメッセージ改善
- 冗長なコードの排除

---

## 成果物

### 期待される出力

| 成果物 | パス | 説明 |
|--------|------|------|
| 同期スクリプト | `sync-to-svn.sh` | 方式A（マージ単位コミット方式）の同期スクリプト |

---

## 完了条件

### 機能的条件

- [ ] sync-to-svn.sh が実行可能（chmod +x）である
- [ ] 引数パース（--mode, --dry-run, --full-sync, --help）が動作する
- [ ] 環境変数チェック（SVN_URL, SVN_USERNAME, SVN_PASSWORD）が動作する
- [ ] 終了コードが設計書通り（0:成功, 2:環境変数, 3:SVN接続, 4:Git操作, 5:dcommit）
- [ ] 方式A（マージ単位コミット方式）が動作する
- [ ] 初回同期が正常に動作する（E2E-2, E2E-3）
- [ ] 増分同期が正常に動作する（E2E-4）
- [ ] べき等性が保持されている（E2E-5）
- [ ] 環境再構築後の増分同期が動作する（E2E-6）
- [ ] ファイル削除・リネームが正しく同期される（E2E-7, E2E-8）
- [ ] .sync-state.yml が正しく更新される（E2E-9）
- [ ] ログ出力が設計書のフォーマットに準拠

### 品質条件

- [ ] E2Eテスト（e2e-test.sh）が全テスト PASS すること
- [ ] set -euo pipefail でエラーハンドリングが適切であること
- [ ] 内部コマンドの stdout 汚染がないこと（>/dev/null 2>&1 or >&2）

### ドキュメント条件

- [ ] --help でコマンドの使用方法が表示されること

---

## コミット

```bash
cd /tmp/GIT-SVN-001-task04/
git add sync-to-svn.sh
git commit -m "task04: 同期スクリプト実装（TDD GREEN）

- sync-to-svn.sh: 方式A（マージ単位コミット方式）の同期スクリプト
- 引数パース、環境変数チェック、SVN接続テスト
- リニア化アルゴリズム（git checkout SHA -- . 方式）
- git svn dcommit + force push
- .sync-state.yml 状態管理
- 全E2Eテスト PASS"
```

---

## 注意事項

- **TDD GREEN フェーズ**: e2e-test.sh のテストを通過させることが目標
- 方式B（daily-batch）は実装しない（方式Aで確定済み。関数スケルトンのみ残す）
- 内部関数の stdout 汚染に注意（sync_merge_unit, execute_dcommit の戻り値が stdout）
- git コマンドの出力は `>/dev/null 2>&1` または `>&2` にリダイレクト
- GIT_AUTHOR_DATE を元コミットの日時に設定する（設計書の日時保存ポリシー）
- SVN認証キャッシュの事前投入を忘れないこと（setup_git_svn 内で実施）
- dcommit 部分失敗時のリカバリ: `git reset --hard refs/remotes/origin/trunk`
