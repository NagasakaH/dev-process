# 統合ポイント調査: gitlab-ci-local・CI 構成・マルチブランチ操作

## 概要

本プロジェクトの主要統合ポイントは、GitLab CI（定期実行）、gitlab-ci-local（ローカルテスト）、Docker Compose（SVN サーバー）、git-svn（SVN 連携）の4つ。CI 内でのマルチブランチ操作が技術的なキーポイント。

## gitlab-ci-local 調査結果

### 基本情報

| 項目 | 詳細 |
|------|------|
| バージョン | 4.68.1（確認済み） |
| インストール | `npm install -g gitlab-ci-local` |
| 実行モード | Shell executor / Docker executor |
| services: 対応 | ❌ 非対応（Docker Compose で代替） |

### インストール方法

```bash
# NPM（推奨）
npm install -g gitlab-ci-local

# Debian PPA
sudo wget -O /etc/apt/sources.list.d/gitlab-ci-local.sources \
  https://gitlab-ci-local-ppa.firecow.dk/gitlab-ci-local.sources
sudo apt-get update && sudo apt-get install gitlab-ci-local

# Homebrew (macOS)
brew install gitlab-ci-local
```

### 基本的な使い方

```bash
# パイプライン全体を実行
gitlab-ci-local

# 特定ジョブを実行
gitlab-ci-local <job-name>

# 別ファイルを指定
gitlab-ci-local --file .gitlab-ci.yml

# ジョブ一覧
gitlab-ci-local --list

# 変数を渡す
gitlab-ci-local --variable SVN_URL=svn://localhost:3690/repos

# Docker ネットワーク指定
gitlab-ci-local --network host
```

### Docker 対応と services の制約

**重要**: gitlab-ci-local は GitLab CI の `services:` キーワードを**ネイティブサポートしない**。

```yaml
# ❌ GitLab Runner では動くが gitlab-ci-local では services が無視される
test:
  services:
    - name: garethflowers/svn-server
  script:
    - svn info svn://svn-server:3690/repos
```

**回避策**: Docker Compose で事前にサービスを起動し、ネットワーク接続する。

```bash
# 正しいアプローチ
docker compose up -d          # SVN サーバー起動
gitlab-ci-local --network host  # host ネットワークで接続
docker compose down            # 後片付け
```

### 環境変数の渡し方

| 方法 | 例 | 優先度 |
|------|-----|--------|
| CLI `--variable` | `--variable SVN_URL=svn://localhost:3690/repos` | 最高 |
| `.gitlab-ci-local-variables.yml` | ファイルに YAML で定義 | 中 |
| 環境変数 `GCL_*` | `export GCL_NEEDS=true` | 低 |
| `.gitlab-ci-local-env` | KEY=VALUE 形式 | 低 |

```yaml
# .gitlab-ci-local-variables.yml
SVN_URL: "svn://localhost:3690/repos"
SVN_USERNAME: "svnuser"
SVN_PASSWORD: "svnpass"
```

### GitLab Runner との主な違い

| 機能 | GitLab Runner | gitlab-ci-local |
|------|--------------|-----------------|
| services: | ✅ ネイティブ対応 | ❌ 非対応 |
| artifacts | Runner 間共有 | `.gitlab-ci-local/artifacts/` にコピー |
| ファイル同期 | 全ファイル | tracked ファイルのみ |
| cache: | 分散キャッシュ | ローカルのみ |
| 変数 | CI/CD設定画面 | ファイル/CLI |
| needs: | ✅ | ✅（`--needs` フラグ） |
| rules: | ✅ | ✅ |
| `$GITLAB_CI` | `"true"` | `"false"` |
| Docker executor | ✅ | ✅ |
| Shell executor | ✅ | ✅（`--force-shell-executor`） |

## CI 内でのマルチブランチ操作

### sync ブランチからの操作フロー

```mermaid
sequenceDiagram
    participant CI as CI Job (sync ブランチ)
    participant GIT as Git Operations
    participant SVN as SVN Server
    
    CI->>GIT: git clone (sync ブランチ)
    CI->>GIT: git fetch origin main svn
    CI->>CI: .sync-state.yml 読み込み
    
    Note over CI: last_synced_commit 以降の<br/>main コミット特定
    
    CI->>GIT: git checkout svn
    CI->>GIT: git svn init $SVN_URL --stdlayout
    CI->>GIT: git svn fetch
    
    loop 各 first-parent コミット
        CI->>GIT: git rm -rf . && git checkout $sha -- .
        CI->>GIT: git add -A && git commit
    end
    
    CI->>SVN: git svn dcommit
    SVN-->>GIT: SHA 書き換え + git-svn-id 付与
    
    CI->>GIT: git push --force origin svn
    CI->>GIT: git checkout sync
    CI->>CI: .sync-state.yml 更新
    CI->>GIT: git add . && git commit && git push origin sync
```

### CI 内のブランチ操作技術

```bash
# sync ブランチで CI が開始される想定
# 1. 他ブランチの情報を取得
git fetch origin main:refs/remotes/origin/main
git fetch origin svn:refs/remotes/origin/svn 2>/dev/null || true

# 2. svn ブランチが存在しない場合は作成
if ! git rev-parse --verify svn 2>/dev/null; then
  git checkout --orphan svn
  git rm -rf . 2>/dev/null
else
  git checkout svn
fi

# 3. git-svn を設定
git svn init "$SVN_URL" --stdlayout --username "$SVN_USERNAME"
git svn fetch

# 4. リニア化コミットの適用
LAST_SYNCED=$(yq '.last_synced_commit' .sync-state.yml)
for sha in $(git log origin/main --first-parent --reverse --format="%H" ${LAST_SYNCED:+$LAST_SYNCED..}); do
  # ... リニア化処理
done

# 5. SVN に同期
git svn dcommit

# 6. svn ブランチを push
git push --force origin svn

# 7. sync ブランチに戻って状態更新
git checkout sync
# .sync-state.yml 更新
git add .sync-state.yml
git commit -m "sync: update state"
git push origin sync
```

### .gitlab-ci.yml 構成案

```yaml
# sync ブランチに配置
stages:
  - sync
  - test

variables:
  SVN_URL: ${SVN_URL}
  SVN_USERNAME: ${SVN_USERNAME}
  SVN_PASSWORD: ${SVN_PASSWORD}

sync-to-svn:
  stage: sync
  image: debian:bookworm
  before_script:
    - apt-get update && apt-get install -y git git-svn subversion
  script:
    - ./sync-to-svn.sh
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
    - if: $CI_PIPELINE_SOURCE == "web"

e2e-test:
  stage: test
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - apk add --no-cache git git-svn subversion bash
  script:
    - docker compose up -d
    - ./e2e-test.sh
    - docker compose down
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_PIPELINE_SOURCE == "web"
```

## sync ブランチへの CI 内 push

GitLab CI 内からブランチに push するための方法:

```bash
# 方法1: CI_JOB_TOKEN を使用（GitLab CI）
git remote set-url origin "https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.com/group/repo.git"
git push origin sync

# 方法2: Deploy Token
git remote set-url origin "https://deploy-token:${DEPLOY_TOKEN}@gitlab.com/group/repo.git"
git push origin sync

# 方法3: SSH Deploy Key
# before_script で SSH 設定
git push origin sync
```

**注意**: GitLab CI ではデフォルトで `GIT_STRATEGY: fetch` により shallow clone される。`GIT_DEPTH: 0` で全履歴を取得する必要がある。

```yaml
variables:
  GIT_DEPTH: 0
  GIT_STRATEGY: clone
```

## Docker Compose 連携

```yaml
# compose.yaml (sync ブランチに配置)
services:
  svn-server:
    image: garethflowers/svn-server
    ports:
      - "3690:3690"
    volumes:
      - svn-data:/var/opt/svn

volumes:
  svn-data:
```

E2E テストでの利用:
```bash
# 起動
docker compose up -d
sleep 2

# SVN リポジトリ作成
docker compose exec svn-server svnadmin create /var/opt/svn/repos

# 認証設定
docker compose exec svn-server sh -c '...'

# テスト実行
./e2e-test.sh

# 後片付け
docker compose down -v
```

## 備考

- gitlab-ci-local で Docker executor を使う場合、`--network host` でホストネットワークに接続すると Docker Compose で起動したサービスにアクセスできる
- GitLab CI の `$GITLAB_CI` は `"true"`、gitlab-ci-local では `"false"` — 条件分岐に利用可能
- `GIT_DEPTH: 0` を忘れると、main の履歴が不完全になり同期が失敗する
