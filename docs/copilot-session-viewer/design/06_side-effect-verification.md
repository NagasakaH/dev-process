# 06. 弊害検証計画

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | viewer-container-local |
| タスク名 | container |
| 作成日 | 2026-03-21 |
| 調査結果参照 | [investigation/](../investigation/) |

---

## 1. 副作用が発生しやすい箇所

| 箇所 | 影響度 | 発生可能性 | 検証方法 |
|------|--------|----------|---------|
| `terminal.ts` Docker 検出無効化 | 中 | 低 | UT-1,2 で検証。既存 Docker 検出パスが `DISABLE_DOCKER_DETECTION` 未設定時に正常動作することを確認 |
| `next.config.ts` standalone 追加 | 中 | 低 | IT-2 で検証。`npm run dev` でのローカル開発が引き続き動作することを確認 |
| `package.json` 新規依存追加 | 低 | 低 | `npm ci` 成功、`npm run build` 成功を確認 |
| tmux セッション安定性 | 高 | 中 | E2E-3 で検証。30秒間のセッション維持を確認 |
| Next.js standalone サーバー動作 | 中 | 低 | E2E-1 で検証。HTTP 応答確認 |

---

## 2. 弊害検証項目

### 2.1 回帰テスト

- [ ] `npm run dev` でローカル開発サーバーが正常起動する
- [ ] `npm run build` がエラーなく完了する
- [ ] `npm run lint` が新規エラーを出さない
- [ ] ローカル（非コンテナ）環境で Docker 検出が従来通り動作する
- [ ] `DISABLE_DOCKER_DETECTION` 未設定時に既存動作に影響がない
- [ ] Basic Auth が環境変数未設定時にスキップされる（既存動作維持）
- [ ] `/api/dev-process/start-copilot` が `ENABLE_DEV_PROCESS=false` で 403 を返す

### 2.2 パフォーマンス検証

- [ ] コンテナ起動から HTTP 応答可能までの時間: **目標 30 秒以内**
- [ ] `/api/sessions` レスポンスタイム: **目標 500ms 以内**（セッション 100 件以下）
- [ ] `/api/active-sessions` レスポンスタイム: **目標 2 秒以内**（ローカル tmux スキャン）
- [ ] コンテナメモリ使用量: **目標 512MB 以下**（idle 時）
- [ ] Docker イメージサイズ: **目標 1GB 以下**（Playwright 含まない、ベースイメージ + アプリ層合算）

### 2.3 セキュリティ検証

- [ ] `.env` ファイルが Docker イメージに含まれない（`.dockerignore` で除外）
- [ ] `GITHUB_TOKEN` がコンテナログに出力されない
- [ ] Basic Auth が有効な場合、未認証リクエストが 401 で拒否される
- [ ] `ENABLE_DEV_PROCESS=false` で dev-process API が利用不可

### 2.4 互換性検証

- [ ] ローカル開発（`npm run dev`）が `output: "standalone"` 追加後も正常動作
- [ ] `output: "standalone"` で `next build` の出力に `.next/standalone/server.js` が含まれる
- [ ] `.next/static/` が standalone に含まれないため、Dockerfile で別途コピーが必要
- [ ] Vitest が既存 TypeScript 設定（`strict: true`, `isolatedModules: true`）と互換

---

## 3. 検証手順

### 3.1 ローカル開発回帰（手動）

```bash
# viewer リポジトリで実行
cd submodules/copilot-session-viewer

# ビルド確認
npm run build

# ローカル開発サーバー起動
npm run dev
# → http://localhost:3000 でページ表示を確認

# リント
npm run lint
```

### 3.2 コンテナ回帰（手動）

```bash
# ベースイメージビルド
devcontainer build --workspace-folder . --image-name copilot-session-viewer:base

# Next.js ビルド（ホスト側）
npm ci && npm run build

# アプリ層ビルド＆起動
docker compose up -d --build

# ヘルスチェック
curl -s http://localhost:3000/api/sessions | head -c 200

# tmux 確認
docker compose exec viewer tmux list-sessions

# 停止
docker compose down
```

### 3.3 自動検証（CI/テスト）

```bash
# Unit + Integration
npm run test

# E2E（コンテナ起動後）
npm run test:e2e
```

---

## 4. ロールバック計画

コンテナ化の変更は全て**新規ファイル追加**または**最小限の既存ファイル修正**で構成される。

| 変更 | ロールバック方法 |
|------|---------------|
| `.devcontainer/devcontainer.json`, `Dockerfile`, `compose.yaml` 等新規ファイル | 削除するだけ |
| `next.config.ts` の `output: "standalone"` | 該当行を削除 |
| `terminal.ts` の `DISABLE_DOCKER_DETECTION` | 該当行を削除（2行のみ） |
| `package.json` の Vitest/Playwright 追加 | `devDependencies` から削除し `npm install` |

**リスク評価**: ロールバックは容易。既存機能への破壊的変更がないため、部分的なロールバックも可能。

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-03-21 | 1.0 | 初版作成 | Copilot |
| 2026-03-21 | 1.1 | 2層ビルド構成に合わせてコンテナ回帰手順・ロールバック計画を更新 | Copilot |
