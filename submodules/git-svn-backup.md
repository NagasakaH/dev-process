# git-svn-backup

> 最終更新: 2026-03-07

## 概要

GitリポジトリのmainブランチをSVNに一方向同期するための検証リポジトリ。
GitLab上でホストされ、Dockerコンテナ上のSVNサーバーに対してGit→SVN同期を行う仕組みを構築する。
現時点では初期コミット（デフォルトREADME.mdのみ）の状態であり、これから実装を行う。

- **リポジトリURL**: git@gitlab.com:nagasaka-experimental/git-svn-backup.git
- **ホスティング**: GitLab
- **現在のブランチ**: main（+ feature/GIT-SVN-001 作業中）

---

## 優先度A（必須情報）

### 1. プロジェクト構成

```
git-svn-backup/
└── README.md          # GitLabデフォルトテンプレート（未編集）
```

**主要ファイル:**
- `README.md` - GitLabが自動生成したデフォルトテンプレート。プロジェクト固有の情報は未記載。

**今後の想定構成（setup.yamlより）:**

```
git-svn-backup/
├── (main ブランチ)
│   └── (通常の開発コンテンツ - 同期スクリプトは配置しない)
└── (sync ブランチ)
    ├── compose.yaml           # SVNサーバーコンテナ定義（検証用）
    ├── sync-script.sh         # Git→SVN同期スクリプト（Bash）
    ├── .gitlab-ci.yml         # GitLab CI定期実行構成
    └── (同期履歴ファイル)      # 最終同期コミットSHA等
```

### 2. 外部公開インターフェース/API

現時点では公開インターフェースは存在しない。

**今後実装予定:**
- Git→SVN同期スクリプト（Bashスクリプト）
  - 初回同期（全履歴）
  - 増分同期（差分のみ）
- 2つの同期方式:
  - 方式A: マージ単位コミット方式（`--first-parent`でマージ単位、単体コミットはそのまま）
  - 方式B: 日次バッチ方式（1日のコミットをまとめて1SVNコミットに）

### 3. テスト実行方法

現時点ではテストは未構成。

**今後の予定:**
```bash
# gitlab-ci-local を使用したE2Eテスト
gitlab-ci-local
```

- テスト戦略: E2Eテストのみ（単体テスト・結合テストは実施しない）
- compose.yamlで起動したSVNコンテナに対して実際に同期を実行して検証

### 4. ビルド実行方法

Bashスクリプトベースのため、ビルドプロセスは不要。

```bash
# Dockerコンテナ起動（検証用SVNサーバー）
docker compose up -d
```

### 5. 依存関係

#### 本番依存
- `git` - バージョン管理
- `git-svn` - Git-SVNブリッジ
- `svn` - Subversionクライアント
- Docker / Docker Compose - SVNサーバーコンテナ（検証用）

#### 開発依存
- `gitlab-ci-local` - GitLab CIのローカル実行（E2Eテスト用）

### 6. 技術スタック

| カテゴリ | 技術 |
|---|---|
| 言語 | Bash |
| インフラ | Docker / Docker Compose |
| VCS | Git, SVN (git-svn) |
| CI/CD | GitLab CI |
| テスト | gitlab-ci-local（E2Eテスト） |

---

## 優先度B（オプション情報）

### 8. 環境変数/設定

| 変数名 | 説明 | デフォルト値 |
|---|---|---|
| `SVN_URL` | SVNリポジトリURL | なし（必須） |
| `SVN_USERNAME` | SVNユーザー名 | なし（必須） |
| `SVN_PASSWORD` | SVNパスワード | なし（必須） |

### 10. 既知の制約・制限事項

- `git-svn dcommit` はリニアな履歴しか扱えないため、マージコミットを含むmainブランチをそのままdcommitすることはできない
- SVN→Git方向の同期（双方向同期）はスコープ外
- main以外のブランチの同期はスコープ外
- SVNの登録者がGitLabに埋め込んだユーザーになることは許容
