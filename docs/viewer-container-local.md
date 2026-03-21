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

<!-- 調査結果は investigation/ を参照 -->

### 1.2 関連コード・ファイル

| ファイル | 役割 | 備考 |
|----------|------|------|
| | | |

### 1.3 参考情報

<!-- 詳細: investigation/ -->

---

## 2. 設計

<!-- design スキルが更新 -->

### 2.1 設計方針

<!-- 詳細: design/01_implementation-approach.md -->

### 2.2 変更箇所

#### 追加ファイル

| ファイル | 目的 |
|----------|------|
| | |

#### 修正ファイル

| ファイル | 変更内容 |
|----------|----------|
| | |

#### 削除ファイル

| ファイル | 理由 |
|----------|------|
| | |

### 2.3 インターフェース設計

<!-- 詳細: design/02_interface-api-design.md -->

### 2.4 データ構造

<!-- 詳細: design/03_data-structure-design.md -->

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

### 4.2 テストケース

| No | テスト内容 | 期待結果 | 結果 |
|----|------------|----------|------|
| 1 | | | ⬜ |

### 4.3 テスト環境

---

## 5. 弊害検証

<!-- design/06_side-effect-verification.md を参照 -->

### 5.1 影響範囲

### 5.2 リスク分析

| リスク | 影響度 | 発生可能性 | 対策 |
|--------|--------|------------|------|
| | | | |

### 5.3 ロールバック計画

---

## 6. レビュー・承認

### 6.1 レビュー履歴

| 日付 | レビュアー | 結果 | コメント |
|------|------------|------|----------|
| | | | |

### 6.2 承認

- [ ] 設計レビュー完了
- [ ] 実装レビュー完了
- [ ] テスト完了
- [ ] 弊害検証完了

---

## 7. 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-03-21 | 1.0 | 初版作成 | Hiroaki |
