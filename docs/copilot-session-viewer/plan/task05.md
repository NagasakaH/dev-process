# Task 05: middleware.ts 単体テスト

## タスク情報

| 項目 | 内容 |
|------|------|
| ID | 05 |
| タスク名 | middleware.ts 単体テスト |
| 前提タスク | 01 |
| 並列実行 | P2-A (03, 04, 06 と並列可) |
| 見積時間 | 10分 |

## 作業環境

- **worktree**: `/tmp/viewer-container-local-05/`
- **ブランチ**: `task/05-middleware-unit-tests`
- **サブモジュール**: `submodules/copilot-session-viewer/`

## 前提条件

- Task 01 の成果物 (Vitest 設定) が cherry-pick 済み

## 作業内容

### 目的

`middleware.ts` の Basic Auth ロジックの全パス（認証無効・認証成功・認証失敗）をテストする。カバレッジ 80%+ を目標とする。

### 設計参照

- `docs/copilot-session-viewer/design/05_test-plan.md` — セクション 3.3 (UT-9, UT-10, UT-11)
- `docs/copilot-session-viewer/design/02_interface-api-design.md` — セクション 6.2 (Basic Auth 環境変数)

### 実装ステップ

1. **単体テスト作成**: `src/__tests__/middleware.test.ts`
   - UT-9: `BASIC_AUTH_USER/PASS` 未設定時 → `NextResponse.next()` (認証スキップ)
   - UT-10: 正しい Basic Auth ヘッダー → `NextResponse.next()`
   - UT-11: 不正な Basic Auth ヘッダー → 401 レスポンス

2. **NextRequest モック**: Vitest で `NextRequest` と `NextResponse` をモックまたは直接構築

### 対象ファイル

| ファイル | 操作 |
|---------|------|
| `submodules/copilot-session-viewer/src/__tests__/middleware.test.ts` | 新規作成 |

## TDD アプローチ

### RED (失敗するテストを書く)

```typescript
// src/__tests__/middleware.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

describe("middleware", () => {
  beforeEach(() => {
    vi.resetModules();
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllEnvs();
  });

  it("UT-9: should skip auth when BASIC_AUTH_USER/PASS not set", async () => {
    vi.stubEnv("BASIC_AUTH_USER", "");
    vi.stubEnv("BASIC_AUTH_PASS", "");

    const { middleware } = await import("@/middleware");
    const request = new Request("http://localhost:3000/", {
      method: "GET",
    });
    // NextRequest wrapping may be needed
    const response = middleware(request as any);
    // Expect next() behavior (no 401)
    expect(response.status).not.toBe(401);
  });

  it("UT-10: should allow request with correct Basic Auth", async () => {
    vi.stubEnv("BASIC_AUTH_USER", "admin");
    vi.stubEnv("BASIC_AUTH_PASS", "secret");

    const { middleware } = await import("@/middleware");
    const encoded = btoa("admin:secret");
    const request = new Request("http://localhost:3000/", {
      method: "GET",
      headers: { Authorization: `Basic ${encoded}` },
    });
    const response = middleware(request as any);
    expect(response.status).not.toBe(401);
  });

  it("UT-11: should return 401 with incorrect Basic Auth", async () => {
    vi.stubEnv("BASIC_AUTH_USER", "admin");
    vi.stubEnv("BASIC_AUTH_PASS", "secret");

    const { middleware } = await import("@/middleware");
    const encoded = btoa("admin:wrong");
    const request = new Request("http://localhost:3000/", {
      method: "GET",
      headers: { Authorization: `Basic ${encoded}` },
    });
    const response = middleware(request as any);
    expect(response.status).toBe(401);
  });
});
```

### GREEN (テストを通す最小実装)

middleware.ts は既存コードのため変更不要。テストが正しく動作し PASS する状態にする。

> **NOTE**: Next.js の `NextRequest` / `NextResponse` は Edge Runtime API。Vitest の `environment: "node"` で直接使用できない場合、`next/server` のモックまたは `Request`/`Response` Web API を使用して検証する。

### REFACTOR (改善)

- NextRequest/NextResponse のモックヘルパーを共通化
- エッジケース追加（scheme が Basic でない場合等）

## 期待される成果物

- `submodules/copilot-session-viewer/src/__tests__/middleware.test.ts`

## 完了条件

- [ ] UT-9, UT-10, UT-11 の全テストが PASS
- [ ] `npm run test` が成功する
- [ ] middleware.ts のカバレッジが 80%+ を目標

## コミット

```bash
git add -A
git commit -m "test: add middleware.ts Basic Auth unit tests (UT-9 to UT-11)

- Test auth skip when credentials not configured
- Test successful Basic Auth with correct credentials
- Test 401 response with incorrect credentials

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```
