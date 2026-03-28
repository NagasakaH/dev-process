# 実装方針

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | tmux-pane-viewer |
| タスク名 | tmux pane ターミナルビューア機能 |
| 作成日 | 2025-07-17 |

---

## 1. 選定したアプローチ

### 1.1 実装方針

Next.js standalone 出力をラップするカスタム server.js を作成し、HTTP サーバーに WebSocket サーバー（ws ライブラリ）を同居させる。フロントエンドでは xterm.js をモーダル内に配置し、WebSocket 経由で tmux capture-pane（`-e` フラグ付き）のリアルタイムストリームを受信、キーボード入力を send-keys で tmux pane に転送する。

**アーキテクチャの全体像:**

```
[Browser: xterm.js TerminalModal]
    ↕ WebSocket (ws://host:3000/ws/terminal?sessionId=xxx)
[server.js: HTTP + WebSocket Server]
    ↕ execFileSync / docker exec
[tmux: capture-pane -p -e / send-keys]
```

**実装レイヤー:**

1. **サーバー層**: カスタム server.js（Next.js standalone ラッパー + WebSocket Server）
2. **WebSocket ハンドラー層**: `src/lib/ws-terminal.ts`（接続管理、capture-pane ループ、send-keys 処理）
3. **フロントエンド層**: `TerminalModal` + `TerminalView` コンポーネント + `useTerminalWebSocket` フック
4. **統合層**: `ActiveSessionsDashboard` へのターミナル起動ボタン追加

### 1.2 技術選定

| 技術/ツール | 選定理由 | 備考 |
|-------------|----------|------|
| ws | Node.js 標準的な WebSocket ライブラリ。noServer モードで HTTP サーバーと共存可能 | socket.io は過剰、ブラウザ側も標準 WebSocket API で十分 |
| @xterm/xterm v5 | ANSI エスケープシーケンス完全対応のターミナルエミュレータ。React 19 と互換（DOM 直接操作） | React ラッパー不要 |
| @xterm/addon-fit | xterm.js のサイズをコンテナに自動追従 | モーダルリサイズ対応 |
| capture-pane -p -e | ANSI エスケープ付きで端末内容を取得 | 既存の `-p` のみから拡張 |
| send-keys -l | xterm.js onData の入力をリテラルとして安全に tmux に送信 | シェルインジェクション防止 |

---

## 2. 代替案の比較

| 案 | 概要 | メリット | デメリット | 採用 |
|----|------|----------|------------|------|
| 案1: カスタム server.js + ws | standalone server.js をラップし WS サーバーを同居 | 同一ポートで HTTP/WS 共存、既存デプロイメントパイプライン変更最小 | カスタムサーバーのメンテナンス負荷 | ✅ |
| 案2: 別プロセスで WS サーバー | Next.js とは別に WS 専用サーバーを起動 | 関心の分離が明確 | ポート追加・CORS設定・Docker compose 変更が必要 | ❌ |
| 案3: SSE (Server-Sent Events) | API Route で SSE ストリームを使用 | Next.js App Router 内で完結 | 双方向通信不可（入力に別 API が必要）、レイテンシ増大 | ❌ |
| 案4: socket.io | リアルタイム通信フレームワーク | 自動再接続・Room機能 | 過剰な抽象化、バンドルサイズ増加、カスタムサーバー要は同じ | ❌ |

---

## 3. 採用理由

### 3.1 決定要因

1. **双方向リアルタイム通信の要件**: ターミナルビューアでは capture-pane の出力受信とキー入力送信を低レイテンシで双方向に行う必要があり、WebSocket が最適
2. **既存アーキテクチャとの親和性**: 既存 terminal.ts の execTmux/execContainerBash パターンをそのまま WebSocket ハンドラーから呼び出せる
3. **デプロイメント影響の最小化**: 同一ポートで動作するため、compose.yaml のポート設定変更不要
4. **ブラウザ標準 API**: ws ライブラリ + ブラウザ標準 WebSocket API の組み合わせで追加クライアントライブラリ不要

### 3.2 トレードオフ

- **カスタム server.js のメンテナンス**: Next.js のメジャーアップデート時にカスタム server.js の互換性確認が必要。ただし Next.js standalone の server.js は安定した API（createServer + getRequestHandler）を提供しており、リスクは低い
- **開発モードとの差異**: `next dev` ではカスタム server.js を使用しないため、開発時は `node server.js` で起動する必要がある。`package.json` の `dev` スクリプトを更新する

---

## 4. 制約事項

| 制約 | 影響 | 対応方針 |
|------|------|----------|
| Next.js App Router は WebSocket 非対応 | API Routes 内で WS Upgrade を処理できない | カスタム server.js の Upgrade ハンドラーで処理 |
| standalone 出力の server.js は immutable | 直接編集不可 | ラッパー server.js から require して使用 |
| capture-pane は差分取得不可 | 毎回全画面取得が必要 | サーバー側で前回出力と比較、差分がある場合のみ送信 |
| tmux send-keys は同期実行 | execFileSync でブロッキング | WebSocket メッセージ処理を非同期キューで管理 |
| Docker exec オーバーヘッド 30-100ms | リアルタイム性低下 | Docker 環境ではキャプチャ間隔を 500ms に設定 |
| ブラウザ WebSocket API はカスタムヘッダー非対応 | Authorization ヘッダーを直接設定できない | Upgrade リクエストの Authorization ヘッダー（ブラウザ Basic Auth 済み時に自動付与）を利用 |

---

## 5. 前提条件

- [x] tmux がホスト/コンテナにインストール済み
- [x] `capture-pane -e` フラグが利用可能な tmux バージョン（1.8+）
- [x] Node.js 20+ ランタイム
- [x] 既存の terminal.ts の execTmux / execContainerBash が正常動作
- [x] Next.js 16 の standalone ビルドが正常動作
- [ ] ws パッケージの追加（新規依存）
- [ ] @xterm/xterm, @xterm/addon-fit パッケージの追加（新規依存）

---

## 変更ファイル一覧

### 追加ファイル

| ファイル | 目的 |
|----------|------|
| `server.js` | カスタムサーバー（HTTP + WebSocket） |
| `src/lib/ws-terminal.ts` | WebSocket ターミナルハンドラー（接続管理、capture-pane ループ、send-keys） |
| `src/components/TerminalModal.tsx` | ターミナルモーダル（オーバーレイ UI） |
| `src/components/TerminalView.tsx` | xterm.js ラッパーコンポーネント |
| `src/hooks/useTerminalWebSocket.ts` | WebSocket 接続管理フック |
| `src/lib/__tests__/ws-terminal.test.ts` | WebSocket ハンドラーの単体テスト |
| `src/components/__tests__/TerminalModal.test.tsx` | モーダルコンポーネントテスト |
| `src/components/__tests__/TerminalView.test.tsx` | xterm.js ラッパーテスト |
| `e2e/terminal-viewer.spec.ts` | E2E テスト |

### 修正ファイル

| ファイル | 変更内容 |
|----------|----------|
| `src/components/ActiveSessionsDashboard.tsx` | セッションカードにターミナルボタン追加 |
| `src/lib/terminal.ts` | captureTmuxPane に `-e` フラグオプション追加 |
| `package.json` | ws, @xterm/xterm, @xterm/addon-fit 依存追加、dev スクリプト更新 |
| `scripts/start-viewer.sh` | カスタム server.js 起動に変更 |
| `Dockerfile` | server.js をコピーに含める |

### 削除ファイル

なし

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2025-07-17 | 1.0 | 初版作成 | Copilot |
