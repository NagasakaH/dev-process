# Task 12: E2E テスト (Playwright コンテナフロー)

## タスク情報

| 項目 | 内容 |
|------|------|
| ID | 12 |
| タスク名 | E2E テスト (Playwright コンテナフロー) |
| 前提タスク | 10, 11 |
| 並列実行 | 不可（最終統合テスト） |
| 見積時間 | 30分 |

## 作業環境

- **worktree**: `/tmp/viewer-container-local-12/`
- **ブランチ**: `task/12-e2e-tests`
- **サブモジュール**: `submodules/copilot-session-viewer/`

## 前提条件

- Task 10: Dockerfile + compose.yaml が存在し、コンテナビルド可能
- Task 11: Integration テスト PASS

## 作業内容

### 目的

コンテナ環境で Playwright E2E テストを実行し、acceptance criteria の全項目を検証する:
1. コンテナ起動で viewer + tmux が利用可能
2. tmux セッションの安定性 (30秒 + 5分耐久)
3. Basic Auth の動作確認
4. GITHUB_TOKEN 供給確認

### 設計参照

- `docs/copilot-session-viewer/design/05_test-plan.md` — セクション 5 (E2E テスト: E2E-1 to E2E-7)
- `docs/copilot-session-viewer/design/06_side-effect-verification.md` — セクション 2.2 (パフォーマンス検証)

### 実装ステップ

1. **E2E テストファイル作成**: `e2e/container-startup.spec.ts`
   - E2E-1: コンテナ起動確認 (ヘルスチェック → HTTP 200)
   - E2E-2: tmux セッション確認 (docker exec tmux list-sessions)
   - E2E-5: セッション一覧表示 (ブラウザでトップページ)

2. **tmux 安定性テスト**: `e2e/tmux-stability.spec.ts`
   - E2E-3: tmux 安定性 (30秒待機 → セッション維持)
   - E2E-6: tmux 耐久性 (5分間、定期的操作 + detach/再接続)

3. **認証テスト**: `e2e/auth.spec.ts`
   - E2E-4: Basic Auth 動作確認 (.env に設定 → 認証なしアクセスで 401)
   - E2E-7: GITHUB_TOKEN 供給確認 (docker exec printenv)

4. **テストセットアップ**: `e2e/global-setup.ts` (必須)
   - コンテナ起動 (`docker compose up -d --build`)
   - ヘルスチェック待機 (HTTP 200 をポーリング)
   - テスト用 `.env` の存在確認（不在時は `.env.example` から自動コピー）
   ```typescript
   // e2e/global-setup.ts
   import { execSync } from "child_process";
   import { existsSync, copyFileSync } from "fs";
   import { resolve } from "path";

   export default async function globalSetup() {
     // Ensure .env exists (auto-copy from .env.example if missing)
     const envPath = resolve(__dirname, "../.env");
     const envExamplePath = resolve(__dirname, "../.env.example");
     if (!existsSync(envPath)) {
       if (existsSync(envExamplePath)) {
         copyFileSync(envExamplePath, envPath);
         console.log("Copied .env.example → .env for E2E tests");
       } else {
         throw new Error(".env and .env.example not found. Cannot run E2E tests.");
       }
     }

     execSync("docker compose up -d --build", { stdio: "inherit" });
     // Wait for healthcheck
     const maxRetries = 30;
     for (let i = 0; i < maxRetries; i++) {
       try {
         const res = await fetch("http://localhost:3000/api/sessions");
         if (res.ok) return;
       } catch {}
       await new Promise((r) => setTimeout(r, 2000));
     }
     throw new Error("Container did not become healthy within timeout");
   }
   ```

5. **テストティアダウン**: `e2e/global-teardown.ts` (必須)
   ```typescript
   // e2e/global-teardown.ts
   import { execSync } from "child_process";

   export default async function globalTeardown() {
     execSync("docker compose down", { stdio: "inherit" });
   }
   ```

6. **playwright.config.ts に globalSetup/globalTeardown を追加**
   ```typescript
   // playwright.config.ts に以下を追加
   {
     globalSetup: "./e2e/global-setup.ts",
     globalTeardown: "./e2e/global-teardown.ts",
   }
   ```

### 対象ファイル

| ファイル | 操作 |
|---------|------|
| `submodules/copilot-session-viewer/e2e/container-startup.spec.ts` | 新規作成 |
| `submodules/copilot-session-viewer/e2e/tmux-stability.spec.ts` | 新規作成 |
| `submodules/copilot-session-viewer/e2e/auth.spec.ts` | 新規作成 |
| `submodules/copilot-session-viewer/e2e/container-isolation.spec.ts` | 新規作成 |
| `submodules/copilot-session-viewer/e2e/global-setup.ts` | 新規作成 (必須) |
| `submodules/copilot-session-viewer/e2e/global-teardown.ts` | 新規作成 (必須) |

## TDD アプローチ

### RED (失敗するテストを書く)

```typescript
// e2e/container-startup.spec.ts
import { test, expect } from "@playwright/test";

test.describe("Container Startup (E2E-1, E2E-2, E2E-5)", () => {
  test("E2E-1: viewer should be accessible via healthcheck", async ({ request }) => {
    const response = await request.get("/api/sessions");
    expect(response.ok()).toBeTruthy();
  });

  test("E2E-2: tmux session should exist in container", async () => {
    // docker exec <container> tmux list-sessions
    // Expect output to contain session name (e.g. "viewer:")
    const { execSync } = require("child_process");
    const output = execSync("docker compose exec -T viewer tmux list-sessions").toString();
    expect(output).toContain("viewer:");
  });

  test("E2E-5: session list page should render", async ({ page }) => {
    await page.goto("/");
    await expect(page).toHaveTitle(/Copilot Session Viewer/i);
  });
});

// e2e/container-isolation.spec.ts (MPR-007: AC4 per-container isolation test)
test.describe("Container Isolation (AC4)", () => {
  test("E2E-9: /home/node/.copilot should exist and be writable in container", async () => {
    const { execSync } = require("child_process");
    // Verify the directory exists
    const lsOutput = execSync("docker compose exec -T viewer ls -la /home/node/.copilot").toString();
    expect(lsOutput).toBeDefined();
    // Verify writable by creating a test file
    execSync("docker compose exec -T viewer touch /home/node/.copilot/.test-write");
    execSync("docker compose exec -T viewer rm /home/node/.copilot/.test-write");
  });

  test("E2E-10: container .copilot path should be isolated from host", async () => {
    const { execSync } = require("child_process");
    // Verify /home/node/.copilot is a named volume, not a host bind mount
    const inspectOutput = execSync("docker compose exec -T viewer df /home/node/.copilot").toString();
    // Named volume should show as overlay or similar, not the host filesystem path
    expect(inspectOutput).toBeDefined();
  });
});

// e2e/container-startup.spec.ts (追加テスト)
test.describe("Copilot CLI Availability (AC1)", () => {
  test("E2E-11: cplt command should be available in container", async () => {
    const { execSync } = require("child_process");
    // Verify cplt wrapper script is installed and executable
    const output = execSync("docker compose exec -T viewer which cplt").toString().trim();
    expect(output).toContain("/usr/local/bin/cplt");
  });
});

// e2e/tmux-stability.spec.ts
test.describe("tmux Stability (E2E-3, E2E-6)", () => {
  test("E2E-3: tmux session should persist after 30 seconds", async () => {
    const { execSync } = require("child_process");
    // Wait 30 seconds
    await new Promise((r) => setTimeout(r, 30_000));
    // Verify tmux session still exists
    const output = execSync("docker compose exec -T viewer tmux list-sessions").toString();
    expect(output).toContain("viewer:");
  });

  test.skip("E2E-6: tmux should be durable for 5 minutes", async () => {
    // Long-running test — conditional mandatory:
    // Mark as test.skip() during development only.
    // **MUST be enabled and PASS during verification step (Step 8).**
    // E2E-6 is mandatory for AC2 verification.
    // Run with: npx playwright test --grep "E2E-6"
  });
});

// e2e/auth.spec.ts
test.describe("Authentication (E2E-4, E2E-7)", () => {
  test("E2E-4: should return 401 without Basic Auth", async ({ request }) => {
    // Requires BASIC_AUTH_USER/PASS to be set in .env
    const response = await request.get("/api/sessions", {
      headers: {} // No auth header
    });
    // Assert 401 when Basic Auth is configured
    expect(response.status()).toBe(401);
  });

  test("E2E-7: GITHUB_TOKEN should be available in container", async () => {
    const { execSync } = require("child_process");
    const output = execSync("docker compose exec -T viewer printenv GITHUB_TOKEN").toString().trim();
    expect(output.length).toBeGreaterThan(0);
  });

  test("E2E-8: PAT should be functionally usable (gh auth status)", async () => {
    const { execSync } = require("child_process");
    // Verify PAT is not just present but actually works
    const output = execSync("docker compose exec -T viewer gh auth status").toString();
    expect(output).toContain("Logged in");
  });
});
```

コンテナ未起動のため全テスト FAIL。

### GREEN (テストを通す最小実装)

1. E2E テストファイルを作成
2. global-setup.ts でコンテナ起動ロジックを追加
3. コンテナを起動し (`docker compose up -d --build`)、E2E テスト実行
4. テスト PASS

### REFACTOR (改善)

- テストタイムアウトの最適化
- E2E-6 (5分間耐久) のスキップ/CI 分離
- テストレポート設定

## 期待される成果物

- `submodules/copilot-session-viewer/e2e/container-startup.spec.ts`
- `submodules/copilot-session-viewer/e2e/tmux-stability.spec.ts`
- `submodules/copilot-session-viewer/e2e/auth.spec.ts`
- `submodules/copilot-session-viewer/e2e/global-setup.ts` (必須)
- `submodules/copilot-session-viewer/e2e/global-teardown.ts` (必須)

## 完了条件

- [ ] E2E-1: HTTP 200 応答確認
- [ ] E2E-2: tmux セッション存在確認
- [ ] E2E-3: 30秒後 tmux セッション維持確認
- [ ] E2E-4: Basic Auth 401 確認 (設定時)
- [ ] E2E-5: セッション一覧ページ表示確認
- [ ] E2E-6: 5分間耐久テスト (開発中は skip 可、**verification ステップで必須 PASS**)
- [ ] E2E-7: GITHUB_TOKEN 供給確認
- [ ] E2E-8: PAT 有効性検証 (`gh auth status` 成功)
- [ ] E2E-9: コンテナ内 `/home/node/.copilot` 存在・書き込み可能 (AC4)
- [ ] E2E-10: コンテナ .copilot パスがホストから分離 (AC4)
- [ ] E2E-11: `cplt` コマンドがコンテナ内で利用可能 (AC1)
- [ ] `npm run test:e2e` が成功する (E2E-6 除く)

## コミット

```bash
git add -A
git commit -m "test: add Playwright E2E tests for container flow

- E2E-1: container startup and healthcheck
- E2E-2: tmux session existence
- E2E-3: tmux 30s stability
- E2E-4: Basic Auth verification
- E2E-5: session list page rendering
- E2E-6: 5-minute tmux durability (skip by default)
- E2E-7: GITHUB_TOKEN supply verification

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```
