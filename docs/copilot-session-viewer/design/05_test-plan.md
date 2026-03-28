# テスト計画

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | tmux-pane-viewer |
| タスク名 | tmux pane ターミナルビューア機能 |
| 作成日 | 2025-07-17 |

---

## 1. テスト方針

### 1.1 テストスコープ

| 範囲 | 対象 | 除外 |
|------|------|------|
| 単体テスト (Vitest) | ws-terminal.ts（WS ハンドリング、capture-pane パース、Docker 対応ロジック、キー変換） | xterm.js 内部動作 |
| 結合テスト (Vitest) | WS→capture-pane→出力パイプライン、キー入力往復 | 実 tmux プロセス |
| E2E テスト (Playwright) | モーダル操作、リアルタイム連携、既存機能影響なし | パフォーマンスベンチマーク |

### 1.2 テストカバレッジ目標

| 項目 | 目標値 | 備考 |
|------|--------|------|
| 行カバレッジ | 80% | ws-terminal.ts, useTerminalWebSocket.ts |
| 分岐カバレッジ | 70% | エラーパス・Docker 分岐含む |
| 関数カバレッジ | 90% | 全 export 関数をカバー |

### 1.3 テスト戦略（brainstorming 決定事項準拠）

| テスト種別 | フレームワーク | 対象 |
|------------|--------------|------|
| 単体テスト | Vitest | WS ハンドリング、capture-pane パース、Docker 対応ロジック |
| 結合テスト | Vitest | WS→capture-pane→xterm.js パイプライン、キー入力往復 |
| E2Eテスト | Playwright + Docker Compose | モーダル操作、リアルタイム連携、既存機能影響なし |

---

## 2. 新規テストケース

### 2.1 単体テスト（src/lib/__tests__/ws-terminal.test.ts）

| No | テスト対象 | テスト内容 | 期待結果 | 優先度 |
|----|------------|------------|----------|--------|
| UT-1 | authenticateUpgrade | Basic Auth ヘッダーが正しい場合に true を返す | true | 高 |
| UT-2 | authenticateUpgrade | Basic Auth ヘッダーが不正な場合に false を返す | false | 高 |
| UT-3 | authenticateUpgrade | 環境変数未設定時は認証をスキップ（true） | true | 高 |
| UT-4 | resolveSession | 有効な sessionId でアクティブセッション情報を返す | ResolvedSession オブジェクト | 高 |
| UT-5 | resolveSession | 無効な sessionId で null を返す | null | 高 |
| UT-6 | resolveSession | tmuxPane がないセッションで null を返す | null | 中 |
| UT-7 | capturePane | ローカル tmux で capture-pane -p -e を実行 | ANSI エスケープ付き文字列 | 高 |
| UT-8 | capturePane | Docker exec 経由で capture-pane を実行 | ANSI エスケープ付き文字列 | 高 |
| UT-9 | capturePane | capture-pane 失敗時に空文字を返す | "" | 中 |
| UT-10 | sendInput | 通常文字を send-keys -l で送信 | execFileSync が正しい引数で呼ばれる | 高 |
| UT-11 | sendInput | 特殊キー（\r → Enter）を変換して送信 | send-keys Enter が呼ばれる | 高 |
| UT-12 | sendInput | Ctrl+C（\x03）を tmux C-c に変換 | send-keys C-c が呼ばれる | 高 |
| UT-13 | sendInput | 矢印キー（\x1b[A → Up）を変換 | send-keys Up が呼ばれる | 中 |
| UT-14 | sendInput | 混合入力（文字+Enter）を分割して送信 | send-keys -l + send-keys Enter | 高 |
| UT-15 | sendInput | Docker exec 経由の送信 | docker exec args が正しい | 高 |
| UT-16 | getPaneSize | pane サイズ（cols × rows）を正しく取得 | { cols: 80, rows: 24 } | 中 |
| UT-17 | 差分検出 | 前回と同じ出力の場合は送信しない | ws.send が呼ばれない | 中 |
| UT-18 | 差分検出 | 前回と異なる出力の場合に送信する | ws.send が OutputMessage で呼ばれる | 中 |
| UT-19 | 接続数制限 | 同一 pane に MAX_CONNECTIONS_PER_PANE 超の接続で拒否 | CONNECTION_LIMIT エラー | 中 |
| UT-20 | SPECIAL_KEY_MAP | 全マッピングが正しく定義されている | 全キー対応テーブルとの一致 | 低 |
| UT-21-r | resizePane | ローカル tmux で resize-pane が正しい引数で実行される（MRD-010） | execFileSync が resize-pane -t pane -x cols -y rows で呼ばれる | 中 |
| UT-22-r | resizePane | Docker exec 経由で resize-pane が実行される（MRD-010） | docker exec 引数が正しい | 中 |
| UT-23-r | resizePane | 不正なサイズ（cols=0, rows=-1）で無視される（MRD-010） | execFileSync が呼ばれない | 低 |
| UT-24-r | authenticateUpgrade | Basic Auth 環境変数未設定時に false と "no_auth_config" を返す（MRD-001） | { authenticated: false, reason: "no_auth_config" } | 高 |

### 2.2 単体テスト（src/components/__tests__/TerminalModal.test.tsx）

| No | テスト対象 | テスト内容 | 期待結果 | 優先度 |
|----|------------|------------|----------|--------|
| UT-21 | TerminalModal | モーダルがレンダリングされる | fixed + z-50 要素が存在 | 高 |
| UT-22 | TerminalModal | ✕ボタンで onClose が呼ばれる | onClose コールバック発火 | 高 |
| UT-23 | TerminalModal | Escape キーで onClose が呼ばれる | onClose コールバック発火 | 中 |
| UT-24 | TerminalModal | セッション情報が表示される | sessionId / summary 表示 | 中 |
| UT-25 | TerminalModal | エラー状態で適切なメッセージ表示 | エラーメッセージ要素が存在 | 中 |

### 2.3 単体テスト（src/components/__tests__/TerminalView.test.tsx）

| No | テスト対象 | テスト内容 | 期待結果 | 優先度 |
|----|------------|------------|----------|--------|
| UT-26 | TerminalView | xterm.js Terminal が初期化される | termRef に Terminal がマウント | 高 |
| UT-27 | TerminalView | コンポーネント unmount 時に Terminal.dispose() が呼ばれる | dispose 呼び出し確認 | 高 |
| UT-28 | TerminalView | テーマ変更で xterm.js テーマが同期 | options.theme が更新される | 中 |

### 2.4 結合テスト（src/lib/__tests__/ws-terminal.test.ts 内）

| No | テスト対象 | テスト内容 | 期待結果 | 優先度 |
|----|------------|------------|----------|--------|
| IT-1 | WS接続→セッション解決→capture開始 | WebSocket 接続確立後に connected メッセージが返る | connected メッセージの内容が正しい | 高 |
| IT-2 | capture-pane→WS出力 | capture-pane の結果が OutputMessage として送信される | クライアントが output メッセージを受信 | 高 |
| IT-3 | WS入力→send-keys | InputMessage 受信後に send-keys が実行される | execFileSync が正しく呼ばれる | 高 |
| IT-4 | 認証→WS接続拒否 | 認証失敗時に接続が拒否される | socket が destroy される | 高 |
| IT-5 | WS切断→クリーンアップ | WebSocket close 後にキャプチャループが停止 | clearInterval が呼ばれ、接続ストアから削除 | 高 |
| IT-6 | Docker環境でのcapture+send | containerId ありの場合 docker exec 経由で実行 | docker 引数が正しい | 中 |
| IT-7 | 接続再確立 | 一度切断後に再接続で新しいキャプチャループが開始 | 新しい connected メッセージ受信 | 中 |
| IT-8 | resize メッセージ→tmux resize-pane（MRD-010） | ResizeMessage 受信後に tmux resize-pane が正しい引数で実行される | execFileSync が resize-pane -t pane -x cols -y rows で呼ばれる | 中 |
| IT-9 | 認証未設定時の接続拒否（MRD-001） | BASIC_AUTH 未設定時に WebSocket 接続が拒否される | 403 応答でソケット切断 | 高 |

### 2.5 E2Eテスト（e2e/terminal-viewer.spec.ts）

| No | テストシナリオ | 手順 | 期待結果 | 優先度 |
|----|----------------|------|----------|--------|
| E2E-1 | ターミナルモーダル表示 | 1. トップページ開く 2. アクティブセッション確認 3. ターミナルボタンクリック | モーダルが表示され xterm.js 領域が見える | 高 |
| E2E-2 | リアルタイム表示 | 1. ターミナルモーダル開く 2. 別プロセスで tmux pane に出力 3. 数秒待機 | モーダル内に出力が反映される | 高 |
| E2E-3 | キー入力送信 | 1. ターミナルモーダル開く 2. キーボードで "echo hello" + Enter 入力 | tmux pane で echo コマンドが実行され "hello" が表示される | 高 |
| E2E-4 | モーダル閉じる | 1. ターミナルモーダル開く 2. ✕ボタンクリック | モーダルが閉じ、セッション一覧が見える | 中 |
| E2E-5 | Docker コンテナ内セッション | 1. Docker Compose 環境で起動 2. コンテナ内セッションのターミナルボタンクリック | コンテナ内の tmux pane 内容が表示される | 高 |
| E2E-6 | 既存機能への影響なし — セッション一覧 | 1. トップページ開く 2. セッション一覧が表示される | 既存のセッション一覧が正常に動作 | 高 |
| E2E-7 | 既存機能への影響なし — ask_user 応答 | 1. ask_user 待ちセッションを開く 2. 応答を送信 | 応答が正常に送信される | 高 |
| E2E-8 | 認証付き環境での WebSocket 接続 | 1. Basic Auth 設定あり環境 2. ログイン後にターミナルモーダル開く | WebSocket 接続が認証を通過して確立 | 中 |
| E2E-9 | 未認証 WebSocket 接続拒否（MRD-005） | 1. Basic Auth 設定あり環境 2. 認証なしで /ws/terminal に WebSocket 接続 | 接続が拒否される（401 / socket.destroy） | 高 |
| E2E-10 | 誤認証情報での WebSocket 接続拒否（MRD-005） | 1. Basic Auth 設定あり環境 2. 誤ったユーザー名/パスワードで WebSocket 接続 | 接続が拒否される（401 / socket.destroy） | 高 |
| E2E-11 | 認証後のみ入力可能（MRD-005） | 1. Basic Auth 設定あり環境 2. ログイン後にターミナルモーダル開く 3. キー入力送信 | 認証済みの場合のみ入力が tmux pane に反映される | 高 |
| E2E-12 | ターミナルリサイズ（MRD-010） | 1. ターミナルモーダル開く 2. ブラウザウィンドウサイズ変更 | xterm.js がリサイズされ、tmux pane もリサイズされる | 中 |

---

## 3. acceptance_criteria との対応表

| acceptance_criteria | テスト種別 | テストケース No |
|---------------------|-----------|-----------------|
| アクティブセッション一覧からターミナルビューを開く UI が存在する | E2E | E2E-1 |
| ターミナルビューに tmux pane の内容がリアルタイム表示される | 単体: UT-7,8 / 結合: IT-2 / E2E | E2E-2 |
| キーボード入力が tmux pane に正しく送信される | 単体: UT-10〜15 / 結合: IT-3 / E2E | E2E-3 |
| Docker コンテナ内のセッションでもターミナルビューが動作する | 単体: UT-8,15 / 結合: IT-6 / E2E | E2E-5 |
| 既存のセッション一覧・ask_user 応答機能が正常に動作する | E2E | E2E-6, E2E-7 |
| 認証済みユーザーのみがターミナル操作できること（MRD-005） | 単体: UT-1〜3,UT-24-r / 結合: IT-4,IT-9 / E2E | E2E-8, E2E-9, E2E-10, E2E-11 |
| ターミナルリサイズが正常に動作する（MRD-010） | 単体: UT-21-r〜23-r / 結合: IT-8 / E2E | E2E-12 |

---

## 4. 既存テスト修正

### 4.1 修正が必要なテスト

| ファイル | テスト名 | 修正内容 | 理由 |
|----------|----------|----------|------|
| `src/lib/__tests__/terminal.test.ts` | captureTmuxPane 関連テスト | withEscape パラメータ追加に対応 | captureTmuxPane シグネチャ変更 |

### 4.2 削除が必要なテスト

なし。

---

## 5. テストデータ設計

### 5.1 テストデータ一覧

| データ名 | 用途 | 形式 | 備考 |
|----------|------|------|------|
| mockActiveSession | resolveSession テスト用 | ActiveSession オブジェクト | tmuxPane: "0:1.0", containerId: undefined |
| mockDockerSession | Docker 環境テスト用 | ActiveSession オブジェクト | tmuxPane: "0:1.0", containerId: "abc123", containerUser: "1000" |
| mockCapturePaneOutput | capture-pane 出力テスト用 | string | ANSI エスケープ付きテキスト |
| mockCapturePaneDiff | 差分検出テスト用 | string[] (2件) | 異なる内容の capture-pane 出力ペア |

### 5.2 テストフィクスチャ

```typescript
// src/lib/__tests__/fixtures/terminal-data.ts

export const mockActiveSession: ActiveSession = {
  id: "test-session-001",
  sessionState: "working",
  lastActivity: new Date().toISOString(),
  tmuxPane: "0:1.0",
  summary: "Test session",
};

export const mockDockerSession: ActiveSession = {
  id: "docker-session-001",
  sessionState: "working",
  lastActivity: new Date().toISOString(),
  tmuxPane: "0:1.0",
  containerId: "abc123def456",
  containerUser: "1000",
  summary: "Docker test session",
};

export const mockCapturePaneOutput =
  "\x1b[32muser@host\x1b[0m:\x1b[34m~/project\x1b[0m$ ls\r\n" +
  "file1.txt  file2.txt  src/\r\n" +
  "\x1b[32muser@host\x1b[0m:\x1b[34m~/project\x1b[0m$ ";

export const mockCapturePaneOutputUpdated =
  "\x1b[32muser@host\x1b[0m:\x1b[34m~/project\x1b[0m$ ls\r\n" +
  "file1.txt  file2.txt  src/\r\n" +
  "\x1b[32muser@host\x1b[0m:\x1b[34m~/project\x1b[0m$ echo hello\r\n" +
  "hello\r\n" +
  "\x1b[32muser@host\x1b[0m:\x1b[34m~/project\x1b[0m$ ";
```

---

## 6. モック/スタブ設計

### 6.1 モック対象

| 対象 | モック方法 | 戻り値 |
|------|------------|--------|
| `child_process.execFileSync` | `vi.mock("child_process")` | capture-pane: mockCapturePaneOutput, send-keys: undefined |
| `getActiveSessions()` | `vi.mock("../terminal")` | [mockActiveSession] |
| xterm.js Terminal | jest/vitest mock class | { open: vi.fn(), write: vi.fn(), dispose: vi.fn(), onData: vi.fn() } |
| WebSocket | ws ライブラリの実 WebSocket（テスト内でサーバー起動） | — |

### 6.2 スタブ定義

```typescript
// execFileSync モック
vi.mock("child_process", async (importOriginal) => {
  const actual = await importOriginal<typeof import("child_process")>();
  return {
    ...actual,
    execFileSync: vi.fn((cmd: string, args: string[]) => {
      if (args.includes("capture-pane")) {
        return mockCapturePaneOutput;
      }
      if (args.includes("list-panes")) {
        return "0:1.0: [80x24]";
      }
      return "";
    }),
  };
});

// xterm.js モック（コンポーネントテスト用）
vi.mock("@xterm/xterm", () => ({
  Terminal: vi.fn().mockImplementation(() => ({
    open: vi.fn(),
    write: vi.fn(),
    dispose: vi.fn(),
    onData: vi.fn(),
    loadAddon: vi.fn(),
    options: {},
  })),
}));

vi.mock("@xterm/addon-fit", () => ({
  FitAddon: vi.fn().mockImplementation(() => ({
    fit: vi.fn(),
    proposeDimensions: vi.fn(() => ({ cols: 80, rows: 24 })),
  })),
}));
```

---

## 7. テスト環境

### 7.1 環境要件

| 項目 | 要件 | 備考 |
|------|------|------|
| Node.js | >= 20 | ws ライブラリ互換性 |
| Vitest | ^4.1.0 | 既存バージョン |
| Playwright | ^1.58.2 | 既存バージョン |
| Docker Compose | >= 2.0 | E2E テスト環境 |
| tmux | >= 1.8 | capture-pane -e サポート |

### 7.2 テスト環境設定

```typescript
// vitest.config.mts への追加
environmentMatchGlobs: [
  // 既存
  ["**/*.theme.test.{ts,tsx}", "jsdom"],
  ["**/components/**/*.test.{ts,tsx}", "jsdom"],
  // 追加: TerminalModal/TerminalView テスト
  ["**/components/__tests__/Terminal*.test.tsx", "jsdom"],
],
```

### 7.3 E2E テスト実行手順

```bash
# Docker Compose 環境起動
docker compose -f compose.yaml -f compose.dev.yaml up -d

# E2E テスト実行
npx playwright test e2e/terminal-viewer.spec.ts

# 全 E2E テスト実行（既存 + 新規）
npx playwright test
```

---

## 8. 実行計画

### 8.1 テスト実行順序

1. 単体テスト（Vitest / Node 環境）
2. コンポーネントテスト（Vitest / jsdom 環境）
3. 結合テスト（Vitest / Node 環境、WS サーバー起動）
4. E2E テスト（Playwright / Docker Compose 環境）

### 8.2 テスト実行コマンド

```bash
# 単体 + 結合テスト
npx vitest run src/lib/__tests__/ws-terminal.test.ts

# コンポーネントテスト
npx vitest run src/components/__tests__/TerminalModal.test.tsx src/components/__tests__/TerminalView.test.tsx

# 全テスト
npx vitest run

# E2E テスト
npx playwright test e2e/terminal-viewer.spec.ts
```

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2025-07-17 | 1.0 | 初版作成 | Copilot |
| 2025-07-17 | 1.1 | MRD-005: 認証E2E陰性テスト追加、MRD-010: resizeテストケース追加(UT/IT/E2E) | Copilot |
