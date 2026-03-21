# Review-Plan Round 2 — viewer-container-local

## レビュー概要

| 項目 | 内容 |
|------|------|
| ラウンド | 2 |
| レビュアー | GPT-5.3-Codex, Claude Opus 4.6 |
| 判定 | **conditional** |
| 日付 | 2026-03-22 |

---

## レビュアー別結果

| レビュアー | 判定 | Major | Minor | Info |
|-----------|------|-------|-------|------|
| GPT-5.3-Codex | conditional | 2 | 3 | 0 |
| Claude Opus 4.6 | conditional | 2 | 3 | 0 |

---

## 統合判定

| 項目 | 内容 |
|------|------|
| 最終判定 | **conditional** (条件付き承認) |
| Major | 2 |
| Minor | 3 |
| 合計 | 5 |

---

## Round 1 指摘事項 解決状況

| ID | Severity | 状態 | 備考 |
|----|----------|------|------|
| MPR-001 | major | ✅ resolved | findDockerContainers export 追加済み |
| MPR-002 | major | ✅ resolved | Task06→Task10 依存関係追加済み |
| MPR-003 | major | ✅ resolved | TDD RED テスト具体化済み |
| MPR-004 | major | ✅ resolved | global-setup.ts 必須化済み |
| MPR-005 | major | ✅ resolved | E2E-6 条件付き必須化済み |
| MPR-006 | major | ✅ resolved | gh auth status テスト追加済み |
| MPR-007 | major | ✅ resolved | コンテナ分離 E2E テスト追加済み |
| MPR-008 | minor | ⚠️ partially_resolved | gosu を task07 で採用したが task10 Dockerfile に未追加 → NPR-001 |
| MPR-009 | minor | ⚠️ partially_resolved | 回帰テスト重複が部分的に残存 → 継続指摘 |
| MPR-010 | minor | ✅ resolved | Task10 見積もり 30min に更新済み |
| MPR-011 | minor | ✅ resolved | 対象ファイル表修正済み |
| MPR-012 | minor | ✅ resolved | バッファ注記追加済み |
| MPR-013 | info | ✅ resolved | テストファイル配置規約追加済み |

**解決率**: 11/13 (84.6%)

---

## Round 2 新規指摘事項

### Major

#### NPR-001: task10 Dockerfile に gosu パッケージ未追加

- **カテゴリ**: 依存関係
- **影響タスク**: task10, task07
- **問題**: task07 の `start-viewer.sh` が `exec gosu node "$0"` を使用するが、task10 の Dockerfile は `tini` のみインストールしており `gosu` が含まれていない。コンテナ起動時に `gosu: not found` エラーになる。
- **修正内容**:
  - task10: Dockerfile の `apt-get install` に `gosu` を追加
  - task07: gosu がベースイメージではなくアプリ層 Dockerfile で提供される旨を明記

#### NPR-002: AC1 Copilot CLI 動作確認テスト未定義

- **カテゴリ**: 受入基準
- **影響タスク**: task12
- **問題**: AC1 は「Copilot CLI 実行環境、session viewer、tmux が利用可能」を要求するが、E2E テストは viewer (E2E-1) と tmux (E2E-2) のみ検証しており、Copilot CLI (`cplt`) の可用性を検証するテストがない。
- **修正内容**:
  - task12: `cplt` コマンドの存在確認 E2E テスト (E2E-11) を追加

---

### Minor

#### NPR-003: container-isolation.spec.ts が task12 対象ファイル表に未記載

- **カテゴリ**: タスク分割
- **影響タスク**: task12
- **問題**: E2E-9/E2E-10 が `container-isolation.spec.ts` を参照するが、対象ファイル表に記載がない。
- **修正内容**:
  - task12: 対象ファイル表に `e2e/container-isolation.spec.ts` を追加

#### NPR-004: E2E .env 自動セットアップ未定義

- **カテゴリ**: TDD
- **影響タスク**: task12
- **問題**: E2E テストは `.env` を必要とするが、`global-setup.ts` に `.env` が存在しない場合の処理が定義されていない。CI 環境等で `.env` 未作成時にテストが不明確に失敗する。
- **修正内容**:
  - task12: `global-setup.ts` に `.env` 存在チェック + `.env.example` からの自動コピーを追加

#### MPR-009 (継続): Task11 回帰テスト重複

- **カテゴリ**: タスク分割
- **影響タスク**: task11
- **問題**: `regression.test.ts` の `findDockerContainers()` 単体テストが task03 の UT-1 と実質重複。
- **修正内容**:
  - task11: 単一関数テストをパイプラインレベル統合テスト (`getActiveSessions()` レベル) に置換

---

## 次のステップ

1. 全 5 件の指摘を plan ドキュメントに反映
2. project.yaml の plan.review セクションを更新
3. 修正後、Round 3 レビューを実施（approved を目指す）
