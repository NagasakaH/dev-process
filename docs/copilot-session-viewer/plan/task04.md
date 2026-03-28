# タスク: task04 - server.js + setupTerminalWebSocket + 結合テスト

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task04 |
| タスク名 | server.js + setupTerminalWebSocket + 結合テスト |
| 前提条件タスク | task03-03 |
| 並列実行可否 | 不可 |
| 推定所要時間 | 30分 |

## 作業環境

- **作業ディレクトリ（worktree）**: submodules/editable/copilot-session-viewer
- **ブランチ**: feature/tmux-pane-viewer

## 前提条件

- task03-03 完了（ws-terminal.ts の全関数が実装済み）
- ws パッケージがインストール済み

## 作業内容

### 目的

リポジトリルートに `server.js` を新規作成し、Next.js standalone をラップした HTTP + WebSocket サーバーを構築する。また `setupTerminalWebSocket` 関数を実装し、WebSocket 接続のライフサイクル（接続確立→capture-pane ループ→メッセージ処理→切断クリーンアップ）を管理する。結合テスト IT-1〜IT-11 を作成して全パイプラインを検証する。

### 設計参照

- `01_implementation-approach.md` §1.1 アーキテクチャ全体像
- `02_interface-api-design.md` §3.1 setupTerminalWebSocket
- `04_process-flow-design.md` §4 カスタム server.js の処理フロー
- `04_process-flow-design.md` §6 capture-pane ループ処理フロー
- `04_process-flow-design.md` §3 エラーフロー

### 実装ステップ

1. **結合テスト作成（RED）**
   - `src/lib/__tests__/ws-terminal.test.ts` に結合テスト (IT-1〜IT-11) を追加
   - テスト内で実際の WebSocket サーバーを起動し、ws クライアントで接続

2. **setupTerminalWebSocket 実装（GREEN）**
   - ws の `WebSocketServer({ noServer: true })` を作成
   - server の `upgrade` イベントを登録
   - パス検証 → 認証 → 接続上限チェック → `wss.handleUpgrade()` → `connection` イベント
   - connection ハンドラー:
     - `resolveSession(sessionId)` → TerminalConnection 作成
     - `getPaneSize()` → connected メッセージ送信
     - `setInterval` で capture-pane ループ開始（200ms/500ms）
     - メッセージハンドラー: input → `sendInput()`, resize → `resizePane()`, ping → pong
     - close ハンドラー: clearInterval, connections.delete

3. **server.js 作成（GREEN）**
   - `const next = require("next");` → `app.prepare()`
   - `http.createServer()` でリクエストハンドラー設定
   - `setupTerminalWebSocket(server)` を呼び出し
   - `server.listen(PORT)`
   - 本番/開発モード分岐

4. **REFACTOR**
   - エラーハンドリング強化（capture 連続失敗 → disconnected）
   - Graceful shutdown 対応

### 対象ファイル

| ファイル | 操作 | 変更内容 |
|----------|------|----------|
| `src/lib/ws-terminal.ts` | 修正 | setupTerminalWebSocket 関数追加、capture ループ、メッセージハンドリング |
| `server.js` | 新規 | カスタムサーバー（HTTP + WS） |
| `src/lib/__tests__/ws-terminal.test.ts` | 修正 | IT-1〜IT-11 結合テスト追加 |

## テスト方針（TDD: RED-GREEN-REFACTOR）

### RED: 失敗するテストケース

```typescript
// src/lib/__tests__/ws-terminal.test.ts - 結合テスト部分

import { WebSocket, WebSocketServer } from "ws";
import http from "http";
import { setupTerminalWebSocket } from "../ws-terminal";

describe("結合テスト: WebSocket ターミナル", () => {
  let server: http.Server;
  let port: number;

  beforeAll(async () => {
    server = http.createServer();
    setupTerminalWebSocket(server);
    await new Promise<void>((resolve) => {
      server.listen(0, () => {
        port = (server.address() as any).port;
        resolve();
      });
    });
  });

  afterAll(() => {
    server.close();
  });

  // IT-1: WS接続→connected メッセージ
  it("WebSocket 接続確立後に connected メッセージが返る", async () => {
    process.env.BASIC_AUTH_USER = "admin";
    process.env.BASIC_AUTH_PASS = "secret";
    const auth = Buffer.from("admin:secret").toString("base64");
    const ws = new WebSocket(
      `ws://localhost:${port}/ws/terminal?sessionId=session-001`,
      { headers: { authorization: `Basic ${auth}` } }
    );

    const msg = await new Promise<any>((resolve) => {
      ws.on("message", (data) => resolve(JSON.parse(data.toString())));
    });

    expect(msg.type).toBe("connected");
    expect(msg.sessionId).toBe("session-001");
    ws.close();
  });

  // IT-2: capture-pane→WS出力
  it("capture-pane の結果が output メッセージとして送信される", async () => {
    // 接続後、output メッセージを受信するまで待機
    const auth = Buffer.from("admin:secret").toString("base64");
    const ws = new WebSocket(
      `ws://localhost:${port}/ws/terminal?sessionId=session-001`,
      { headers: { authorization: `Basic ${auth}` } }
    );

    const messages: any[] = [];
    ws.on("message", (data) => messages.push(JSON.parse(data.toString())));

    await new Promise((r) => setTimeout(r, 500)); // capture ループ待ち
    const outputMsg = messages.find((m) => m.type === "output");
    expect(outputMsg).toBeDefined();
    expect(outputMsg.data).toContain("\x1b[H\x1b[2J"); // MRD-002
    ws.close();
  });

  // IT-3: WS入力→send-keys
  it("InputMessage 受信後に send-keys が実行される", async () => {
    const auth = Buffer.from("admin:secret").toString("base64");
    const ws = new WebSocket(
      `ws://localhost:${port}/ws/terminal?sessionId=session-001`,
      { headers: { authorization: `Basic ${auth}` } }
    );

    await new Promise<void>((resolve) => ws.on("open", resolve));
    ws.send(JSON.stringify({ type: "input", data: "ls\r" }));
    await new Promise((r) => setTimeout(r, 100));

    // sendInput が呼ばれたことを mock で検証
    expect(vi.mocked(execFileSync)).toHaveBeenCalledWith(
      "tmux",
      expect.arrayContaining(["send-keys"]),
      expect.any(Object)
    );
    ws.close();
  });

  // IT-4: 認証→WS接続拒否
  it("認証失敗時に接続が拒否される", async () => {
    const ws = new WebSocket(
      `ws://localhost:${port}/ws/terminal?sessionId=session-001`,
      { headers: { authorization: "Basic " + Buffer.from("wrong:wrong").toString("base64") } }
    );

    await new Promise<void>((resolve) => {
      ws.on("error", () => resolve());
      ws.on("close", () => resolve());
    });
    expect(ws.readyState).not.toBe(WebSocket.OPEN);
  });

  // IT-5: WS切断→クリーンアップ
  it("WebSocket close 後にキャプチャループが停止し接続ストアから削除", async () => {
    const auth = Buffer.from("admin:secret").toString("base64");
    const ws = new WebSocket(
      `ws://localhost:${port}/ws/terminal?sessionId=session-001`,
      { headers: { authorization: `Basic ${auth}` } }
    );
    await new Promise<void>((resolve) => ws.on("open", resolve));

    const connCountBefore = connections.size;
    ws.close();
    await new Promise((r) => setTimeout(r, 200));
    expect(connections.size).toBeLessThan(connCountBefore);
  });

  // IT-6: Docker環境
  it("containerId ありの場合 docker exec 経由で実行", async () => {
    // Docker セッションのモックを設定して接続
    // ...（getActiveSessions モックを docker session に変更）
  });

  // IT-7: 接続再確立
  it("一度切断後に再接続で新しい connected メッセージ受信", async () => {
    // 接続→切断→再接続の流れ
  });

  // IT-8: resize メッセージ→tmux resize-pane
  it("ResizeMessage 受信後に tmux resize-pane が実行される", async () => {
    const auth = Buffer.from("admin:secret").toString("base64");
    const ws = new WebSocket(
      `ws://localhost:${port}/ws/terminal?sessionId=session-001`,
      { headers: { authorization: `Basic ${auth}` } }
    );
    await new Promise<void>((resolve) => ws.on("open", resolve));
    ws.send(JSON.stringify({ type: "resize", cols: 120, rows: 40 }));
    await new Promise((r) => setTimeout(r, 100));

    expect(vi.mocked(execFileSync)).toHaveBeenCalledWith(
      "tmux",
      expect.arrayContaining(["resize-pane", "-x", "120", "-y", "40"]),
      expect.any(Object)
    );
    ws.close();
  });

  // IT-9: 認証未設定時の接続拒否
  it("BASIC_AUTH 未設定時に 403 で接続拒否", async () => {
    delete process.env.BASIC_AUTH_USER;
    delete process.env.BASIC_AUTH_PASS;

    const ws = new WebSocket(
      `ws://localhost:${port}/ws/terminal?sessionId=session-001`
    );

    await new Promise<void>((resolve) => {
      ws.on("error", () => resolve());
      ws.on("close", () => resolve());
    });
    expect(ws.readyState).not.toBe(WebSocket.OPEN);
  });

  // IT-10: ローカル環境の総接続上限
  it("ローカル環境で6番目のWebSocket接続が拒否される", async () => {
    process.env.BASIC_AUTH_USER = "admin";
    process.env.BASIC_AUTH_PASS = "secret";
    const auth = Buffer.from("admin:secret").toString("base64");

    const clients: WebSocket[] = [];
    for (let i = 0; i < 5; i++) {
      const ws = new WebSocket(
        `ws://localhost:${port}/ws/terminal?sessionId=session-${i}`,
        { headers: { authorization: `Basic ${auth}` } }
      );
      await new Promise<void>((resolve) => ws.on("open", resolve));
      clients.push(ws);
    }

    const ws6 = new WebSocket(
      `ws://localhost:${port}/ws/terminal?sessionId=session-5`,
      { headers: { authorization: `Basic ${auth}` } }
    );
    await new Promise<void>((resolve) => {
      ws6.on("error", () => resolve());
      ws6.on("close", () => resolve());
    });
    expect(ws6.readyState).not.toBe(WebSocket.OPEN);

    clients.forEach((c) => c.close());
  });

  // IT-11: Docker環境の総接続上限
  it("Docker環境で3番目のWebSocket接続が拒否される", async () => {
    // Docker セッションモック + 3番目の接続試行
  });
});
```

### GREEN: 最小限の実装

setupTerminalWebSocket と server.js の完全な実装。

### REFACTOR: コード改善

- capture ループのエラーカウント管理
- Graceful shutdown: `process.on("SIGTERM")` で全接続に disconnected 送信

## 完了条件

- [ ] `server.js` が HTTP + WS サーバーとして起動
- [ ] `setupTerminalWebSocket` が Upgrade ハンドラーを正しく登録
- [ ] 認証→接続上限→セッション解決→capture ループのフルパイプラインが動作
- [ ] IT-1〜IT-11 が全通過
- [ ] `node server.js` で開発モードサーバーが起動
- [ ] `npx tsc --noEmit` がエラーなし
- [ ] 既存テストが全通過
