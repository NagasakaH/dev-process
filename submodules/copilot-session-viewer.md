# copilot-session-viewer

> 最終更新: 2025-07-24

## 概要

GitHub Copilot CLI のセッションデータ (`~/.copilot/session-state/`) をブラウザから閲覧・操作するための Web ビューア。会話履歴の確認、アクティブセッションの監視、実行中エージェントとの対話（tmux 経由のキー入力送信）、セッション成果物の確認が可能。Docker コンテナ内でのローカルモードもサポートし、Dev-process 連携（ワークツリー管理・Copilot CLI 起動）にも対応する。

---

## 優先度A（必須情報）

### 1. プロジェクト構成

```
copilot-session-viewer/
├── .devcontainer/          # Dev Container 設定
├── e2e/                    # Playwright E2Eテスト
│   ├── global-setup.ts
│   ├── global-teardown.ts
│   ├── auth.spec.ts
│   ├── container-isolation.spec.ts
│   ├── container-startup.spec.ts
│   ├── tmux-stability.spec.ts
│   └── yaml-viewer.spec.ts
├── public/                 # 静的アセット
├── scripts/                # 運用スクリプト
│   ├── cplt               # Copilot CLI ラッパー
│   ├── docker-entrypoint.sh
│   ├── e2e-selftest.sh
│   ├── setup.sh
│   └── start-viewer.sh
├── src/
│   ├── app/                # Next.js App Router ページ & API
│   │   ├── page.tsx                          # トップページ（セッション一覧）
│   │   ├── layout.tsx                        # ルートレイアウト
│   │   ├── sessions/[id]/page.tsx            # セッション詳細ページ
│   │   └── api/                              # API Routes
│   │       ├── sessions/route.ts             #   GET /api/sessions
│   │       ├── sessions/[id]/route.ts        #   GET /api/sessions/[id]
│   │       ├── sessions/[id]/files/route.ts  #   GET /api/sessions/[id]/files
│   │       ├── sessions/[id]/respond/route.ts       #   POST 入力送信
│   │       ├── sessions/[id]/resume/route.ts        #   POST セッション再開
│   │       ├── sessions/[id]/terminate/route.ts     #   POST セッション終了
│   │       ├── sessions/[id]/event-count/route.ts   #   GET イベント数
│   │       ├── sessions/[id]/rate-limit/route.ts    #   GET レート制限
│   │       ├── active-sessions/route.ts      #   GET アクティブセッション
│   │       └── dev-process/start-copilot/route.ts   #   POST Dev-process操作
│   ├── components/         # React クライアントコンポーネント
│   │   ├── ActiveSessionsDashboard.tsx
│   │   ├── ContextWindowBadge.tsx
│   │   ├── ConversationTimeline.tsx
│   │   ├── DevProcessPanel.tsx
│   │   ├── ExpandableTextInput.tsx
│   │   ├── FileViewer.tsx
│   │   ├── ProjectFilesSection.tsx
│   │   ├── RateLimitBanner.tsx
│   │   ├── SessionAskUserPanel.tsx
│   │   ├── SessionFilesSection.tsx
│   │   ├── SessionResumePanel.tsx
│   │   ├── SessionSidebar.tsx
│   │   ├── SessionTodosPanel.tsx
│   │   ├── ThemeProvider.tsx
│   │   ├── ThemeToggle.tsx
│   │   └── renderers/
│   │       ├── MarkdownRenderer.tsx
│   │       └── YamlRenderer.tsx
│   ├── lib/                # サーバーサイドライブラリ
│   │   ├── sessions.ts     # セッションデータ解析
│   │   ├── terminal.ts     # ターミナル操作（tmux/Docker）
│   │   ├── format.ts       # フォーマットユーティリティ
│   │   └── yaml-utils.ts   # YAML セクション解析
│   └── middleware.ts       # Basic Auth ミドルウェア
├── submodules/
│   └── dev-process/        # dev-process サブモジュール
├── Dockerfile              # マルチステージビルド（builder → production）
├── compose.yaml            # 本番用 Docker Compose
├── compose.dev.yaml        # 開発用 Docker Compose オーバーライド
├── .gitlab-ci.yml          # GitLab CI/CD
├── next.config.ts
├── tsconfig.json
├── vitest.config.mts
├── playwright.config.ts
├── eslint.config.mjs
└── postcss.config.mjs
```

**主要ファイル:**
- `src/lib/sessions.ts` — セッションデータ(events.jsonl, workspace.yaml)の解析ロジック
- `src/lib/terminal.ts` — tmux/Docker経由のターミナル操作（アクティブセッション検出、入力送信）
- `src/app/page.tsx` — トップページ（セッション一覧 + アクティブセッションダッシュボード）
- `src/app/sessions/[id]/page.tsx` — セッション詳細ページ（会話タイムライン、ファイルビューア）
- `src/middleware.ts` — Basic Auth ミドルウェア

### 2. 外部公開インターフェース/API

#### API Routes

| エンドポイント | メソッド | 説明 |
|---|---|---|
| `/api/sessions` | GET | セッション一覧取得 |
| `/api/sessions/[id]` | GET | セッション詳細・イベント解析 |
| `/api/sessions/[id]/files` | GET | プロジェクト/セッションファイル取得 |
| `/api/sessions/[id]/respond` | POST | ユーザー入力送信（テキスト、選択肢、フリーフォーム） |
| `/api/sessions/[id]/resume` | POST | セッション再開 |
| `/api/sessions/[id]/terminate` | POST | セッション終了（SIGINT送信） |
| `/api/sessions/[id]/event-count` | GET | イベント数取得 |
| `/api/sessions/[id]/rate-limit` | GET | レート制限ステータス取得 |
| `/api/active-sessions` | GET | アクティブセッション検出（tmux/Docker） |
| `/api/dev-process/start-copilot` | POST | Dev-process操作（起動、ワークツリー管理） |

#### ライブラリ公開インターフェース (`src/lib/`)

**sessions.ts:**
- `listSessions(): SessionMeta[]` — セッション一覧取得
- `getSessionDetail(sessionId: string): SessionDetail | null` — セッション詳細取得
- 型定義: `SessionMeta`, `SessionEvent`, `ConversationEntry`, `TodoItem`, `SessionDetail`, `ContextWindowInfo` 等

**terminal.ts:**
- `getActiveSessions(): ActiveSession[]` — アクティブセッション検出
- `findDockerContainers(): string[]` — Docker コンテナ検出
- `sendTmuxKeys(...)` — tmux 経由のキー入力送信
- `sendAskUserChoice(...)` / `sendAskUserFreeform(...)` — ask_user 応答送信
- `terminateCopilotSession(...)` — セッション終了
- `sendTextInput(...)` — テキスト入力送信
- `checkRateLimitStatus(...)` — レート制限ステータス確認
- `getResumeInfo(sessionId: string): ResumeInfo` — セッション再開情報取得
- 型定義: `ActiveSession`, `PendingAskUser`, `SessionState`, `AgentDef`, `ResumeInfo`

**format.ts:**
- `formatDate(isoString)` — 日付フォーマット
- `relativeTime(isoString)` — 相対時間表示
- `shortId(id)` — セッションID短縮

**yaml-utils.ts:**
- `parseYamlSections(content: string): YamlSection[]` — YAML セクション解析
- `MIN_LINES_FOR_COLLAPSE` — 折りたたみ最小行数定数

### 3. テスト実行方法

```bash
# 単体テスト（Vitest）
npm test               # vitest run
npm run test:watch     # vitest (watchモード)
npm run test:coverage  # vitest run --coverage (src/lib/** のカバレッジ)

# E2Eテスト（Playwright）
npm run test:e2e       # playwright test
npm run test:e2e:ui    # playwright test --ui

# コンテナ内 E2E セルフテスト
docker compose exec viewer e2e-selftest
```

- **単体テスト**: Vitest + jsdom（コンポーネントテスト用）。テストファイルは `src/**/__tests__/**/*.test.{ts,tsx}` に配置。カバレッジは `src/lib/` を対象に v8 プロバイダで取得。
- **E2Eテスト**: Playwright。`e2e/` ディレクトリに配置。globalSetup/globalTeardown でサーバー起動・停止を管理。

### 4. ビルド実行方法

```bash
# 開発サーバー
npm run dev            # next dev (Turbopack)

# 本番ビルド
npm run build          # next build (standalone出力)
npm start              # next start

# リント
npm run lint           # eslint

# Docker ビルド（本番イメージ）
npm install && npm run build
docker build -t copilot-session-viewer:local .

# Docker Compose 起動
TAG=<commit-sha> docker compose up -d
```

- Next.js の `output: "standalone"` により、ビルド成果物は `.next/standalone/` に自己完結型で出力される。
- Dockerfile はマルチステージビルド（devcontainer base → builder → production）。

### 5. 依存関係

#### 本番依存
| パッケージ | バージョン | 用途 |
|---|---|---|
| `next` | 16.2.0 | フレームワーク (App Router) |
| `react` / `react-dom` | 19.2.4 | UI ライブラリ |
| `better-sqlite3` | ^12.8.0 | session.db 読み取り |
| `js-yaml` | ^4.1.1 | YAML 解析 |
| `mermaid` | ^11.13.0 | Mermaid 図レンダリング |
| `react-markdown` | ^10.1.0 | Markdown レンダリング |
| `react-syntax-highlighter` | ^16.1.1 | コードハイライト |
| `remark-gfm` | ^4.0.1 | GitHub Flavored Markdown |
| `next-themes` | ^0.4.6 | テーマ切替 |
| `@tailwindcss/typography` | ^0.5.19 | Tailwind Typography プラグイン |

#### 開発依存
| パッケージ | バージョン | 用途 |
|---|---|---|
| `typescript` | ^5 | 型チェック |
| `vitest` | ^4.1.0 | 単体テスト |
| `@vitest/coverage-v8` | ^4.1.0 | カバレッジ |
| `@playwright/test` | ^1.58.2 | E2Eテスト |
| `@testing-library/react` | ^16.3.2 | コンポーネントテスト |
| `@testing-library/jest-dom` | ^6.9.1 | DOM マッチャー |
| `jsdom` | ^29.0.1 | テスト環境 |
| `tailwindcss` | ^4 | CSS フレームワーク |
| `eslint` / `eslint-config-next` | ^9 / 16.2.0 | リント |

### 6. 技術スタック

| カテゴリ | 技術 |
|---|---|
| 言語 | TypeScript 5 |
| フレームワーク | Next.js 16 (App Router, Turbopack) |
| UIライブラリ | React 19 |
| スタイリング | Tailwind CSS v4 |
| テストフレームワーク | Vitest 4 (単体) + Playwright (E2E) |
| ビルドツール | Next.js (standalone output) |
| DB | better-sqlite3 (session.db 読み取り) |
| コンテナ | Docker (multi-stage) + Docker Compose |
| CI/CD | GitLab CI/CD |
| 認証 | Basic Auth ミドルウェア |

---

## 優先度B（オプション情報）

### 7. 利用方法/Getting Started

**Docker（推奨）:**
```bash
git clone https://gitlab.com/nagasakatools/copilot-session-viewer.git
cd copilot-session-viewer
cp .env.example .env
# .env を編集: GITHUB_TOKEN, TAG を設定
TAG=<commit-sha> docker compose pull
TAG=<commit-sha> docker compose up -d
# → http://localhost:3000
```

**ローカル開発:**
```bash
npm install
cp .env.example .env
npm run dev
# → http://localhost:3000
```

### 8. 環境変数/設定

| 変数名 | 説明 | デフォルト値 |
|---|---|---|
| `GITHUB_TOKEN` | GitHub Personal Access Token | — (必須) |
| `TAG` | コンテナイメージタグ（コミットSHA） | — (必須) |
| `BASIC_AUTH_USER` | Basic Auth ユーザー名（空=無効） | — |
| `BASIC_AUTH_PASS` | Basic Auth パスワード | — |
| `ENABLE_DEV_PROCESS` | Dev-process パネルの有効化 | `false` |
| `DEV_PROCESS_PATH` | dev-process リポジトリのパス | — |
| `DEV_PROCESS_REPO_URL` | 起動時にクローンするリポジトリURL | — |
| `DEV_PROCESS_COPILOT_CMD` | 実行するCopilot CLIコマンド | `copilot --yolo --agent dev-workflow` |
| `DISABLE_DOCKER_DETECTION` | Docker コンテナ検出を無効化 | `false` |
| `PORT` | リッスンポート | `3000` |
| `DEV_MODE` | コンテナ開発モード | `false` |
| `GITLAB_URL` | GitLab URL | `https://gitlab.com` |
| `GITLAB_TOKEN` | GitLab Personal Access Token | — |

### 9. 他submoduleとの連携

- `submodules/dev-process/` — dev-process リポジトリをサブモジュールとして内包。コンテナ内ローカルモードで dev-process ワークフローの起動・管理に使用。

### 14. ライセンス情報

プライベートパッケージ (`"private": true`)
