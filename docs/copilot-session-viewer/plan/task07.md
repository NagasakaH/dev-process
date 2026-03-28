# タスク: task07 - デプロイ設定 (Dockerfile + scripts)

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task07 |
| タスク名 | デプロイ設定 (Dockerfile + scripts) |
| 前提条件タスク | task04 |
| 並列実行可否 | 可（task06 と並列） |
| 推定所要時間 | 10分 |

## 作業環境

- **作業ディレクトリ（worktree）**: submodules/editable/copilot-session-viewer
- **ブランチ**: feature/tmux-pane-viewer

## 前提条件

- task04 完了（server.js が作成済み）

## 作業内容

### 目的

カスタム `server.js` の導入に伴い、`Dockerfile` と `scripts/start-viewer.sh` を更新し、本番環境で `server.js` 経由でアプリケーションが起動するようにする。

### 設計参照

- `01_implementation-approach.md` §変更ファイル一覧（Dockerfile, start-viewer.sh）
- `06_side-effect-verification.md` §6 カスタム server.js 導入の影響検証

### 実装ステップ

1. **Dockerfile 更新**
   - standalone ビルド成果物の COPY に `server.js` を含める
   - `CMD` を `node server.js` に変更

2. **scripts/start-viewer.sh 更新**
   - `node .next/standalone/server.js` → `node server.js` に変更
   - 環境変数の設定を確認

3. **動作確認**
   - `docker build` が成功すること
   - コンテナ起動時に `server.js` が正しく起動すること

### 対象ファイル

| ファイル | 操作 | 変更内容 |
|----------|------|----------|
| `Dockerfile` | 修正 | server.js の COPY 追加、CMD 変更 |
| `scripts/start-viewer.sh` | 修正 | node server.js 起動に変更 |

## テスト方針（TDD: RED-GREEN-REFACTOR）

### RED: 失敗するテストケース

このタスクは設定変更のため、明示的なテストコードはなし。以下の手動確認を実施:

```bash
# Dockerfile のビルド確認
docker build -t copilot-session-viewer:test .

# コンテナ起動確認
docker run --rm -p 3000:3000 copilot-session-viewer:test

# server.js がリッスンしていることを確認
curl http://localhost:3000/
```

### GREEN: 最小限の実装

**Dockerfile 変更例:**
```dockerfile
# ... existing build stage ...

# standalone ステージに server.js をコピー
COPY server.js ./server.js

# CMD を変更
CMD ["node", "server.js"]
```

**start-viewer.sh 変更例:**
```bash
#!/bin/bash
# ... existing setup ...

# 起動コマンドを変更
exec node server.js
```

### REFACTOR: コード改善

- Dockerfile のレイヤーキャッシュ最適化
- start-viewer.sh のエラーハンドリング

## 完了条件

- [ ] `Dockerfile` が `server.js` を含むイメージをビルド
- [ ] `scripts/start-viewer.sh` が `node server.js` で起動
- [ ] `docker build` が成功
- [ ] 既存の E2E テスト（container-startup.spec.ts）が通過（task08 で確認）
