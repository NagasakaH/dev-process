# 実装方針

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | GIT-SVN-001 |
| タスク名 | Git→SVN一方向同期の検証環境構築 |
| 作成日 | 2026-03-07 |

---

## 1. 同期方式の比較設計

ユーザー指示により、2つの同期方式を詳細設計し比較する。

### 1.1 方式A: マージ単位コミット方式

#### 概要

`git log --first-parent` で main ブランチの直系履歴を走査し、各コミットをSVNコミットとして反映する方式。

- **マージコミット** → PR全体の変更を1つのSVNコミットとして記録
- **通常コミット** → そのまま1つのSVNコミットとして記録
- リニア化は `git checkout COMMIT -- .` でスナップショット方式（実験確認済み）

#### リニア化アルゴリズム

```bash
# svn ブランチ上で実行
LAST_SYNCED="<last_synced_commit or empty>"

# --first-parent で main の直系コミットのみ取得（マージの第2親は無視）
COMMITS=$(git log origin/main --first-parent --reverse --format="%H" \
  ${LAST_SYNCED:+${LAST_SYNCED}..})

for sha in $COMMITS; do
  msg=$(git log --format="%B" -1 "$sha")
  author_date=$(git log --format="%ai" -1 "$sha")

  # スナップショット方式: 全ファイル削除→コミットの状態を復元
  git rm -rf . 2>/dev/null || true
  git checkout "$sha" -- .
  git add -A

  # 差分がある場合のみコミット（べき等性確保）
  # 日時保存ポリシー:
  #   GIT_AUTHOR_DATE  = 元コミットの日時（author date）を保持
  #   GIT_COMMITTER_DATE = 同期実行時の日時（自動設定）
  if ! git diff --cached --quiet; then
    GIT_AUTHOR_DATE="$author_date" git commit -m "$msg"
  fi
done
```

#### コミット粒度の例

```
main の履歴:
  a1 Initial commit           → SVN r1: Initial commit
  a2 Add feature X            → SVN r2: Add feature X
  m1 Merge branch 'feature-Y' → SVN r3: Merge branch 'feature-Y'（PR全体の差分）
  a3 Fix bug Z                → SVN r4: Fix bug Z
```

#### メリット

- PR単位の意味のあるコミット粒度をSVN側でも保持
- コミットメッセージがGitのマージコミットと対応するため追跡が容易
- `--first-parent` によりマージ内の個別コミットを無視し、シンプルなリニア履歴を生成
- 増分同期が自然（last_synced_commit 以降の --first-parent コミットを処理するだけ）

#### デメリット

- マージコミットが大きい場合、1つのSVNコミットに大量の変更が含まれる
- PR内の個別コミット履歴はSVN側で失われる
- main に直接 push された細かいコミットもそれぞれSVNコミットになる

### 1.2 方式B: 日次バッチ方式

#### 概要

1日のコミットをまとめて1つのSVNコミットとして記録する方式。

#### リニア化アルゴリズム

```bash
LAST_SYNCED="<last_synced_commit or empty>"

# 日付ごとにグループ化
DATES=$(git log origin/main --first-parent --reverse --format="%ad" --date=short \
  ${LAST_SYNCED:+${LAST_SYNCED}..} | sort -u)

for date in $DATES; do
  # その日の最後のコミットSHAを取得
  last_sha=$(git log origin/main --first-parent --reverse --format="%H" \
    --after="${date}T00:00:00" --before="${date}T23:59:59" \
    ${LAST_SYNCED:+${LAST_SYNCED}..} | tail -1)

  [ -z "$last_sha" ] && continue

  # その日のコミット数を取得
  commit_count=$(git log origin/main --first-parent --format="%H" \
    --after="${date}T00:00:00" --before="${date}T23:59:59" \
    ${LAST_SYNCED:+${LAST_SYNCED}..} | wc -l)

  git rm -rf . 2>/dev/null || true
  git checkout "$last_sha" -- .
  git add -A

  if ! git diff --cached --quiet; then
    git commit -m "sync: ${date} (${commit_count} commits)"
  fi
done
```

#### コミット粒度の例

```
main の履歴（2日間で4コミット）:
  2024-01-15: a1, a2, m1  → SVN r1: sync: 2024-01-15 (3 commits)
  2024-01-16: a3           → SVN r2: sync: 2024-01-16 (1 commit)
```

#### メリット

- 実装がシンプル（日付でグループ化するだけ）
- SVNコミット数が少なく、SVNリポジトリの負荷が低い
- 日次の変更サマリーとして見やすい

#### デメリット

- コミットの意味的な粒度が失われる（PR単位の情報なし）
- 元のコミットメッセージが失われ、追跡が困難
- 1日に大量の変更がある場合、diff の把握が難しい
- 日付境界の判定がタイムゾーンに依存する（UTC vs ローカル）
- 同じ日に複数回同期を実行した場合の挙動が不明確

---

## 2. 方式比較表

| 比較項目 | 方式A: マージ単位 | 方式B: 日次バッチ |
|----------|-------------------|-------------------|
| **コミット粒度** | PR/コミット単位（意味のある粒度） | 日単位（粗い粒度） |
| **コミットメッセージ** | 元のメッセージを保持 | 自動生成（日付+件数） |
| **追跡性** | ⭐⭐⭐ Git↔SVN の対応が明確 | ⭐ 対応が不明確 |
| **実装複雑度** | ⭐⭐ やや複雑（--first-parent） | ⭐⭐⭐ シンプル |
| **SVNコミット数** | Git の first-parent コミット数と同等 | 日数と同等（少ない） |
| **増分同期** | ⭐⭐⭐ last_synced_commit 以降を処理 | ⭐⭐ 日付境界の扱いに注意 |
| **べき等性** | ⭐⭐⭐ コミットSHA ベースで確実 | ⭐⭐ 日付ベースで不安定要素あり |
| **タイムゾーン問題** | なし | あり（日付グループ化） |
| **大量コミット時** | コミット数に比例して処理 | 日単位で集約され高速 |
| **元情報の保存** | マージコミットメッセージ保持 | ほぼ全て失われる |

---

## 3. 推奨案

**方式A: マージ単位コミット方式を推奨する。**

### 推奨理由

1. **追跡性**: Git のマージコミット/通常コミットとSVNリビジョンが1:1対応し、問題発生時のトレースが容易
2. **コミットメッセージ保持**: 元のコミットメッセージがSVN側にも記録され、変更内容が理解しやすい
3. **べき等性**: コミットSHA ベースの増分同期が確実で、再実行時の挙動が予測可能
4. **タイムゾーン非依存**: 日付グループ化のタイムゾーン問題がない
5. **実装複雑度の差が小さい**: `--first-parent` の使用と日付グループ化、どちらもコア部分は同程度の複雑さ

### トレードオフ

- SVNコミット数は方式Bより多くなるが、検証環境では問題ない規模
- PR内の個別コミット履歴はいずれの方式でも失われる（`--first-parent` の特性）

> **決定**: 設計レビューにより**方式Aで実装確定**とする。方式Bは比較資料として本ドキュメントに残す。

---

## 4. 選定した全体アーキテクチャ

### 4.1 3ブランチ構成

brainstorming で決定済みの3ブランチ構成を採用。

| ブランチ | 種別 | 責務 |
|----------|------|------|
| main | 通常 | 開発対象リポジトリ（同期元） |
| svn | orphan | SVN同期用リニア履歴保持（dcommit対象） |
| sync | orphan | 同期ツール・CI設定・状態管理 |

### 4.2 技術選定

| 技術/ツール | 選定理由 | 備考 |
|-------------|----------|------|
| git-svn (dcommit) | Git→SVN の標準ブリッジ。git-svn-id で再構築可能 | Perl依存 |
| `git checkout COMMIT -- .` | リニア化で最も安全・確実（実験確認済み） | スナップショット方式 |
| garethflowers/svn-server | 最もシンプルなSVNコンテナ（svn://のみ） | Alpine ベース |
| gitlab-ci-local | ローカルCI実行。services 非対応のため Compose で代替 | --network host |
| yq | YAML操作（.sync-state.yml の読み書き） | v4+ |
| bash | 同期スクリプトの実装言語 | 4.0+ |

### 4.3 sync ブランチのファイル構成

```
sync ブランチ:
├── sync-to-svn.sh            # メイン同期スクリプト
├── e2e-test.sh                # E2Eテストスクリプト
├── compose.yaml               # SVNサーバーコンテナ定義
├── .gitlab-ci.yml             # GitLab CI ジョブ定義
├── .gitlab-ci-local-variables.yml.example  # ローカルCI用変数テンプレート（実ファイルは .gitignore 管理）
├── .sync-state.yml            # 同期状態記録
└── README.md                  # sync ブランチの説明
```

---

## 5. 制約事項

| 制約 | 影響 | 対応方針 |
|------|------|----------|
| git-svn はリニア履歴のみ dcommit 可能 | main のマージ履歴をリニア化する必要 | `git checkout COMMIT -- .` 方式 |
| dcommit が Git SHA を書き換える | svn ブランチで force push が必須 | ブランチ保護解除 |
| gitlab-ci-local は services 非対応 | Docker Compose で SVN サーバーを起動 | --network host で接続 |
| SVN ユーザー = CI 実行ユーザー固定 | SVN 側のコミッター名が単一 | 要件として許容済み |
| 一方向同期のみ (Git→SVN) | SVN→Git の変更は反映されない | scope 定義により対象外 |

---

## 6. 前提条件

- [x] ターゲットリポジトリ（git-svn-backup）が GitLab 上に存在する
- [x] 3ブランチ構成（main/svn/sync）が brainstorming で合意済み
- [x] 方式Aでの実装が設計レビューにより確定済み
- [x] `git checkout COMMIT -- .` 方式の動作が実験で確認済み
- [x] garethflowers/svn-server の動作が実験で確認済み
- [x] git-svn-id による .rev_map 自動再構築が実験で確認済み
- [ ] svn ブランチのブランチ保護が解除されている（force push 許可）
- [ ] GitLab CI/CD Variables に SVN 接続情報が設定されている

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-03-07 | 1.0 | 初版作成 | Copilot |
| 2026-03-07 | 1.1 | 設計レビュー指摘対応（RD-002, RD-013） | Copilot |
| 2026-03-07 | 1.2 | 設計レビュー Round 2 指摘対応（RD-003残余） | Copilot |
