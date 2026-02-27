# タスク: task03 - Playwright E2Eテスト作成

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task03 |
| タスク名 | Playwright E2Eテスト作成（10ケース） |
| 前提条件タスク | task02-01, task02-02, task02-03 |
| 並列実行可否 | 不可（全実装タスク完了後に実施） |
| 推定所要時間 | 15分 |
| 優先度 | 高 |

---

## 作業環境

- **作業ディレクトリ（worktree）**: /tmp/WEB-DESIGN-001-task03/
- **ブランチ**: WEB-DESIGN-001-task03
- **対象リポジトリ**: submodules/web-design
- **重要**: 必ず上記の作業ディレクトリ内で作業を行ってください

---

## 前提条件

### 前提タスク成果物

| タスク | 成果物パス | 参照内容 |
|--------|------------|----------|
| task02-01 | `scripts/dev-container.sh` | コンテナ起動方法、ラベル `managed-by=dev-container-sh` |
| task02-02 | `scripts/build-and-push-devcontainer.sh` | ビルドコマンド |
| task02-03 | `package.json` | `@playwright/test` 依存、`test:e2e` スクリプト |
| task02-03 | `src/App.tsx` | "Vite + React" テキスト（E2E-2, E2E-8で検証） |
| task02-03 | `src/mocks/handlers.ts` | `/api/health` ハンドラー（E2E-9で検証） |

### 確認事項

- [ ] task02-01, task02-02, task02-03が全て完了していること
- [ ] 全前提タスクのコミットがcherry-pick済みであること

---

## 作業内容

### 目的

devcontainerビルド→起動後の動作確認をPlaywright E2Eテストとして実装する。テスト計画の10ケース（E2E-1〜E2E-10）を全て実装する。

### 設計参照

- [design/05_test-plan.md](../design/05_test-plan.md) — テストケース一覧、playwright.config.ts設計、テストコード設計
- [design/03_data-structure-design.md](../design/03_data-structure-design.md) — e2e/ディレクトリ構造

### 実装ステップ

1. `e2e/` ディレクトリを作成
2. `e2e/playwright.config.ts` を作成（timeout 120s、baseURL、chromium）
3. `e2e/helpers/container.ts` を作成（`getContainerName()`, `execInContainer()` ヘルパー）
4. `e2e/code-server.spec.ts` を作成（E2E-1: code-serverアクセス確認）
5. `e2e/react-preview.spec.ts` を作成（E2E-2: Reactプレビュー確認）
6. `e2e/extensions.spec.ts` を作成（E2E-3: 拡張機能、E2E-4: 開発ツール、E2E-7: Copilot CLI）
7. `e2e/docker-mode.spec.ts` を作成（E2E-5: DinD、E2E-6: DooD）
8. `e2e/hmr.spec.ts` を作成（E2E-8: HMR反映確認）
9. `e2e/msw.spec.ts` を作成（E2E-9: MSWモック応答、E2E-10: MSWモック統合）

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `e2e/playwright.config.ts` | 新規作成 | Playwright設定（timeout 120s, chromium） |
| `e2e/helpers/container.ts` | 新規作成 | コンテナ名取得・コマンド実行ヘルパー（MRD-003対応） |
| `e2e/code-server.spec.ts` | 新規作成 | E2E-1: code-serverアクセス |
| `e2e/react-preview.spec.ts` | 新規作成 | E2E-2: Reactプレビュー |
| `e2e/extensions.spec.ts` | 新規作成 | E2E-3, E2E-4, E2E-7: 拡張機能・ツール・Copilot CLI |
| `e2e/docker-mode.spec.ts` | 新規作成 | E2E-5, E2E-6: DinD/DooD動作 |
| `e2e/hmr.spec.ts` | 新規作成 | E2E-8: HMR反映 |
| `e2e/msw.spec.ts` | 新規作成 | E2E-9, E2E-10: MSWモック |

---

## テスト方針

このタスク自体がE2Eテストの実装タスクである。TDDの観点では、テストコードを先に作成し（RED状態）、実装はPhase 1-2のタスクで完了済み。テストは実環境（devcontainerビルド・起動後）でのみ実行可能。

### テストケース詳細

#### E2E-1: code-serverアクセス確認

```typescript
// e2e/code-server.spec.ts
test('E2E-1: code-serverにブラウザからアクセスできる', async ({ page }) => {
  await page.goto('http://localhost:8080');
  await expect(page).toHaveTitle(/code-server|Visual Studio Code/i);
});
```

#### E2E-2: Reactアプリプレビュー確認

```typescript
// e2e/react-preview.spec.ts
test('E2E-2: Reactアプリがプレビューできる', async ({ page }) => {
  await page.goto('http://localhost:5173');
  await expect(page.locator('body')).toContainText(/Vite|React/i);
});
```

#### E2E-3: 拡張機能インストール確認

```typescript
// e2e/extensions.spec.ts
test('E2E-3: 必要な拡張機能がインストールされている', async () => {
  const output = execInContainer(containerName, 'code-server --list-extensions');
  const required = ['dbaeumer.vscode-eslint', 'esbenp.prettier-vscode', ...];
  for (const ext of required) {
    expect(output.toLowerCase()).toContain(ext.toLowerCase());
  }
});
```

#### E2E-4: 開発ツール動作確認

```typescript
test('E2E-4: 開発ツールが利用可能', async () => {
  const commands = ['node --version', 'npm --version', 'git --version', ...];
  for (const cmd of commands) {
    const output = execInContainer(containerName, cmd);
    expect(output.trim()).not.toBe('');
  }
});
```

#### E2E-5/6: DinD/DooDモード

```typescript
test('E2E-5: DinDモードでdocker psが実行できる', async () => {
  const output = execInContainer(containerName, 'docker ps');
  expect(output).toContain('CONTAINER ID');
});
```

#### E2E-7: Copilot CLIフォールバック確認

```typescript
test('E2E-7: Copilot CLIが利用可能', async () => {
  const output = execInContainer(containerName, 'github-copilot-cli --version');
  expect(output.trim()).not.toBe('');
});
```

#### E2E-8: HMR反映確認

```typescript
test('E2E-8: ファイル編集がブラウザに自動反映される', async ({ page }) => {
  await page.goto('http://localhost:5173');
  const marker = `HMR-TEST-${randomUUID().slice(0, 8)}`;
  execInContainer(containerName, `bash -c "sed -i 's/Vite + React/${marker}/' /workspaces/web-design/src/App.tsx"`);
  await expect(page.locator('body')).toContainText(marker, { timeout: 10_000 });
  // 元に戻す
  execInContainer(containerName, `bash -c "sed -i 's/${marker}/Vite + React/' /workspaces/web-design/src/App.tsx"`);
});
```

#### E2E-9/10: MSWモック

```typescript
test('E2E-9: /api/health がMSWモックレスポンスを返す', async ({ page }) => {
  await page.goto('http://localhost:5173');
  await page.waitForTimeout(2000);
  const response = await page.evaluate(async () => {
    const res = await fetch('/api/health');
    return res.json();
  });
  expect(response).toEqual({ status: 'ok' });
});
```

---

## 成果物

### 期待される出力

| 成果物 | パス | 説明 |
|--------|------|------|
| Playwright設定 | `e2e/playwright.config.ts` | テスト全体設定 |
| ヘルパー | `e2e/helpers/container.ts` | コンテナ操作ヘルパー |
| テストファイル | `e2e/*.spec.ts` (6ファイル) | 10テストケース |

---

## 完了条件

### 機能的条件

- [ ] `playwright.config.ts` にtimeout 120s、baseURL、chromiumプロジェクトが設定されていること
- [ ] `helpers/container.ts` に `getContainerName()` と `execInContainer()` が実装されていること
- [ ] E2E-1〜E2E-10の全10テストケースが実装されていること
- [ ] 各テストケースが設計書（05_test-plan.md）の仕様に準拠していること
- [ ] DooD/DinDテスト（E2E-5/6）が環境変数 `DOCKER_MODE` に依存する実行方式であること

### 品質条件

- [ ] TypeScript構文エラーがないこと
- [ ] テストの意図が明確であること（テスト名に期待動作が含まれる）

---

## コミット

```bash
cd /tmp/WEB-DESIGN-001-task03/
git add -A
git status
git diff --staged

git commit -m "test(e2e): Playwright E2Eテスト10ケースを作成

- playwright.config.ts: timeout 120s, chromium
- helpers/container.ts: コンテナ名取得・コマンド実行ヘルパー
- code-server.spec.ts: E2E-1 アクセス確認
- react-preview.spec.ts: E2E-2 Reactプレビュー
- extensions.spec.ts: E2E-3,4,7 拡張機能・ツール・Copilot CLI
- docker-mode.spec.ts: E2E-5,6 DinD/DooD
- hmr.spec.ts: E2E-8 HMR反映
- msw.spec.ts: E2E-9,10 MSWモック応答

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"

git rev-parse HEAD
```

---

## 注意事項

- MRD-003: コンテナ名は `getContainerName()` ヘルパーで動的取得。ラベル `managed-by=dev-container-sh` でフィルタ
- MRD-004: E2E-7(Copilot CLI), E2E-8(HMR), E2E-9(MSW), E2E-10(MSW統合) はレビュー指摘対応で追加されたテスト
- MRD-006: DooD/DinDテストは `DOCKER_MODE` 環境変数を変更してコンテナ再起動が必要
- E2E-8のHMRテスト: sedで`src/App.tsx`を編集→HMR確認→元に戻す。マーカーにUUIDを使用
- テストの実行はdevcontainerビルド・起動後に行う（verificationフェーズ）
