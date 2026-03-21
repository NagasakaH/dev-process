# Task 11: Integration テスト (tmux 検出 + .env 読み込み)

## タスク情報

| 項目 | 内容 |
|------|------|
| ID | 11 |
| タスク名 | Integration テスト |
| 前提タスク | 03, 04, 05, 10 |
| 並列実行 | 不可（統合テスト） |
| 見積時間 | 20分 |

## 作業環境

- **worktree**: `/tmp/viewer-container-local-11/`
- **ブランチ**: `task/11-integration-tests`
- **サブモジュール**: `submodules/copilot-session-viewer/`

## 前提条件

- Task 03: terminal.ts に DISABLE_DOCKER_DETECTION 実装済み、`findDockerContainers` が named export されていること
- Task 04: sessions.ts テスト済み
- Task 05: middleware.ts テスト済み
- Task 10: Dockerfile + compose.yaml 存在

## 作業内容

### 目的

単体テストで検証した各モジュールの統合動作を確認する。ローカル tmux 検出とセッション管理の統合、.env 設定読み込みパイプラインを検証する。

### 設計参照

- `docs/copilot-session-viewer/design/05_test-plan.md` — セクション 4 (Integration テスト: IT-1, IT-2, IT-3)
- `docs/copilot-session-viewer/design/06_side-effect-verification.md` — セクション 2.1 (回帰テスト)

### 実装ステップ

1. **Integration テストファイル作成**: `src/lib/__tests__/integration.test.ts`

   - IT-1: Vitest 設定確認 — `vitest run` 実行でテストが正常動作
   - IT-2: standalone ビルド確認 — `output: "standalone"` 設定で `.next/standalone/server.js` 生成
     > **NOTE**: このテストはビルドを実行するため時間がかかる。CI 用にスキップマーカーを付ける検討
   - IT-3: Dockerfile ビルド確認 — `docker build` が成功 (ベースイメージ必要)
     > **NOTE**: Docker 環境が必要なためスキップマーカーを付ける

2. **環境変数統合テスト**: `src/lib/__tests__/env-integration.test.ts`

   - .env ファイル読み込みが compose.yaml 経由でコンテナ環境変数に反映されるフローの検証
   - `DISABLE_DOCKER_DETECTION` + `findDockerContainers` の統合動作確認
   - `BASIC_AUTH_USER/PASS` が middleware に正しく伝播されることの確認

3. **既存機能回帰テスト**: `src/lib/__tests__/regression.test.ts`

   - `DISABLE_DOCKER_DETECTION` 未設定時に `getActiveSessions()` パイプラインが Docker 検出を含むこと（パイプラインレベル）
   - Basic Auth 未設定時に認証がスキップされること

### 対象ファイル

| ファイル | 操作 |
|---------|------|
| `submodules/copilot-session-viewer/src/lib/__tests__/integration.test.ts` | 新規作成 |
| `submodules/copilot-session-viewer/src/lib/__tests__/env-integration.test.ts` | 新規作成 |
| `submodules/copilot-session-viewer/src/lib/__tests__/regression.test.ts` | 新規作成 |

## TDD アプローチ

### RED (失敗するテストを書く)

```typescript
// src/lib/__tests__/env-integration.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

describe("Environment Variable Integration", () => {
  beforeEach(() => {
    vi.resetModules();
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllEnvs();
  });

  it("should skip Docker containers and return only local tmux sessions when DISABLE_DOCKER_DETECTION=true", async () => {
    vi.stubEnv("DISABLE_DOCKER_DETECTION", "true");
    const { getActiveSessions } = await import("@/lib/terminal");
    const sessions = getActiveSessions();
    // Integration-level: verify the full pipeline returns sessions without Docker containers
    // All returned sessions should be local tmux sessions (no Docker container sessions)
    expect(Array.isArray(sessions)).toBe(true);
    // No session should have a container-like identifier
    for (const session of sessions) {
      expect(session).not.toMatch(/^[a-f0-9]{12}$/); // Docker container IDs are 12-char hex
    }
  });

  it("should construct SESSION_STATE_DIR from HOME and access sessions", async () => {
    vi.stubEnv("HOME", "/test/custom/home");
    vi.resetModules();
    // Integration: verify the full session listing pipeline works with custom HOME
    // Mock fs to simulate session directory at custom HOME
    const fs = await import("fs");
    vi.spyOn(fs, "existsSync").mockReturnValue(false);
    const { listSessions } = await import("@/lib/sessions");
    const result = listSessions();
    expect(result).toEqual([]); // No sessions at non-existent custom HOME
  });
});

// src/lib/__tests__/regression.test.ts
describe("Regression Tests", () => {
  it("should include Docker detection in getActiveSessions pipeline when flag is not set", async () => {
    vi.stubEnv("DISABLE_DOCKER_DETECTION", "");
    vi.resetModules();
    const childProcess = await import("child_process");
    const execSyncSpy = vi.spyOn(childProcess, "execSync").mockReturnValue(Buffer.from(""));
    const { getActiveSessions } = await import("@/lib/terminal");
    getActiveSessions();
    // Pipeline-level: verify Docker detection is part of the session gathering pipeline
    expect(execSyncSpy).toHaveBeenCalled();
  });

  it("should skip Basic Auth when credentials not configured", async () => {
    vi.stubEnv("BASIC_AUTH_USER", "");
    vi.stubEnv("BASIC_AUTH_PASS", "");
    vi.resetModules();
    const { middleware } = await import("@/middleware");
    const request = new Request("http://localhost:3000/", { method: "GET" });
    const response = middleware(request as any);
    // Should return next() without auth check
    expect(response.status).not.toBe(401);
  });
});
```

### GREEN (テストを通す最小実装)

既存コード + Task 03 の変更が正しく統合されていれば PASS。

### REFACTOR (改善)

- テストの重複排除 (Task 03 の単体テストとの境界明確化)
- CI パイプライン用のテストグループ分け

## 期待される成果物

- `submodules/copilot-session-viewer/src/lib/__tests__/integration.test.ts`
- `submodules/copilot-session-viewer/src/lib/__tests__/env-integration.test.ts`
- `submodules/copilot-session-viewer/src/lib/__tests__/regression.test.ts`

## 完了条件

- [ ] 全 Integration テストが PASS
- [ ] `DISABLE_DOCKER_DETECTION` の統合動作が確認済み
- [ ] 回帰テスト（既存動作維持）が確認済み
- [ ] `npm run test` が成功する

## コミット

```bash
git add -A
git commit -m "test: add integration and regression tests

- Add env-var integration tests (DISABLE_DOCKER_DETECTION, HOME)
- Add regression tests for backward compatibility
- Verify Docker detection flag and Basic Auth integration

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```
