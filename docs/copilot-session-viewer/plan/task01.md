# タスク: task01 - 依存パッケージ追加 & プロジェクト設定

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task01 |
| タスク名 | 依存パッケージ追加 & プロジェクト設定 |
| 前提条件タスク | なし |
| 並列実行可否 | 不可（基盤タスク） |
| 推定所要時間 | 10分 |

## 作業環境

- **作業ディレクトリ（worktree）**: submodules/editable/copilot-session-viewer
- **ブランチ**: feature/tmux-pane-viewer

## 前提条件

- Node.js 20+ がインストール済み
- 既存の `npm install` が正常動作すること

## 作業内容

### 目的

ターミナルビューア機能に必要な新規依存パッケージ（ws, @xterm/xterm, @xterm/addon-fit, @types/ws）を追加し、ビルド・テスト設定を更新する。

### 設計参照

- `01_implementation-approach.md` §1.2 技術選定
- `05_test-plan.md` §7.2 テスト環境設定

### 実装ステップ

1. **依存パッケージ追加**
   ```bash
   cd submodules/editable/copilot-session-viewer
   npm install ws @xterm/xterm @xterm/addon-fit
   npm install -D @types/ws
   ```

2. **package.json の dev スクリプト更新**
   - `"dev"` スクリプトを `node server.js` ベースに変更
   - 注意: server.js は task04 で作成されるため、ここでは `"dev": "node server.js"` と定義するのみ

3. **vitest.config.mts の更新**
   - `environmentMatchGlobs` に Terminal コンポーネントテスト用の jsdom 設定を追加
   ```typescript
   ["**/components/__tests__/Terminal*.test.tsx", "jsdom"],
   ```

4. **TypeScript 設定確認**
   - `@xterm/xterm` の型が正しく解決されることを確認（`npx tsc --noEmit`）

### 対象ファイル

| ファイル | 操作 | 変更内容 |
|----------|------|----------|
| `package.json` | 修正 | dependencies に ws, @xterm/xterm, @xterm/addon-fit 追加、devDependencies に @types/ws 追加、dev スクリプト更新 |
| `vitest.config.mts` | 修正 | environmentMatchGlobs に Terminal テスト設定追加 |

## テスト方針（TDD: RED-GREEN-REFACTOR）

### RED: 失敗するテストケース

このタスクは設定のみのため、明示的な RED フェーズはなし。ただし以下を確認:

```bash
# 依存追加前: import が解決できないことを確認
npx tsc --noEmit  # ws, @xterm/xterm が未解決エラー
```

### GREEN: 最小限の実装

```bash
# 依存追加後
npm install ws @xterm/xterm @xterm/addon-fit
npm install -D @types/ws
npx tsc --noEmit  # エラーなし
```

### REFACTOR: コード改善

- package-lock.json の整合性確認
- 不要な依存がないことを確認

## 完了条件

- [ ] `npm install` が正常完了
- [ ] `package.json` に ws, @xterm/xterm, @xterm/addon-fit, @types/ws が記載
- [ ] `vitest.config.mts` に Terminal テスト設定が追加
- [ ] `npx tsc --noEmit` がエラーなし
- [ ] `npx vitest run` で既存テストが全通過
- [ ] `npm run build` が正常完了
