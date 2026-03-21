# 04. 既存パターン調査

## 背景

実装パターン・コーディング規約を把握し、新規コード（Vitest テスト、Dockerfile 等）の一貫性を確保する。

## コーディングスタイル

### TypeScript 設定

- `strict: true` — null チェック、暗黙 any 禁止
- `isolatedModules: true` — 各ファイルが独立してトランスパイル可能
- Path alias: `@/*` → `./src/*`
- `jsx: "react-jsx"` (React 17+ の新 JSX トランスフォーム)

### ESLint 設定

```javascript
// eslint.config.mjs (ESLint 9 flat config)
import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  globalIgnores([".next/**", "out/**", "build/**", "next-env.d.ts"]),
]);
```

- ESLint 9 の flat config 形式
- Next.js Core Web Vitals + TypeScript ルール
- カスタムルールなし

### スタイリング

- Tailwind CSS v4 + PostCSS
- `@tailwindcss/typography` プラグイン使用
- インラインクラス方式（className に直接 Tailwind クラス）

## API ルートパターン

### 標準的な GET エンドポイント

```typescript
import { NextResponse } from "next/server";
import { listSessions } from "@/lib/sessions";

export async function GET() {
  try {
    const sessions = listSessions();
    return NextResponse.json(sessions);
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
```

### 動的ルートパラメータ

```typescript
interface RouteParams {
  params: Promise<{ id: string }>;
}

export async function GET(request: NextRequest, { params }: RouteParams) {
  const { id } = await params;
  // ...
}
```

**注意**: Next.js 16 では `params` が `Promise` 型。

### レスポンスパターン

| 状況 | ステータス | レスポンス形式 |
|------|----------|--------------|
| 成功 | 200 | `NextResponse.json(data)` |
| 未検出 | 404 | `NextResponse.json({ error: "..." }, { status: 404 })` |
| 不正リクエスト | 400 | `NextResponse.json({ error: "..." }, { status: 400 })` |
| 無効化機能 | 403 | `NextResponse.json({ error: "..." }, { status: 403 })` |
| サーバーエラー | 500 | `NextResponse.json({ error: String(e) }, { status: 500 })` |

## エラーハンドリングパターン

### API ルート

- 全 API ルートで `try-catch` 包括
- エラーメッセージ: `String(e)` で文字列化
- 一部で型安全な変換: `String(e instanceof Error ? e.message : e)`

### Lib モジュール

- **サイレント失敗パターン**: `try { ... } catch { /* skip */ }`
- Docker/tmux コマンドの失敗は握りつぶし、空配列を返却
- ファイル I/O エラーもサイレントにスキップ
- タイムアウト設定: Docker exec 5 秒、Bash exec 10 秒

```typescript
// terminal.ts の典型的パターン
function findDockerContainers(): string[] {
  try {
    const output = execSync(
      "docker ps --format '{{.ID}}' 2>/dev/null",
      { encoding: "utf-8", timeout: 5000 }
    ).trim();
    if (!output) return [];
    return output.split("\n").filter(Boolean);
  } catch {
    return [];  // Docker が利用不可でも正常動作
  }
}
```

## ファイル I/O パターン

### 同期 I/O のみ使用

- `fs.readFileSync`, `fs.readdirSync`, `fs.statSync`
- `execSync`, `execFileSync` (child_process)
- **非同期 I/O は未使用** (Next.js API route 内で同期実行)

### YAML パース

```typescript
import yaml from "js-yaml";

const content = fs.readFileSync(filePath, "utf-8");
const data = yaml.load(content) as Record<string, unknown>;
```

### JSONL パース

```typescript
const lines = content.split("\n").filter(Boolean);
for (const line of lines) {
  try {
    const event = JSON.parse(line);
    // ...
  } catch {
    continue;  // 壊れた行はスキップ
  }
}
```

## プロセス実行パターン

### 安全な実行（execFileSync）

```typescript
// Shell を介さない安全な実行
execFileSync("docker", ["exec", containerId, "tmux", ...args], {
  encoding: "utf-8",
  timeout: 5000,
});
```

### Shell 経由の実行（execSync）

```typescript
// ps コマンドなど、パイプが必要な場合のみ
execSync("ps -eo pid,tty,command 2>/dev/null | grep '/copilot' | grep -v grep", {
  encoding: "utf-8",
  timeout: 5000,
});
```

## テストパターン

### 現状

- **テストファイル: 0** — テスト基盤が存在しない
- `package.json` にテストスクリプトなし
- テストフレームワーク未導入

### Vitest 導入時の推奨パターン

```typescript
// src/lib/__tests__/sessions.test.ts
import { describe, it, expect, vi } from 'vitest';
import { listSessions } from '../sessions';

describe('listSessions', () => {
  it('should return empty array when no sessions exist', () => {
    vi.spyOn(fs, 'readdirSync').mockReturnValue([]);
    expect(listSessions()).toEqual([]);
  });
});
```

## コンポーネントパターン

### Server Components（デフォルト）

```typescript
// src/app/page.tsx
export default function Home() {
  return <main>...</main>;
}
```

### Client Components

```typescript
// "use client" ディレクティブ使用
"use client";
import { useState, useEffect } from "react";

export default function ActiveSessionsDashboard() {
  const [sessions, setSessions] = useState<ActiveSession[]>([]);
  // ...
}
```

### データフェッチ（Client Side）

```typescript
useEffect(() => {
  const fetchSessions = async () => {
    const res = await fetch("/api/active-sessions");
    const data = await res.json();
    setSessions(data);
  };
  fetchSessions();
  const interval = setInterval(fetchSessions, 5000);
  return () => clearInterval(interval);
}, []);
```

- ポーリング方式（5 秒間隔）で Active Sessions を更新
- WebSocket/SSE は未使用

## 認証パターン

### middleware.ts

```typescript
export function middleware(request: NextRequest) {
  const user = process.env.BASIC_AUTH_USER?.trim();
  const pass = process.env.BASIC_AUTH_PASS?.trim();

  // 環境変数未設定時は認証スキップ
  if (!user || !pass) return NextResponse.next();

  // Basic Auth ヘッダー検証
  // ...
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
```

- 環境変数で有効/無効を制御
- Next.js static assets は除外
- 全 API ルートに適用

## 命名規約

| 対象 | 規約 | 例 |
|------|------|-----|
| ファイル名 (コンポーネント) | PascalCase | `ActiveSessionsDashboard.tsx` |
| ファイル名 (ライブラリ) | camelCase | `sessions.ts`, `terminal.ts` |
| ファイル名 (API) | `route.ts` (Next.js 規約) | `src/app/api/sessions/route.ts` |
| 変数名 | camelCase | `sessionState`, `containerUser` |
| 型名 | PascalCase | `SessionMeta`, `ActiveSession` |
| 定数 | UPPER_SNAKE_CASE | `SESSION_STATE_DIR`, `COPILOT_LOGS_DIR` |
| 環境変数 | UPPER_SNAKE_CASE | `BASIC_AUTH_USER`, `ENABLE_DEV_PROCESS` |
