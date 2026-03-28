# インターフェース/API設計

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | tmux-pane-viewer |
| タスク名 | tmux pane ターミナルビューア機能 |
| 作成日 | 2025-07-17 |

---

## 1. WebSocket エンドポイント

### 1.1 新規エンドポイント

| プロトコル | パス | 概要 | 認証 |
|------------|------|------|------|
| WebSocket | `/ws/terminal` | tmux pane のリアルタイム端末ストリーム + キー入力 | Basic Auth（Upgrade ハンドラーで検証） |

### 1.2 修正エンドポイント

なし。既存の REST API エンドポイントは一切変更しない。

---

## 2. WebSocket プロトコル設計

### 2.1 接続確立フロー

```
Client                                     Server
  |                                          |
  |--- HTTP GET /ws/terminal?sessionId=xxx -->|
  |    Headers:                              |
  |      Upgrade: websocket                  |
  |      Connection: Upgrade                 |
  |      Authorization: Basic base64(u:p)    |
  |                                          |
  |    [server.js upgrade handler]           |
  |    1. パス検証 (/ws/terminal)            |
  |    2. Basic Auth 検証                    |
  |    3. sessionId → ActiveSession 解決     |
  |    4. tmuxPane 存在確認                  |
  |                                          |
  |<-- 101 Switching Protocols --------------|
  |                                          |
  |<-- {"type":"connected",...} -------------|
  |                                          |
  |    [capture-pane ループ開始]              |
  |<-- {"type":"output","data":"..."} -------|
  |--- {"type":"input","data":"ls\r"} ------>|
  |    [send-keys 実行]                      |
  |<-- {"type":"output","data":"..."} -------|
  |                                          |
  |--- close -------------------------------->|
  |<-- close ---------------------------------|
```

### 2.2 接続パラメータ（クエリストリング）

| パラメータ | 型 | 必須 | 説明 |
|------------|-----|------|------|
| `sessionId` | string | ✅ | アクティブセッションの ID |

### 2.3 クライアント→サーバー メッセージ

#### `input` — キー入力送信

```typescript
{
  type: "input";
  data: string;  // xterm.js onData の生データ
}
```

#### `resize` — ターミナルサイズ変更

```typescript
{
  type: "resize";
  cols: number;
  rows: number;
}
```

#### `ping` — KeepAlive

```typescript
{
  type: "ping";
}
```

### 2.4 サーバー→クライアント メッセージ

#### `connected` — 接続確立通知

```typescript
{
  type: "connected";
  sessionId: string;
  tmuxPane: string;
  containerId?: string;
  cols: number;   // 現在の pane のカラム数
  rows: number;   // 現在の pane の行数
}
```

#### `output` — 端末出力

```typescript
{
  type: "output";
  data: string;   // capture-pane -p -e の出力（ANSI エスケープ付き全画面）
                  // サーバー側で \x1b[H\x1b[2J（カーソルホーム+画面クリア）をプリペンド済み（MRD-002）
}
```

> **MRD-002 対応**: capture-pane はスナップショット（全画面）を返すため、xterm.js の write() で累積すると画面が崩壊する。サーバー側 ws-terminal.ts の capturePane 出力送信時に `\x1b[H\x1b[2J`（カーソルをホームに移動 + 画面クリア）をプリペンドし、毎回全画面を上書き描画する。

#### `error` — エラー通知

```typescript
{
  type: "error";
  code: string;
  message: string;
}
```

#### `pong` — KeepAlive 応答

```typescript
{
  type: "pong";
}
```

#### `disconnected` — セッション切断通知

```typescript
{
  type: "disconnected";
  reason: DisconnectReason;  // 03_data-structure-design.md の DisconnectReason 型を参照
  // "session_ended" | "pane_closed" | "timeout" | "capture_failed" | "auth_expired" | "server_shutdown"
}
```

### 2.5 エラーコード

| コード | 説明 | クライアント対応 |
|--------|------|-----------------|
| `SESSION_NOT_FOUND` | 指定 sessionId のアクティブセッションが見つからない | エラー表示、モーダルを閉じる |
| `PANE_NOT_FOUND` | セッションに tmuxPane が紐付いていない | エラー表示 |
| `CAPTURE_FAILED` | capture-pane の実行に失敗 | 再接続を提案 |
| `AUTH_FAILED` | 認証失敗（Upgrade 時） | 接続拒否（HTTP 401: 認証情報不正 / HTTP 403: 認証未設定） |
| `CONNECTION_LIMIT` | 同一 pane への接続数上限超過、または環境別の総接続数上限超過 | エラー表示 |

---

## 3. 関数シグネチャ

### 3.1 サーバー側（src/lib/ws-terminal.ts）

```typescript
/**
 * WebSocket ターミナルハンドラーを初期化
 * HTTP server の upgrade イベントに接続する
 */
export function setupTerminalWebSocket(server: http.Server): void;

/**
 * WebSocket 接続の認証を検証
 * Basic Auth ヘッダーを検証。未設定時は false を返しターミナル機能を無効化する（MRD-001）
 */
export function authenticateUpgrade(
  request: http.IncomingMessage
): { authenticated: boolean; reason?: "no_auth_config" | "invalid_credentials" | "missing_header" };

/**
 * sessionId からアクティブセッション情報を解決
 * tmuxPane と containerId/containerUser を取得
 */
export function resolveSession(
  sessionId: string
): Promise<ResolvedSession | null>;

/**
 * capture-pane -p -e を実行し ANSI エスケープ付き出力を取得
 * 前回の出力と比較して差分がある場合のみ返す
 */
export function capturePane(
  tmuxPane: string,
  containerId?: string,
  containerUser?: string
): string;

/**
 * xterm.js onData のキー入力を tmux send-keys で送信
 * 特殊キーは tmux キー名に変換
 */
export function sendInput(
  tmuxPane: string,
  data: string,
  containerId?: string,
  containerUser?: string
): void;

/**
 * tmux pane のサイズ（cols × rows）を取得
 */
export function getPaneSize(
  tmuxPane: string,
  containerId?: string,
  containerUser?: string
): { cols: number; rows: number };

/**
 * tmux pane をリサイズする（MRD-003）
 * resize メッセージ受信時に呼び出される
 * tmux resize-pane -t pane -x cols -y rows を実行
 */
export function resizePane(
  tmuxPane: string,
  cols: number,
  rows: number,
  containerId?: string,
  containerUser?: string
): void;
```

### 3.2 サーバー側（src/lib/terminal.ts — 既存関数の拡張）

```typescript
/**
 * 既存の captureTmuxPane を拡張
 * @param withEscape true の場合 -e フラグを追加（ANSI エスケープ付き）
 */
export function captureTmuxPane(
  tmuxPane: string,
  containerId?: string,
  containerUser?: string,
  withEscape?: boolean        // 追加パラメータ
): string;
```

### 3.3 クライアント側（src/hooks/useTerminalWebSocket.ts）

```typescript
/**
 * WebSocket 接続管理フック
 * 接続の確立・切断・再接続を管理
 */
export function useTerminalWebSocket(
  sessionId: string | null,
  options?: {
    onOutput?: (data: string) => void;
    onConnected?: (info: ConnectedMessage) => void;
    onError?: (error: ErrorMessage) => void;
    onDisconnected?: (reason: string) => void;
  }
): {
  connectionState: ConnectionState;  // 03_data-structure-design.md の ConnectionState 型を参照（MRD2-002）
  error: string | null;
  sendInput: (data: string) => void;
  sendResize: (cols: number, rows: number) => void;
  disconnect: () => void;
};
```

### 3.4 修正関数

| 関数名 | 変更前 | 変更後 | 理由 |
|--------|--------|--------|------|
| `captureTmuxPane` (terminal.ts) | `captureTmuxPane(tmuxPane, containerId?, containerUser?)` | `captureTmuxPane(tmuxPane, containerId?, containerUser?, withEscape?)` | `-e` フラグ対応 |

---

## 4. コンポーネントインターフェース

### 4.1 TerminalModal

```typescript
interface TerminalModalProps {
  session: ActiveSession;   // 対象セッション
  onClose: () => void;      // モーダルを閉じるコールバック
}

/**
 * ターミナルビューアのモーダルコンポーネント
 * - fixed position + z-50 + backdrop パターン（既存パターン準拠）
 * - Escape キーまたは✕ボタンで閉じる
 * - TerminalView と WebSocket 接続を内包
 */
export function TerminalModal({ session, onClose }: TerminalModalProps): JSX.Element;
```

### 4.2 TerminalView

```typescript
interface TerminalViewProps {
  sessionId: string;
  onReady?: (terminal: Terminal) => void;  // xterm.js 初期化完了時
}

/**
 * xterm.js ラッパーコンポーネント（MRD-012: WS接続管理責務を担う）
 * - useRef で DOM 要素を管理
 * - useEffect で xterm.js の初期化・破棄
 * - FitAddon でコンテナサイズに追従
 * - next-themes と xterm.js テーマを同期
 * - useTerminalWebSocket フックを内部で使用し、WebSocket 接続のライフサイクルを管理
 *   （TerminalModal は UI 表示のみ、TerminalView が通信と描画の責務を持つ）
 */
export function TerminalView({ sessionId, onReady }: TerminalViewProps): JSX.Element;
```

### 4.3 ActiveSessionsDashboard への追加

```typescript
// 既存の SessionCard 内に追加するボタン
// tmuxPane が存在するセッションにのみ表示
{session.tmuxPane && (
  <button
    onClick={() => setTerminalSession(session)}
    title="ターミナルを開く"
  >
    {/* ターミナルアイコン */}
  </button>
)}
```

---

## 5. エラーハンドリング

### 5.1 エラー種別

| エラー種別 | 説明 | 対応 |
|------------|------|------|
| 接続エラー | WebSocket 接続に失敗 | 3秒後に自動再接続（最大3回） |
| 認証エラー | Basic Auth 検証失敗 | モーダルにエラー表示、再接続しない |
| セッション未検出 | sessionId に対応するアクティブセッションがない | エラー表示、閉じるボタンのみ |
| pane 未検出 | セッションに tmuxPane がない | エラー表示 |
| capture 失敗 | capture-pane 実行エラー | エラーメッセージ送信、ループ継続 |
| 接続断 | WebSocket 切断 | 自動再接続試行 |

### 5.2 再接続ロジック

```
接続断
  → 1秒待機 → 再接続試行(1/3)
  → 失敗 → 2秒待機 → 再接続試行(2/3)
  → 失敗 → 4秒待機 → 再接続試行(3/3)
  → 失敗 → "接続できません" エラー表示
```

---

## 6. 認証フロー（WebSocket Upgrade）

### 6.1 サーバー側 Upgrade ハンドラー

> **MRD-001 対応**: WebSocket 認証は常時必須。BASIC_AUTH_USER/PASS 未設定時はターミナル機能自体を無効化する。

```
server.on("upgrade") イベント
  ↓
パス検証: pathname === "/ws/terminal" ?
  → No: socket.destroy()
  → Yes: ↓
Basic Auth 環境変数チェック
  → BASIC_AUTH_USER/PASS 未設定: ターミナル機能無効化
    → 403 応答("Terminal feature requires authentication configuration") → socket.destroy()
  → 設定済み: ↓
Authorization ヘッダー検証
  → ヘッダーなし: 401 応答("Authorization header required") → socket.destroy()
  → Basic スキーム以外: 401 応答 → socket.destroy()
  → 認証情報不一致: 401 応答 → socket.destroy()
  → 認証OK: ↓
総接続上限チェック（MRD2-003）
  → ローカル環境: connections.size >= MAX_TOTAL_CONNECTIONS_LOCAL(5) → CONNECTION_LIMIT エラー → socket.destroy()
  → Docker環境: connections.size >= MAX_TOTAL_CONNECTIONS_DOCKER(2) → CONNECTION_LIMIT エラー → socket.destroy()
  → 上限内: WebSocket 確立
```

### 6.2 クライアント側

ブラウザが Basic Auth で認証済みの場合、WebSocket Upgrade リクエストにも `Authorization` ヘッダーが自動付与される。追加のクライアント側実装は不要。

> **MRD-011 対応**: WebSocket Upgrade への Authorization ヘッダー自動付与はブラウザ実装依存。対応ブラウザ: Chrome 16+、Firefox 11+、Safari 7+、Edge 12+。非対応ブラウザでは「ターミナル機能は利用できません」のエラー表示を行う。

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2025-07-17 | 1.0 | 初版作成 | Copilot |
| 2025-07-17 | 1.1 | MRD-001: WS認証必須化、MRD-002: OutputMessage クリアシーケンス、MRD-003: resizePane追加、MRD-011: ブラウザ互換性注記、MRD-012: コンポーネント責務明確化 | Copilot |
| 2025-07-18 | 1.2 | MRD2-002: DisconnectedMessage.reason を DisconnectReason 型に統一、useTerminalWebSocket 返却型を connectionState: ConnectionState に統一 | Copilot |
