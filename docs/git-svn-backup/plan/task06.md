# タスク: task06 - E2E全体検証・REFACTOR

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task06 |
| タスク名 | E2E全体検証・リファクタリング（TDD REFACTOR フェーズ） |
| 前提条件タスク | task05-01, task05-02 |
| 並列実行可否 | 不可 |
| 推定所要時間 | 15分 |
| 優先度 | 高 |

---

## 作業環境

- **作業ディレクトリ（worktree）**: /tmp/GIT-SVN-001-task06/
- **ブランチ**: GIT-SVN-001-task06
- **ターゲットリポジトリ**: submodules/git-svn-backup
- **作業ブランチ**: sync（orphan ブランチ）

---

## 前提条件

### 前提タスク成果物

| タスク | 成果物パス | 参照内容 |
|--------|------------|----------|
| task01 | `compose.yaml` | SVNサーバー起動 |
| task01 | `.sync-state.yml` | 同期状態テンプレート |
| task01 | `.gitlab-ci-local-variables.yml.example` | ローカルCI変数テンプレート |
| task01 | `.gitignore` | 除外設定 |
| task02 | `docs/comparison-method-a-vs-b.md` | 方式比較ドキュメント |
| task03 | `e2e-test.sh` | E2Eテストスクリプト |
| task04 | `sync-to-svn.sh` | 同期スクリプト |
| task05-01 | `.gitlab-ci.yml` | CI構成 |
| task05-02 | `README.md` | 使用方法ドキュメント |

### 確認事項

- [ ] 全タスク（task01〜task05-02）が完了していること
- [ ] 全タスクのコミットが cherry-pick 済みであること
- [ ] 全ファイルが sync ブランチ上に存在すること

---

## 作業内容

### 目的

TDD の REFACTOR フェーズとして、全成果物が統合された状態で E2E テストを実行し、全 acceptance_criteria を検証する。品質改善が必要な箇所をリファクタリングする。

### 設計参照

- [design/05_test-plan.md](../design/05_test-plan.md) - テスト計画全体
- [design/06_side-effect-verification.md](../design/06_side-effect-verification.md) - 弊害検証

### 実装ステップ

1. 全ファイル存在チェック
2. compose.yaml で SVN サーバー起動
3. e2e-test.sh 実行（全テスト通過確認）
4. gitlab-ci-local での e2e-test ジョブ実行（利用可能な場合）
5. acceptance_criteria の全項目チェック
6. コード品質レビュー（リファクタリング対象の特定）
7. リファクタリング実施（必要な場合）
8. リファクタリング後の再テスト
9. 最終確認・クリーンアップ

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `sync-to-svn.sh` | 修正（必要な場合） | リファクタリング |
| `e2e-test.sh` | 修正（必要な場合） | リファクタリング |

---

## テスト方針（TDD: RED-GREEN-REFACTOR）

### REFACTOR: コード改善

**目的**: テストが通る状態を維持しながらコードを改善

**改善ポイント**:

- [ ] 重複コードの排除（sync-to-svn.sh, e2e-test.sh 間の共通関数）
- [ ] 可読性の向上（コメント、関数の分割）
- [ ] エラーハンドリングの強化（エッジケース対応）
- [ ] ログ出力の改善（情報量、フォーマット統一）
- [ ] 不要な一時ファイルのクリーンアップ

**確認コマンド**:

```bash
cd /tmp/GIT-SVN-001-task06/

# 1. 全ファイル存在チェック
for f in compose.yaml .sync-state.yml .gitlab-ci-local-variables.yml.example \
         .gitignore .gitlab-ci.yml sync-to-svn.sh e2e-test.sh README.md \
         docs/comparison-method-a-vs-b.md; do
  test -f "$f" && echo "OK: $f" || echo "MISSING: $f"
done

# 2. E2Eテスト実行
docker compose up -d && sleep 3
./e2e-test.sh
docker compose down -v

# 3. gitlab-ci-local での実行（利用可能な場合）
docker compose up -d && sleep 3
gitlab-ci-local e2e-test --network host \
  --variable SVN_URL=svn://localhost:3690/repos \
  --variable SVN_USERNAME=svnuser \
  --variable SVN_PASSWORD=svnpass
docker compose down -v
```

---

## acceptance_criteria チェックリスト

| # | acceptance_criteria | 検証方法 | 結果 |
|---|---------------------|----------|------|
| 1 | compose.yamlでSVNサーバーが起動し、svnコマンドでアクセスできる | E2E-1 テスト結果 | ⬜ |
| 2 | 同期スクリプトがGitのmainブランチの内容をSVNに正しく反映する | E2E-2, E2E-3 テスト結果 | ⬜ |
| 3 | マージコミットを含む履歴が適切に変換されてSVNに記録される | E2E-3 テスト結果 | ⬜ |
| 4 | 増分同期が正しく動作する（前回同期以降の変更のみ反映） | E2E-4 テスト結果 | ⬜ |
| 5 | 同期スクリプトの再実行がべき等である | E2E-5 テスト結果 | ⬜ |
| 6 | syncブランチにGitLab CI構成（.gitlab-ci.yml）が定義されている | ファイル存在チェック | ⬜ |
| 7 | gitlab-ci-localでE2Eテストが実行できる | gitlab-ci-local 実行結果 | ⬜ |
| 8 | 2つの同期方式のメリット・デメリット比較ドキュメントが存在する | ファイル存在チェック | ⬜ |

---

## 成果物

### 期待される出力

| 成果物 | パス | 説明 |
|--------|------|------|
| リファクタリング済みコード | `sync-to-svn.sh`, `e2e-test.sh` | 品質改善されたスクリプト（変更がある場合） |

---

## 完了条件

### 機能的条件

- [ ] 全ファイルが sync ブランチ上に存在する
- [ ] E2Eテスト（e2e-test.sh）が全テスト PASS する
- [ ] gitlab-ci-local での e2e-test ジョブが成功する（利用可能な場合）
- [ ] 全 acceptance_criteria が充足されている

### 品質条件

- [ ] sync-to-svn.sh のコードが可読性高い状態である
- [ ] e2e-test.sh のテストケースが独立して実行可能
- [ ] 不要なデバッグ出力が含まれていない
- [ ] エラーハンドリングが適切

---

## コミット

```bash
cd /tmp/GIT-SVN-001-task06/

# リファクタリングによる変更がある場合のみコミット
git add -A
git diff --staged --quiet || git commit -m "task06: E2E全体検証・リファクタリング

- 全E2Eテスト PASS 確認
- acceptance_criteria 全項目充足確認
- コード品質改善（リファクタリング）"
```

---

## 注意事項

- **全タスクの統合確認**: cherry-pick の順序ミスによるファイル欠落がないことを確認
- **リファクタリング後の再テスト**: コード変更後は必ず全E2Eテストを再実行
- **gitlab-ci-local**: 環境にインストールされていない場合はスキップ可（直接実行テストで代替）
- **クリーンアップ**: docker compose down -v で SVN データを確実に削除
