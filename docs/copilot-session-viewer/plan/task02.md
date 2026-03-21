# Task 02: next.config.ts standalone 出力 + .dockerignore

## タスク情報

| 項目 | 内容 |
|------|------|
| ID | 02 |
| タスク名 | next.config.ts standalone 出力 + .dockerignore |
| 前提タスク | 01 |
| 並列実行 | 不可 |
| 見積時間 | 10分 |

## 作業環境

- **worktree**: `/tmp/viewer-container-local-02/`
- **ブランチ**: `task/02-standalone-dockerignore`
- **サブモジュール**: `submodules/copilot-session-viewer/`

## 前提条件

- Task 01 の成果物 (Vitest 設定) が cherry-pick 済み

## 作業内容

### 目的

Next.js のビルド出力を standalone モードに変更し、コンテナ内で `node server.js` による軽量実行を可能にする。また `.dockerignore` を作成してビルドコンテキストを最適化する。

### 設計参照

- `docs/copilot-session-viewer/design/02_interface-api-design.md` — セクション 1.2 (next.config.ts standalone)
- `docs/copilot-session-viewer/design/01_implementation-approach.md` — セクション 3.5 (.dockerignore)
- `docs/copilot-session-viewer/design/03_data-structure-design.md` — セクション 5 (standalone 出力構造)

### 実装ステップ

1. **next.config.ts に `output: "standalone"` を追加**

   修正前:
   ```typescript
   const nextConfig: NextConfig = {
     allowedDevOrigins: ["192.168.1.175"],
   };
   ```

   修正後:
   ```typescript
   const nextConfig: NextConfig = {
     output: "standalone",
     allowedDevOrigins: ["192.168.1.175"],
   };
   ```

2. **.dockerignore を作成**
   ```
   # Secrets
   .env
   .env.*
   !.env.example

   # Dependencies (standalone build に含まれる)
   node_modules

   # Version control
   .git
   .gitignore

   # Test / Development
   e2e/
   docs/
   .devcontainer/
   tests/

   # Documentation
   *.md
   LICENSE

   # Editor / IDE
   .vscode/
   .idea/

   # Build intermediates (standalone 以外)
   .next/cache/
   ```

3. **`npm run build` で standalone 出力を確認**
   - `.next/standalone/server.js` が生成されることを検証

### 対象ファイル

| ファイル | 操作 |
|---------|------|
| `submodules/copilot-session-viewer/next.config.ts` | 修正 |
| `submodules/copilot-session-viewer/.dockerignore` | 新規作成 |

## TDD アプローチ

### RED (失敗するテストを書く)

```typescript
// src/lib/__tests__/standalone-build.test.ts
import { describe, it, expect } from "vitest";
import fs from "fs";
import path from "path";

describe("Next.js standalone build", () => {
  it("next.config.ts should have output: standalone", async () => {
    const configPath = path.resolve(__dirname, "../../../next.config.ts");
    const content = fs.readFileSync(configPath, "utf-8");
    expect(content).toContain('output: "standalone"');
  });
});
```

`npm run test` → `output: "standalone"` が存在しないため FAIL。

### GREEN (テストを通す最小実装)

1. `next.config.ts` に `output: "standalone"` を追加
2. `.dockerignore` を作成
3. テスト再実行 → PASS

### REFACTOR (改善)

- `npm run build` を実行し `.next/standalone/server.js` の存在を確認
- `npm run dev` が引き続き正常に動作することを確認 (回帰確認)

## 期待される成果物

- `submodules/copilot-session-viewer/next.config.ts` (修正済)
- `submodules/copilot-session-viewer/.dockerignore` (新規)
- `submodules/copilot-session-viewer/src/lib/__tests__/standalone-build.test.ts`

## 完了条件

- [ ] `next.config.ts` に `output: "standalone"` が含まれる
- [ ] `.dockerignore` が存在し、`.env`, `node_modules`, `.git` を除外する
- [ ] `npm run build` で `.next/standalone/server.js` が生成される
- [ ] `npm run test` が成功する
- [ ] `npm run lint` が新規エラーを出さない

## コミット

```bash
git add -A
git commit -m "feat: add standalone output to next.config.ts and .dockerignore

- Set output: 'standalone' in next.config.ts for container deployment
- Create .dockerignore to optimize build context
- Add test to verify standalone config

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```
