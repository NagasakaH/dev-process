# Task 03: terminal.ts DISABLE_DOCKER_DETECTION + 単体テスト

## タスク情報

| 項目 | 内容 |
|------|------|
| ID | 03 |
| タスク名 | terminal.ts DISABLE_DOCKER_DETECTION 環境変数サポート |
| 前提タスク | 01 |
| 並列実行 | P2-A (04, 05, 06 と並列可) |
| 見積時間 | 15分 |

## 作業環境

- **worktree**: `/tmp/viewer-container-local-03/`
- **ブランチ**: `task/03-disable-docker-detection`
- **サブモジュール**: `submodules/copilot-session-viewer/`

## 前提条件

- Task 01 の成果物 (Vitest 設定) が cherry-pick 済み

## 作業内容

### 目的

`terminal.ts` に `DISABLE_DOCKER_DETECTION` 環境変数フラグを追加し、コンテナ内で Docker 検出をスキップしてローカル tmux セッションのみを使用する動作を実現する。

### 設計参照

- `docs/copilot-session-viewer/design/02_interface-api-design.md` — セクション 1.1 (terminal.ts Docker 検出無効化フラグ)
- `docs/copilot-session-viewer/design/05_test-plan.md` — セクション 3.1 (UT-1, UT-2, UT-3, UT-4)
- `docs/copilot-session-viewer/design/04_process-flow-design.md` — セクション 3 (セッション検出フロー)

### 実装ステップ

1. **`terminal.ts` にモジュールスコープ定数を追加** (L6 あたり、SESSION_STATE_DIR の前後)
   ```typescript
   const DISABLE_DOCKER_DETECTION =
     process.env.DISABLE_DOCKER_DETECTION?.trim() === "true";
   ```

2. **`findDockerContainers()` に早期リターンを追加** (L126 あたり)
   ```typescript
   function findDockerContainers(): string[] {
     if (DISABLE_DOCKER_DETECTION) return [];
     // ... 既存コード
   }
   ```

3. **単体テストを作成**: `src/lib/__tests__/terminal.test.ts`
   - UT-1: `DISABLE_DOCKER_DETECTION=true` で `findDockerContainers()` が空配列
   - UT-2: `DISABLE_DOCKER_DETECTION` 未設定時に execSync を呼び出す
   - UT-3: `SESSION_STATE_DIR` パス構築
   - UT-4: Docker 検出無効時に `findContainerCopilotSessions()` が空配列

### 対象ファイル

| ファイル | 操作 |
|---------|------|
| `submodules/copilot-session-viewer/src/lib/terminal.ts` | 修正 |
| `submodules/copilot-session-viewer/src/lib/__tests__/terminal.test.ts` | 新規作成 |

## TDD アプローチ

### RED (失敗するテストを書く)

```typescript
// src/lib/__tests__/terminal.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

describe("findDockerContainers", () => {
  beforeEach(() => {
    vi.resetModules();
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllEnvs();
  });

  it("UT-1: should return empty array when DISABLE_DOCKER_DETECTION=true", async () => {
    vi.stubEnv("DISABLE_DOCKER_DETECTION", "true");
    const mod = await import("@/lib/terminal");
    // findDockerContainers is not exported, but we can test via getActiveSessions
    // or we need to export it for testing
    // Alternative: test indirectly via getActiveSessions behavior
    expect(mod).toBeDefined();
  });

  it("UT-2: should call execSync when DISABLE_DOCKER_DETECTION is not set", async () => {
    vi.stubEnv("DISABLE_DOCKER_DETECTION", "");
    const mod = await import("@/lib/terminal");
    expect(mod).toBeDefined();
  });
});

describe("SESSION_STATE_DIR", () => {
  it("UT-3: should construct path from HOME env var", async () => {
    vi.stubEnv("HOME", "/test/home");
    vi.resetModules();
    // After re-import, SESSION_STATE_DIR should use /test/home
    // Test via exported functions that use it
  });
});
```

`npm run test` → `DISABLE_DOCKER_DETECTION` 定数が存在しないため、テストの期待動作と一致しない。

### GREEN (テストを通す最小実装)

1. `terminal.ts` の先頭（SESSION_STATE_DIR 付近）に `DISABLE_DOCKER_DETECTION` 定数を追加
2. `findDockerContainers()` の先頭に `if (DISABLE_DOCKER_DETECTION) return [];` を追加
3. テストで `findDockerContainers` を直接テストするため、関数をエクスポートするか、間接的にテスト

> **NOTE (MRD-009)**: `DISABLE_DOCKER_DETECTION` はモジュールスコープの `const` で評価される。テスト間で値を切り替えるには `vi.resetModules()` + `await import()` による動的インポートが必須。

### REFACTOR (改善)

- テストヘルパーの共通化 (resetModules + stubEnv パターン)
- 不要な export が増えた場合の整理

## 期待される成果物

- `submodules/copilot-session-viewer/src/lib/terminal.ts` (修正済)
- `submodules/copilot-session-viewer/src/lib/__tests__/terminal.test.ts` (新規)

## 完了条件

- [ ] `DISABLE_DOCKER_DETECTION=true` で `findDockerContainers()` が空配列を返す
- [ ] `DISABLE_DOCKER_DETECTION` 未設定時に従来動作が維持される
- [ ] UT-1, UT-2, UT-3, UT-4 の全テストが PASS
- [ ] `npm run test` が成功する
- [ ] `npm run lint` が新規エラーを出さない

## コミット

```bash
git add -A
git commit -m "feat: add DISABLE_DOCKER_DETECTION env var to terminal.ts

- Add module-scope DISABLE_DOCKER_DETECTION constant
- Skip Docker container detection when flag is true
- Add unit tests (UT-1 to UT-4) with vi.resetModules() pattern

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```
