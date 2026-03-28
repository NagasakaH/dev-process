# 既存パターン調査

## 概要

Next.js App Router + React 19 + Tailwind CSS v4 のモダン構成で、React hooks のみで状態管理し、ポーリングベースのリアルタイム更新を実装。テストは Vitest (単体/結合) + Playwright (E2E) で構成される。

## コーディングスタイル

### 設定ファイル

| ファイル | 内容 |
|----------|------|
| `eslint.config.mjs` | ESLint v9 flat config + eslint-config-next |
| `tsconfig.json` | strict: true, module: esnext, bundler resolution |
| `postcss.config.mjs` | @tailwindcss/postcss v4 |
| `src/app/globals.css` | Tailwind v4 インポート、ダークモード設定 |

### 命名規則

| 対象 | 規則 | 例 |
|------|------|-----|
| コンポーネントファイル | PascalCase | `ActiveSessionsDashboard.tsx` |
| ライブラリファイル | kebab-case | `yaml-utils.ts` |
| APIルートファイル | kebab-case ディレクトリ | `api/active-sessions/route.ts` |
| コンポーネント名 | PascalCase | `SessionSidebar` |
| 関数名 | camelCase | `getActiveSessions`, `sendTmuxKeys` |
| 定数 | UPPER_SNAKE_CASE | `MAX_FILE_SIZE`, `SKIP_DIRS`, `AVAILABLE_MODELS` |
| インターフェース名 | PascalCase | `ActiveSession`, `PendingAskUser` |
| 型エイリアス | PascalCase | `SessionState` |
| CSS | Tailwind ユーティリティクラス | `bg-amber-100 text-amber-700` |

## 実装パターン

### API Route パターン

```typescript
// force-dynamic でキャッシュ無効化
export const dynamic = "force-dynamic";

// Next.js 16 のパラメータは Promise で取得
interface RouteParams {
  params: Promise<{ id: string }>;
}

export async function GET(_req: Request, { params }: RouteParams) {
  const { id } = await params;
  // ... ビジネスロジック ...
  return NextResponse.json(result);
}

export async function POST(request: Request, { params }: RouteParams) {
  const { id } = await params;
  const body = await request.json();
  // ... ビジネスロジック ...
  return NextResponse.json({ success: true });
}
```

### ポーリングパターン（コンポーネント）

```typescript
// パターン1: 定期ポーリング（ActiveSessionsDashboard）
useEffect(() => {
  fetchSessions();
  const interval = setInterval(fetchSessions, 10000);
  return () => clearInterval(interval);
}, []);

// パターン2: mtime ベースの変更検出（ConversationTimeline）
useEffect(() => {
  const interval = setInterval(async () => {
    const res = await fetch(`/api/sessions/${sessionId}/event-count`);
    const { mtime } = await res.json();
    if (mtime !== lastMtimeRef.current) {
      lastMtimeRef.current = mtime;
      fetchConversation(false);  // 変更時のみ再取得
    }
  }, 3000);
  return () => clearInterval(interval);
}, [sessionId]);
```

### 状態管理パターン（React hooks のみ）

```typescript
// パターン1: useState でコンポーネント状態
const [sessions, setSessions] = useState<ActiveSession[]>([]);
const [loading, setLoading] = useState(true);

// パターン2: useRef で非UI状態
const autoScrollRef = useRef(true);
const lastMtimeRef = useRef<number>(0);

// パターン3: コールバックによる親子連携
<SessionCard session={session} onRefresh={fetchSessions} />
// 子コンポーネント内で:
setTimeout(() => onRefresh(), 3000);

// パターン4: ローカル Context（ConversationTimeline内のみ）
const UserIdxContext = createContext<{ next: () => number }>({ next: () => 0 });
```

### ターミナル操作パターン (terminal.ts)

```typescript
// execFileSync によるシェルインジェクション防止
// シェル経由ではなく直接プロセス実行
function execTmux(args: string[], containerId?: string, containerUser?: string, timeout = 5000): string {
  if (containerId) {
    const dockerArgs = ["exec", ...(containerUser ? ["-u", containerUser] : []),
      containerId, "tmux", ...args];
    return execFileSync("docker", dockerArgs, { encoding: "utf-8", timeout });
  }
  return execFileSync("tmux", args, { encoding: "utf-8", timeout });
}

// Docker コンテナ向けの複合コマンド（bash -c 経由）
function execContainerBash(bashCmd: string, containerId: string, containerUser?: string, timeout = 10000): string {
  const dockerArgs = ["exec", ...(containerUser ? ["-u", containerUser] : []),
    containerId, "bash", "-c", bashCmd];
  return execFileSync("docker", dockerArgs, { encoding: "utf-8", timeout });
}
```

### モーダル/オーバーレイパターン

```typescript
// パターン: fixed position + z-index + backdrop
function FullscreenModal({ content, onClose }) {
  return (
    <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm">
      <div className="relative w-full max-w-5xl h-[95vh]...">
        <button onClick={onClose}>✕</button>
        {/* コンテンツ */}
      </div>
    </div>
  );
}

// 別パターン: 背景クリックで閉じる
<div className="fixed inset-0 z-40 bg-black/60" onClick={() => setExpanded(false)} />
<div className="fixed inset-4 z-50 flex flex-col...">
  {/* 展開コンテンツ */}
</div>
```

### ダークモードパターン

```css
/* globals.css */
@import "tailwindcss";
@custom-variant dark (&:where(.dark, .dark *));
@plugin "@tailwindcss/typography";

body {
  @apply bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-100;
}
```

```typescript
// ThemeProvider.tsx (next-themes)
<NextThemesProvider attribute="class" defaultTheme="system" enableSystem disableTransitionOnChange>
  {children}
</NextThemesProvider>
```

## テストパターン

### テストファイル配置

```
src/
├── __tests__/
│   └── middleware.test.ts          # ミドルウェアテスト
├── lib/
│   └── __tests__/
│       ├── terminal.test.ts        # ターミナル操作テスト
│       ├── sessions.test.ts        # セッション解析テスト
│       ├── yaml-utils.test.ts      # YAMLユーティリティテスト
│       ├── regression.test.ts      # 回帰テスト
│       ├── env-integration.test.ts # 環境変数統合テスト
│       ├── smoke.test.ts           # スモークテスト
│       ├── ci-config.test.ts       # CI設定テスト
│       ├── standalone-build.test.ts # スタンドアロンビルドテスト
│       └── fixtures/
│           └── session-data.ts     # テストフィクスチャ
├── components/
│   └── __tests__/
│       ├── ThemeToggle.test.tsx     # テーマ切替テスト
│       ├── ThemeProvider.test.tsx   # テーマプロバイダテスト
│       ├── FileViewer.test.tsx      # ファイルビューアテスト
│       └── ComponentSmoke.theme.test.tsx
├── app/api/sessions/[id]/files/
│   └── __tests__/
│       └── route.test.ts           # ファイルAPIテスト
e2e/
├── auth.spec.ts                    # 認証テスト
├── yaml-viewer.spec.ts             # YAMLビューアテスト
├── container-startup.spec.ts       # コンテナ起動テスト
├── container-isolation.spec.ts     # コンテナ分離テスト
└── tmux-stability.spec.ts          # tmux安定性テスト
```

### Vitest 設定

```typescript
// vitest.config.mts
export default defineConfig({
  test: {
    environment: "node",           // デフォルト: Node環境
    environmentMatchGlobs: [
      ["**/*.theme.test.{ts,tsx}", "jsdom"],  // テーマテスト: jsdom
      ["**/components/**/*.test.{ts,tsx}", "jsdom"],  // コンポーネント: jsdom
    ],
    coverage: { include: ["src/lib/**"] },
  },
});
```

### 単体テストパターン

```typescript
// 環境変数スタブ
vi.stubEnv("BASIC_AUTH_USER", "admin");
vi.stubEnv("BASIC_AUTH_PASS", "secret");

// モジュールモック
vi.mock("child_process", async (importOriginal) => {
  const actual = await importOriginal();
  return { ...actual, execSync: vi.fn(actual.execSync) };
});

// テスト間リセット
beforeEach(() => {
  vi.resetModules();
  vi.mocked(execSync).mockReset();
});

afterEach(() => {
  vi.restoreAllMocks();
  vi.unstubAllEnvs();
});
```

### テスト命名規則

```typescript
// UT-N: ユニットテスト番号付き
it("UT-9: should skip auth when env not set", async () => { ... });
it("UT-10: should allow request with correct Basic Auth", async () => { ... });

// INT-N: 統合テスト番号付き
it("INT-4: BASIC_AUTH credentials propagate to middleware", async () => { ... });

// REG-N: 回帰テスト番号付き
it("REG-4: Without Basic Auth credentials, auth is skipped", async () => { ... });

// E2E-N: E2Eテスト番号付き
test("E2E-4: 401 without Basic Auth when configured", async ({ request }) => { ... });
```

### E2E テストパターン (Playwright)

```typescript
// グローバルセットアップでDocker起動・認証ヘッダー構築
// global-setup.ts
const authUser = process.env.BASIC_AUTH_USER?.trim();
const authPass = process.env.BASIC_AUTH_PASS?.trim();
if (authUser && authPass) {
  headers["Authorization"] = "Basic " + Buffer.from(`${authUser}:${authPass}`).toString("base64");
}

// 条件付きスキップ
if (!user || !pass) { test.skip(); return; }

// 環境対応の閾値
const THRESHOLD = process.env.CI ? 4000 : 2000;
```

## エラーハンドリングパターン

```typescript
// パターン1: try/catch で空値返却（terminal.ts）
function captureTmuxPane(tmuxPane: string): string {
  try {
    return execTmux(["capture-pane", "-t", tmuxPane, "-p"]).trim();
  } catch {
    return "";  // エラー時は空文字
  }
}

// パターン2: success/error オブジェクト返却
function sendTmuxKeys(tmuxPane: string, keys: string): { success: boolean; error?: string } {
  try {
    execTmux(["send-keys", "-t", tmuxPane, keys]);
    return { success: true };
  } catch (e) {
    return { success: false, error: String(e) };
  }
}

// パターン3: NextResponse エラーレスポンス
export async function POST(request: Request) {
  try {
    // ... 処理 ...
    return NextResponse.json({ success: true });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
```

## 備考

- **shadcn/ui やHeadless UI は未使用**: モーダル等はすべてカスタム実装（Tailwind CSS直接記述）
- **テスト番号付き命名**: UT-N, INT-N, REG-N, E2E-N の体系的な番号付与
- **force-dynamic**: すべてのAPIルートでキャッシュを無効化
- **execFileSync 優先**: シェルインジェクション防止のため、execSync よりも execFileSync を使用（ただしDokcer複合コマンドは bash -c 経由）
