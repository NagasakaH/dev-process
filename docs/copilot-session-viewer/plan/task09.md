# タスク: task09 - 弊害検証

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task09 |
| タスク名 | 弊害検証 |
| 前提条件タスク | task08-01, task08-02 |
| 並列実行可否 | 不可（最終検証） |
| 推定所要時間 | 15分 |

## 作業環境

- **作業ディレクトリ（worktree）**: submodules/editable/copilot-session-viewer
- **ブランチ**: feature/tmux-pane-viewer

## 前提条件

- task08-01, task08-02 完了（全 E2E テスト通過）
- 全実装が完了していること

## 作業内容

### 目的

`06_side-effect-verification.md` に基づいて、ターミナルビューア機能の追加による既存機能への副作用がないことを体系的に検証する。

### 設計参照

- `06_side-effect-verification.md` 全体

### 実装ステップ

1. **回帰テスト実行**
   ```bash
   # 全単体・結合テスト
   npx vitest run

   # 全 E2E テスト
   npx playwright test
   ```

2. **セキュリティ検証チェックリスト確認**
   - WebSocket Upgrade ハンドラーで Authorization ヘッダー検証
   - 無効パスの socket.destroy()
   - sessionId の突合検証
   - send-keys が execFileSync 直接実行
   - 接続数制限の動作確認

3. **互換性検証**
   - 既存 REST API ルートの動作確認
   - `captureTmuxPane` のデフォルト値後方互換確認

4. **ビルドサイズ確認**
   ```bash
   npm run build
   # .next/standalone のサイズを確認
   du -sh .next/standalone/
   ```

5. **TypeScript / Lint 確認**
   ```bash
   npx tsc --noEmit
   npm run lint
   ```

6. **検証結果レポート作成**
   - `06_side-effect-verification.md` §8 の結果テンプレートに結果を記入

### 対象ファイル

| ファイル | 操作 | 変更内容 |
|----------|------|----------|
| なし（検証のみ） | — | — |

## テスト方針（TDD: RED-GREEN-REFACTOR）

このタスクはテスト実行・検証タスクのため、TDD サイクルは適用外。

### 検証項目

```
回帰テスト:
  [ ] npx vitest run → 全テスト通過
  [ ] npx playwright test → 全 E2E テスト通過

セキュリティ:
  [ ] WS 認証（設定時）: 正しい認証で接続可能
  [ ] WS 認証（未設定時）: 403 で接続拒否
  [ ] WS 認証バイパス: 認証なしで接続不可
  [ ] 入力サニタイズ: send-keys -l でリテラル送信
  [ ] sessionId 検証: 無効 sessionId で拒否
  [ ] 接続数制限: 上限超過で拒否

互換性:
  [ ] 既存 REST API が正常応答
  [ ] captureTmuxPane デフォルト値で後方互換
  [ ] セッション一覧 UI が正常表示

ビルド:
  [ ] npm run build が成功
  [ ] npx tsc --noEmit がエラーなし
  [ ] npm run lint がエラーなし
  [ ] ビルドサイズが許容範囲内
```

## 完了条件

- [ ] 全テストスイート（単体・結合・E2E）が通過
- [ ] セキュリティチェックリスト全項目 ✅
- [ ] 互換性チェックリスト全項目 ✅
- [ ] ビルド・TypeScript・Lint が正常
- [ ] 検証結果が記録されている
