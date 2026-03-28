# タスク: task02 - terminal.ts captureTmuxPane `-e` フラグ拡張

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task02 |
| タスク名 | terminal.ts captureTmuxPane `-e` フラグ拡張 |
| 前提条件タスク | task01 |
| 並列実行可否 | 可（task03-01 と並列） |
| 推定所要時間 | 10分 |

## 作業環境

- **作業ディレクトリ（worktree）**: submodules/editable/copilot-session-viewer
- **ブランチ**: feature/tmux-pane-viewer

## 前提条件

- task01 完了（依存パッケージ追加済み）
- 既存の `src/lib/terminal.ts` と `src/lib/__tests__/terminal.test.ts` が正常動作

## 作業内容

### 目的

既存の `captureTmuxPane` 関数に `withEscape?: boolean` パラメータを追加し、`true` 時に `-e` フラグ付きで capture-pane を実行できるようにする。既存呼び出しはデフォルト `false` で後方互換を維持する。

### 設計参照

- `02_interface-api-design.md` §3.2 既存関数の拡張
- `04_process-flow-design.md` §6 capture-pane ループ処理フロー

### 実装ステップ

1. **既存テスト修正（RED）**
   - `src/lib/__tests__/terminal.test.ts` に `withEscape: true` のテストケースを追加
   - テスト実行 → 失敗確認

2. **captureTmuxPane 修正（GREEN）**
   - `withEscape?: boolean` パラメータ追加
   - `true` 時に args に `-e` を追加
   - 既存テストが通過することを確認

3. **REFACTOR**
   - パラメータの型安全性確認

### 対象ファイル

| ファイル | 操作 | 変更内容 |
|----------|------|----------|
| `src/lib/terminal.ts` | 修正 | captureTmuxPane に `withEscape` パラメータ追加 |
| `src/lib/__tests__/terminal.test.ts` | 修正 | `withEscape: true` のテストケース追加 |

## テスト方針（TDD: RED-GREEN-REFACTOR）

### RED: 失敗するテストケース

```typescript
// src/lib/__tests__/terminal.test.ts に追加

describe("captureTmuxPane with -e flag", () => {
  // UT-T1: withEscape=true → -e フラグ
  it("withEscape=true の場合、capture-pane に -e フラグが含まれる", () => {
    const mockExecFileSync = vi.mocked(execFileSync);
    mockExecFileSync.mockReturnValue(Buffer.from("test output"));

    captureTmuxPane("0:1.0", undefined, undefined, true);

    expect(mockExecFileSync).toHaveBeenCalledWith(
      "tmux",
      expect.arrayContaining(["-e"]),
      expect.any(Object)
    );
  });

  // UT-T2: withEscape=false（デフォルト）→ -e なし
  it("withEscape=false の場合（デフォルト）、-e フラグが含まれない", () => {
    const mockExecFileSync = vi.mocked(execFileSync);
    mockExecFileSync.mockReturnValue(Buffer.from("test output"));

    captureTmuxPane("0:1.0");

    expect(mockExecFileSync).toHaveBeenCalledWith(
      "tmux",
      expect.not.arrayContaining(["-e"]),
      expect.any(Object)
    );
  });

  // UT-T3: Docker exec + withEscape=true
  it("Docker exec 経由でも withEscape=true で -e フラグが含まれる", () => {
    const mockExecFileSync = vi.mocked(execFileSync);
    mockExecFileSync.mockReturnValue(Buffer.from("test output"));

    captureTmuxPane("0:1.0", "container123", "1000", true);

    expect(mockExecFileSync).toHaveBeenCalledWith(
      "docker",
      expect.arrayContaining(["-e"]),
      expect.any(Object)
    );
  });
});
```

### GREEN: 最小限の実装

```typescript
// src/lib/terminal.ts - captureTmuxPane 修正
export function captureTmuxPane(
  tmuxPane: string,
  containerId?: string,
  containerUser?: string,
  withEscape?: boolean  // 追加
): string {
  const captureArgs = ["capture-pane", "-t", tmuxPane, "-p"];
  if (withEscape) {
    captureArgs.push("-e");
  }

  // 以下、既存の execFileSync 呼び出しロジック
  // containerId がある場合は docker exec 経由
  // ...
}
```

### REFACTOR: コード改善

- 既存の captureTmuxPane 呼び出し元が影響を受けないことを確認
- 引数のオーダーが直感的かレビュー

## 完了条件

- [ ] `captureTmuxPane` に `withEscape` パラメータが追加されている
- [ ] `withEscape=true` で `-e` フラグ付き capture-pane が実行される
- [ ] `withEscape` 未指定（デフォルト）で既存動作が維持される
- [ ] Docker exec 経由でも `-e` フラグが正しく渡される
- [ ] 既存テストが全通過
- [ ] 新規テストが全通過
- [ ] `npx tsc --noEmit` がエラーなし
