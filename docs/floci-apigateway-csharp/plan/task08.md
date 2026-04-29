# タスク: task08 - Playwright config + `e2e/todo.spec.ts` (E2E-1〜E2E-6)

## タスク情報

| 項目           | 値                       |
| -------------- | ------------------------ |
| タスク識別子   | task08                   |
| 前提条件       | task04, task07           |
| 並列実行可否   | 可（task06 と並列）      |
| 推定所要時間   | 1.5h                     |
| 優先度         | 高                       |

## 作業環境

- 作業ディレクトリ: `/tmp/FRONTEND-001-task08/`
- ブランチ: `FRONTEND-001-task08`

## 設計参照

- [design/05_test-plan.md](../design/05_test-plan.md) §2.3 (E2E-1〜E2E-6), Playwright 設定要点
- [design/04_process-flow-design.md](../design/04_process-flow-design.md) §4.4
- [design/06_side-effect-verification.md](../design/06_side-effect-verification.md) §2.4

## 目的

Playwright 1.45.3 を導入し、`frontend/playwright.config.ts` と `frontend/e2e/todo.spec.ts` で E2E-1〜E2E-6 を実装する。`WEB_BASE_URL` / `AWS_ENDPOINT_URL` 未設定時は **globalSetup で throw** し fail-fast (RD-002 / RD2-003)。fallback 値は持たない。

## 実装ステップ (TDD)

### RED
1. `frontend/playwright.config.ts` (新規) を作成 (内容は GREEN セクション参照)
2. `frontend/e2e/todo.spec.ts` (新規) に E2E-1〜E2E-6 を test として追加
3. `WEB_BASE_URL` 未設定で `npx playwright test` を実行 → **globalSetup throw で abort** することを確認

### GREEN
4. **`frontend/playwright.config.ts`**:
   ```typescript
   import { defineConfig, devices } from '@playwright/test';
   function requireEnv(name: string): string {
     const v = process.env[name];
     if (!v) throw new Error(`FATAL: required env ${name} is not set`);
     return v;
   }
   export default defineConfig({
     testDir: './e2e',
     workers: 1,
     globalSetup: require.resolve('./e2e/global-setup.ts'),
     use: {
       baseURL: requireEnv('WEB_BASE_URL'),
       trace: 'retain-on-failure',
     },
     projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
     reporter: [['junit', { outputFile: 'test-results/junit.xml' }], ['html']],
   });
   ```
5. **`frontend/e2e/global-setup.ts`**: `WEB_BASE_URL` / `AWS_ENDPOINT_URL` を再検証して throw if 未設定
6. **`frontend/e2e/todo.spec.ts`**:
   - **E2E-1**: `/` を開き title 入力 → 送信 → 表示 id を控え → 取得フォームで GET → 同じ title が表示
   - **E2E-2**: `/foo/bar` を直接開き 200 + index.html (Angular ルータ処理)
   - **E2E-3**: `page.on('console', ...)` で console.error が出ない / Network で OPTIONS=204, POST=201
   - **E2E-4**: title 空送信 → UI に `errors[0]` 表示
   - **E2E-5**: floci の Lambda を `docker compose stop` で停止し 5xx 再現 → "サーバエラーが発生しました" 表示。**skip 禁止**、再現失敗時は test を fail (RD-002)
   - **E2E-6**: `WEB_BASE_URL=` 空で `scripts/web-e2e.sh` を実行 → shell が exit 1、Playwright が起動しない
7. `cd frontend && WEB_BASE_URL=http://localhost:8080 AWS_ENDPOINT_URL=http://localhost:4566 npx playwright test` をローカル devcontainer で **GREEN** 確認 (floci + nginx + tf apply 後)

### REFACTOR
8. `e2e/fixtures/` で共通 page object を抽出
9. `playwright.config.ts` に `expect: { timeout: 5000 }` 等の妥当な timeout 設定
10. junit + HTML レポートを `frontend/test-results/` / `frontend/playwright-report/` に出力

## 対象ファイル

| ファイル                              | 操作 |
| ------------------------------------- | ---- |
| `frontend/playwright.config.ts`       | 新規 |
| `frontend/e2e/global-setup.ts`        | 新規 |
| `frontend/e2e/todo.spec.ts`           | 新規 |
| `frontend/package.json`               | 修正 (`@playwright/test` ピン `1.45.3`) |

## 完了条件

- [ ] E2E-1〜E2E-6 がローカル devcontainer (floci + nginx + tf apply + ng build + s3 sync 完了後) で全 pass
- [ ] `WEB_BASE_URL` 未設定で globalSetup throw → run abort
- [ ] junit.xml が生成される
- [ ] result.md 作成

## コミット

```bash
git add -A
git commit -m "refs FRONTEND-001 task08 Playwright config と E2E-1〜E2E-6 を追加

- @playwright/test 1.45.3 を frontend に導入
- globalSetup と use.baseURL は requireEnv で fail-fast (RD-002 / RD2-003)
- workers:1 で floci 競合回避、Chromium 単一に限定 (R6)
- E2E-3 で OPTIONS=204 / POST=201 / console.error 無を必須アサート (RD-006)"
```

## 注意事項

- `localhost:8080` 等の fallback 値を **絶対に** 設定しない (RD2-003)
- E2E-5 で skip 運用は禁止 (RD-002)
