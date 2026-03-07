# 既存パターン調査: git-svn 詳細動作・履歴リニア化手法

## 概要

本プロジェクトはコード既存パターンではなく、git-svn の詳細動作仕様と Git 履歴リニア化手法が設計の鍵となる。実験により動作を検証済み。

## git-svn コマンド詳細動作

### git svn init

SVN リポジトリへの接続情報を `.git/config` に設定する。実際のデータ取得は行わない。

```bash
# 基本形（stdlayout = trunk/branches/tags 構成）
git svn init <SVN_URL> --stdlayout

# trunk のみ指定
git svn init <SVN_URL> -T trunk

# 認証付き
git svn init <SVN_URL> --stdlayout --username <user>
```

**orphan ブランチでの動作**: ✅ 実験で確認済み。orphan ブランチ上でも問題なく init できる。

### git svn fetch

SVN リポジトリから未取得のリビジョンを取得し、`refs/remotes/origin/trunk` 等にマッピングする。

```bash
git svn fetch
```

- git-svn-id メタ情報からコミットと SVN リビジョンの対応を `.rev_map` に記録
- CI 環境で毎回 clone しても、既存コミットの git-svn-id から `.rev_map` を自動再構築
- 空の SVN リポジトリに対しても正常動作（何も取得しないだけ）

### git svn dcommit

Git のコミットを SVN に1つずつコミットし、その後 Git コミットを書き換える。

```bash
git svn dcommit
```

**重要な動作（実験確認済み）**:

1. 未 dcommit の各コミットに対して SVN commit を実行
2. 各 Git コミットのメッセージに `git-svn-id` トレーラーを追加
3. **Git コミットの SHA が書き換わる**（メッセージ変更のため）
4. HEAD は新しい SHA にリセットされる

```
# dcommit 前
503ab37 Add file1    ← 元のSHA
7091792 Add file2    ← 元のSHA

# dcommit 後
3ce2a27 Add file1    ← SHA が変更された
18da618 Add file2    ← SHA が変更された（git-svn-id 追加のため）
```

### dcommit 後の force push 必要性

**結論: svn ブランチでは毎回 `git push --force` が必要**

理由:
1. dcommit が Git コミットの SHA を書き換える
2. リモートの svn ブランチとは異なる SHA になる
3. 通常の `git push` は拒否される（non-fast-forward）
4. `git push --force origin svn` で上書きする必要がある

これは orphan ブランチの設計上、想定通りの動作。svn ブランチは他者が直接編集しないため、force push のリスクは許容できる。

## 履歴リニア化手法の比較

main ブランチのマージコミットを含む履歴を、SVN 互換のリニア履歴に変換する手法を比較。

### 手法一覧

| 手法 | 概要 | ファイル追加 | ファイル削除 | リネーム | 実装複雑度 |
|------|------|-------------|-------------|---------|-----------|
| `git checkout COMMIT -- .` + `git rm` + `git add -A` | ツリー全体をコピー | ✅ | ✅ | ✅ | 低 |
| `git diff` + `git apply` | パッチ適用 | ✅ | ✅ | △ バイナリ注意 | 中 |
| `git format-patch` + `git am` | メール形式パッチ | ✅ | ✅ | △ | 中 |
| `git cherry-pick --no-commit` | コミット単位チェリーピック | ✅ | ✅ | ✅ | 高（マージ不可） |
| `git read-tree` + `git checkout-index` | 低レベル操作 | ✅ | ✅ | ✅ | 高 |

### 推奨手法: `git checkout COMMIT -- .` 方式

**実験で検証済み**。最もシンプルかつ確実な方法。

```bash
# リニア化のコアロジック
for sha in $(git log main --first-parent --reverse --format="%H"); do
  msg=$(git log --format="%s" -1 $sha)
  
  # 作業ツリーをクリーンにしてからターゲットコミットの状態を適用
  git rm -rf . 2>/dev/null
  git checkout $sha -- .
  git add -A
  
  if ! git diff --cached --quiet; then
    git commit -m "$msg"
  fi
done
```

**メリット**:
- ファイルの追加・削除・リネームを全て正しく処理
- マージコミットも「結果のスナップショット」として確実に適用
- 最終的なツリーが main の HEAD と完全一致することを実験で確認

**注意点**:
- `git rm -rf .` で一旦全ファイルを削除してから `git checkout COMMIT -- .` で復元するため、差分ではなくスナップショット方式
- 大量のファイルがある場合はパフォーマンスに影響（検証環境では問題ない規模）

### git log --first-parent による解析

```bash
# マージコミットを含む main の履歴を first-parent で見ると:
# - 通常コミットはそのまま表示
# - マージコミットは「マージ結果」として1つのコミットに見える
git log --first-parent --oneline main
```

実験結果:
```
a3e26f2 Main commit 3          ← 通常コミット
6c16e44 Merge feature branch   ← マージコミット（差分はマージ結果全体）
cec094b Main commit 2          ← 通常コミット
64839e6 Initial commit         ← 初期コミット
```

`--first-parent` で得た各コミット間の diff は、マージの場合は「マージ前後の差分」になる。これをそのままリニアコミットとして svn ブランチに適用する。

## git-svn の制約事項

| 制約 | 詳細 | 影響 |
|------|------|------|
| リニア履歴のみ | dcommit はリニア履歴しか処理できない | main の履歴をリニア化する必要がある |
| SHA 書き換え | dcommit 後に Git SHA が変わる | force push が必要 |
| Perl 依存 | git-svn は Perl で実装 | CI イメージに perl + libsvn-perl が必要 |
| 認証キャッシュ | svn 認証情報を `~/.subversion/` にキャッシュ | CI では毎回設定が必要 |
| --no-rebase 非推奨 | dcommit 後の rebase をスキップすると不整合 | デフォルト動作（rebase）を使用 |

## テストパターン

### E2E テスト戦略

brainstorming で決定済み: E2E テストのみ（単体・結合テストなし）。

```bash
# E2E テストの基本パターン
# 1. SVN サーバー起動（compose.yaml）
# 2. テスト用 Git リポジトリ構築（マージ履歴付き）
# 3. 同期スクリプト実行
# 4. SVN 側の結果を svn コマンドで検証
# 5. 増分同期テスト
# 6. べき等性テスト（再実行）
```

### gitlab-ci-local でのテスト

```bash
# ローカル実行
docker compose up -d                    # SVN サーバー起動
gitlab-ci-local --variable SVN_URL=svn://localhost:3690/repos e2e-test
docker compose down
```

## 備考

- `git checkout COMMIT -- .` 方式は全コミットでツリー全体をコピーするため、差分方式より安全だが遅い
- 大規模リポジトリでは `git diff --name-status` で差分ファイルのみ処理する最適化も可能
- dcommit の `--no-rebase` オプションは使用しない（不整合の原因になる）
