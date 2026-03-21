# Task 01: テスト基盤セットアップ (Vitest + Playwright + package.json)

## タスク情報

| 項目 | 内容 |
|------|------|
| ID | 01 |
| タスク名 | テスト基盤セットアップ |
| 前提タスク | なし |
| 並列実行 | 不可 (後続タスクの基盤) |
| 見積時間 | 15分 |

## 作業環境

- **worktree**: `/tmp/viewer-container-local-01/`
- **ブランチ**: `task/01-test-infrastructure`
- **サブモジュール**: `submodules/copilot-session-viewer/`

## 前提条件

- copilot-session-viewer サブモジュールが利用可能
- Node.js + npm が利用可能

## 作業内容

### 目的

Vitest (単体/結合テスト) と Playwright (E2E テスト) の実行基盤をセットアップする。テストフレームワークが動作する状態を確立し、後続の全テストタスクの基礎とする。

### 設計参照

- `docs/copilot-session-viewer/design/05_test-plan.md` — セクション 1.2, 1.3 (テスト実行コマンド, package.json スクリプト)
- `docs/copilot-session-viewer/design/03_data-structure-design.md` — セクション 6 (テスト設定データ構造)

### 実装ステップ

1. **Vitest + Playwright + 関連パッケージの devDependencies 追加**
   - `vitest`, `@vitest/coverage-v8`
   - `@playwright/test`
   - 対象: `submodules/copilot-session-viewer/package.json`

2. **package.json にテストスクリプト追加**
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

3. **vitest.config.ts 作成**
   - テスト対象: `src/**/__tests__/**/*.test.ts`
   - 除外: `e2e/**`
   - パスエイリアス: `@` → `./src`
   - カバレッジ: v8 プロバイダ、`src/lib/**` 対象
   - 参照: `docs/copilot-session-viewer/design/03_data-structure-design.md` セクション 6.1

4. **playwright.config.ts 作成**
   - テストディレクトリ: `./e2e`
   - ベースURL: `http://localhost:${PORT || 3000}`
   - ヘッドレス: true
   - webServer.command: `node /app/server.js`（コンテナ内実行想定、reuseExistingServer: true）
   - 参照: `docs/copilot-session-viewer/design/03_data-structure-design.md` セクション 6.2

5. **npm install を実行して依存関係を解決**

6. **ダミーテストファイルで動作確認**
   - `src/lib/__tests__/smoke.test.ts` — Vitest が動作するか確認
   - `e2e/smoke.spec.ts` — Playwright 設定ファイルが正しいか確認（スキップ可）

### 対象ファイル

| ファイル | 操作 |
|---------|------|
| `submodules/copilot-session-viewer/package.json` | 修正 |
| `submodules/copilot-session-viewer/vitest.config.ts` | 新規作成 |
| `submodules/copilot-session-viewer/playwright.config.ts` | 新規作成 |
| `submodules/copilot-session-viewer/src/lib/__tests__/smoke.test.ts` | 新規作成 |
| `submodules/copilot-session-viewer/e2e/smoke.spec.ts` | 新規作成 (scaffolding — task12 で本番 E2E に置換) |

## TDD アプローチ

### RED (失敗するテストを書く)

```typescript
// src/lib/__tests__/smoke.test.ts
import { describe, it, expect } from "vitest";

describe("Vitest smoke test", () => {
  it("should run vitest successfully", () => {
    expect(1 + 1).toBe(2);
  });
});
```

`npm run test` を実行 → Vitest 未インストールのためエラー。

### GREEN (テストを通す最小実装)

1. devDependencies に vitest, @vitest/coverage-v8, @playwright/test を追加
2. vitest.config.ts, playwright.config.ts を作成
3. package.json にスクリプトを追加
4. `npm install` 実行
5. `npm run test` → smoke.test.ts が PASS

### REFACTOR (改善)

- 不要な smoke.test.ts は後続タスクで実テストに置き換え後に削除
- tsconfig.json の調整が必要であれば実施

## 期待される成果物

- `submodules/copilot-session-viewer/vitest.config.ts`
- `submodules/copilot-session-viewer/playwright.config.ts`
- `submodules/copilot-session-viewer/package.json` (修正済)
- `submodules/copilot-session-viewer/src/lib/__tests__/smoke.test.ts`
- `npm run test` が正常実行される状態

## 完了条件

- [ ] `npm run test` が成功する (Vitest smoke テスト PASS)
- [ ] `vitest.config.ts` が `@` パスエイリアスを正しく解決する
- [ ] `playwright.config.ts` が存在し、構文エラーがない
- [ ] `npm run lint` が新規エラーを出さない

## コミット

```bash
git add -A
git commit -m "feat: add Vitest + Playwright test infrastructure

- Add vitest.config.ts with path alias and coverage settings
- Add playwright.config.ts for E2E testing
- Add test scripts to package.json
- Add smoke test to verify Vitest setup

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```
