# タスク: task03 - E2Eテストスクリプト作成（TDD RED）

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task03 |
| タスク名 | E2Eテストスクリプト作成（e2e-test.sh）- TDD RED フェーズ |
| 前提条件タスク | task01 |
| 並列実行可否 | 不可 |
| 推定所要時間 | 20〜30分 |
| 優先度 | 高 |

---

## 作業環境

- **作業ディレクトリ（worktree）**: /tmp/GIT-SVN-001-task03/
- **ブランチ**: GIT-SVN-001-task03
- **ターゲットリポジトリ**: submodules/git-svn-backup
- **作業ブランチ**: sync（orphan ブランチ）
- **重要**: sync ブランチ上で作業すること

---

## 前提条件

### 前提タスク成果物

| タスク | 成果物パス | 参照内容 |
|--------|------------|----------|
| task01 | `compose.yaml` | SVNサーバー定義（docker compose up/down） |
| task01 | `.sync-state.yml` | 初期テンプレート（検証用） |

### 確認事項

- [ ] task01 が完了していること
- [ ] task01 の成果物（compose.yaml 等）が存在すること
- [ ] task01 のコミットが cherry-pick 済みであること

---

## 作業内容

### 目的

TDD の RED フェーズとして、sync-to-svn.sh が実装される前に失敗するE2Eテストスクリプトを作成する。テスト計画（05_test-plan.md）に基づく全10テストケースを実装する。

### 設計参照

- [design/02_interface-api-design.md](../design/02_interface-api-design.md) - e2e-test.sh インターフェース定義
- [design/05_test-plan.md](../design/05_test-plan.md) - テストケース一覧・テストデータ設計・検証方法

### 実装ステップ

1. e2e-test.sh のスケルトン作成（引数パース、ヘルプ表示）
2. テストヘルパー関数の実装（assert_equal, assert_contains, run_test, print_summary）
3. ログ関数の実装（log_info, log_error）
4. SVNリポジトリ初期化関数の実装（setup_svn_repo）
5. テスト用Gitリポジトリ構築関数の実装（setup_test_repo）
6. テストケース E2E-1〜E2E-10 の実装
   - **推奨実装順序**: E2E-1 → E2E-10 → E2E-2〜E2E-9
   - 理由: E2E-1（接続確認）を最初に、E2E-10（trunk自動作成）を次に実装することで、他テストの前提となるインフラ検証を先に固める
7. 環境クリーンアップ関数の実装
8. テスト実行確認（sync-to-svn.sh が存在しないため全テスト失敗を確認 = RED）

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `e2e-test.sh` | 新規作成 | E2Eテストスクリプト（全テストケース） |

---

## テスト方針（TDD: RED-GREEN-REFACTOR）

### RED: 失敗するテストケース

**目的**: sync-to-svn.sh が未実装の状態でテストが失敗することを確認

**テストファイル**: `e2e-test.sh`

**テストケース一覧**（設計書 05_test-plan.md に基づく）:

```bash
# E2E-1: SVNサーバー接続確認
test_svn_server_access() {
  # compose up → svn info で接続確認
  # 期待: SVNリポジトリ情報が取得できる
}

# E2E-2: 初回同期（通常コミットのみ）
test_initial_sync() {
  # テストGitリポ作成（通常コミット3件）→ sync-to-svn.sh 実行
  # 期待: SVN trunk に3件のリビジョン
}

# E2E-3: 初回同期（マージコミット含む）
test_merge_commit_sync() {
  # テストGitリポ作成（通常2件+マージ1件）→ sync-to-svn.sh 実行
  # 期待: SVN trunk に3件のリビジョン（マージは1コミット）
}

# E2E-4: 増分同期
test_incremental_sync() {
  # E2E-2完了後、2件追加 → 再実行
  # 期待: 追加の2件のみSVNに反映
}

# E2E-5: べき等性テスト
test_idempotency() {
  # 変更なしで再実行
  # 期待: "No new commits to sync" で exit 0
}

# E2E-6: 環境再構築後の増分同期
test_ci_rebuild() {
  # ローカルリポ削除 → 再clone → 1件追加 → 同期
  # 期待: git-svn-id から .rev_map 再構築、増分同期正常動作
}

# E2E-7: ファイル削除の同期
test_file_delete_sync() {
  # main でファイル削除 → 同期
  # 期待: SVN trunk からもファイル削除
}

# E2E-8: ファイルリネームの同期
test_file_rename_sync() {
  # main でリネーム → 同期
  # 期待: SVN trunk で旧ファイル削除・新ファイル追加
}

# E2E-9: .sync-state.yml 整合性
test_sync_state_integrity() {
  # 同期後の .sync-state.yml を検証
  # 期待: version, last_synced_commit, svn_revision が正しい
}

# E2E-10: SVN trunk 自動作成検証
test_svn_trunk_auto_create() {
  # git svn init 後に trunk 存在確認
  # 期待: trunk が自動初期化される
}
```

**確認コマンド**:

```bash
cd /tmp/GIT-SVN-001-task03/
docker compose up -d && sleep 3
./e2e-test.sh
# 結果: FAIL（sync-to-svn.sh が未実装のため）
docker compose down -v
```

### GREEN: （次タスク task04 で実施）

sync-to-svn.sh を実装してテストを通過させる。

### REFACTOR: （task06 で実施）

全体統合後にリファクタリング。

---

## 成果物

### 期待される出力

| 成果物 | パス | 説明 |
|--------|------|------|
| E2Eテストスクリプト | `e2e-test.sh` | 全10テストケースを含むテストスクリプト |

---

## 完了条件

### 機能的条件

- [ ] e2e-test.sh が実行可能（chmod +x）である
- [ ] 引数パース（--test, --with-server, --help）が動作する
- [ ] テストヘルパー関数（assert_equal, assert_contains, run_test）が実装されている
- [ ] SVNリポジトリ初期化関数（setup_svn_repo）が実装されている
- [ ] テスト用Gitリポジトリ構築関数が実装されている
- [ ] E2E-1〜E2E-10 の全テストケースが実装されている
- [ ] テスト結果サマリーが出力される
- [ ] E2E-1（SVNサーバー接続確認）は PASS する（sync-to-svn.sh 不要）
- [ ] E2E-2 以降は sync-to-svn.sh 未実装のため FAIL する（RED 状態）

### 品質条件

- [ ] テストケースが設計書（05_test-plan.md）と整合している
- [ ] 各テスト関数が独立して実行可能（--test オプション）
- [ ] テスト間のクリーンアップが適切に行われている
- [ ] ログ出力が設計書（02_interface-api-design.md）のフォーマットに準拠

---

## コミット

```bash
cd /tmp/GIT-SVN-001-task03/
git add e2e-test.sh
git commit -m "task03: E2Eテストスクリプト作成（TDD RED）

- 全10テストケース（E2E-1〜E2E-10）を実装
- テストヘルパー関数（assert_equal, assert_contains, run_test）
- SVNリポジトリ初期化・テスト用Gitリポジトリ構築関数
- sync-to-svn.sh 未実装のためE2E-2以降はFAIL（RED状態）"
```

---

## 注意事項

- **TDD RED フェーズ**: テストが失敗する状態が正常。sync-to-svn.sh の実装は次タスク
- テスト用Gitリポジトリは一時ディレクトリに作成し、各テスト後にクリーンアップする
- SVNリポジトリ初期化（svnadmin create, 認証設定, trunk作成）は e2e-test.sh 内で行う
- 各テストケースは独立して実行可能にする（--test オプション対応）
- テスト関数名は設計書の命名規則に従う
- SVN認証情報はハードコードせず環境変数から取得する（テスト用デフォルト値は可）
