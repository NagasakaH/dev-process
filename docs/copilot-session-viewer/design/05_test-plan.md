# 05. テスト計画

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | viewer-container-local |
| タスク名 | container |
| 作成日 | 2026-03-21 |
| 調査結果参照 | [investigation/](../investigation/) |

---

## 1. テスト方針

### 1.1 テストスコープ（brainstorming.test_strategy 準拠）

| 種別 | フレームワーク | 対象 |
|------|--------------|------|
| Unit | Vitest | セッション検出ロジック、Docker 検出無効化、認証設定注入 |
| Integration | Vitest | ローカル tmux 検出 + セッション管理の統合、.env 設定読み込み |
| E2E | Playwright | コンテナ起動 → viewer 起動 → tmux 確認 → 認証確認 |

### 1.2 テスト実行コマンド

```bash
# Unit + Integration
npm run test              # vitest run
npm run test:watch        # vitest (watch mode)
npm run test:coverage     # vitest run --coverage

# E2E
npm run test:e2e          # playwright test
npm run test:e2e:ui       # playwright test --ui (デバッグ用)
```

### 1.3 package.json スクリプト追加

```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui"
  }
}
```

---

## 2. acceptance_criteria とテスト種別の対応表

| acceptance_criteria | テスト種別 | テストNo |
|---------------------|----------|---------|
| コンテナ起動で Copilot CLI 実行環境・viewer・tmux が利用可能 | E2E | E2E-1, E2E-2 |
| tmux セッションが予期せず終了しない | E2E | E2E-3 |
| .env から PAT を含む認証設定を供給できる | Unit + E2E | UT-5, UT-6, E2E-4 |
| $HOME/.copilot がコンテナごとに分離 | Unit | UT-3 |
| Unit/Integration/E2E テストが実行可能 | Integration | IT-1 |

---

## 3. 単体テスト

### 3.1 terminal.ts テスト

| No | テスト対象 | テスト内容 | 期待結果 |
|----|-----------|-----------|---------|
| UT-1 | `findDockerContainers()` | `DISABLE_DOCKER_DETECTION=true` 設定時 | 空配列 `[]` を返却 |
| UT-2 | `findDockerContainers()` | `DISABLE_DOCKER_DETECTION` 未設定時 | execSync を呼び出す（モック検証） |
| UT-3 | `SESSION_STATE_DIR` | `process.env.HOME` 変更時のパス構築 | `{HOME}/.copilot/session-state` |
| UT-4 | `findContainerCopilotSessions()` | Docker 検出無効時 | 空配列 `[]`（`findDockerContainers` が空のため） |

### 3.2 sessions.ts テスト

| No | テスト対象 | テスト内容 | 期待結果 |
|----|-----------|-----------|---------|
| UT-5 | `listSessions()` | セッションディレクトリが空の場合 | 空配列 `[]` |
| UT-6 | `listSessions()` | workspace.yaml が存在するセッション | `SessionMeta` オブジェクトを返却 |
| UT-7 | `getSessionDetail()` | events.jsonl パース | 正しい `SessionDetail` を構築 |
| UT-8 | `getSessionDetail()` | 壊れた JSONL 行をスキップ | エラーなしでパース完了 |

### 3.3 middleware.ts テスト

| No | テスト対象 | テスト内容 | 期待結果 |
|----|-----------|-----------|---------|
| UT-9 | `middleware()` | `BASIC_AUTH_USER/PASS` 未設定時 | `NextResponse.next()` (認証スキップ) |
| UT-10 | `middleware()` | 正しい Basic Auth ヘッダー | `NextResponse.next()` |
| UT-11 | `middleware()` | 不正な Basic Auth ヘッダー | 401 レスポンス |

### 3.4 テスト実装例

```typescript
// src/lib/__tests__/terminal.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

describe("findDockerContainers", () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv };
  });

  afterEach(() => {
    process.env = originalEnv;
    vi.restoreAllMocks();
  });

  it("should return empty array when DISABLE_DOCKER_DETECTION=true", () => {
    process.env.DISABLE_DOCKER_DETECTION = "true";
    // Re-import to pick up env change or test the exported function
    // ... implementation depends on module structure
  });
});
```

---

## 4. Integration テスト

| No | テスト対象 | テスト内容 | 期待結果 |
|----|-----------|-----------|---------|
| IT-1 | Vitest 設定 | `vitest run` 実行 | テストが正常に実行される |
| IT-2 | next.config.ts | `output: "standalone"` でビルド | `.next/standalone/server.js` が生成される |
| IT-3 | Dockerfile | `docker build`（アプリ層）完了 | イメージビルド成功（要 `copilot-session-viewer:base` ） |

---

## 5. E2E テスト

### 5.1 テストシナリオ

| No | テストシナリオ | 手順 | 期待結果 |
|----|-------------|------|---------|
| E2E-1 | コンテナ起動確認 | 1. `docker compose up -d` 2. ヘルスチェック | HTTP 200 応答 |
| E2E-2 | tmux セッション確認 | 1. コンテナ起動 2. `docker exec ... tmux list-sessions` | viewer セッション存在 |
| E2E-3 | tmux 安定性 | 1. コンテナ起動 2. 30秒待機 3. tmux 再確認 | セッション維持 |
| E2E-4 | Basic Auth 動作確認 | 1. .env に BASIC_AUTH 設定 2. 認証なしアクセス | 401 レスポンス |
| E2E-5 | セッション一覧表示 | 1. コンテナ起動 2. ブラウザでトップページ | ページ正常表示 |

### 5.2 E2E テスト実装例

```typescript
// e2e/container-startup.spec.ts
import { test, expect } from "@playwright/test";

test.describe("Container Startup", () => {
  test("viewer should be accessible", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveTitle(/Copilot Session Viewer/i);
  });

  test("sessions API should respond", async ({ request }) => {
    const response = await request.get("/api/sessions");
    expect(response.ok()).toBeTruthy();
  });

  test("active sessions API should respond", async ({ request }) => {
    const response = await request.get("/api/active-sessions");
    expect(response.ok()).toBeTruthy();
    const data = await response.json();
    expect(Array.isArray(data)).toBeTruthy();
  });
});
```

### 5.3 E2E 実行環境

- **実行場所**: Docker コンテナ内
- **ブラウザ**: Chromium (headless)
- **前提条件**: コンテナが起動済み、Next.js サーバーが応答可能
- **環境変数**: `DISABLE_DOCKER_DETECTION=true`, `ENABLE_DEV_PROCESS=false`

---

## 6. テストデータ設計

### 6.1 モックデータ

```typescript
// src/lib/__tests__/fixtures/session-data.ts
export const mockWorkspaceYaml = `
cwd: "/workspace/project"
git_root: "/workspace/project"
repository: "org/project"
branch: "main"
host_type: "cli"
`;

export const mockEventsJsonl = [
  '{"type":"session.init","id":"evt-1","timestamp":"2024-01-01T00:00:00Z","parentId":null,"data":{}}',
  '{"type":"user.message","id":"evt-2","timestamp":"2024-01-01T00:01:00Z","parentId":"evt-1","data":{"content":"Hello"}}',
].join("\n");
```

### 6.2 テスト用ファイルシステム

Unit テストでは `vi.spyOn(fs, ...)` でファイルシステムをモック。
Integration テストでは一時ディレクトリに実ファイルを作成。

---

## 7. 既存テスト修正

既存テストファイルは 0 件のため、修正対象なし。

---

## 8. テストカバレッジ目標

| 対象 | 目標カバレッジ | 備考 |
|------|-------------|------|
| `src/lib/terminal.ts` | 60%+ | Docker 検出無効化パス中心 |
| `src/lib/sessions.ts` | 60%+ | パース処理中心 |
| `src/middleware.ts` | 80%+ | 認証ロジック全パス |
| 全体 | 50%+ | 初回導入のため段階的に向上 |

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-03-21 | 1.0 | 初版作成 | Copilot |
| 2026-03-21 | 1.1 | IT-3 を2層ビルド構成に合わせて更新 | Copilot |
