# テスト計画

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | WEB-DESIGN-001 |
| タスク名 | ウェブデザイン要件定義プロジェクト環境構築 |
| 作成日 | 2026-02-27 |

---

## 1. テスト方針

### 1.1 テストスコープ

brainstorming で決定されたテスト戦略に基づき、**E2Eテストのみ**を実施する。

| 範囲 | 対象 | 除外 |
|------|------|------|
| 単体テスト | スコープ外 | 全て（将来追加） |
| 結合テスト | スコープ外 | 全て（将来追加） |
| E2Eテスト | devcontainerビルド・起動後のcode-server・React・拡張機能・Docker動作確認 | パフォーマンス測定 |

### 1.2 テスト方法

- **テストフレームワーク**: Playwright
- **テスト環境**: devcontainerをビルド→起動し、Playwrightで動作確認
- **実行方法**: ホスト側または別コンテナからPlaywrightテストを実行

### 1.3 acceptance_criteria との対応表

| acceptance_criteria | テスト種別 | テストケースNo |
|---------------------|-----------|---------------|
| devcontainerでcode-serverが起動し、ブラウザからアクセスできる | E2E | E2E-1 |
| Reactプロジェクトが初期化され、code-server上でプレビューできる | E2E | E2E-2 |
| DooD/DinD切り替え機構が動作する | E2E | E2E-5, E2E-6 |
| copilot CLI, git, playwright, prettierが使用可能 | E2E | E2E-4 |
| code-serverにReact開発用拡張機能がインストールされている | E2E | E2E-3 |
| code-serverにGitHub Copilot拡張機能がインストールされている | E2E | E2E-3 |
| 画面デザインのモック作成・プレビューのワークフローが確立されている | E2E | E2E-2 |

---

## 2. E2Eテストケース

### 2.1 playwright.config.ts 設計

```typescript
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  timeout: 120_000,  // devcontainer起動を含むため長めに設定
  retries: 1,
  use: {
    baseURL: 'http://localhost:8080',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { browserName: 'chromium' },
    },
  ],
});
```

### 2.2 テストケース一覧

| No | テストシナリオ | 手順 | 期待結果 | 優先度 |
|----|----------------|------|----------|--------|
| E2E-1 | code-serverアクセス確認 | 1. devcontainer起動<br/>2. `http://localhost:8080` にアクセス | code-serverのWeb UIが表示される。タイトルに"code-server"または"Visual Studio Code"が含まれる | 高 |
| E2E-2 | Reactアプリプレビュー確認 | 1. code-serverターミナルで `npm run dev` 実行<br/>2. `http://localhost:5173` にアクセス | Reactアプリが表示される。Viteロゴまたは"Vite + React"テキストが表示される | 高 |
| E2E-3 | 拡張機能インストール確認 | 1. devcontainer起動<br/>2. `code-server --list-extensions` を実行 | 以下の拡張機能がリストに含まれる:<br/>- `dbaeumer.vscode-eslint`<br/>- `esbenp.prettier-vscode`<br/>- `bradlc.vscode-tailwindcss`<br/>- `redhat.vscode-yaml`<br/>- `dsznajder.es7-react-js-snippets` | 高 |
| E2E-4 | 開発ツール動作確認 | 1. devcontainer起動<br/>2. 各コマンドのバージョン確認 | 以下が正常にバージョン表示される:<br/>- `node --version`<br/>- `npm --version`<br/>- `git --version`<br/>- `gh --version`<br/>- `npx playwright --version`<br/>- `prettier --version`<br/>- `yq --version` | 高 |
| E2E-5 | DinDモード動作確認 | 1. `DOCKER_MODE=dind` でdevcontainer起動<br/>2. コンテナ内で `docker ps` 実行 | `docker ps` が成功し、コンテナ一覧が表示される（dockerdがコンテナ内で起動している） | 中 |
| E2E-6 | DooDモード動作確認 | 1. `DOCKER_MODE=dood` でdevcontainer起動<br/>2. コンテナ内で `docker ps` 実行 | `docker ps` が成功し、ホストのコンテナ一覧が表示される（ホストのDocker socketを使用） | 中 |

### 2.3 テストファイル設計

#### e2e/code-server.spec.ts

```typescript
import { test, expect } from '@playwright/test';

test.describe('code-server アクセス確認', () => {
  test('E2E-1: code-serverにブラウザからアクセスできる', async ({ page }) => {
    await page.goto('http://localhost:8080');
    // code-serverのUIが表示されることを確認
    await expect(page).toHaveTitle(/code-server|Visual Studio Code/i);
  });
});
```

#### e2e/react-preview.spec.ts

```typescript
import { test, expect } from '@playwright/test';

test.describe('Reactアプリプレビュー確認', () => {
  test('E2E-2: Reactアプリがプレビューできる', async ({ page }) => {
    await page.goto('http://localhost:5173');
    // Reactアプリが表示されることを確認
    await expect(page.locator('body')).toContainText(/Vite|React/i);
  });
});
```

#### e2e/extensions.spec.ts

```typescript
import { test, expect } from '@playwright/test';
import { execSync } from 'child_process';

test.describe('拡張機能インストール確認', () => {
  test('E2E-3: 必要な拡張機能がインストールされている', async () => {
    const output = execSync(
      'docker exec <container> code-server --list-extensions',
    ).toString();

    const requiredExtensions = [
      'dbaeumer.vscode-eslint',
      'esbenp.prettier-vscode',
      'bradlc.vscode-tailwindcss',
      'redhat.vscode-yaml',
      'dsznajder.es7-react-js-snippets',
    ];

    for (const ext of requiredExtensions) {
      expect(output.toLowerCase()).toContain(ext.toLowerCase());
    }
  });

  test('E2E-4: 開発ツールが利用可能', async () => {
    const commands = [
      'node --version',
      'npm --version',
      'git --version',
      'gh --version',
      'prettier --version',
      'yq --version',
    ];

    for (const cmd of commands) {
      const output = execSync(`docker exec <container> ${cmd}`).toString();
      expect(output.trim()).not.toBe('');
    }
  });
});
```

#### e2e/docker-mode.spec.ts

```typescript
import { test, expect } from '@playwright/test';
import { execSync } from 'child_process';

test.describe('DooD/DinD動作確認', () => {
  test('E2E-5: DinDモードでdocker psが実行できる', async () => {
    // DinDモードでコンテナを起動し、docker psが成功することを確認
    const output = execSync(
      'docker exec <container> docker ps',
    ).toString();
    expect(output).toContain('CONTAINER ID');
  });

  test('E2E-6: DooDモードでdocker psが実行できる', async () => {
    // DooDモードでコンテナを起動し、docker psが成功することを確認
    const output = execSync(
      'docker exec <container> docker ps',
    ).toString();
    expect(output).toContain('CONTAINER ID');
  });
});
```

---

## 3. 既存テスト修正

新規プロジェクトのため、既存テストの修正は不要。

---

## 4. テストデータ設計

### 4.1 テストデータ一覧

| データ名 | 用途 | 形式 | 備考 |
|----------|------|------|------|
| devcontainerイメージ | E2Eテスト対象 | Docker Image | `nagasakah/web-design:latest` |
| Reactプロジェクトファイル | プレビューテスト | TypeScript/JSX | `src/App.tsx` etc. |

---

## 5. テスト環境

### 5.1 環境要件

| 項目 | 要件 | 備考 |
|------|------|------|
| Docker Engine | 20.10+ | devcontainerビルド・起動に必要 |
| Node.js | LTS (20.x or 22.x) | Playwright実行に必要 |
| Playwright | 1.50+ | devcontainer feature でインストール |
| ポート 8080 | 空きポート | code-server用 |
| ポート 5173 | 空きポート | Vite dev server用 |

### 5.2 テスト実行手順

```bash
# 1. devcontainerイメージビルド
./scripts/build-and-push-devcontainer.sh --no-push

# 2. devcontainer起動
./scripts/dev-container.sh up

# 3. コンテナ内でnpm install & dev server起動
docker exec <container> bash -c "cd /workspaces/web-design && npm install && npm run dev &"

# 4. E2Eテスト実行
npx playwright test

# 5. テスト結果確認
npx playwright show-report

# 6. クリーンアップ
./scripts/dev-container.sh down
```

---

## 6. 実行計画

### 6.1 テスト実行順序

1. devcontainerイメージビルド確認
2. code-serverアクセス確認 (E2E-1)
3. 拡張機能・開発ツール確認 (E2E-3, E2E-4)
4. Reactアプリプレビュー確認 (E2E-2)
5. DinD/DooD動作確認 (E2E-5, E2E-6)

### 6.2 テスト判定基準

| 判定 | 条件 |
|------|------|
| PASS | E2E-1〜E2E-4 が全て成功 |
| CONDITIONAL PASS | E2E-1〜E2E-4 成功、E2E-5/E2E-6 のいずれかが失敗 |
| FAIL | E2E-1〜E2E-4 のいずれかが失敗 |

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-02-27 | 1.0 | 初版作成 | Copilot |
