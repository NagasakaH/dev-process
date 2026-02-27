# 計画レビュー: Round 1

## レビュー情報

| 項目 | 値 |
|------|-----|
| チケットID | WEB-DESIGN-001 |
| タスク名 | ウェブデザイン要件定義プロジェクト環境構築 |
| レビューラウンド | 1 |
| レビュー日 | 2026-02-27 |
| レビューステータス | conditional_pass |

---

## レビュー結果サマリー

| 重大度 | 件数 | 修正済 |
|--------|------|--------|
| Major | 5 | 5 |
| Minor | 5 | 5 |
| **合計** | **10** | **10** |

---

## Major指摘（5件）

### MRP-001: 受入基準の未修正

- **対象**: setup.yaml, task-list.md
- **問題**: setup.yaml の acceptance_criteria に「code-serverにGitHub Copilot拡張機能がインストールされている」が残っていた。設計フェーズでCopilot CLI代替が決定されたが、正式な要件変更が行われていなかった。
- **修正内容**:
  - setup.yaml: acceptance_criteria を「GitHub Copilot CLI が使用可能である（Open VSX制約によりCopilot拡張はCLIで代替）」に変更
  - task-list.md: 要件変更記録を追加
- **ステータス**: ✅ 修正済

### MRP-002: 弊害検証タスク化不足

- **対象**: task-list.md
- **問題**: 設計書06（弊害検証計画）の検証項目がverificationフェーズの具体的なチェックリストとして反映されていなかった。E2Eテストでカバーできない検証（HMR性能、セキュリティ確認等）の手動検証手順が未整理。
- **修正内容**:
  - task-list.md に「verificationフェーズ検証チェックリスト」セクションを追加
  - 自動検証（E2Eテスト対応表）と手動検証チェックリスト（V-01〜V-08）を整理
- **ステータス**: ✅ 修正済

### MRP-003: TDD方針の担保不足

- **対象**: task-list.md, task03.md, parent-agent-prompt.md
- **問題**: task03（E2Eテスト作成）がPhase 3に配置されており、「失敗するテスト作成→実装→テスト通過」のRED→GREENフローが計画上担保されていなかった。
- **修正内容**:
  - task03をPhase 2に移動し、task02-01/02/03と並列実行可能に変更
  - task03の前提条件をtask01のみに変更（テストコード記述のみで実装成果物への依存なし）
  - TDD方針（RED→GREENフロー）セクションをtask-list.mdに追加
  - parent-agent-prompt.mdの依存関係グラフ、並列グループ、worktree管理、cherry-pickフローを更新
- **ステータス**: ✅ 修正済

### MRP-004: MSW serviceWorker.js生成漏れ

- **対象**: task02-03.md
- **問題**: `public/mockServiceWorker.js` の生成手順（`npx msw init public/`）がtask02-03の実装ステップに含まれていなかった。
- **修正内容**:
  - task02-03.md の実装ステップに `npx msw init public/` コマンドを追加（ステップ18-19）
  - 対象ファイルテーブルに `public/mockServiceWorker.js`（自動生成、コミット対象）を追加
  - 注意事項のnoteをコミット対象に含める旨に変更
- **ステータス**: ✅ 修正済

### MRP-005: playwright.config.ts配置パス不整合

- **対象**: task03.md, design/03, design/05
- **問題**: playwright.config.ts の配置パスが文書間で不整合。design/03では `e2e/playwright.config.ts`、design/05のコード例では `testDir: './e2e'`（ルート配置前提）、task03では `e2e/playwright.config.ts`。
- **修正内容**:
  - playwright.config.ts をプロジェクトルートに配置する方式に統一
  - design/03: ファイル構造からe2e/配下のplaywright.config.tsを削除し、ルートレベルに追加
  - design/05: MRP-005対応のnoteを追加（ルート配置、testDir: './e2e'）
  - task03.md: 対象ファイル、実装ステップ、成果物、完了条件を更新
- **ステータス**: ✅ 修正済

---

## Minor指摘（5件）

### MRP-006: 工数見積もりバッファ不足

- **対象**: task-list.md, task02-03.md, task03.md
- **問題**: task02-03（15分）とtask03（15分）の見積もりにバッファがなく、MSW Service Worker生成やplaywright.config.ts配置の追加作業分が考慮されていなかった。
- **修正内容**: task02-03: 15分→25分、task03: 15分→25分に変更。task-list.md、各タスクファイル、parent-agent-prompt.mdを更新。
- **ステータス**: ✅ 修正済

### MRP-007: 並列実行時の競合回避手順未記載

- **対象**: task02-01.md, task02-02.md, task02-03.md
- **問題**: Phase 2の並列実行タスクに、ファイル競合を回避するための具体的な注意事項が記載されていなかった。
- **修正内容**: 各タスクの注意事項セクションに並列実行時の競合回避手順（編集対象ファイルの明示、worktree分離）を追加。
- **ステータス**: ✅ 修正済

### MRP-008: クリティカルパス時間の不整合

- **対象**: task-list.md, parent-agent-prompt.md
- **問題**: task-list.mdの概要テーブルのクリティカルパスが50分、parent-agent-prompt.mdが55分と不整合があった。
- **修正内容**: task03をPhase 2に移動したことにより、クリティカルパスは 15+25+10=50分に統一。バッファ追加の注記を記載。
- **ステータス**: ✅ 修正済

### MRP-009: E2E-10が自明なアサーション

- **対象**: task03.md, design/05_test-plan.md
- **問題**: E2E-10「ReactコンポーネントがMSWモックデータを表示する」のアサーションが `not.toBeEmpty()` のみで自明すぎた。
- **修正内容**: E2E-10を「MSW Service Workerが正常に登録されている」に変更。`navigator.serviceWorker.getRegistrations()` で `mockServiceWorker.js` の登録を確認するテストに置換。design/05のテストケース一覧とコード例も更新。
- **ステータス**: ✅ 修正済

### MRP-010: 誤字修正

- **対象**: task02-01.md
- **問題**: 注意事項セクションに「DooD時もDooDでも」という誤記があった。
- **修正内容**: 「DinD時もDooD時も」に修正。
- **ステータス**: ✅ 修正済

---

## 修正対象ファイル一覧

| ファイル | 修正内容 | 対応MRP |
|----------|----------|---------|
| setup.yaml | acceptance_criteria変更 | MRP-001 |
| docs/web-design/plan/task-list.md | 要件変更記録、TDDフロー、Phase再構成、バッファ、クリティカルパス、検証チェックリスト | MRP-001,002,003,006,008 |
| docs/web-design/plan/task03.md | Phase 2移動、前提条件変更、TDD方針、playwright.config.ts配置、E2E-10変更、工数 | MRP-003,005,006,009 |
| docs/web-design/plan/task02-03.md | MSW init追加、工数バッファ、並列競合回避 | MRP-004,006,007 |
| docs/web-design/plan/task02-01.md | 誤字修正、並列競合回避 | MRP-007,010 |
| docs/web-design/plan/task02-02.md | 並列競合回避 | MRP-007 |
| docs/web-design/plan/task04.md | 前提条件更新 | MRP-003 |
| docs/web-design/plan/parent-agent-prompt.md | Phase再構成、並列グループ、worktree、cherry-pick、チェックポイント | MRP-003,006,008 |
| docs/web-design/design/03_data-structure-design.md | playwright.config.tsパス修正 | MRP-005 |
| docs/web-design/design/05_test-plan.md | playwright.config.ts配置note、E2E-10テスト変更 | MRP-005,009 |

---

## 判定

全10件の指摘（Major 5件 + Minor 5件）を修正完了。

**判定: conditional_pass** — 修正適用済み。次ラウンドで修正内容の確認を推奨。
