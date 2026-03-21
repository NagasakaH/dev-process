# 03. データ構造設計

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | viewer-container-local |
| タスク名 | container |
| 作成日 | 2026-03-21 |
| 調査結果参照 | [investigation/](../investigation/) |

---

## 1. 方針

既存のデータ構造（TypeScript 型定義、ファイルシステム構造）に変更は不要。  
コンテナ化においては、データの**配置先（パス）**と**永続化方法**のみが変化する。

---

## 2. ファイルシステム構造（コンテナ内）

### 2.1 修正前（ホスト環境）

```
$HOME/.copilot/                      # $HOME = /Users/username (macOS) or /home/username (Linux)
├── session-state/
│   └── {session-id}/
│       ├── workspace.yaml
│       ├── events.jsonl
│       └── inuse.{PID}.lock
├── logs/
│   └── process-{timestamp}-{PID}.log
└── config.json
```

### 2.2 修正後（コンテナ内）

```
/home/node/.copilot/                 # $HOME = /home/node (container user)
├── session-state/                   # Named volume "copilot-data" でマウント
│   └── {session-id}/
│       ├── workspace.yaml
│       ├── events.jsonl
│       └── inuse.{PID}.lock
├── logs/
│   └── process-{timestamp}-{PID}.log
└── config.json
```

### 2.3 変更点サマリー

| 項目 | 修正前 | 修正後 | 理由 |
|------|--------|--------|------|
| `$HOME` | ホストユーザーの HOME | `/home/node` | コンテナ内 node ユーザー |
| データ永続化 | ホスト FS | Named volume `copilot-data` | コンテナ再起動後もデータ保持 |
| パス構築 | `process.env.HOME` 依存 | 同一（変更不要） | コンテナ内で自動分離 |
| ロックファイル PID | ホスト PID | コンテナ内 PID | 衝突なし |

---

## 3. 既存型定義（変更不要）

以下の型定義はコンテナ化に伴う変更は不要。

### 3.1 セッションデータ型

```typescript
// sessions.ts — 変更不要
interface SessionMeta {
  id: string;
  cwd: string;
  git_root: string;
  repository: string;
  branch: string;
  host_type: string;
  summary: string;
  summary_count: number;
  created_at: string;
  updated_at: string;
}
```

### 3.2 アクティブセッション型

```typescript
// terminal.ts — 変更不要
interface ActiveSession {
  id: string;
  summary?: string;
  cwd?: string;
  repository?: string;
  branch?: string;
  lastActivity: string;
  pid?: number;
  tty?: string;
  tmuxPane?: string;
  containerId?: string;      // コンテナ内では常に undefined
  containerUser?: string;    // コンテナ内では常に undefined
  // ... 以下略
}
```

**コンテナ内の動作**: `containerId` と `containerUser` は `DISABLE_DOCKER_DETECTION=true` の場合、
Docker 検出がスキップされるため常に `undefined` になる。ローカル tmux セッションの `pid`、`tty`、
`tmuxPane` のみが使用される。

---

## 4. 新規設定データ構造

### 4.1 compose.yaml ボリューム定義

```yaml
# compose.yaml
volumes:
  copilot-data:
    # Docker managed named volume
    # Default driver: local
    # Mount target: /home/node/.copilot
```

### 4.2 .env ファイル構造

```bash
# Required
GITHUB_TOKEN=ghp_...

# Authentication (optional)
BASIC_AUTH_USER=
BASIC_AUTH_PASS=

# Container behavior
DISABLE_DOCKER_DETECTION=true
ENABLE_DEV_PROCESS=false
PORT=3000
PROJECT_NAME=viewer
```

---

## 5. Next.js standalone 出力構造

### 5.1 ビルド出力（`output: "standalone"`）

```
.next/
├── standalone/
│   ├── server.js            # Standalone server entry point
│   ├── node_modules/        # Pruned production dependencies
│   ├── package.json
│   └── .next/
│       └── server/          # Server-side bundles
├── static/                  # Static assets (CSS, JS, images)
│   ├── chunks/
│   ├── css/
│   └── media/
└── ...
```

### 5.2 Dockerfile でのコピー

```dockerfile
# Standalone server
COPY --from=builder /app/.next/standalone ./
# Static assets (standalone に含まれない)
COPY --from=builder /app/.next/static ./.next/static
# Public assets
COPY --from=builder /app/public ./public
```

---

## 6. テスト設定データ構造

### 6.1 vitest.config.ts

```typescript
import { defineConfig } from "vitest/config";
import path from "path";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    include: ["src/**/__tests__/**/*.test.ts"],
    exclude: ["e2e/**"],
    coverage: {
      provider: "v8",
      include: ["src/lib/**"],
    },
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
});
```

### 6.2 playwright.config.ts

```typescript
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  timeout: 30000,
  use: {
    baseURL: `http://localhost:${process.env.PORT || 3000}`,
    headless: true,
  },
  webServer: {
    command: "node .next/standalone/server.js",
    port: Number(process.env.PORT) || 3000,
    reuseExistingServer: true,
    timeout: 120000,
    env: {
      NODE_ENV: "production",
      HOSTNAME: "0.0.0.0",
    },
  },
});
```

---

## 7. ディレクトリ構造（変更後）

```
copilot-session-viewer/
├── Dockerfile                          # NEW: マルチステージビルド
├── compose.yaml                        # NEW: コンテナ起動設定
├── .dockerignore                       # NEW: ビルドコンテキスト除外
├── .env.example                        # NEW: 環境変数テンプレート
├── vitest.config.ts                    # NEW: Vitest 設定
├── playwright.config.ts                # NEW: Playwright 設定
├── scripts/
│   ├── start-viewer.sh                 # NEW: エントリポイント
│   └── cplt                            # NEW: Copilot CLI ラッパー
├── e2e/
│   └── container-startup.spec.ts       # NEW: E2E テスト
├── src/
│   ├── lib/
│   │   ├── __tests__/
│   │   │   ├── terminal.test.ts        # NEW: 単体テスト
│   │   │   └── sessions.test.ts        # NEW: 単体テスト
│   │   ├── sessions.ts                 # 変更なし
│   │   └── terminal.ts                 # 修正: DISABLE_DOCKER_DETECTION 追加
│   ├── middleware.ts                   # 変更なし
│   └── app/                            # 変更なし
├── next.config.ts                      # 修正: output: "standalone" 追加
├── package.json                        # 修正: Vitest/Playwright 追加
└── tsconfig.json                       # 変更なし
```

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-03-21 | 1.0 | 初版作成 | Copilot |
