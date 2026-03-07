# タスク: task01 - 基盤ファイル作成

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task01 |
| タスク名 | 基盤ファイル作成（compose.yaml, .gitignore, .sync-state.yml, variables.example） |
| 前提条件タスク | Phase 0（syncブランチ初期化） |
| 並列実行可否 | 可（task02と並列） |
| 推定所要時間 | 10分 |
| 優先度 | 高 |

---

## 作業環境

- **作業ディレクトリ（worktree）**: /tmp/GIT-SVN-001-task01/
- **ブランチ**: GIT-SVN-001-task01
- **ターゲットリポジトリ**: submodules/git-svn-backup
- **作業ブランチ**: sync（orphan ブランチ）
- **重要**: sync ブランチ上で作業すること。sync ブランチは Phase 0 で作成済みであること

---

## 前提条件

### 確認事項

- [ ] Phase 0 が完了し、sync ブランチが存在すること
- [ ] submodules/git-svn-backup リポジトリが存在すること
- [ ] Docker / Docker Compose が利用可能であること

---

## 作業内容

### 目的

同期ツールの基盤となる構成ファイル群を sync ブランチに作成する。

### 設計参照

- [design/01_implementation-approach.md](../design/01_implementation-approach.md) - sync ブランチのファイル構成
- [design/02_interface-api-design.md](../design/02_interface-api-design.md) - compose.yaml, 環境変数定義
- [design/03_data-structure-design.md](../design/03_data-structure-design.md) - .sync-state.yml スキーマ, compose.yaml 構造

### 実装ステップ

1. sync ブランチに切り替え（Phase 0 で作成済み）
2. compose.yaml を作成（SVNサーバーコンテナ定義）
3. .sync-state.yml の初期テンプレートを作成
4. .gitlab-ci-local-variables.yml.example を作成
5. .gitignore を作成（認証情報ファイル除外）
6. Docker Compose でSVNサーバーが起動することを確認

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `compose.yaml` | 新規作成 | garethflowers/svn-server コンテナ定義 |
| `.sync-state.yml` | 新規作成 | 同期状態管理の初期テンプレート |
| `.gitlab-ci-local-variables.yml.example` | 新規作成 | ローカルCI用変数テンプレート |
| `.gitignore` | 新規作成 | .gitlab-ci-local-variables.yml 等の除外 |

---

## テスト方針（TDD: RED-GREEN-REFACTOR）

### RED: 失敗するテストケース

**目的**: 実装前にファイルが存在しないことを確認し、テストが失敗する状態を記録する

```bash
# 【実装前に実行して失敗を確認すること】
# compose.yaml が存在しないことを確認
test -f compose.yaml && echo "FAIL: already exists" || echo "PASS: not yet created"

# SVNサーバーが起動しないことを確認
docker compose up -d 2>&1 || echo "Expected: compose.yaml not found"
```

**完了条件**: 上記コマンドの実行結果（失敗）をログに記録すること

### GREEN: 最小限の実装

以下の4ファイルを設計に基づき作成し、動作確認を行う。

**動作確認**:

```bash
# SVNサーバーが起動すること
docker compose up -d
sleep 3
docker compose ps | grep svn-server | grep -q "Up"

# SVNポートが応答すること（リポジトリ未作成のため接続テストのみ）
svn info svn://localhost:3690/ 2>&1 || echo "Expected: no repos yet"

docker compose down -v
```

**compose.yaml**:
```yaml
services:
  svn-server:
    image: garethflowers/svn-server
    container_name: svn-server
    ports:
      - "3690:3690"
    volumes:
      - svn-data:/var/opt/svn

volumes:
  svn-data:
```

**.sync-state.yml**:
```yaml
version: "1.0"
sync_mode: "merge-unit"
last_synced_commit: ""
last_synced_at: ""
svn_revision: 0
sync_history: []
```

**.gitlab-ci-local-variables.yml.example**:
```yaml
# コピーして .gitlab-ci-local-variables.yml を作成し、実際の値を設定してください
SVN_URL: "svn://localhost:3690/repos"
SVN_USERNAME: "svnuser"
SVN_PASSWORD: "svnpass"
```

**.gitignore**:
```
# ローカルCI用変数ファイル（実値を含むため除外）
.gitlab-ci-local-variables.yml
```

### REFACTOR: コード改善

- compose.yaml のコメント追加（必要に応じて）
- .gitignore に追加すべきパターンの確認

---

## 成果物

### 期待される出力

| 成果物 | パス | 説明 |
|--------|------|------|
| compose.yaml | `compose.yaml` | SVNサーバーコンテナ定義 |
| .sync-state.yml | `.sync-state.yml` | 同期状態管理の初期テンプレート |
| .gitlab-ci-local-variables.yml.example | `.gitlab-ci-local-variables.yml.example` | ローカルCI用変数テンプレート |
| .gitignore | `.gitignore` | 認証情報ファイル除外設定 |

---

## 完了条件

### 機能的条件

- [ ] compose.yaml で `docker compose up -d` が成功する
- [ ] SVNサーバーコンテナが起動し、ポート3690でリッスンする
- [ ] .sync-state.yml が設計書のスキーマに準拠している
- [ ] .gitlab-ci-local-variables.yml.example にSVN接続情報のテンプレートが含まれる
- [ ] .gitignore に .gitlab-ci-local-variables.yml が含まれる

### 品質条件

- [ ] compose.yaml が設計書（03_data-structure-design.md）と一致すること
- [ ] .sync-state.yml の初期値が設計書と一致すること
- [ ] RED実行証跡（実装前のテスト失敗ログ）が記録されていること

---

## コミット

```bash
cd /tmp/GIT-SVN-001-task01/
git add compose.yaml .sync-state.yml .gitlab-ci-local-variables.yml.example .gitignore
git commit -m "task01: 基盤ファイル作成

- compose.yaml: SVNサーバーコンテナ定義
- .sync-state.yml: 同期状態管理の初期テンプレート
- .gitlab-ci-local-variables.yml.example: ローカルCI用変数テンプレート
- .gitignore: 認証情報ファイル除外設定"
```

---

## 注意事項

- sync ブランチは Phase 0 で作成済み。このタスクではブランチの作成は行わない
- compose.yaml は設計書通りに作成する（独自の変更を加えない）
- SVNリポジトリの初期化（svnadmin create）はこのタスクでは行わない（E2Eテストスクリプトで実施）
