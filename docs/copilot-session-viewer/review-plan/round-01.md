# Review-Plan Round 1 — viewer-container-local

## レビュー概要

| 項目 | 内容 |
|------|------|
| ラウンド | 1 |
| レビュアー | GPT-5.3-Codex, Claude Opus 4.6 |
| 判定 | **conditional** |
| 日付 | 2026-03-22 |

---

## レビュアー別結果

| レビュアー | 判定 | Major | Minor | Info |
|-----------|------|-------|-------|------|
| GPT-5.3-Codex | conditional | 7 | 5 | 1 |
| Claude Opus 4.6 | conditional | 7 | 5 | 1 |

---

## 統合判定

| 項目 | 内容 |
|------|------|
| 最終判定 | **conditional** (条件付き承認) |
| Major | 7 |
| Minor | 5 |
| Info | 1 |
| 合計 | 13 |

---

## 指摘事項一覧

### Major

#### MPR-001: findDockerContainers 未エクスポート — task03/11 テスト不成立

- **カテゴリ**: TDD
- **影響タスク**: task03, task11
- **問題**: `findDockerContainers` は `terminal.ts` の内部関数であり、task03 の RED テストが `expect(mod).toBeDefined()` というプレースホルダーになっている。task11 も同関数の import を前提としているが export 指示がない。
- **修正内容**:
  - task03: `findDockerContainers` を named export する明示的指示を追加
  - task03: プレースホルダー RED テストを具体的な `findDockerContainers()` 呼び出しに置換
  - task11: task03 が `findDockerContainers` を export する前提を明記

#### MPR-002: Task06 → Task10 依存関係欠落

- **カテゴリ**: 依存関係
- **影響タスク**: task10, task-list, parent-agent-prompt
- **問題**: Task10 (Dockerfile) は `.env.example` (Task06) を参照する compose.yaml の `env_file` で `.env` を使うが、`.env.example` の存在が前提。依存関係に task06 が含まれていない。
- **修正内容**:
  - task-list: task10 の依存に task06 を追加
  - task10: 前提条件に task06 を追加
  - parent-agent-prompt: 依存グラフ・実行順序を更新

#### MPR-003: TDD RED テストがプレースホルダー (task03, task04, task11, task12)

- **カテゴリ**: TDD
- **影響タスク**: task03, task04, task11, task12
- **問題**: RED フェーズのテストコードが `expect(mod).toBeDefined()` やコメントのみのプレースホルダーで、実際の失敗を検出できない。
- **修正内容**:
  - task03: UT-1〜UT-4 を具体的なアサーションに置換
  - task04: UT-7, UT-8 を具体的なアサーションに置換
  - task11: プレースホルダーを具体的な統合テストアサーションに置換
  - task12: E2E テストを具体的な Playwright アサーションに置換

#### MPR-004: Task12 global-setup.ts が任意扱い

- **カテゴリ**: TDD
- **影響タスク**: task12
- **問題**: `global-setup.ts` が「必要に応じて」とされているが、E2E テストはコンテナ起動が必須前提であり、global-setup/teardown なしでは動作しない。
- **修正内容**:
  - task12: global-setup.ts を「必須」に変更
  - docker compose up -d + healthcheck 待機の実装ステップを追加
  - global-teardown.ts (docker compose down) を追加
  - playwright.config.ts に globalSetup/globalTeardown 設定を追加

#### MPR-005: AC2 E2E-6 skip で tmux 安定性検証不足

- **カテゴリ**: 受入基準
- **影響タスク**: task12, parent-agent-prompt
- **問題**: E2E-6 (5分間耐久テスト) が `test.skip` されており、AC2「tmux セッションが予期せず終了しない」の検証が不十分。
- **修正内容**:
  - task12: E2E-6 を「条件付き必須」に変更（開発中は skip 可、verification ステップで必須）
  - parent-agent-prompt: CP-4 に E2E-6 条件付き要件を追加

#### MPR-006: AC3 PAT 有効性機能検証不足

- **カテゴリ**: 受入基準
- **影響タスク**: task12 (or task11)
- **問題**: GITHUB_TOKEN が環境変数として供給されることは E2E-7 で確認するが、PAT が実際に機能する（`gh auth status` 成功）ことの検証がない。
- **修正内容**:
  - task12: `gh auth status` による PAT 有効性検証ステップを E2E テストに追加

#### MPR-007: AC4 コンテナ間分離テスト不足

- **カテゴリ**: 受入基準
- **影響タスク**: task12 (or task11)
- **問題**: AC4「$HOME/.copilot がコンテナごとに分離」の検証が UT-3 (パス構築) のみで、実際のコンテナ内分離を確認するテストがない。
- **修正内容**:
  - task12: コンテナ内 `/home/node/.copilot` の存在・書き込み可能性・ホストパス非マウントを検証する E2E テストを追加

---

### Minor

#### MPR-008: start-viewer.sh `su -l` 環境変数消失リスク

- **カテゴリ**: タスク分割
- **影響タスク**: task07
- **問題**: `exec su -l node -c "$0"` は login shell を起動するため、`PORT` 等の環境変数が消失するリスクがある。
- **修正内容**:
  - task07: `su -l` を `gosu` に変更し、環境変数保持の注意点を追加

#### MPR-009: Task11/Task03 テスト重複

- **カテゴリ**: タスク分割
- **影響タスク**: task11
- **問題**: task11 の env-integration.test.ts が task03 の UT-1 と実質同一テスト（`findDockerContainers()` + `DISABLE_DOCKER_DETECTION`）を含む。
- **修正内容**:
  - task11: 単一関数テストを削除し、真の統合テスト（`getActiveSessions()` レベル）に置換

#### MPR-010: Task10 見積もり 20 分がタイト

- **カテゴリ**: 見積もり
- **影響タスク**: task10, task-list, parent-agent-prompt
- **問題**: Dockerfile + compose.yaml の統合タスクは 4 つの前提タスク成果物の統合が必要で、20 分は楽観的。
- **修正内容**:
  - task10, task-list, parent-agent-prompt: 見積もりを 30min に更新

#### MPR-011: task01/02 成果物・対象ファイル不一致

- **カテゴリ**: タスク分割
- **影響タスク**: task01, task02
- **問題**: task01 で `e2e/smoke.spec.ts` を作成するが対象ファイル表に記載なし。task02 で `standalone-build.test.ts` を作成するが対象ファイル表に記載なし。
- **修正内容**:
  - task01: `e2e/smoke.spec.ts` を対象ファイル表に追加（scaffolding 注記付き）
  - task02: `standalone-build.test.ts` を対象ファイル表に追加
  - smoke テストのライフサイクル（task01 で作成、task12 で置換）を明記

#### MPR-012: 総見積もり楽観的・バッファなし

- **カテゴリ**: 見積もり
- **影響タスク**: task-list, parent-agent-prompt
- **問題**: 総見積もり 3.5h にリスクバッファがなく、コンフリクト解決・環境問題等の考慮がない。
- **修正内容**:
  - task-list: ~20% バッファ注記を追加（3.5h → ~4.5h）
  - parent-agent-prompt: リスクバッファセクションを追加

---

### Info

#### MPR-013: テストファイル配置規約未明記

- **カテゴリ**: タスク分割
- **影響タスク**: parent-agent-prompt (or task-list)
- **問題**: テストファイルの配置規約（`src/lib/__tests__/` vs `src/__tests__/` vs `e2e/`）が明文化されていない。
- **修正内容**:
  - parent-agent-prompt: テストファイル配置規約を 1-2 行で追加

---

## Acceptance Criteria → タスク対応表

| AC | 内容 | 検証タスク | テスト | 指摘 |
|----|------|----------|--------|------|
| AC1 | コンテナ起動で CLI + viewer + tmux | 10, 12 | E2E-1, E2E-2 | — |
| AC2 | tmux セッション安定性 | 12 | E2E-3, E2E-6 | MPR-005 |
| AC3 | .env から PAT 含む認証設定供給 | 03, 05, 12 | UT-9-11, E2E-4, E2E-7 | MPR-006 |
| AC4 | $HOME/.copilot コンテナ分離 | 03, 12 | UT-3 | MPR-007 |
| AC5 | Unit/Integration/E2E テスト実行可能 | 01, 11, 12 | IT-1, E2E 全体 | — |

---

## 次のステップ

1. 全 13 件の指摘を plan ドキュメントに反映
2. project.yaml の plan.review セクションを更新
3. 修正後、必要に応じて Round 2 レビューを実施
