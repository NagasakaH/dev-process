# 設計レビュー Round 2 — 統合結果

## 総合判定: approved

レビューモデル: GPT-5.3-Codex + Claude Opus 4.6

## レビュー概要

Round 1 の全12件（MRD-001〜MRD-012）の修正を確認し、残存する4件の指摘を Round 2 として提出。
全4件の修正完了を確認し、設計を approved とする。

---

## Round 2 統合指摘事項（全4件）

### MRD2-001 [Major] — UT-3 と UT-24-r の矛盾 + 認証ステータスコード整備
- **カテゴリ**: テスト計画/セキュリティ設計
- **指摘**: UT-3（旧仕様「未設定時 true」）と UT-24-r（MRD-001 対応後「未設定時 authenticated: false」）が矛盾。また、認証失敗ステータスコード（401/403）の使い分けが不明確
- **対象**: 05_test-plan.md, 04_process-flow-design.md, 06_side-effect-verification.md
- **修正提案**:
  1. UT-3 を削除し UT-24-r に統合
  2. 認証ヘッダー不正→401、認証未設定→403 を明記
  3. セキュリティ検証表を更新
- **解決状況**: ✅ 解決済み
  - UT-3 を削除、UT-24-r の説明に「旧 UT-3 を統合」を追記
  - 04_process-flow-design.md のフローチャートとエラー表に 401/403 使い分けを明記
  - 06_side-effect-verification.md のセキュリティ検証項目を 401/403 対応に更新
  - acceptance_criteria 対応表から UT-3 参照を削除

### MRD2-002 [Minor] — DisconnectedMessage.reason / インターフェース不整合
- **カテゴリ**: インターフェース整合性
- **指摘**: 02_interface の DisconnectedMessage.reason が `string` 型（3値のみ）で、03_data-structure の DisconnectReason 列挙（6値）と不一致。また useTerminalWebSocket の返却型が `isConnected: boolean`（02）と `connectionState: ConnectionState`（03）で不整合
- **対象**: 02_interface-api-design.md
- **修正提案**:
  1. DisconnectedMessage.reason を DisconnectReason 型に統一
  2. useTerminalWebSocket の返却型を `connectionState: ConnectionState` に統一
- **解決状況**: ✅ 解決済み
  - DisconnectedMessage.reason の型を `DisconnectReason` に変更、全6値をコメントで列挙
  - useTerminalWebSocket の返却型を `connectionState: ConnectionState` に変更（`isConnected: boolean` を置換）

### MRD2-003 [Minor] — 総接続上限チェックのフロー化・テスト追加
- **カテゴリ**: 処理フロー設計/テスト計画
- **指摘**: 03_data-structure で定義された `MAX_TOTAL_CONNECTIONS_LOCAL(5)` / `MAX_TOTAL_CONNECTIONS_DOCKER(2)` の総接続上限チェックが接続フローに組み込まれていない。テストケースも不足
- **対象**: 04_process-flow-design.md, 05_test-plan.md
- **修正提案**:
  1. 接続フローに総接続上限チェックの判定ノードを追加
  2. UT/IT に「ローカル5超・Docker2超」の明示テストケースを追加
- **解決状況**: ✅ 解決済み
  - 04_process-flow-design.md: サーバー起動フローの認証成功後に総接続上限チェックノードを追加
  - 02_interface-api-design.md: 認証フロー（6.1）に総接続上限チェックステップを追加
  - 05_test-plan.md: UT-25-r（ローカル上限）、UT-26-r（Docker上限）、IT-10（ローカルIT）、IT-11（Docker IT）を追加

### MRD2-004 [Minor] — ConnectionState に "reconnecting" 追加
- **カテゴリ**: データ構造設計
- **指摘**: 03_data-structure の状態遷移図には "Reconnecting" 状態が存在するが、ConnectionState 型定義に含まれていない
- **対象**: 03_data-structure-design.md
- **修正提案**: ConnectionState 型に "reconnecting" を追加
- **解決状況**: ✅ 解決済み
  - ConnectionState 型に `"reconnecting"` を追加: `"connecting" | "connected" | "reconnecting" | "disconnected" | "error"`

---

## Round 1 指摘の確認状況

| ID | 重大度 | 指摘 | Round 1 対応 | Round 2 確認 |
|----|--------|------|-------------|-------------|
| MRD-001 | Critical | WS認証必須化 | ✅ 修正済み | ✅ 確認済み（MRD2-001 で 401/403 補完） |
| MRD-002 | Major | capture-pane レンダリング方式 | ✅ 修正済み | ✅ 確認済み |
| MRD-003 | Major | resize ハンドラー欠落 | ✅ 修正済み | ✅ 確認済み |
| MRD-004 | Major | Docker exec 方式不一致 | ✅ 修正済み | ✅ 確認済み |
| MRD-005 | Major | 認証E2E陰性テスト不足 | ✅ 修正済み | ✅ 確認済み |
| MRD-006 | Minor | バックプレッシャー/接続上限 | ✅ 修正済み | ✅ 確認済み（MRD2-003 でフロー補完） |
| MRD-007 | Minor | DisconnectedMessage.reason 不一致 | ✅ 修正済み | ✅ 確認済み（MRD2-002 でインターフェース統一） |
| MRD-008 | Minor | errorCount 欠落 | ✅ 修正済み | ✅ 確認済み |
| MRD-009 | Minor | キー入力分割アルゴリズム | ✅ 修正済み | ✅ 確認済み |
| MRD-010 | Minor | resize テストケース | ✅ 修正済み | ✅ 確認済み |
| MRD-011 | Info | ブラウザ WS 認証互換性 | ✅ 修正済み | ✅ 確認済み |
| MRD-012 | Info | コンポーネント責務明確化 | ✅ 修正済み | ✅ 確認済み |

---

## 修正ファイル一覧

| ファイル | 修正内容 |
|----------|----------|
| 02_interface-api-design.md | DisconnectedMessage.reason→DisconnectReason型、hook返却型→connectionState、認証フロー401/403明記、エラーコード表更新 |
| 03_data-structure-design.md | ConnectionState に "reconnecting" 追加 |
| 04_process-flow-design.md | 認証ステータスコード401/403使い分け、総接続上限チェックノード追加 |
| 05_test-plan.md | UT-3削除(UT-24-rに統合)、UT-25-r/UT-26-r/IT-10/IT-11追加 |
| 06_side-effect-verification.md | セキュリティ検証表を401/403対応+総接続上限検証追加 |
