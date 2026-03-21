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
      args:
        BASE_IMAGE: copilot-session-viewer:base
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
    depends_on:
      base-build:
        condition: service_completed_successfully

  base-build:
    image: copilot-session-viewer:base
    build:
      context: .devcontainer
      dockerfile: devcontainer-build.Dockerfile
    # ビルド専用サービス。実行はしない
    command: ["true"]
    profiles:
      - build

volumes:
  copilot-data:
```

> **NOTE**: ベースイメージのビルドは `devcontainer build` CLI または compose の `base-build` サービスで行う。
> 実運用では `devcontainer build --workspace-folder . --image-name copilot-session-viewer:base` を推奨。

### 3.2 ポートマッピング

| コンテナポート | ホストポート | プロトコル | 用途 |
|---------------|-------------|-----------|------|
| 3000 | ${PORT:-3000} | HTTP | Next.js (Session Viewer) |

### 3.3 ボリュームマウント

| タイプ | コンテナパス | 用途 |
|--------|-------------|------|
| Named volume | `/home/node/.copilot` | Copilot セッションデータ永続化 |

---

## 4. devcontainer.json インターフェース（Layer 1: ベースイメージ）

### 4.1 `.devcontainer/devcontainer.json`

```json
{
  "name": "Copilot Session Viewer Base",
  "image": "mcr.microsoft.com/devcontainers/javascript-node:22",
  "features": {
    "ghcr.io/devcontainers/features/git:1": {},
    "ghcr.io/devcontainers/features/github-cli:1": {},
    "ghcr.io/devcontainers/features/copilot-cli:1": {},
    "ghcr.io/schlich/devcontainer-features/playwright:0": {},
    "ghcr.io/devcontainers-extra/features/tmux-apt-get:1": {},
    "ghcr.io/jungaretti/features/ripgrep:1": {}
  }
}
```

### 4.2 features 一覧と用途

| Feature | 用途 | 必須/推奨 |
|---------|------|----------|
| `git:1` | セッション情報取得、リポジトリ操作 | 推奨 |
| `github-cli:1` | GitHub 認証、API アクセス | 推奨 |
| `copilot-cli:1` | Copilot CLI セッション実行環境 | 必須 |
| `playwright:0` | E2E テスト実行時のブラウザ依存関係 | 推奨 |
| `tmux-apt-get:1` | tmux 基本インストール（3.6a へのアップグレードはアプリ層で実施） | 必須 |
| `ripgrep:1` | テキスト検索（Copilot CLI が使用） | 推奨 |

### 4.3 ベースイメージビルドコマンド

```bash
# devcontainer CLI でベースイメージをビルド
devcontainer build \
  --workspace-folder . \
  --image-name copilot-session-viewer:base

# または npx 経由
npx @devcontainers/cli build \
  --workspace-folder . \
  --image-name copilot-session-viewer:base
```

---

## 5. Dockerfile インターフェース（Layer 2: アプリ層）

### 5.1 ビルド引数

| ARG | デフォルト | 説明 |
|-----|----------|------|
| `BASE_IMAGE` | `copilot-session-viewer:base` | ベースイメージ名 |

### 5.2 環境変数（ビルド時）

| ENV | 値 | 説明 |
|-----|-----|------|
| `NEXT_TELEMETRY_DISABLED` | `1` | Next.js テレメトリ無効化 |

### 5.3 公開ポート

| EXPOSE | プロトコル | 用途 |
|--------|-----------|------|
| 3000 | TCP | Next.js サーバー |

### 5.4 エントリポイント

```dockerfile
ARG BASE_IMAGE=copilot-session-viewer:base
FROM ${BASE_IMAGE}

# Install tini for proper PID 1 zombie reaping
RUN apt-get update && apt-get install -y --no-install-recommends tini && rm -rf /var/lib/apt/lists/*

# Build tmux 3.6a from source (upgrade from apt version)
RUN apt-get update && apt-get install -y --no-install-recommends \
      libevent-dev ncurses-dev build-essential bison pkg-config \
    && cd /tmp \
    && curl -fsSL https://github.com/tmux/tmux/releases/download/3.6a/tmux-3.6a.tar.gz | tar xz \
    && cd tmux-3.6a \
    && ./configure && make -j$(nproc) && make install \
    && cd / && rm -rf /tmp/tmux-3.6a \
    && apt-get purge -y build-essential bison && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Copy Next.js standalone build artifacts
COPY .next/standalone ./app/
COPY .next/static ./app/.next/static
COPY public ./app/public

# Copy entrypoint and tools
COPY scripts/start-viewer.sh /usr/local/bin/start-viewer
COPY scripts/cplt /usr/local/bin/cplt
RUN chmod +x /usr/local/bin/start-viewer /usr/local/bin/cplt

ENTRYPOINT ["tini", "--"]
CMD ["start-viewer"]
```

---

## 6. 環境変数インターフェース (.env)

### 6.1 必須変数

| 変数名 | 説明 | 例 |
|--------|------|-----|
| `GITHUB_TOKEN` | GitHub Personal Access Token (Copilot CLI 認証) | `ghp_xxxx...` |

### 6.2 任意変数（認証）

| 変数名 | デフォルト | 説明 |
|--------|----------|------|
| `BASIC_AUTH_USER` | (空 = 認証無効) | Basic Auth ユーザー名 |
| `BASIC_AUTH_PASS` | (空 = 認証無効) | Basic Auth パスワード |

### 6.3 任意変数（コンテナ動作制御）

| 変数名 | デフォルト | 説明 |
|--------|----------|------|
| `DISABLE_DOCKER_DETECTION` | `false` | Docker コンテナ検出を無効化 |
| `ENABLE_DEV_PROCESS` | `false` | dev-process API を有効化 |
| `PORT` | `3000` | Next.js リスニングポート |
| `PROJECT_NAME` | `viewer` | tmux セッション名 |
| `HOSTNAME` | `0.0.0.0` | Next.js バインドアドレス |

### 6.4 .env.example

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

## 7. 既存 API ルート（変更不要）

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
| 2026-03-21 | 1.1 | devcontainer.json 設計追加、Dockerfile を2層構成に変更、compose.yaml 更新 | Copilot |
