# copilot-session-viewer

> 最終更新: 2025-07-18

## 概要

GitHub Copilot CLI のセッションデータ (`~/.copilot/session-state/`) をブラウザから閲覧・操作するための Web ビューア。会話履歴の確認、アクティブセッションの監視、実行中エージェントとの対話（ask_user応答・終了）、セッション成果物の確認が可能。

---

## 優先度A（必須情報）

### 1. プロジェクト構成

```
copilot-session-viewer/
├── src/
│   ├── app/
│   │   ├── api/
│   │   │   ├── active-sessions/route.ts
│   │   │   ├── dev-process/start-copilot/route.ts
│   │   │   └── sessions/
│   │   │       ├── route.ts
│   │   │       └── [id]/
│   │   │           ├── route.ts
│   │   │           ├── event-count/route.ts
│   │   │           ├── files/route.ts
│   │   │           ├── respond/route.ts
│   │   │           └── terminate/route.ts
│   │   ├── sessions/[id]/page.tsx
│   │   ├── page.tsx
│   │   ├── layout.tsx
│   │   └── globals.css
│   ├── components/
│   │   ├── ActiveSessionsDashboard.tsx
│   │   ├── ContextWindowBadge.tsx
│   │   ├── ConversationTimeline.tsx
│   │   ├── DevProcessPanel.tsx
│   │   ├── ExpandableTextInput.tsx
│   │   ├── MarkdownFileViewer.tsx
│   │   ├── ProjectFilesSection.tsx
│   │   ├── SessionAskUserPanel.tsx
│   │   ├── SessionFilesSection.tsx
│   │   ├── SessionSidebar.tsx
│   │   └── SessionTodosPanel.tsx
│   ├── lib/
│   │   ├── format.ts
│   │   ├── sessions.ts
│   │   └── terminal.ts
│   └── middleware.ts
├── public/
├── package.json
├── tsconfig.json
├── next.config.ts
└── submodules/dev-process/
```

**主要ファイル:**

| ファイル | 役割 |
|---|---|
| `src/app/page.tsx` | トップページ（セッション一覧 + アクティブセッション） |
| `src/app/sessions/[id]/page.tsx` | セッション詳細ページ |
| `src/lib/sessions.ts` | セッションデータ解析（events.jsonl, workspace.yaml, session.db） |
| `src/lib/terminal.ts` | ターミナル操作（tmux, Docker exec, 入力送信） |
| `src/lib/format.ts` | フォーマットユーティリティ（日付、相対時刻、短縮ID） |
| `src/middleware.ts` | Basic Auth ミドルウェア |
| `next.config.ts` | Next.js設定（allowedDevOrigins） |

### 2. 外部公開インターフェース/API

#### API Routes

| メソッド | エンドポイント | 説明 |
|---|---|---|
| GET | `/api/sessions` | セッション一覧取得 |
| GET | `/api/sessions/[id]` | セッション詳細・イベント解析 |
| GET | `/api/sessions/[id]/files` | プロジェクト/セッションファイル取得 |
| GET | `/api/sessions/[id]/event-count` | イベント数取得 |
| POST | `/api/sessions/[id]/respond` | ユーザー入力送信（テキスト、選択肢、フリーフォーム） |
| POST | `/api/sessions/[id]/terminate` | セッション終了（SIGINT送信） |
| GET | `/api/active-sessions` | アクティブセッション検出（tmux/Docker） |
| GET/POST/DELETE | `/api/dev-process/start-copilot` | Dev-process操作（一覧、起動、ワークツリー管理） |

#### ライブラリ公開インターフェース

**`lib/sessions.ts`:**
- `listSessions(): SessionMeta[]` — セッション一覧取得
- `getSessionDetail(sessionId: string): SessionDetail | null` — セッション詳細取得
- 型定義: `SessionMeta`, `SessionEvent`, `UserMessage`, `AssistantMessage`, `ToolRequest`, `ToolExecution`, `SubagentEvent`, `SessionShutdown`, `ConversationEntry`, `TodoItem`, `RunningUsage`, `ContextWindowSnapshot`, `ContextWindowInfo`, `SessionDetail`

**`lib/terminal.ts`:**
- `getActiveSessions(): ActiveSession[]` — アクティブセッション検出
- `sendTmuxKeys(...)` — tmux経由キー入力送信
- `sendAskUserChoice(...)` — ask_user選択肢応答
- `sendAskUserFreeform(...)` — ask_userフリーフォーム応答
- `terminateCopilotSession(...)` — セッション終了
- `sendTextInput(...)` — テキスト入力送信
- 型定義: `PendingAskUser`, `SessionState`, `ActiveSession`

**`lib/format.ts`:**
- `formatDate(isoString)` — 日付フォーマット
- `relativeTime(isoString)` — 相対時刻表示
- `shortId(id)` — ID短縮表示

#### コンポーネント

| コンポーネント | 役割 |
|---|---|
| `ActiveSessionsDashboard` | アクティブセッション表示（intent, タスク, todo） |
| `ConversationTimeline` | 会話タイムライン（シンタックスハイライト、サブエージェント色分け） |
| `MarkdownFileViewer` | マークダウンファイル表示（ツリー、フルスクリーン） |
| `SessionTodosPanel` | 右サイドバー（Todo進捗、ナビゲーション） |
| `SessionSidebar` | 左サイドバー（セッションリスト） |
| `SessionAskUserPanel` | ask_user応答パネル |
| `DevProcessPanel` | Dev-process操作パネル |
| `ContextWindowBadge` | コンテキストウィンドウ使用量バッジ |
| `ExpandableTextInput` | 展開可能テキスト入力 |
| `ProjectFilesSection` | プロジェクトファイルセクション |
| `SessionFilesSection` | セッションファイルセクション |

### 3. テスト実行方法

```bash
# テストなし
```

テストファイル・テストフレームワークは未導入。`package.json` にも `test` スクリプトは定義されていない。

### 4. ビルド実行方法

```bash
# 開発サーバー
npm run dev

# 本番ビルド
npm run build

# 本番起動
npm start

# リント
npm run lint   # eslint
```

### 5. 依存関係

#### 本番依存

| パッケージ | バージョン | 用途 |
|---|---|---|
| next | 16.2.0 | Webフレームワーク（App Router） |
| react / react-dom | 19.2.4 | UIライブラリ |
| react-markdown | ^10.1.0 | Markdown表示 |
| react-syntax-highlighter | ^16.1.1 | シンタックスハイライト |
| remark-gfm | ^4.0.1 | GitHub Flavored Markdown |
| mermaid | ^11.13.0 | Mermaid図表レンダリング |
| better-sqlite3 | ^12.8.0 | SQLiteアクセス（session.db） |
| js-yaml | ^4.1.1 | YAML解析（workspace.yaml） |
| @tailwindcss/typography | ^0.5.19 | Tailwind Typographyプラグイン |

#### 開発依存

| パッケージ | バージョン | 用途 |
|---|---|---|
| typescript | ^5 | 型システム |
| tailwindcss | ^4 | CSSフレームワーク |
| @tailwindcss/postcss | ^4 | PostCSSプラグイン |
| eslint / eslint-config-next | ^9 / 16.2.0 | リンター |
| @types/node, @types/react, @types/react-dom | 各種 | 型定義 |
| @types/better-sqlite3, @types/js-yaml | 各種 | 型定義 |
| @types/react-syntax-highlighter | ^15.5.13 | 型定義 |

### 6. 技術スタック

| カテゴリ | 技術 |
|---|---|
| 言語 | TypeScript 5 |
| フレームワーク | Next.js 16 (App Router, Turbopack) |
| UI | React 19, Tailwind CSS v4 |
| ビルドツール | Next.js (Turbopack) |
| テストフレームワーク | なし（未導入） |
| リンター | ESLint 9 |
| データアクセス | better-sqlite3 (session.db), js-yaml, fs (events.jsonl) |
| ターミナル連携 | tmux (send-keys), child_process |

---

## 優先度B（オプション情報）

### 7. 利用方法/Getting Started

```bash
# 依存関係のインストール
npm install

# 環境変数の設定（オプション）
# .env.local を作成して設定

# 開発サーバー起動
npm run dev

# 本番ビルド＆起動
npm run build
PORT=3456 npm start
```

セッションデータは `~/.copilot/session-state/` から自動読み込み。

### 8. 環境変数/設定

| 変数名 | 説明 | デフォルト値 |
|---|---|---|
| `BASIC_AUTH_USER` | Basic Auth ユーザー名（空=認証無効） | — |
| `BASIC_AUTH_PASS` | Basic Auth パスワード | — |
| `ENABLE_DEV_PROCESS` | Dev-process パネルの有効化 | `false` |
| `DEV_PROCESS_PATH` | dev-process リポジトリのパス | — |
| `DEV_PROCESS_COPILOT_CMD` | 実行するCopilot CLIコマンド | `copilot --yolo --agent dev-workflow` |

### 9. 他submoduleとの連携

- `submodules/dev-process/` — Dev-process操作パネルがこのサブモジュールと連携し、Docker dev-container 内で Copilot CLI セッション起動・Git ワークツリー管理を行う。
