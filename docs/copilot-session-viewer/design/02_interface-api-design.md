# 02. インターフェース / API 設計

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | viewer-container-local |
| タスク名 | container |
| 作成日 | 2026-03-21 |
| 調査結果参照 | [investigation/](../investigation/) |

---

## 1. 変更が必要な既存インターフェース

### 1.1 terminal.ts — Docker 検出無効化フラグ

#### 修正前

```typescript
function findDockerContainers(): string[] {
  try {
    const output = execSync(
      "docker ps --format '{{.ID}}' 2>/dev/null",
      { encoding: "utf-8", timeout: 5000 }
    ).trim();
    if (!output) return [];
    return output.split("\n").filter(Boolean);
  } catch {
    return [];
  }
}
```

#### 修正後

```typescript
const DISABLE_DOCKER_DETECTION =
  process.env.DISABLE_DOCKER_DETECTION?.trim() === "true";

function findDockerContainers(): string[] {
  if (DISABLE_DOCKER_DETECTION) return [];
  try {
    const output = execSync(
      "docker ps --format '{{.ID}}' 2>/dev/null",
      { encoding: "utf-8", timeout: 5000 }
    ).trim();
    if (!output) return [];
    return output.split("\n").filter(Boolean);
  } catch {
    return [];
  }
}
```

**影響範囲**:
- `findDockerContainers()` → 空配列を返却
- `findContainerCopilotSessions()` → `findDockerContainers()` に依存するため自動的に無効化
- `getActiveSessions()` → コンテナセッション部分がスキップされ、ローカル tmux セッションのみ返却

**後方互換性**: `DISABLE_DOCKER_DETECTION` 未設定時は従来通り Docker 検出が有効。既存動作に影響なし。

### 1.2 next.config.ts — standalone 出力

#### 修正前

```typescript
const nextConfig: NextConfig = {
  allowedDevOrigins: ["192.168.1.175"],
};
```

#### 修正後

```typescript
const nextConfig: NextConfig = {
  output: "standalone",
  allowedDevOrigins: ["192.168.1.175"],
};
```

**影響範囲**:
- `next build` の出力先が `.next/standalone/` に変更
- コンテナ内では `node .next/standalone/server.js` で起動可能
- ローカル開発（`npm run dev`）には影響なし

---

## 2. 新規スクリプトインターフェース

### 2.1 scripts/start-viewer.sh

コンテナエントリポイントスクリプト。

```bash
#!/bin/bash
# start-viewer.sh — Container entrypoint for copilot-session-viewer
#
# Environment Variables:
#   PROJECT_NAME    tmux session name (default: "viewer")
#   NODE_ENV        Node.js environment (default: "production")
#   PORT            Next.js listening port (default: 3000)
#   HOSTNAME        Next.js bind address (default: "0.0.0.0")
#
# Behavior:
#   1. UID/GID sync (if running as root)
#   2. Start tmux session with 3 windows:
#      - viewer:  Next.js standalone server
#      - copilot: Interactive shell for Copilot CLI
#      - bash:    General purpose shell
#   3. Keep-alive loop (wait + sleep)
```

**入力**: 環境変数のみ（引数なし）
**出力**: tmux セッション起動、Next.js サーバー起動
**終了条件**: keep-alive ループにより永続実行

### 2.2 scripts/cplt

Copilot CLI ラッパー。dev-process 版をベースに調整。

```bash
#!/bin/bash
# cplt — Copilot CLI wrapper with tmux integration
#
# Options:
#   -r          Resume session (--resume)
#   -n, --no-split  Suppress tmux pane split
#   --debug     Enable debug logging
#
# Behavior:
#   - Auto-split tmux pane if only 1 pane exists (40/60 ratio)
#   - Rename tmux window to "copilot" during execution
#   - Default: copilot --allow-all --agent general-purpose
```

**変更点（dev-process からの差分）**: なし（そのまま流用可能）

---

## 3. compose.yaml インターフェース

### 3.1 サービス定義

```yaml
services:
  viewer:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "${PORT:-3000}:3000"
    volumes:
      - copilot-data:/home/node/.copilot
    env_file:
      - .env
    environment:
      - DISABLE_DOCKER_DETECTION=true
      - ENABLE_DEV_PROCESS=false
      - NODE_ENV=production
    tty: true
    stdin_open: true
    init: false   # tini is baked into the image

volumes:
  copilot-data:
```

### 3.2 ポートマッピング

| コンテナポート | ホストポート | プロトコル | 用途 |
|---------------|-------------|-----------|------|
| 3000 | ${PORT:-3000} | HTTP | Next.js (Session Viewer) |

### 3.3 ボリュームマウント

| タイプ | コンテナパス | 用途 |
|--------|-------------|------|
| Named volume | `/home/node/.copilot` | Copilot セッションデータ永続化 |

---

## 4. Dockerfile インターフェース

### 4.1 ビルド引数

| ARG | デフォルト | 説明 |
|-----|----------|------|
| `NODE_VERSION` | `22` | Node.js メジャーバージョン |

### 4.2 環境変数（ビルド時）

| ENV | 値 | 説明 |
|-----|-----|------|
| `NEXT_TELEMETRY_DISABLED` | `1` | Next.js テレメトリ無効化 |

### 4.3 公開ポート

| EXPOSE | プロトコル | 用途 |
|--------|-----------|------|
| 3000 | TCP | Next.js サーバー |

### 4.4 エントリポイント

```dockerfile
ENTRYPOINT ["tini", "--"]
CMD ["start-viewer"]
```

---

## 5. 環境変数インターフェース (.env)

### 5.1 必須変数

| 変数名 | 説明 | 例 |
|--------|------|-----|
| `GITHUB_TOKEN` | GitHub Personal Access Token (Copilot CLI 認証) | `ghp_xxxx...` |

### 5.2 任意変数（認証）

| 変数名 | デフォルト | 説明 |
|--------|----------|------|
| `BASIC_AUTH_USER` | (空 = 認証無効) | Basic Auth ユーザー名 |
| `BASIC_AUTH_PASS` | (空 = 認証無効) | Basic Auth パスワード |

### 5.3 任意変数（コンテナ動作制御）

| 変数名 | デフォルト | 説明 |
|--------|----------|------|
| `DISABLE_DOCKER_DETECTION` | `false` | Docker コンテナ検出を無効化 |
| `ENABLE_DEV_PROCESS` | `false` | dev-process API を有効化 |
| `PORT` | `3000` | Next.js リスニングポート |
| `PROJECT_NAME` | `viewer` | tmux セッション名 |
| `HOSTNAME` | `0.0.0.0` | Next.js バインドアドレス |

### 5.4 .env.example

```bash
# === Required ===
GITHUB_TOKEN=ghp_your_personal_access_token_here

# === Authentication (optional, omit to disable Basic Auth) ===
# BASIC_AUTH_USER=admin
# BASIC_AUTH_PASS=secret

# === Container Settings (defaults shown, usually no change needed) ===
# DISABLE_DOCKER_DETECTION=true
# ENABLE_DEV_PROCESS=false
# PORT=3000
# PROJECT_NAME=viewer
```

---

## 6. 既存 API ルート（変更不要）

以下の既存 API はコンテナ内でもそのまま動作する。変更不要。

| エンドポイント | メソッド | 動作 |
|---------------|---------|------|
| `/api/sessions` | GET | セッション一覧（`sessions.ts` → `$HOME/.copilot/`） |
| `/api/active-sessions` | GET | アクティブセッション（`terminal.ts` → ローカル tmux のみ） |
| `/api/sessions/[id]` | GET | セッション詳細 |
| `/api/sessions/[id]/respond` | POST | ask_user 応答（ローカル tmux 経由） |
| `/api/sessions/[id]/terminate` | POST | セッション終了 |
| `/api/sessions/[id]/files` | GET | セッションファイル一覧 |
| `/api/sessions/[id]/event-count` | GET | イベント数 |
| `/api/dev-process/start-copilot` | GET/POST/DELETE | dev-process 管理（`ENABLE_DEV_PROCESS=false` で 403 返却） |

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-03-21 | 1.0 | 初版作成 | Copilot |
