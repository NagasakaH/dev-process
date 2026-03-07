# アーキテクチャ調査

## 概要

git-svn-backup は GitLab 上の Git リポジトリの main ブランチを SVN サーバーに一方向同期するための検証環境・同期ツールプロジェクト。ターゲットリポジトリは現時点でほぼ空（README.md のみ）であり、今回新規に構築する。

## ターゲットリポジトリ現状

```
submodules/git-svn-backup/
├── .git/
└── README.md      # GitLab初期テンプレート（操作ガイド）
```

- GitLab リポジトリ: `https://gitlab.com/nagasaka-experimental/git-svn-backup.git`
- ブランチ: `main` のみ（コミット1件）
- 既存コード: なし（設計・実装は全て新規）

## 計画アーキテクチャ: 3ブランチ構成

brainstorming で決定した3ブランチ構成を採用する。

```mermaid
graph TD
    subgraph "git-svn-backup リポジトリ"
        MAIN["main ブランチ<br/>（開発対象・同期元）"]
        SVN["svn ブランチ (orphan)<br/>（SVN同期用・dcommit対象）"]
        SYNC["sync ブランチ (orphan)<br/>（同期ツール・CI設定・履歴管理）"]
    end
    
    subgraph "外部システム"
        SVN_SERVER["SVN サーバー<br/>（Docker コンテナ）"]
        GITLAB_CI["GitLab CI<br/>（定期実行）"]
    end
    
    MAIN -->|"履歴リニア化"| SVN
    SVN -->|"git svn dcommit"| SVN_SERVER
    SYNC -->|"同期状態管理"| SVN
    GITLAB_CI -->|"トリガー"| SYNC
```

## ブランチ別責務

| ブランチ | 種別 | 責務 | 主要コンテンツ |
|----------|------|------|---------------|
| main | 通常 | 開発対象リポジトリ。同期元の履歴を持つ | ソースコード、README.md |
| svn | orphan | SVN と同期するためのリニア履歴を保持 | main からリニア化されたファイル群 |
| sync | orphan | 同期ツール・CI設定・状態管理 | スクリプト、.gitlab-ci.yml、compose.yaml、.sync-state.yml |

## 同期フロー概要

```mermaid
sequenceDiagram
    participant CI as GitLab CI (syncブランチ)
    participant MAIN as main ブランチ
    participant SVN_BR as svn ブランチ
    participant SVN_SRV as SVN サーバー
    
    CI->>CI: sync ブランチ checkout
    CI->>CI: .sync-state.yml 読み込み
    CI->>MAIN: main ブランチの履歴取得
    CI->>CI: last_synced_commit 以降のコミット特定
    CI->>SVN_BR: svn ブランチ checkout
    CI->>SVN_BR: リニア化コミット適用
    CI->>SVN_BR: git svn init / fetch
    SVN_BR->>SVN_SRV: git svn dcommit
    SVN_SRV-->>SVN_BR: SVN revision 付与
    CI->>SVN_BR: git push --force origin svn
    CI->>CI: .sync-state.yml 更新
    CI->>CI: git push origin sync
```

## インフラ構成

```mermaid
graph LR
    subgraph "Docker Compose (検証環境)"
        SVN_CONTAINER["SVN サーバー<br/>garethflowers/svn-server<br/>Port: 3690"]
    end
    
    subgraph "CI/ローカル実行環境"
        SCRIPT["sync-to-svn.sh<br/>同期スクリプト"]
        GCL["gitlab-ci-local<br/>ローカルCI実行"]
    end
    
    SCRIPT -->|"svn:// プロトコル"| SVN_CONTAINER
    GCL -->|"実行"| SCRIPT
```

## 主要コンポーネント（計画）

| コンポーネント | 配置先 | 役割 |
|---------------|--------|------|
| `compose.yaml` | sync ブランチ | SVN サーバーコンテナ定義 |
| `sync-to-svn.sh` | sync ブランチ | Git→SVN 同期メインスクリプト |
| `.gitlab-ci.yml` | sync ブランチ | GitLab CI 定期実行ジョブ定義 |
| `.sync-state.yml` | sync ブランチ | 同期状態記録（最終同期コミットSHA等） |
| `e2e-test.sh` | sync ブランチ | E2E テストスクリプト |

## 備考

- ターゲットリポジトリは完全に新規構築のため、既存コードの制約はない
- 3ブランチ構成は brainstorming で合意済み
- SVN サーバーは検証用 Docker コンテナで、本番 SVN への接続は scope 外
