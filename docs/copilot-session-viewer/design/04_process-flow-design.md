# 処理フロー設計

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | tmux-pane-viewer |
| タスク名 | tmux pane ターミナルビューア機能 |
| 作成日 | 2025-07-17 |

---

## 1. シーケンス図（修正前/修正後対比）

### 1.1 修正前：現在の tmux pane 内容確認フロー

```mermaid
sequenceDiagram
    participant U as ユーザー
    participant B as ブラウザ
    participant API as API Routes
    participant T as terminal.ts
    participant Tmux as tmux

    Note over U,Tmux: 【修正前】セッション状態確認フロー（ポーリング）

    U->>B: セッション一覧を開く
    B->>API: GET /api/active-sessions
    API->>T: getActiveSessions()
    T->>Tmux: capture-pane -t pane -p
    Note right of Tmux: ANSIエスケープなし
    Tmux-->>T: テキスト内容
    T->>T: sessionState判定(ask_user/working/idle)
    T-->>API: ActiveSession[]
    API-->>B: JSON レスポンス

    Note over B: 10秒ごとにポーリング繰り返し
    Note over U: tmux pane の詳細内容は<br/>直接見ることができない
```

### 1.2 修正後：ターミナルビューアによるリアルタイム表示フロー

```mermaid
sequenceDiagram
    participant U as ユーザー
    participant B as ブラウザ (xterm.js)
    participant WS as WebSocket Server
    participant T as ws-terminal.ts
    participant Tmux as tmux

    Note over U,Tmux: 【修正後】ターミナルビューアフロー（WebSocket）

    U->>B: セッションカードの「ターミナル」ボタンクリック
    B->>B: TerminalModal をレンダリング
    B->>WS: WebSocket 接続 /ws/terminal?sessionId=xxx
    WS->>WS: Basic Auth 検証
    WS->>T: resolveSession(sessionId)
    T->>T: getActiveSessions() → tmuxPane 解決
    T-->>WS: ResolvedSession { tmuxPane, containerId? }
    WS-->>B: {"type":"connected", "tmuxPane":"0:1.0", "cols":80, "rows":24}

    B->>B: xterm.js 初期化 + FitAddon

    loop capture-pane ループ (200ms / 500ms)
        T->>Tmux: capture-pane -t pane -p -e
        Note right of Tmux: ANSIエスケープ付き
        Tmux-->>T: ANSI出力
        T->>T: 前回出力と差分比較
        alt 差分あり
            T->>T: \x1b[H\x1b[2J をプリペンド（MRD-002: 画面クリア）
            T-->>WS: OutputMessage
            WS-->>B: {"type":"output","data":"[クリアシーケンス+ANSIデータ]"}
            B->>B: xterm.js.write(data)
        end
    end

    U->>B: キーボード入力 (例: "ls" + Enter)
    B->>B: xterm.js onData("ls\r")
    B->>WS: {"type":"input","data":"ls\r"}
    WS->>T: sendInput(pane, "ls\r")
    T->>T: "\r" → 分割: send-keys -l "ls" + send-keys Enter
    T->>Tmux: send-keys -t pane -l "ls"
    T->>Tmux: send-keys -t pane Enter
    Note over T,Tmux: 結果は次回 capture-pane で反映

    U->>B: ブラウザウィンドウリサイズ
    B->>B: FitAddon.fit() → cols, rows 算出
    B->>WS: {"type":"resize","cols":120,"rows":40}
    WS->>T: resizePane(pane, 120, 40)
    T->>Tmux: resize-pane -t pane -x 120 -y 40
    Note over T,Tmux: MRD-003: paneリサイズ後、次回captureで新サイズ反映

    U->>B: Escape キー or ✕ボタン
    B->>WS: WebSocket close
    WS->>T: clearInterval(captureLoop)
    WS->>WS: 接続ストアからクリーンアップ
```

### 1.3 変更点サマリー

| 項目 | 修正前 | 修正後 | 理由 |
|------|--------|--------|------|
| 端末内容の取得 | ポーリング(10秒) + capture-pane -p | WebSocket + capture-pane -p -e (200ms) | リアルタイム表示 + ANSI色対応 |
| 表示方式 | セッション状態のみ（テキスト要約） | xterm.js によるフルターミナル描画 | TUI アプリ操作対応 |
| キー入力 | ask_user 応答のみ（テキストフォーム） | xterm.js → WS → send-keys パイプライン | 直接ターミナル操作 |
| 通信方式 | HTTP ポーリング | WebSocket 双方向 | 低レイテンシ |
| サーバー構成 | Next.js standalone server.js | カスタム server.js (HTTP + WS) | WebSocket 対応のため |

---

## 2. 状態遷移図

### 2.1 WebSocket 接続の状態遷移

```mermaid
stateDiagram-v2
    [*] --> Idle: 初期状態
    Idle --> Connecting: ユーザーがターミナルボタンクリック
    Connecting --> Connected: connected メッセージ受信
    Connecting --> Error: 認証失敗 / セッション未検出
    Connected --> Connected: output/input メッセージ交換
    Connected --> Reconnecting: 予期しない切断
    Connected --> Disconnected: disconnected メッセージ受信
    Reconnecting --> Connected: 再接続成功
    Reconnecting --> Error: 再接続3回失敗
    Disconnected --> Idle: ユーザーがモーダルを閉じる
    Error --> Idle: ユーザーがモーダルを閉じる

    note right of Connected
        capture-pane ループ稼働中
        キー入力受付中
    end note

    note right of Reconnecting
        1秒 → 2秒 → 4秒
        指数バックオフ
    end note
```

### 2.2 状態定義

| 状態 | 説明 | 遷移条件（IN） | 遷移条件（OUT） |
|------|------|----------------|-----------------|
| Idle | モーダル未表示 | モーダル閉じる | ターミナルボタンクリック |
| Connecting | WebSocket 接続中 | ボタンクリック | connected / error |
| Connected | アクティブストリーミング中 | 接続確立 | 切断 / エラー |
| Reconnecting | 自動再接続中 | 予期しない切断 | 再接続成功 / 3回失敗 |
| Disconnected | セッション終了による切断 | disconnected メッセージ | モーダル閉じる |
| Error | エラー状態 | 認証失敗 / 再接続失敗 | モーダル閉じる |

---

## 3. エラーフロー

### 3.1 エラーハンドリングフロー

```mermaid
flowchart TD
    A["WebSocket メッセージ受信"] --> B{メッセージ種別}
    B -->|"input"| C{JSON パース}
    C -->|"失敗"| D["無視（ログ出力）"]
    C -->|"成功"| E{セッション存在確認}
    E -->|"No"| F["error: SESSION_NOT_FOUND"]
    E -->|"Yes"| G["sendInput() 実行"]
    G --> H{send-keys 成功?}
    H -->|"Yes"| I["正常完了"]
    H -->|"No"| J["error メッセージ送信"]

    B -->|"capture-pane ループ内"| K{capture-pane 実行}
    K -->|"成功"| L{差分あり?}
    L -->|"Yes"| M["output メッセージ送信"]
    L -->|"No"| N["スキップ"]
    K -->|"失敗（一時的）"| O["エラーカウント++"]
    O --> P{3回連続失敗?}
    P -->|"No"| Q["次回ループで再試行"]
    P -->|"Yes"| R["error: CAPTURE_FAILED<br/>disconnected 送信"]
```

### 3.2 エラー種別と対応

| エラー種別 | 発生条件 | サーバー側対応 | クライアント側対応 | リトライ |
|------------|----------|---------------|-------------------|----------|
| 認証失敗 | Authorization ヘッダー不正 | 401 → socket.destroy() | — (接続不可) | ❌ |
| セッション未検出 | sessionId に対応するアクティブセッションなし | error メッセージ → close | エラー表示 | ❌ |
| pane 未検出 | tmuxPane が null | error メッセージ → close | エラー表示 | ❌ |
| capture 一時失敗 | tmux コマンドエラー | エラーカウント、ループ継続 | — | ✅(自動) |
| capture 連続失敗 | 3回連続 capture 失敗 | disconnected メッセージ → close | 再接続提案 | ✅(ユーザー操作) |
| 予期しない切断 | ネットワーク断等 | — | 自動再接続(3回) | ✅(自動) |
| 接続数超過 | 同一 pane に MAX_CONNECTIONS_PER_PANE 超 | error: CONNECTION_LIMIT → close | エラー表示 | ❌ |

---

## 4. カスタム server.js の処理フロー

### 4.1 サーバー起動フロー

```mermaid
flowchart TD
    A["server.js 起動"] --> B["Next.js app 初期化<br/>next({ dev })"]
    B --> C["app.prepare()"]
    C --> D["HTTP server 作成<br/>createServer()"]
    D --> E["WebSocketServer 作成<br/>new WebSocketServer({ noServer: true })"]
    E --> F["upgrade イベント登録"]
    F --> G["setupTerminalWebSocket(server)"]
    G --> H["server.listen(PORT)"]

    F --> I["upgrade ハンドラー"]
    I --> J{パス === /ws/terminal?}
    J -->|"No"| K["socket.destroy()"]
    J -->|"Yes"| L{認証検証}
    L -->|"失敗"| M["401 応答 → socket.destroy()"]
    L -->|"成功"| N["wss.handleUpgrade()"]
    N --> O["connection イベント"]
    O --> P["resolveSession(sessionId)"]
    P --> Q{セッション存在?}
    Q -->|"No"| R["error メッセージ → close"]
    Q -->|"Yes"| S["TerminalConnection 作成"]
    S --> T["capture-pane ループ開始"]
    T --> U["connected メッセージ送信"]
```

### 4.2 本番モード vs 開発モード

```mermaid
flowchart TD
    A["server.js"] --> B{NODE_ENV}
    B -->|"production"| C["next({ dev: false })<br/>standalone ビルド利用"]
    B -->|"development"| D["next({ dev: true })<br/>HMR + ソースマップ有効"]
    C --> E["同一 HTTP server で<br/>HTTP + WebSocket"]
    D --> E
```

---

## 5. send-keys 入力処理フロー

### 5.1 キー入力変換パイプライン

```mermaid
flowchart TD
    A["xterm.js onData(rawData)"] --> B["WebSocket 送信<br/>{type:'input', data: rawData}"]
    B --> C["サーバー受信"]
    C --> D{rawData の内容を解析}
    D -->|"SPECIAL_KEY_MAP にヒット"| E["tmux キー名に変換<br/>send-keys -t pane keyName"]
    D -->|"通常文字"| F["リテラル送信<br/>send-keys -t pane -l data"]
    D -->|"混合（文字+特殊キー）"| G["文字列を分割"]
    G --> H["通常文字部分: send-keys -l"]
    G --> I["特殊キー部分: send-keys keyName"]

    E --> J{Docker コンテナ?}
    F --> J
    H --> J
    I --> J
    J -->|"No"| K["execFileSync('tmux', args)"]
    J -->|"Yes"| L["execFileSync('docker', ['exec', '-u', uid, cid, 'tmux', ...args])<br/>MRD-004: bash -c 不使用、直接実行に統一"]
```

---

## 6. capture-pane ループ処理フロー

### 6.1 キャプチャ制御フロー

```mermaid
flowchart TD
    A["setInterval 開始<br/>(200ms / 500ms)"] --> B["capture-pane -t pane -p -e 実行"]
    B --> C{実行成功?}
    C -->|"Yes"| D["errorCount = 0"]
    D --> E{出力 !== lastOutput?}
    E -->|"Yes"| F["lastOutput = 出力<br/>\\x1b[H\\x1b[2J をプリペンド（MRD-002）<br/>WS send: OutputMessage"]
    E -->|"No"| G["スキップ"]
    C -->|"No"| H["errorCount++"]
    H --> I{errorCount >= 3?}
    I -->|"No"| G
    I -->|"Yes"| J["WS send: error CAPTURE_FAILED<br/>WS send: disconnected<br/>clearInterval"]
    F --> G
    G --> K["次回 interval へ"]

    L["WS close イベント"] --> M["clearInterval<br/>接続ストアからクリーンアップ"]
```

---

## 7. resize 処理フロー（MRD-003）

### 7.1 resize メッセージ受信時の処理フロー

```mermaid
flowchart TD
    A["WebSocket メッセージ受信<br/>{type:'resize', cols, rows}"] --> B{cols, rows の妥当性検証}
    B -->|"cols < 1 or rows < 1"| C["無視（ログ出力）"]
    B -->|"妥当"| D{Docker コンテナ?}
    D -->|"No"| E["execFileSync('tmux',<br/>['resize-pane', '-t', pane, '-x', cols, '-y', rows])"]
    D -->|"Yes"| F["execFileSync('docker',<br/>['exec', '-u', uid, cid, 'tmux',<br/>'resize-pane', '-t', pane, '-x', cols, '-y', rows])"]
    E --> G["リサイズ完了"]
    F --> G
    G --> H["次回 capture-pane で新サイズの出力を取得"]
```

---

## 8. sendInput 擬似コード（MRD-009）

### 8.1 入力分割アルゴリズム

```typescript
/**
 * sendInput 擬似コード
 * 基本方針: xterm.js onData は通常1キーずつ発火する。
 * ペースト時は複数文字が一括で来るため -l（リテラル）で送信する。
 * エスケープシーケンス途中での分割を防ぐため、先頭からマッチングを行う。
 */
function sendInput(pane: string, data: string, containerId?: string, containerUser?: string): void {
  let remaining = data;

  while (remaining.length > 0) {
    let matched = false;

    // 1. SPECIAL_KEY_MAP の長いキーから順にマッチ（エスケープシーケンス優先）
    for (const [sequence, tmuxKey] of sortedByLengthDesc(SPECIAL_KEY_MAP)) {
      if (remaining.startsWith(sequence)) {
        execTmuxSendKeys(pane, tmuxKey, containerId, containerUser);  // send-keys KeyName
        remaining = remaining.slice(sequence.length);
        matched = true;
        break;
      }
    }

    if (!matched) {
      // 2. 次の特殊キーまでの通常文字をまとめてリテラル送信
      const nextSpecialIdx = findNextSpecialKeyIndex(remaining);
      const literal = nextSpecialIdx === -1 ? remaining : remaining.slice(0, nextSpecialIdx);
      execTmuxSendKeysLiteral(pane, literal, containerId, containerUser);  // send-keys -l "text"
      remaining = remaining.slice(literal.length);
    }
  }
}
```

> **設計判断**: 単一キー入力が主ケース。ペースト時は `send-keys -l` でリテラル送信し、エスケープシーケンスの途中分割を回避する。

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2025-07-17 | 1.0 | 初版作成 | Copilot |
| 2025-07-17 | 1.1 | MRD-002: クリアシーケンスプリペンド、MRD-003: resizeフロー追加、MRD-004: Docker exec統一、MRD-009: sendInput擬似コード追加 | Copilot |
