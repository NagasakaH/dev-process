# ブレインストーミング成果物 — GIT-SVN-001

## 概要

Git→SVN一方向同期の検証環境構築に向けて、ブランチ構成・同期方式・テスト戦略を対話で確定した。

## 決定事項

### 1. 3ブランチ構成

| ブランチ | 役割 | 特徴 |
|----------|------|------|
| `main` | 通常の開発ブランチ | マージコミットあり、同期ツールは配置しない |
| `svn` | SVNと直接同期するブランチ | orphanブランチ、リニア履歴、git-svn dcommit用 |
| `sync` | 同期ツール・CI設定・同期履歴を管理 | orphanブランチ、.sync-state.yml配置 |

### 2. 同期方式（設計フェーズで比較・選択）

- **方式A: マージ単位コミット方式** — `git log --first-parent`でmainの直系履歴を走査。マージコミットはPR全体を1SVNコミットに。単体コミットはそのまま
- **方式B: 日次バッチ方式** — 1日のコミットをまとめて1SVNコミットに

### 3. 技術方式

mainの履歴をリニア化 → svnブランチにコミット → `git-svn dcommit`

- `git-svn dcommit` 後のメタ情報（git-svn-id）により、CI環境を毎回破棄しても差分のみdcommit可能
- svnブランチは dcommit 後に `git push --force` が必要

### 4. 同期フロー（CI毎回実行）

```
1. git clone → svnブランチをcheckout
2. git svn init -s SVN_URL → SVNリモートを設定
3. git svn fetch → SVN履歴を取得し、git-svn-idとマッピングを復元
4. syncブランチの.sync-state.ymlからmainの同期ポイントを取得
5. mainの差分をリニア化してsvnブランチにコミット
6. git svn dcommit → 新しいコミットのみSVNに反映
7. svnブランチを git push --force
8. syncブランチに同期履歴を記録してpush
```

### 5. 同期状態管理

`.sync-state.yml`（syncブランチ配置）:

```yaml
last_synced_commit: "abc123..."
last_sync_timestamp: "2026-03-07T00:00:00Z"
sync_history:
  - commit: "abc123..."
    timestamp: "..."
    svn_revision: 42
```

### 6. 環境変数

| 変数 | 説明 |
|------|------|
| `SVN_URL` | SVNリポジトリURL |
| `SVN_USERNAME` | SVNユーザー名 |
| `SVN_PASSWORD` | SVNパスワード |

## テスト戦略

- **E2Eテストのみ**（単体・結合テストは実施しない）
- **ツール**: gitlab-ci-local
- **環境**: Docker compose（ローカルSVNコンテナ）

### テストシナリオ

1. compose.yamlでSVNサーバーコンテナを起動
2. Gitリポジトリにテスト用コミット（マージコミット含む）を作成
3. 初回同期を実行 → SVNの内容を検証
4. 追加コミットを作成
5. 増分同期を実行 → 新しい変更のみ反映されることを検証（重複なし）
6. **0から環境を再構築** → 増分同期が正しく動作することを検証（CI再現テスト）
7. マージコミットがリニア化されてSVNに正しく記録されることを検証

### acceptance_criteria テストマッピング

| acceptance_criteria | テスト方法 |
|---|---|
| compose.yamlでSVNサーバーが起動し、svnコマンドでアクセスできる | E2E: コンテナ起動 + svn info |
| 同期スクリプトがmainの内容をSVNに正しく反映する | E2E: 初回同期 + SVN内容検証 |
| マージコミットが適切に変換されてSVNに記録される | E2E: マージコミット含むリポ → 同期 → SVN log検証 |
| 増分同期が正しく動作する | E2E: 複数回同期実行 + 差分のみ反映確認 |
| 同期スクリプトの再実行がべき等 | E2E: 同一状態で2回実行 → SVN変更なし |
| GitLab CI構成が定義されている | E2E: gitlab-ci-local で実行成功 |
| gitlab-ci-localでE2Eテストが実行できる | E2E: gitlab-ci-local で実行成功 |
| 2つの同期方式の比較ドキュメントが存在する | ファイル存在チェック |

## 追加要件（対話で追加）

- svnブランチはorphanブランチとして作成し、dcommit後にgit push --forceする
- syncブランチもorphanブランチとして作成する
- CI実行時は毎回git clone→svnブランチcheckout→git svn init/fetchでSVN履歴を復元する
- 環境変数: SVN_URL, SVN_USERNAME, SVN_PASSWORD
- E2Eテストで0から環境再構築後の増分同期の正常動作を検証する

## 次のステップ

1. **investigation** — git-svn dcommitの詳細動作、SVNコンテナイメージの調査
2. **design** — 方式A/Bの詳細設計・比較ドキュメント作成、ユーザーによる方式選択
