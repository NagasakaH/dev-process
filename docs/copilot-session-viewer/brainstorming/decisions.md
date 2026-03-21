# Brainstorming 決定事項

## 1. コンテナ化方針: ハイブリッドアプローチ

**質問**: コンテナ化のアーキテクチャはどうするか？

**決定**: copilot-session-viewer リポジトリに新規 Dockerfile + compose.yaml を作成し、1コンテナに Next.js (viewer) + tmux + Copilot CLI を同居させるハイブリッドアプローチを採用する。

**詳細**:
- dev-process の `start-tmux.sh` / `tini` / `cplt` パターンを参考にする
- compose.yaml を使用（Docker Compose V2 標準命名。docker-compose.yml ではない）
- 1コンテナ構成により、プロセス間通信の複雑さを排除しつつ自己完結した環境を実現

## 2. セッション検出: ローカル専用モード

**質問**: セッション検出のロジックをどう変更するか？

**決定**: Docker 検出ロジック（`docker ps`, `docker exec`）を環境変数やフラグで無効化可能にし、ローカル tmux 検出は常に有効とする。

**詳細**:
- 新しい環境変数（例: `DISABLE_DOCKER_DETECTION=true`）でホスト上の Docker 検出をスキップ
- コンテナ内ではローカル tmux 検出のみで動作
- ホスト直接起動時の既存動作（ローカル tmux 検出）は維持
- 将来的に Docker 検出を再有効化する余地を残す

## 3. テストフレームワーク: Vitest + Playwright

**質問**: テストフレームワークは何を使うか？

**決定**: Unit/Integration に Vitest、E2E に Playwright を新規導入する。

**詳細**:
- copilot-session-viewer には現在テスト基盤が一切存在しないため、ゼロから構築
- Vitest: Next.js / React エコシステムとの親和性が高い
- Playwright: コンテナ内での E2E テスト実行に適している
- E2E テストフロー: コンテナ起動 → viewer 起動 → tmux 確認 → 認証確認

## 4. 認証・設定の管理

**質問**: 認証・設定の管理方法は？

**決定**: `.env` から PAT + BASIC_AUTH 等を注入する。`$HOME/.copilot` はコンテナ内で自動分離される。

**詳細**:
- `.env` ファイルで PAT、BASIC_AUTH 等の認証情報を管理
- `$HOME/.copilot` は `process.env.HOME` に依存する既存パターンで自然にコンテナごとに分離
- `.env.example` を提供してセットアップを容易にする

## 5. ファイル命名規約

**質問**: compose.yaml のファイル名は？

**決定**: `compose.yaml` を使用する（Docker Compose V2 の標準命名に従う）。

**詳細**:
- `docker-compose.yml` は Docker Compose V1 のレガシー命名
- Docker Compose V2 では `compose.yaml` が推奨ファイル名
- プロジェクト全体で V2 標準に統一する
