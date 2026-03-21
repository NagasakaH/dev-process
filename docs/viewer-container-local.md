# viewer-container-local - container

<!-- 
================================================================================
このドキュメントは setup.yaml を Single Source of Truth (SSOT) として参照します。
基本情報は setup.yaml の description フィールドから動的に埋め込まれます。
================================================================================
-->

## 基本情報

| 項目 | 内容 |
|------|------|
| チケットID | viewer-container-local |
| タスク名 | container |
| 作成日 | 2026-03-21 |
| 作成者 | Hiroaki |
| ステータス | 🔵 初期化 |

---

## 概要

<!-- setup.yaml の description.overview から埋め込み -->
Adapt `copilot-session-viewer` so it can operate fully inside its own container.
The container should provide the Copilot CLI execution environment, session viewer,
and tmux together, while keeping session management local to the container rather
than depending on host-side Copilot coordination.

---

## 目的

<!-- setup.yaml の description.purpose から埋め込み -->
Establish a stable, self-contained runtime that can be operated on another Linux
machine without depending on host integration. This should make it possible to
validate the workflow in a simpler single-container or local-only mode first.

---

## 背景

<!-- setup.yaml の description.background から埋め込み -->
The current approach manages another container from a dev-process container, but
tmux exits unexpectedly for an unknown reason. As an intermediate step, the goal
is to make the target project run in a self-contained local/container-only mode,
while keeping existing behavior as unchanged as possible outside the session
management boundary.

---

## 要件

### 機能要件

<!-- setup.yaml の description.requirements.functional から埋め込み -->
- Start the Copilot CLI execution environment, session viewer, and tmux together inside the container.
- Manage sessions only in the local/container environment rather than coordinating with host-side Copilot.
- Isolate `$HOME/.copilot` on a per-container basis.
- Inject the required PAT and related auth settings via `.env`.
- Include a dev-process devcontainer-equivalent development toolset in the container.
- Prepare Playwright-based E2E test support in addition to unit and integration tests.

### 非機能要件

<!-- setup.yaml の description.requirements.non_functional から埋め込み -->
- Keep existing project functionality largely unchanged except for the session-management/runtime boundary.
- Prioritize stable container startup and tmux session persistence.
- Prefer host-independent local/container-only operation.

---

## スコープ

### 対象範囲

<!-- setup.yaml の description.scope から埋め込み -->
- Containerize the existing `copilot-session-viewer` project so it runs self-contained in a single/local container.
- Keep the current feature set largely intact while changing runtime/session-management behavior to local/container-only.
- Enable in-container Playwright E2E execution after container startup.

### 対象外

<!-- setup.yaml の description.out_of_scope から埋め込み -->
- Large-scale functional redesign of the existing viewer behavior.
- Maintaining host-side Copilot/session-management compatibility as a primary goal for this task.

---

## 受け入れ条件

<!-- setup.yaml の description.acceptance_criteria から埋め込み -->
- Starting the container makes the Copilot CLI execution environment, session viewer, and tmux available.
- tmux sessions remain stable instead of exiting unexpectedly during normal use.
- Authentication-related settings can be supplied from `.env`, including the required PAT.
- `$HOME/.copilot` is isolated per container.
- Unit tests, integration tests, and Playwright E2E tests can be executed.

---

## 補足情報

<!-- setup.yaml の description.notes から埋め込み -->
E2E tests should run inside the container after startup by using Playwright.
The target repository already contains `dev-process` as a submodule, so no
separate related repository is required in this setup. The initial focus is on
making the self-contained container workflow reliable before revisiting broader
host-integrated operation.

---

## 1. 調査結果

<!-- investigation スキルが更新 -->

### 1.1 現状分析

Next.js 16 App Router + ファイルベースセッションストア (`~/.copilot/`) + child_process (tmux/docker) の3層構成。
Docker 検出ロジックは環境変数フラグで無効化可能。better-sqlite3 は未使用依存。テスト基盤なし（Vitest 新規導入）。

詳細は [investigation/](./copilot-session-viewer/investigation/) を参照。

### 1.2 関連コード・ファイル

| ファイル | 役割 | 備考 |
|----------|------|------|
| `src/lib/terminal.ts` | ターミナル/Docker/tmux 制御 (866行) | Docker 検出ロジック L126-226 が無効化対象 |
| `src/lib/sessions.ts` | セッションデータアクセス (751行) | `$HOME/.copilot/session-state/` を参照 |
| `src/middleware.ts` | Basic Auth 認証 | `BASIC_AUTH_USER/PASS` で制御 |
| `src/app/api/dev-process/start-copilot/route.ts` | Dev-process 管理 API (607行) | `ENABLE_DEV_PROCESS=false` で無効化 |
| `next.config.ts` | Next.js 設定 | `output: "standalone"` 追加が必要 |
| `package.json` | 依存関係 | better-sqlite3 未使用、Vitest/Playwright 追加予定 |

### 1.3 参考情報

- [アーキテクチャ調査](./copilot-session-viewer/investigation/01_architecture.md)
- [データ構造調査](./copilot-session-viewer/investigation/02_data-structure.md)
- [依存関係調査](./copilot-session-viewer/investigation/03_dependencies.md)
- [既存パターン調査](./copilot-session-viewer/investigation/04_existing-patterns.md)
- [統合ポイント調査](./copilot-session-viewer/investigation/05_integration-points.md)
- [リスク・制約分析](./copilot-session-viewer/investigation/06_risks-and-constraints.md)

---

## 2. 設計

<!-- design スキルが更新 -->

### 2.1 設計方針

ハイブリッドアプローチを採用。copilot-session-viewer リポジトリに Dockerfile + compose.yaml を新規作成し、
1コンテナに Next.js (standalone) + tmux + Copilot CLI を同居させる。dev-process の tini + start-tmux.sh +
cplt パターンを参考に、viewer 専用のエントリポイント（start-viewer.sh）を構築する。
ローカル（非コンテナ）動作は既存のまま維持する。

詳細は [design/01_implementation-approach.md](./copilot-session-viewer/design/01_implementation-approach.md) を参照。

### 2.2 変更箇所

#### 追加ファイル

| ファイル | 目的 |
|----------|------|
| `Dockerfile` | マルチステージビルド（deps→builder→runner） |
| `compose.yaml` | コンテナ起動設定（ボリューム、環境変数、ポート） |
| `.dockerignore` | ビルドコンテキストから不要ファイルを除外 |
| `scripts/start-viewer.sh` | エントリポイント（tmux + Next.js 起動） |
| `scripts/cplt` | Copilot CLI ラッパー（dev-process から流用） |
| `.env.example` | 環境変数テンプレート |
| `vitest.config.ts` | Vitest 設定 |
| `playwright.config.ts` | Playwright 設定 |
| `src/lib/__tests__/terminal.test.ts` | terminal.ts 単体テスト |
| `src/lib/__tests__/sessions.test.ts` | sessions.ts 単体テスト |
| `e2e/container-startup.spec.ts` | E2E テスト |

#### 修正ファイル

| ファイル | 変更内容 |
|----------|----------|
| `next.config.ts` | `output: "standalone"` 追加 |
| `src/lib/terminal.ts` | `DISABLE_DOCKER_DETECTION` 環境変数フラグ追加（2行） |
| `package.json` | Vitest / Playwright / テストスクリプト追加 |

#### 削除ファイル

| ファイル | 理由 |
|----------|------|
| なし | 既存機能を維持 |

### 2.3 インターフェース設計

terminal.ts に `DISABLE_DOCKER_DETECTION` 環境変数フラグを追加し、Docker 検出を無効化可能にする。
既存 API ルートはすべて変更不要（コンテナ内でそのまま動作）。

詳細は [design/02_interface-api-design.md](./copilot-session-viewer/design/02_interface-api-design.md) を参照。

### 2.4 データ構造

既存のデータ構造（TypeScript 型定義、ファイルシステム構造）に変更なし。
`$HOME/.copilot` パスは `process.env.HOME` 依存のため、コンテナ内で自動分離される。
Named volume `copilot-data` でセッションデータを永続化する。

詳細は [design/03_data-structure-design.md](./copilot-session-viewer/design/03_data-structure-design.md) を参照。

---

## 3. 実装計画

<!-- plan スキルが更新 -->

### 3.1 タスク分割

<!-- 詳細: plan/task-list.md -->

| タスク識別子 | タスク名 | 前提条件 | 並列可否 | 推定時間 | ステータス |
|--------------|----------|----------|----------|----------|------------|
| | | | | | ⬜ 未着手 |

### 3.2 依存関係

<!-- 依存関係図は plan スキルで生成 -->

### 3.3 見積もり

| タスク | 見積もり | 実績 |
|--------|----------|------|
| | | |

---

## 4. テスト計画

<!-- design/05_test-plan.md を参照 -->

### 4.1 テスト対象

- Unit: terminal.ts (Docker 検出無効化)、sessions.ts (パース処理)、middleware.ts (認証)
- Integration: Next.js standalone ビルド、Vitest 設定動作
- E2E: コンテナ起動 → viewer → tmux → 認証

### 4.2 テストケース

| No | テスト内容 | 期待結果 | 結果 |
|----|------------|----------|------|
| UT-1 | DISABLE_DOCKER_DETECTION=true で Docker 検出無効化 | 空配列返却 | ⬜ |
| UT-5 | セッションディレクトリ空時 | 空配列返却 | ⬜ |
| UT-9 | Basic Auth 未設定時 | 認証スキップ | ⬜ |
| E2E-1 | コンテナ起動→HTTP応答 | 200 OK | ⬜ |
| E2E-2 | tmux セッション存在確認 | viewer セッション存在 | ⬜ |

詳細は [design/05_test-plan.md](./copilot-session-viewer/design/05_test-plan.md) を参照。

### 4.3 テスト環境

- Unit/Integration: Vitest (Node.js)
- E2E: Playwright (Chromium headless, コンテナ内実行)

---

## 5. 弊害検証

<!-- design/06_side-effect-verification.md を参照 -->

### 5.1 影響範囲

- terminal.ts Docker 検出無効化（環境変数未設定時は既存動作維持）
- next.config.ts standalone 追加（ローカル開発に影響なし）
- package.json 新規依存追加

### 5.2 リスク分析

| リスク | 影響度 | 発生可能性 | 対策 |
|--------|--------|------------|------|
| tmux セッション予期せぬ終了 | 高 | 中 | tini + キープアライブループ |
| better-sqlite3 ビルド失敗 | 低 | 中 | Dockerfile に build-essential 含める |
| Playwright イメージサイズ増加 | 中 | 中 | マルチステージビルドで分離 |
| Next.js 16 + Vitest 互換性 | 中 | 低 | lib モジュールから段階的導入 |

詳細は [design/06_side-effect-verification.md](./copilot-session-viewer/design/06_side-effect-verification.md) を参照。

### 5.3 ロールバック計画

全変更は新規ファイル追加または最小限の既存ファイル修正。ロールバックは該当行/ファイル削除で容易。

---

## 6. レビュー・承認

### 6.1 レビュー履歴

| 日付 | レビュアー | 結果 | コメント |
|------|------------|------|----------|
| | | | |

### 6.2 承認

#### 完了条件

##### 実装レビュー完了
- [ ] コード品質確認
  - [ ] コーディング規約準拠
  - [ ] 可読性・保守性確認
  - [ ] 重複コード排除確認
- [ ] 設計方針の遵守確認
  - [ ] 設計書との整合性確認
  - [ ] アーキテクチャ準拠確認
- [ ] セキュリティレビュー完了
  - [ ] .env がイメージに含まれない確認
  - [ ] GITHUB_TOKEN がログ出力されない確認
  - [ ] Basic Auth 動作確認

##### テスト完了
- [ ] テスト計画に記載のテスト実行完了
  - [ ] 単体テスト完了（Vitest: terminal.ts, sessions.ts, middleware.ts）
  - [ ] 結合テスト完了（standalone ビルド、設定互換性）
  - [ ] E2E テスト完了（Playwright: コンテナ起動、tmux、認証）
- [ ] テストカバレッジ確認
  - [ ] 目標カバレッジ達成（lib: 60%+, middleware: 80%+）
  - [ ] 未カバー箇所の妥当性確認

##### 弊害検証完了
- [ ] 回帰テスト完了
  - [ ] ローカル開発（npm run dev）正常動作
  - [ ] npm run build エラーなし
  - [ ] npm run lint 新規エラーなし
  - [ ] Docker 検出が DISABLE_DOCKER_DETECTION 未設定時に動作
- [ ] パフォーマンス検証確認
  - [ ] コンテナ起動→HTTP応答: 30秒以内
  - [ ] API レスポンスタイム: 500ms 以内
  - [ ] メモリ使用量: 512MB 以下
- [ ] 弊害検証結果レポート作成

---

## 7. 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-03-21 | 1.0 | 初版作成 | Hiroaki |
