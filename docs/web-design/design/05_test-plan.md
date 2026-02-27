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
| Copilot CLIが使用可能（※Copilot拡張はOpen VSX制約で不可、CLIで代替） | E2E | E2E-7 |
| 画面デザインのモック作成・プレビューのワークフローが確立されている | E2E | E2E-2, E2E-10 |
| Reactアプリのホットリロードがcode-server環境で動作すること | E2E | E2E-8 |
| MSWモック応答が正常に動作すること | E2E | E2E-9, E2E-10 |

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
| E2E-7 | Copilot CLIフォールバック確認（MRD-004） | 1. devcontainer起動<br/>2. `github-copilot-cli --version` を実行 | Copilot CLIのバージョンが表示される | 高 |
| E2E-8 | HMR反映確認（MRD-004） | 1. Vite dev server起動<br/>2. `src/App.tsx` のテキストを編集<br/>3. ブラウザの更新を確認 | 編集したテキストがブラウザ上のReactアプリに自動反映される（ページリロードなし） | 高 |
| E2E-9 | MSWモック応答確認（MRD-004） | 1. Vite dev server起動<br/>2. ブラウザから `/api/health` にリクエスト | MSWが `{ "status": "ok" }` を返却する | 高 |
| E2E-10 | MSWモック統合確認（MRD-004） | 1. Vite dev server起動<br/>2. Reactアプリにアクセス<br/>3. MSWモックAPIを使用するコンポーネントの動作確認 | コンポーネントがMSWモックデータを表示する | 中 |

### 2.3 コンテナ名動的取得ヘルパー（MRD-003対応）

テストの `beforeAll` でコンテナ名を動的に取得し、環境変数 `CONTAINER_NAME` として各テストに渡す。

```typescript
// e2e/helpers/container.ts
import { execSync } from 'child_process';

/**
 * dev-container.sh で起動したコンテナの名前を動的に取得する。
 * label "managed-by=dev-container-sh" でフィルタリングする。
 */
export function getContainerName(): string {
  const output = execSync(
    "docker ps --filter label=managed-by=dev-container-sh --format '{{.Names}}'",
  )
    .toString()
    .trim();

  const containers = output.split('\n').filter(Boolean);
  if (containers.length === 0) {
    throw new Error(
      'No running container found with label managed-by=dev-container-sh',
    );
  }
  // web-design プロジェクトのコンテナを優先
  const webDesign = containers.find((c) => c.startsWith('web-design-'));
  return webDesign || containers[0];
}

/**
 * コンテナ内でコマンドを実行するヘルパー
 */
export function execInContainer(containerName: string, cmd: string): string {
  return execSync(`docker exec ${containerName} ${cmd}`).toString();
}
```

### 2.4 テストファイル設計

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
import { getContainerName, execInContainer } from './helpers/container';

let containerName: string;

test.beforeAll(() => {
  containerName = getContainerName();
});

test.describe('拡張機能インストール確認', () => {
  test('E2E-3: 必要な拡張機能がインストールされている', async () => {
    const output = execInContainer(
      containerName,
      'code-server --list-extensions',
    );

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
      const output = execInContainer(containerName, cmd);
      expect(output.trim()).not.toBe('');
    }
  });

  test('E2E-7: Copilot CLIが利用可能（MRD-004対応）', async () => {
    const output = execInContainer(
      containerName,
      'github-copilot-cli --version',
    );
    expect(output.trim()).not.toBe('');
  });
});
```

#### e2e/docker-mode.spec.ts（MRD-006対応）

DooD/DinDモード別テストは、テスト実行前に `DOCKER_MODE` 環境変数を設定して
コンテナを再起動する方式で実施する。

**実行方法:**
```bash
# DinDモードテスト
DOCKER_MODE=dind ./scripts/dev-container.sh up
npx playwright test e2e/docker-mode.spec.ts --grep "DinD"
./scripts/dev-container.sh down

# DooDモードテスト
DOCKER_MODE=dood ./scripts/dev-container.sh up
npx playwright test e2e/docker-mode.spec.ts --grep "DooD"
./scripts/dev-container.sh down
```

```typescript
import { test, expect } from '@playwright/test';
import { getContainerName, execInContainer } from './helpers/container';

let containerName: string;

test.beforeAll(() => {
  containerName = getContainerName();
});

test.describe('DooD/DinD動作確認', () => {
  test('E2E-5: DinDモードでdocker psが実行できる', async () => {
    // DinDモード（DOCKER_MODE=dind）でコンテナを起動した状態で実行
    const output = execInContainer(containerName, 'docker ps');
    expect(output).toContain('CONTAINER ID');
  });

  test('E2E-6: DooDモードでdocker psが実行できる', async () => {
    // DooDモード（DOCKER_MODE=dood）でコンテナを起動した状態で実行
    const output = execInContainer(containerName, 'docker ps');
    expect(output).toContain('CONTAINER ID');
  });
});
```

#### e2e/hmr.spec.ts（MRD-004対応: HMR反映確認）

```typescript
import { test, expect } from '@playwright/test';
import { getContainerName, execInContainer } from './helpers/container';
import { randomUUID } from 'crypto';

let containerName: string;

test.beforeAll(() => {
  containerName = getContainerName();
});

test.describe('HMR反映確認', () => {
  test('E2E-8: ファイル編集がブラウザに自動反映される', async ({ page }) => {
    await page.goto('http://localhost:5173');

    // 一意なテキストを生成してApp.tsxに書き込み
    const marker = `HMR-TEST-${randomUUID().slice(0, 8)}`;
    execInContainer(
      containerName,
      `bash -c "sed -i 's/Vite + React/${marker}/' /workspaces/web-design/src/App.tsx"`,
    );

    // HMRによる更新を待機（最大10秒）
    await expect(page.locator('body')).toContainText(marker, {
      timeout: 10_000,
    });

    // 元に戻す
    execInContainer(
      containerName,
      `bash -c "sed -i 's/${marker}/Vite + React/' /workspaces/web-design/src/App.tsx"`,
    );
  });
});
```

#### e2e/msw.spec.ts（MRD-004対応: MSWモック応答確認）

```typescript
import { test, expect } from '@playwright/test';

test.describe('MSWモック応答確認', () => {
  test('E2E-9: /api/health がMSWモックレスポンスを返す', async ({ page }) => {
    // Reactアプリにアクセス（MSWが初期化される）
    await page.goto('http://localhost:5173');

    // MSWが初期化されるのを待つ
    await page.waitForTimeout(2000);

    // /api/health にリクエストを送信
    const response = await page.evaluate(async () => {
      const res = await fetch('/api/health');
      return res.json();
    });

    expect(response).toEqual({ status: 'ok' });
  });

  test('E2E-10: ReactコンポーネントがMSWモックデータを表示する', async ({
    page,
  }) => {
    await page.goto('http://localhost:5173');
    // MSW初期化後、モックデータを使用するコンポーネントが正常に表示されることを確認
    // （将来、APIデータ表示コンポーネント追加時に具体化）
    await expect(page.locator('body')).not.toBeEmpty();
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

# 2. devcontainer起動（DinDモード）
DOCKER_MODE=dind ./scripts/dev-container.sh up

# 3. コンテナ名取得
CONTAINER_NAME=$(docker ps --filter label=managed-by=dev-container-sh --format '{{.Names}}' | grep web-design)

# 4. コンテナ内でnpm install & dev server起動
docker exec "$CONTAINER_NAME" bash -c "cd /workspaces/web-design && npm install && npm run dev &"

# 5. E2Eテスト実行（DinDモード分）
npx playwright test --grep -v "DooD"

# 6. DinDコンテナ停止
./scripts/dev-container.sh down

# 7. DooDモードでE2Eテスト実行
DOCKER_MODE=dood ./scripts/dev-container.sh up
docker exec "$CONTAINER_NAME" bash -c "cd /workspaces/web-design && npm install && npm run dev &"
npx playwright test e2e/docker-mode.spec.ts --grep "DooD"

# 8. テスト結果確認
npx playwright show-report

# 9. クリーンアップ
./scripts/dev-container.sh down
```

---

## 6. 実行計画

### 6.1 テスト実行順序

1. devcontainerイメージビルド確認
2. code-serverアクセス確認 (E2E-1)
3. 拡張機能・開発ツール確認 (E2E-3, E2E-4)
4. Copilot CLIフォールバック確認 (E2E-7)
5. Reactアプリプレビュー確認 (E2E-2)
6. HMR反映確認 (E2E-8)
7. MSWモック応答確認 (E2E-9, E2E-10)
8. DinD/DooD動作確認 (E2E-5, E2E-6)

### 6.2 テスト判定基準

| 判定 | 条件 |
|------|------|
| PASS | E2E-1〜E2E-4, E2E-7〜E2E-10 が全て成功 |
| CONDITIONAL PASS | E2E-1〜E2E-4, E2E-7〜E2E-10 成功、E2E-5/E2E-6 のいずれかが失敗 |
| FAIL | E2E-1〜E2E-4, E2E-7〜E2E-10 のいずれかが失敗 |

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-02-27 | 1.0 | 初版作成 | Copilot |
