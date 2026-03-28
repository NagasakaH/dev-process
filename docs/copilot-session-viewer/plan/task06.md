# タスク: task06 - ActiveSessionsDashboard 統合

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task06 |
| タスク名 | ActiveSessionsDashboard 統合 |
| 前提条件タスク | task05-02 |
| 並列実行可否 | 可（task07 と並列） |
| 推定所要時間 | 10分 |

## 作業環境

- **作業ディレクトリ（worktree）**: submodules/editable/copilot-session-viewer
- **ブランチ**: feature/tmux-pane-viewer

## 前提条件

- task05-02 完了（TerminalModal が利用可能）

## 作業内容

### 目的

既存の `ActiveSessionsDashboard.tsx` のセッションカードにターミナルボタンを追加し、クリック時に `TerminalModal` を開く。

### 設計参照

- `02_interface-api-design.md` §4.3 ActiveSessionsDashboard への追加

### 実装ステップ

1. **テスト確認（RED）**
   - 既存の `src/components/__tests__/ActiveSessionsDashboard.test.tsx` が存在するか確認
   - ターミナルボタンの表示条件テストを追加

2. **state 追加**
   - `const [terminalSession, setTerminalSession] = useState<ActiveSession | null>(null);`

3. **ターミナルボタン追加（GREEN）**
   - `session.tmuxPane` が存在するセッションカードにのみ表示
   - ターミナルアイコン（SVG or Lucide icon）
   - `onClick={() => setTerminalSession(session)}`
   - `title="ターミナルを開く"`

4. **TerminalModal レンダリング**
   ```tsx
   {terminalSession && (
     <TerminalModal
       session={terminalSession}
       onClose={() => setTerminalSession(null)}
     />
   )}
   ```

5. **REFACTOR**
   - TerminalModal の dynamic import（SSR 回避）

### 対象ファイル

| ファイル | 操作 | 変更内容 |
|----------|------|----------|
| `src/components/ActiveSessionsDashboard.tsx` | 修正 | ターミナルボタン追加 + TerminalModal 表示ロジック |

## テスト方針（TDD: RED-GREEN-REFACTOR）

### RED: 失敗するテストケース

```typescript
// 既存 ActiveSessionsDashboard テスト内に追加

it("tmuxPane があるセッションにターミナルボタンが表示される", () => {
  render(<ActiveSessionsDashboard />);
  // tmuxPane ありセッションのカードにボタンが存在
  const terminalBtn = screen.getByTitle("ターミナルを開く");
  expect(terminalBtn).toBeInTheDocument();
});

it("tmuxPane がないセッションにターミナルボタンが表示されない", () => {
  // tmuxPane が undefined のセッションのみ
  // ターミナルボタンが存在しないことを確認
});

it("ターミナルボタンクリックで TerminalModal が表示される", () => {
  render(<ActiveSessionsDashboard />);
  const terminalBtn = screen.getByTitle("ターミナルを開く");
  fireEvent.click(terminalBtn);
  expect(screen.getByRole("dialog")).toBeInTheDocument();
});
```

### GREEN: 最小限の実装

```tsx
// ActiveSessionsDashboard.tsx に追加
import { useState } from "react";
import dynamic from "next/dynamic";
import type { ActiveSession } from "../lib/terminal";

const TerminalModal = dynamic(() => import("./TerminalModal").then(m => m.TerminalModal), { ssr: false });

// コンポーネント内:
const [terminalSession, setTerminalSession] = useState<ActiveSession | null>(null);

// セッションカード内:
{session.tmuxPane && (
  <button
    onClick={() => setTerminalSession(session)}
    title="ターミナルを開く"
    className="p-1 rounded hover:bg-gray-200 dark:hover:bg-gray-700"
  >
    <svg /* ターミナルアイコン */ />
  </button>
)}

// コンポーネント末尾:
{terminalSession && (
  <TerminalModal
    session={terminalSession}
    onClose={() => setTerminalSession(null)}
  />
)}
```

### REFACTOR: コード改善

- アイコンの統一性確認（既存のアイコンスタイルに合わせる）
- ボタンのアクセシビリティ属性追加

## 完了条件

- [ ] `tmuxPane` があるセッションのみにターミナルボタンが表示
- [ ] ボタンクリックで `TerminalModal` が開く
- [ ] モーダルを閉じると `terminalSession` が null に戻る
- [ ] 既存の ActiveSessionsDashboard テストが通過
- [ ] `npx tsc --noEmit` がエラーなし
- [ ] 既存テストが全通過
