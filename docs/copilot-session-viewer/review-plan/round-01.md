# タスク計画レビュー Round 1: tmux-pane-viewer

## レビュー概要

| 項目 | 値 |
|------|-----|
| チケットID | tmux-pane-viewer |
| レビューラウンド | 1 |
| レビュー日時 | 2026-03-28 |
| 指摘件数 | 9件（Major: 3, Minor: 6） |
| 判定 | approved（全件修正済み） |

---

## 指摘事項一覧

### 🟠 Major Issues

#### MRP-001: task04 見積もり過小（30→60分）、分割推奨

| 項目 | 内容 |
|------|------|
| 重要度 | 🟠 Major |
| ステータス | ✅ Resolved |

**問題**: task04 は server.js + setupTerminalWebSocket 実装 + 11 件の結合テスト（IT-1〜IT-11）を 30分で完了する見積もりだった。実装量に対して過小見積もり。

**修正内容**:
- task04 を task04-01（server.js + setupTerminalWebSocket 実装, 30分）と task04-02（結合テスト IT-1〜IT-11, 30分）に分割
- task04-01.md, task04-02.md を新規作成、task04.md を削除
- task-list.md, parent-agent-prompt.md の依存関係・並列グループ・Mermaidグラフを更新
- 総タスク数を 13 → 14、推定総工数を 200分 → 230分に更新

---

#### MRP-002: useTerminalWebSocket にテストなし

| 項目 | 内容 |
|------|------|
| 重要度 | 🟠 Major |
| ステータス | ✅ Resolved |

**問題**: task05-01 の useTerminalWebSocket フックは「コンポーネントテストで間接的にカバー」「テストはオプション」と記載されており、フック固有の再接続ロジック・KeepAlive ping/pong・状態遷移の直接テストが欠落していた。

**修正内容**:
- task05-01.md の RED セクションに 5 件の具体的テストケースを追加:
  - UT-29: sessionId null → 未接続
  - UT-30: connecting → connected 状態遷移
  - UT-31: 再接続ロジック（指数バックオフ 1s→2s→4s、最大3回）
  - UT-32: KeepAlive ping 送信 + pong タイムアウト
  - UT-33: error メッセージ → error 状態遷移
- MockWebSocket クラスの充実（close 挙動、コンストラクタでの onopen 呼び出し）
- task-list.md に useTerminalWebSocket.test.ts のテスト ID マッピング追加
- 完了条件に UT-29〜33 通過と KeepAlive 実装を追加

---

#### MRP-003: IT-6/IT-7/IT-11 骨格のみ

| 項目 | 内容 |
|------|------|
| 重要度 | 🟠 Major |
| ステータス | ✅ Resolved |

**問題**: task04 の結合テスト IT-6（Docker exec capture+send）、IT-7（接続再確立）、IT-11（Docker 接続制限）がコメント/骨格のみで具体的なテスト実装が欠落していた。

**修正内容** (task04-02.md に反映):
- IT-6: getActiveSessions モックで Docker セッション設定 → connected メッセージ検証 → docker exec 経由の capture-pane 呼び出し検証 → send-keys の docker exec 経由呼び出し検証
- IT-7: 1回目接続 → connected メッセージ確認 → 切断 → 300ms 待機 → 2回目接続 → 新しい connected メッセージ確認 → output メッセージ受信（新 capture ループ）確認
- IT-11: Docker セッション3件モック → 2件接続成功 → 3件目が拒否される → 全クリーンアップ

---

### 🟡 Minor Issues

#### MRP-004: AC-5 実装担当不明瞭

| 項目 | 内容 |
|------|------|
| 重要度 | 🟡 Minor |
| ステータス | ✅ Resolved |

**問題**: AC-5（既存機能正常動作）は task08-02 でテストされるが、実装担当が「—」で不明だった。

**修正内容**:
- task-list.md の acceptance_criteria テーブルで AC-5 の実装タスクを `task06` に設定
- task06.md の完了条件に「既存のセッション一覧表示・ask_user 応答フローに回帰がないこと（AC-5 実装担当）」を追加
- task-list.md のタスク一覧で task06 の名称に「（AC-5 実装担当）」を付記

---

#### MRP-005: 並列グループ記述不整合

| 項目 | 内容 |
|------|------|
| 重要度 | 🟡 Minor |
| ステータス | ✅ Resolved |

**問題**: task-list.md では task04 が G5（単独）、task05-02 が G6（単独）だが、parent-agent-prompt.md の Phase 5 では並列実行可能としていた。

**修正内容**:
- task04 分割後、task04-01（depends: task03-03）と task05-02（depends: task05-01）は相互依存なし → 並列可能
- G5 を `task04-01, task05-02` の並列グループに統合
- G6 を `task04-02`（task04-01 完了後の結合テスト）に変更
- parent-agent-prompt.md に Phase 5.5（結合テスト）を追加
- 両ファイルの並列グループ一覧を整合

---

#### MRP-006: task08-01/02 同一ファイル書き込み競合リスク

| 項目 | 内容 |
|------|------|
| 重要度 | 🟡 Minor |
| ステータス | ✅ Resolved |

**問題**: task08-01 と task08-02 が同一ファイル `e2e/terminal-viewer.spec.ts` に書き込む設計で、並列実行時に競合リスクがあった。

**修正内容**:
- task08-01 → `e2e/terminal-viewer-basic.spec.ts`（E2E-1〜5）
- task08-02 → `e2e/terminal-viewer-auth.spec.ts`（E2E-6〜12）
- task08-01.md, task08-02.md の対象ファイル・テストコード・完了条件を更新
- task-list.md の E2E テストマッピングを2テーブルに分離
- parent-agent-prompt.md の Phase 7 説明と E2E テストコマンドを更新

---

#### MRP-007: task02 withEscape テスト ID 未付与

| 項目 | 内容 |
|------|------|
| 重要度 | 🟡 Minor |
| ステータス | ✅ Resolved |

**問題**: task02 で追加する `withEscape` パラメータのテストケースにテスト ID が付与されていなかった。

**修正内容**:
- task02.md のテストケースに ID を付与:
  - UT-T1: withEscape=true → -e フラグ付き
  - UT-T2: withEscape=false（デフォルト）→ -e なし
  - UT-T3: Docker exec + withEscape=true
- task-list.md に terminal.test.ts のテスト ID マッピングセクションを追加
- task-list.md のタスク一覧でテストケース列を `UT-T1,T2,T3 + 既存テスト修正` に更新

---

#### MRP-008: task06 完了条件弱い

| 項目 | 内容 |
|------|------|
| 重要度 | 🟡 Minor |
| ステータス | ✅ Resolved |

**問題**: task06 の完了条件が「既存テスト通過」のみで、新規ターミナルボタンの動作確認条件がなかった。

**修正内容**:
- task06.md の完了条件に以下を追加:
  - 「ターミナルボタンが各セッションカードに正しくレンダリングされる」
  - 「ターミナルボタンクリックで TerminalModal が開く」
  - 「既存のセッション一覧表示・ask_user 応答フローに回帰がないこと（AC-5 実装担当）」

---

#### MRP-009: E2E-5 Docker テスト脆弱（last()依存）

| 項目 | 内容 |
|------|------|
| 重要度 | 🟡 Minor |
| ステータス | ✅ Resolved |

**問題**: E2E-5 で `terminalBtns.last().click()` を使用しており、Docker セッションが最後に表示されるという仮定に依存していた。セッション順序が変わるとテストが壊れる。

**修正内容**:
- task08-01.md の E2E-5 テストコードを修正:
  - `terminalBtns.last().click()` → `page.locator("[data-container-id] button[title='ターミナルを開く']").first().click()`
  - `data-container-id` 属性で Docker セッションのカードを特定する方式に変更
  - セッション表示順序に依存しない堅牢なセレクタ

---

## 変更サマリー

### 変更ファイル一覧

| ファイル | 変更種別 | 対応指摘 |
|----------|---------|---------|
| task-list.md | 修正 | MRP-001〜009 全件 |
| parent-agent-prompt.md | 修正 | MRP-001, MRP-005, MRP-006 |
| task04-01.md | 新規 | MRP-001 |
| task04-02.md | 新規 | MRP-001, MRP-003 |
| task04.md | 削除 | MRP-001 |
| task05-01.md | 修正 | MRP-002 |
| task02.md | 修正 | MRP-007 |
| task06.md | 修正 | MRP-004, MRP-008 |
| task08-01.md | 修正 | MRP-006, MRP-009 |
| task08-02.md | 修正 | MRP-006 |

### 数量変更

| 項目 | 変更前 | 変更後 |
|------|--------|--------|
| 総タスク数 | 13 | 14 |
| 推定総工数 | 200分 | 230分 |
| 単体テスト数 | 28 | 36（UT-T1〜T3, UT-29〜33 追加） |
| E2E ファイル数 | 1 | 2 |
