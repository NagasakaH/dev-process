# Task 04: sessions.ts 単体テスト

## タスク情報

| 項目 | 内容 |
|------|------|
| ID | 04 |
| タスク名 | sessions.ts 単体テスト |
| 前提タスク | 01 |
| 並列実行 | P2-A (03, 05, 06 と並列可) |
| 見積時間 | 15分 |

## 作業環境

- **worktree**: `/tmp/viewer-container-local-04/`
- **ブランチ**: `task/04-sessions-unit-tests`
- **サブモジュール**: `submodules/copilot-session-viewer/`

## 前提条件

- Task 01 の成果物 (Vitest 設定) が cherry-pick 済み

## 作業内容

### 目的

`sessions.ts` のセッション一覧取得・詳細取得ロジックの単体テストを作成する。ファイルシステム操作をモックし、パース処理の正確性を検証する。

### 設計参照

- `docs/copilot-session-viewer/design/05_test-plan.md` — セクション 3.2 (UT-5, UT-6, UT-7, UT-8)
- `docs/copilot-session-viewer/design/05_test-plan.md` — セクション 6 (テストデータ設計)

### 実装ステップ

1. **テストフィクスチャ作成**: `src/lib/__tests__/fixtures/session-data.ts`
   ```typescript
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

2. **単体テスト作成**: `src/lib/__tests__/sessions.test.ts`
   - UT-5: `listSessions()` — セッションディレクトリが空の場合 → 空配列
   - UT-6: `listSessions()` — workspace.yaml が存在するセッション → SessionMeta 返却
   - UT-7: `getSessionDetail()` — events.jsonl パース → 正しい SessionDetail 構築
   - UT-8: `getSessionDetail()` — 壊れた JSONL 行 → エラーなしでスキップ

3. **fs モック**: `vi.spyOn(fs, 'readdirSync')`, `vi.spyOn(fs, 'readFileSync')` 等

### 対象ファイル

| ファイル | 操作 |
|---------|------|
| `submodules/copilot-session-viewer/src/lib/__tests__/sessions.test.ts` | 新規作成 |
| `submodules/copilot-session-viewer/src/lib/__tests__/fixtures/session-data.ts` | 新規作成 |

## TDD アプローチ

### RED (失敗するテストを書く)

```typescript
// src/lib/__tests__/sessions.test.ts
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import fs from "fs";

describe("listSessions", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("UT-5: should return empty array when session directory is empty", async () => {
    vi.spyOn(fs, "readdirSync").mockReturnValue([]);
    const { listSessions } = await import("@/lib/sessions");
    const result = listSessions();
    expect(result).toEqual([]);
  });

  it("UT-6: should return SessionMeta when workspace.yaml exists", async () => {
    // Mock fs to return a session directory with workspace.yaml
    vi.spyOn(fs, "readdirSync").mockReturnValue(["session-abc"] as any);
    vi.spyOn(fs, "existsSync").mockReturnValue(true);
    vi.spyOn(fs, "readFileSync").mockReturnValue(mockWorkspaceYaml);
    vi.spyOn(fs, "statSync").mockReturnValue({ mtime: new Date() } as any);
    
    const { listSessions } = await import("@/lib/sessions");
    const result = listSessions();
    expect(result.length).toBeGreaterThan(0);
    expect(result[0].repository).toBe("org/project");
  });
});

describe("getSessionDetail", () => {
  it("UT-7: should parse events.jsonl correctly", async () => {
      vi.spyOn(fs, "readdirSync").mockReturnValue(["session-abc"] as any);
      vi.spyOn(fs, "existsSync").mockReturnValue(true);
      vi.spyOn(fs, "readFileSync").mockReturnValue(mockEventsJsonl);
      vi.spyOn(fs, "statSync").mockReturnValue({ mtime: new Date() } as any);

      const { getSessionDetail } = await import("@/lib/sessions");
      const result = getSessionDetail("session-abc");
      expect(result).toBeDefined();
      expect(result?.events?.length).toBeGreaterThanOrEqual(2);
      expect(result?.events?.[0]?.type).toBe("session.init");
    });

    it("UT-8: should skip broken JSONL lines without error", async () => {
      const brokenJsonl = '{"type":"session.init","id":"evt-1"}\nINVALID_JSON\n{"type":"user.message","id":"evt-2"}';
      vi.spyOn(fs, "readdirSync").mockReturnValue(["session-abc"] as any);
      vi.spyOn(fs, "existsSync").mockReturnValue(true);
      vi.spyOn(fs, "readFileSync").mockReturnValue(brokenJsonl);
      vi.spyOn(fs, "statSync").mockReturnValue({ mtime: new Date() } as any);

      const { getSessionDetail } = await import("@/lib/sessions");
      const result = getSessionDetail("session-abc");
      // Should not throw, and should parse valid lines
      expect(result).toBeDefined();
      expect(result?.events?.length).toBe(2); // only valid lines parsed
    });
});
```

### GREEN (テストを通す最小実装)

sessions.ts は既存コードのため変更不要。テストが正しくモックを使用し PASS する状態にする。

### REFACTOR (改善)

- テストフィクスチャの充実化
- 共通モック設定のヘルパー化

## 期待される成果物

- `submodules/copilot-session-viewer/src/lib/__tests__/sessions.test.ts`
- `submodules/copilot-session-viewer/src/lib/__tests__/fixtures/session-data.ts`

## 完了条件

- [ ] UT-5, UT-6, UT-7, UT-8 の全テストが PASS
- [ ] `npm run test` が成功する
- [ ] テストフィクスチャが適切に分離されている

## コミット

```bash
git add -A
git commit -m "test: add sessions.ts unit tests (UT-5 to UT-8)

- Add listSessions() tests for empty and populated directories
- Add getSessionDetail() tests for JSONL parsing
- Add test fixtures for mock workspace.yaml and events.jsonl

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```
