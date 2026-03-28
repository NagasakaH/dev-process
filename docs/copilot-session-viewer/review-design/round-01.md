# 設計レビュー Round 1 — 統合結果

## 総合判定: rejected

レビューモデル: GPT-5.3-Codex + Claude Opus 4.6

## 統合指摘事項

### MRD-001 [Critical] — WebSocket認証必須化
- **カテゴリ**: セキュリティ/要件整合性
- **指摘**: WebSocket認証が BASIC_AUTH_USER/PASS 未設定時にスキップされる設計で、要件「認証済みユーザーのみ操作可能」を満たせない
- **対象**: 02_interface-api-design.md
- **修正提案**: WS接続を常時認証必須にする。少なくともterminal操作用の明示トークン/セッション検証を必須化し、未設定時はterminal機能を無効化する

### MRD-002 [Major] — capture-pane → xterm.js レンダリング方式未定義
- **カテゴリ**: 技術的妥当性/データフロー設計
- **指摘**: capture-pane のスナップショットを xterm.js write() で流すと画面が累積・重複して崩壊する。カーソルホーム+画面クリア（\x1b[H\x1b[2J）のプリペンドが必要
- **対象**: 04_process-flow-design.md, 02_interface-api-design.md
- **修正提案**: サーバー側 ws-terminal.ts の capturePane 出力時に \x1b[H\x1b[2J をプリペンドする処理を明記。OutputMessage 説明にも反映

### MRD-003 [Major] — resize ハンドラー欠落
- **カテゴリ**: インターフェース設計/機能欠落
- **指摘**: resize メッセージ型は定義済みだがサーバー側処理が未定義。tmux pane リサイズができず TUI 表示が崩れる
- **対象**: 02_interface-api-design.md, 04_process-flow-design.md
- **修正提案**: ws-terminal.ts に resizePane 関数を追加し、tmux resize-pane -t pane -x cols -y rows を実行。Docker対応も含める

### MRD-004 [Major] — Docker exec 方式の不一致
- **カテゴリ**: 実装可能性/設計一貫性
- **指摘**: Docker環境での入力送信が文書間で不一致（execFileSync と bash -c の混在）。サニタイズ責務と安全性境界が曖昧
- **対象**: 04_process-flow-design.md, 01_implementation-approach.md
- **修正提案**: Docker send-keys は execFileSync('docker', ['exec', ...]) で直接実行に統一。bash -c パターンは使用しない方針を明記

### MRD-005 [Major] — 認証E2E陰性テスト不足
- **カテゴリ**: テスト可能性/受け入れ条件
- **指摘**: 認証失敗時のE2E陰性系テストが不足（未認証WS接続拒否、誤認証情報拒否）
- **対象**: 05_test-plan.md
- **修正提案**: E2Eに「未認証WS接続拒否」「誤認証情報で拒否」「認証後のみ入力可能」を追加

### MRD-006 [Minor] — パフォーマンス: バックプレッシャー/イベントループブロッキング
- **カテゴリ**: パフォーマンス
- **指摘**: 固定ポーリングのみで負荷時の調整機構なし。Docker環境で複数接続時にイベントループブロッキングの可能性
- **対象**: 03_data-structure-design.md, 01_implementation-approach.md
- **修正提案**: 同時接続数上限を環境別に設計に明記（ローカル: MAX 5、Docker: MAX 2）。負荷テストシナリオにDocker条件追加

### MRD-007 [Minor] — DisconnectedMessage.reason 不一致
- **カテゴリ**: インターフェース整合性
- **指摘**: DisconnectedMessage.reason の定義値と実フローの切断理由が不一致
- **対象**: 03_data-structure-design.md
- **修正提案**: reason の列挙値にエラー起因切断を追加するか、組み合わせルールを明文化

### MRD-008 [Minor] — TerminalConnection 型に errorCount 欠落
- **カテゴリ**: データ構造設計/型定義不整合
- **指摘**: errorCount フィールドがフローで使用されているが型定義にない
- **対象**: 03_data-structure-design.md
- **修正提案**: TerminalConnection に errorCount: number を追加

### MRD-009 [Minor] — キー入力分割アルゴリズム未定義
- **カテゴリ**: 処理フロー設計
- **指摘**: 混合入力の分割方法が未定義。ペースト時にエスケープシーケンス途中で分割するリスク
- **対象**: 04_process-flow-design.md
- **修正提案**: sendInput の擬似コードを追加。単一キー前提+ペースト時は -l 送信の方式を明記

### MRD-010 [Minor] — resize テストケース欠落
- **カテゴリ**: テスト計画
- **指摘**: resize 関連のテストケースが存在しない
- **対象**: 05_test-plan.md
- **修正提案**: UT/IT/E2E に resize テストケースを追加

### MRD-011 [Info] — ブラウザ WS 認証ヘッダー互換性
- **カテゴリ**: セキュリティ/ブラウザ互換性
- **指摘**: WS Upgrade への Authorization ヘッダー自動付与はブラウザ実装依存
- **修正提案**: 対応ブラウザの明記、非対応時の挙動定義

### MRD-012 [Info] — コンポーネント責務明確化
- **カテゴリ**: 設計明確性
- **指摘**: TerminalModal と TerminalView の責務分担が暗黙的
- **修正提案**: WS接続は TerminalView 内で管理する旨を明記
