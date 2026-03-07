# テスト計画

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | GIT-SVN-001 |
| タスク名 | Git→SVN一方向同期の検証環境構築 |
| 作成日 | 2026-03-07 |

---

## 1. テスト方針

### 1.1 テストスコープ

brainstorming で決定した通り、E2Eテストのみ実施。単体テスト・結合テストは対象外。

| 範囲 | 対象 | 除外 |
|------|------|------|
| E2Eテスト | 同期スクリプト全体の動作、CI再現テスト | - |
| 単体テスト | - | スコープ外（brainstorming で除外決定） |
| 結合テスト | - | スコープ外（brainstorming で除外決定） |

### 1.2 テスト環境

| 項目 | 要件 | 備考 |
|------|------|------|
| Docker Compose | SVNサーバーコンテナ起動 | garethflowers/svn-server |
| git-svn | Git↔SVNブリッジ | apt install git-svn |
| svn | SVNクライアント | apt install subversion |
| gitlab-ci-local | ローカルCI実行 | npm install -g gitlab-ci-local |
| bash | テストスクリプト実行 | 4.0+ |

### 1.3 テスト実行方法

```bash
# 方法1: 直接実行
docker compose up -d
sleep 3
# SVNリポジトリ初期化
docker compose exec svn-server svnadmin create /var/opt/svn/repos
docker compose exec svn-server sh -c '...'  # 認証設定
./e2e-test.sh --with-server
docker compose down -v

# 方法2: gitlab-ci-local で実行
docker compose up -d
gitlab-ci-local e2e-test --network host \
  --variable SVN_URL=svn://localhost:3690/repos \
  --variable SVN_USERNAME=svnuser \
  --variable SVN_PASSWORD=svnpass
docker compose down -v
```

---

## 2. E2Eテストケース

### 2.1 テストケース一覧

| No | テストシナリオ | 手順 | 期待結果 | 優先度 |
|----|----------------|------|----------|--------|
| E2E-1 | SVNサーバー接続確認 | compose up → svn info | SVNリポジトリ情報が取得できる | 高 |
| E2E-2 | 初回同期（通常コミットのみ） | テストGitリポジトリ作成（通常コミット3件）→ sync-to-svn.sh 実行 | SVN trunk に3件のリビジョンが作成される。ファイル内容が一致 | 高 |
| E2E-3 | 初回同期（マージコミット含む） | テストGitリポジトリ作成（通常2件+マージ1件）→ sync-to-svn.sh 実行 | SVN trunk に3件のリビジョン。マージ結果がSVNに正しく反映 | 高 |
| E2E-4 | 増分同期 | E2E-2完了後、main に2件追加コミット → sync-to-svn.sh 再実行 | 追加の2件のみがSVNに反映。.sync-state.yml が更新される | 高 |
| E2E-5 | べき等性テスト | E2E-4完了後、sync-to-svn.sh を変更なしで再実行 | 「No new commits to sync」でexit 0。SVN側に変更なし | 高 |
| E2E-6 | 環境再構築後の増分同期 | E2E-4完了後、ローカルリポジトリを削除→再clone→main に1件追加→同期 | git-svn-id から .rev_map 再構築。増分同期が正常動作 | 高 |
| E2E-7 | ファイル削除の同期 | main でファイル削除→同期 | SVN trunk からもファイルが削除される | 中 |
| E2E-8 | ファイルリネームの同期 | main でファイルリネーム→同期 | SVN trunk でも旧ファイル削除・新ファイル追加 | 中 |
| E2E-9 | .sync-state.yml 整合性 | 各テスト後に .sync-state.yml を検証 | version, last_synced_commit, svn_revision が正しい値 | 中 |

### 2.2 acceptance_criteria との対応

| acceptance_criteria | テストNo | テスト種別 |
|---------------------|----------|------------|
| compose.yamlでSVNサーバーが起動し、svnコマンドでアクセスできる | E2E-1 | E2E |
| 同期スクリプトがGitのmainブランチの内容をSVNに正しく反映する | E2E-2, E2E-3 | E2E |
| マージコミットを含む履歴が適切に変換されてSVNに記録される | E2E-3 | E2E |
| 増分同期が正しく動作する（前回同期以降の変更のみ反映） | E2E-4 | E2E |
| 同期スクリプトの再実行がべき等である | E2E-5 | E2E |
| syncブランチにGitLab CI構成（.gitlab-ci.yml）が定義されている | 目視確認 | ファイル存在チェック |
| gitlab-ci-localでE2Eテストが実行できる | 全テスト | E2E |
| 2つの同期方式のメリット・デメリット比較ドキュメントが存在する | 目視確認 | ドキュメントチェック |

---

## 3. テストデータ設計

### 3.1 テスト用Gitリポジトリ構築

E2Eテストでは、テスト用のGitリポジトリを動的に構築する。

```bash
setup_test_repo() {
  local repo_dir="$1"
  mkdir -p "$repo_dir" && cd "$repo_dir"
  git init && git checkout -b main

  # 通常コミット1
  echo "initial content" > file1.txt
  git add . && git commit -m "Initial commit"

  # 通常コミット2
  echo "second content" > file2.txt
  git add . && git commit -m "Add file2"

  # マージコミット（feature ブランチ作成→マージ）
  git checkout -b feature/test
  echo "feature content" > feature.txt
  git add . && git commit -m "Add feature"
  echo "feature update" >> feature.txt
  git add . && git commit -m "Update feature"

  git checkout main
  git merge --no-ff feature/test -m "Merge branch 'feature/test'"

  # 通常コミット3（マージ後）
  echo "after merge" > file3.txt
  git add . && git commit -m "Add file3 after merge"
}
```

### 3.2 テストデータ一覧

| データ名 | 用途 | 内容 |
|----------|------|------|
| test_repo_basic | 基本テスト | 通常コミット3件 |
| test_repo_merge | マージテスト | 通常2件 + マージ1件 + 通常1件 |
| test_repo_delete | 削除テスト | ファイル追加→削除 |
| test_repo_rename | リネームテスト | ファイル追加→リネーム |

---

## 4. テスト検証方法

### 4.1 SVN側の検証

```bash
# SVN リビジョン数の確認
svn_rev=$(svn info svn://localhost:3690/repos/trunk --username svnuser --password svnpass | grep "Revision:" | awk '{print $2}')
assert_equal "$expected_rev" "$svn_rev"

# SVN のファイル一覧確認
svn_files=$(svn ls svn://localhost:3690/repos/trunk --username svnuser --password svnpass)
assert_contains "$svn_files" "file1.txt"

# SVN ファイル内容の確認
svn_content=$(svn cat svn://localhost:3690/repos/trunk/file1.txt --username svnuser --password svnpass)
assert_equal "$expected_content" "$svn_content"

# SVN コミットログの確認
svn_log=$(svn log svn://localhost:3690/repos/trunk --username svnuser --password svnpass)
```

### 4.2 テストヘルパー関数

```bash
# アサーション関数
assert_equal() {
  local expected="$1" actual="$2" msg="${3:-}"
  if [ "$expected" != "$actual" ]; then
    log_error "FAIL: ${msg:+$msg: }expected '$expected', got '$actual'"
    return 1
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" msg="${3:-}"
  if ! echo "$haystack" | grep -q "$needle"; then
    log_error "FAIL: ${msg:+$msg: }'$needle' not found"
    return 1
  fi
}

assert_exit_code() {
  local expected="$1"; shift
  "$@"
  local actual=$?
  assert_equal "$expected" "$actual" "exit code"
}

# テスト実行フレームワーク
run_test() {
  local test_name="$1"
  log_info "Running: $test_name"
  if "$test_name"; then
    log_info "PASS: $test_name"
    PASSED=$((PASSED + 1))
  else
    log_error "FAIL: $test_name"
    FAILED=$((FAILED + 1))
  fi
  TOTAL=$((TOTAL + 1))
}

# 結果サマリー
print_summary() {
  echo "================================"
  echo "Total: $TOTAL, Passed: $PASSED, Failed: $FAILED"
  echo "================================"
  [ "$FAILED" -eq 0 ] && exit 0 || exit 1
}
```

---

## 5. gitlab-ci-local でのE2Eテスト実行

### 5.1 実行手順

```bash
# 1. SVN サーバー起動
docker compose up -d
sleep 3

# 2. SVN リポジトリ初期化
docker compose exec svn-server svnadmin create /var/opt/svn/repos
docker compose exec svn-server sh -c 'cat > /var/opt/svn/repos/conf/svnserve.conf << EOF
[general]
anon-access = none
auth-access = write
password-db = passwd
EOF'
docker compose exec svn-server sh -c 'cat > /var/opt/svn/repos/conf/passwd << EOF
[users]
svnuser = svnpass
EOF'

# 3. gitlab-ci-local で実行
gitlab-ci-local e2e-test --network host

# 4. 後片付け
docker compose down -v
```

### 5.2 gitlab-ci-local 固有の考慮事項

| 項目 | GitLab Runner | gitlab-ci-local | 対応 |
|------|--------------|-----------------|------|
| services | ✅ | ❌ | Docker Compose で事前起動 |
| ネットワーク | Docker network | --network host | host で接続 |
| SVN_URL | CI/CD Variables | --variable / .yml | localhost:3690 |
| `$GITLAB_CI` | `"true"` | `"false"` | 条件分岐で判定可能 |

---

## 6. 実行計画

### 6.1 テスト実行順序

1. E2E-1: SVNサーバー接続確認（前提条件）
2. E2E-2: 初回同期（基本）
3. E2E-3: 初回同期（マージコミット）
4. E2E-4: 増分同期
5. E2E-5: べき等性テスト
6. E2E-6: 環境再構築後の増分同期
7. E2E-7: ファイル削除の同期
8. E2E-8: ファイルリネームの同期
9. E2E-9: .sync-state.yml 整合性

### 6.2 CI/CD連携

| パイプライン | トリガー | 実行テスト |
|--------------|----------|------------|
| merge_request | MR作成・更新時 | 全E2Eテスト |
| web | 手動実行 | 全E2Eテスト |
| schedule | 定期（同期ジョブ） | 同期のみ（テストなし） |

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-03-07 | 1.0 | 初版作成 | Copilot |
