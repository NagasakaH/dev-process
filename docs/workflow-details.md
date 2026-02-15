# 10ステップワークフロー詳細

各ステップのインプット、成果物、説明を詳述します。ワークフロー全体の概要は [README.md](../README.md) を参照してください。

---

## 1. init-work-branch（作業ブランチ初期化）

**インプット:**

- `setup.yaml`: プロジェクト設定ファイル（SSOT）

**成果物:**

- `feature/{ticket_id}` ブランチ
- `submodules/{repo_name}/`: サブモジュール追加
- `docs/{ticket_id}.md`: 設計ドキュメント

**説明:**

- `setup.yaml` を読み込み、featureブランチを作成
- 関連・修正対象リポジトリをサブモジュールとして追加
- 設計ドキュメント（`docs/{ticket_id}.md`）を生成

> **Note**: このステップでは `project.yaml` はまだ存在しない（`brainstorming` で生成される）

---

## 2. submodule-overview（サブモジュール概要作成）

**インプット:**

- `project.yaml`（存在する場合）
- `submodules/{repo_name}/`: サブモジュールディレクトリ
- `submodules/{repo_name}/README.md`: プロジェクト概要
- `submodules/{repo_name}/CLAUDE.md`: Claude向けコンテキスト（任意）
- `submodules/{repo_name}/AGENTS.md`: エージェント向け指示（任意）

**成果物:**

- `submodules/{name}.md`: サブモジュール概要ドキュメント
- `project.yaml` の `overview` セクション更新

**説明:**

- サブモジュールのREADME/CLAUDE.md/AGENTS.mdから情報収集
- 技術スタック、API、依存関係を分析
- `submodules/{name}.md` に概要ドキュメント生成

---

## 3. brainstorming（要件探索・テスト戦略確認・project.yaml 生成）

**インプット:**

- `setup.yaml`: プロジェクト設定ファイル（ユーザーが作成した一次情報）
- ユーザーとの対話: 意図・要件・背景の聞き取り

**成果物:**

- **`project.yaml`**: 全プロセスの SSOT（`meta`, `setup`, `brainstorming` セクション）
- `docs/{repo}/brainstorming/*.md`: ブレインストーミング詳細ドキュメント

**説明:**

`setup.yaml` を基に `project.yaml` を生成する唯一のプロセスです。ユーザーとの対話により要件の明確化・妥当性評価を行い、機能要件・非機能要件の具体化、技術的制約の確認を実施します。2〜3つのアプローチを提案しトレードオフを説明した上で設計方針を決定し、結果を `project.yaml` の `brainstorming` セクションに記録します。

**テスト戦略の確認（必須）:** テスト範囲（単体テスト/結合テスト/E2Eテスト）を `ask_user` ツールでユーザーに確認し、`test_strategy` として `project.yaml` に記録します。この戦略は以降の design（テスト計画）、plan（E2Eタスク生成）、implement（テスト実行）、verification（acceptance_criteria照合）の全工程で参照されます。

> **Important**: `brainstorming` 以降の全プロセス（investigation, design, plan, implement 等）は `project.yaml` を SSOT として参照・更新します。`setup.yaml` は直接参照しません。

---

## 4. investigation（詳細調査）

**インプット:**

- `project.yaml`（SSOT — `setup.description.background` を背景情報として参照）
- `submodules/{target_repo}/`: 調査対象リポジトリ

**成果物:**

- `docs/{target_repo}/investigation/01_architecture.md`: アーキテクチャ調査
- `docs/{target_repo}/investigation/02_data-structure.md`: データ構造調査
- `docs/{target_repo}/investigation/03_dependencies.md`: 依存関係調査
- `docs/{target_repo}/investigation/04_existing-patterns.md`: 既存パターン調査
- `docs/{target_repo}/investigation/05_integration-points.md`: 統合ポイント調査
- `docs/{target_repo}/investigation/06_risks-and-constraints.md`: リスク・制約分析
- `project.yaml` の `investigation` セクション更新

**説明:**

- `project.yaml` の `setup.description.background` と `brainstorming.refined_requirements` を参照
- アーキテクチャ、データ構造、依存関係を体系的に調査
- UML図（Mermaid形式）を含む調査結果を生成
- `docs/{target_repo}/investigation/` に出力

---

## 5. design（設計）

**インプット:**

- `project.yaml`（SSOT — `setup.description.requirements` を設計要件として参照）
- `docs/{target_repo}/investigation/`: 調査結果

**成果物:**

- `docs/{target_repo}/design/01_implementation-approach.md`: 実装方針
- `docs/{target_repo}/design/02_interface-api-design.md`: インターフェース/API設計
- `docs/{target_repo}/design/03_data-structure-design.md`: データ構造設計
- `docs/{target_repo}/design/04_process-flow-design.md`: 処理フロー設計
- `docs/{target_repo}/design/05_test-plan.md`: テスト計画
- `docs/{target_repo}/design/06_side-effect-verification.md`: 弊害検証計画
- `project.yaml` の `design` セクション更新

**説明:**

- `project.yaml` の `investigation` + `brainstorming.decisions` を参照
- 調査結果を基に詳細設計を実施
- API設計、データ構造設計、処理フロー設計
- 修正前/修正後のシーケンス図を作成
- `docs/{target_repo}/design/` に出力

---

## 5a. review-design（設計レビュー）

設計結果の妥当性をレビューします。指摘がある場合は design に差し戻し、再設計後に再レビューを実施します。

---

## 6. plan（タスク計画）

**インプット:**

- `project.yaml`（SSOT — `setup.acceptance_criteria` を完了条件基準として参照）
- `docs/{target_repo}/design/`: 詳細設計結果

**成果物:**

- `docs/{target_repo}/plan/task-list.md`: タスク一覧と依存関係
- `docs/{target_repo}/plan/task01.md`, `task02-01.md`, ...: 各タスク用プロンプト
- `docs/{target_repo}/plan/parent-agent-prompt.md`: 親エージェント統合管理プロンプト
- `project.yaml` の `plan` セクション更新

**説明:**

- `project.yaml` の `design.artifacts` パスから設計成果物を読み込み
- 設計からタスクを分割、依存関係を整理
- 各タスク用プロンプト（task0X.md）をTDD方針で生成
- 親エージェント用統合管理プロンプトを生成
- `docs/{target_repo}/plan/` に出力

---

## 6a. review-plan（計画レビュー）

タスク計画の妥当性をレビューします。指摘がある場合は plan に差し戻し、再計画後に再レビューを実施します。

---

## 7. implement（実装）

**インプット:**

- `project.yaml`（SSOT — `plan.tasks` からタスク一覧取得、`plan.review.status = approved` が前提）
- `docs/{target_repo}/plan/`: タスク計画（task-list.md, task0X.md, parent-agent-prompt.md）

**成果物:**

- `docs/{target_repo}/implement/execution-log.md`: 実行ログ
- 実装コード（サブモジュール内）
- テストコード（サブモジュール内）
- コミット履歴（各タスク完了時）
- `project.yaml` の `implement` セクション更新

**説明:**

- `project.yaml` の `plan.tasks` からタスク一覧・依存関係を取得
- サブエージェントに実装を依頼（2段階レビュー: 仕様準拠 → コード品質）
- 並列タスクはworktreeを使用して並行実行、cherry-pickで統合
- 各タスク完了時に `project.yaml` の `implement.tasks` を更新
- `docs/{target_repo}/implement/` に実行ログ出力

---

## 8. verification（検証）

**インプット:**

- `project.yaml`（SSOT — `implement.status = completed` が前提）
- `submodules/{target_repo}/`: 実装済みコード

**成果物:**

- `docs/{target_repo}/verification/results.md`: 検証結果レポート
- `project.yaml` の `verification` セクション更新

**説明:**

- テスト・ビルド・リント・型チェックを実行し、自動化可能な客観検証を実施
- `project.yaml` の `brainstorming.test_strategy` に基づき、定義されたテスト（単体/結合/E2E）をすべて実行
- `setup.acceptance_criteria` の各項目に対して検証方法（単体テスト/E2Eテスト等）と結果を照合し `acceptance_criteria_check` として記録
- 全検証通過で code-review へ進行、失敗時は implement に戻る

---

## 9. code-review（コードレビュー）

**インプット:**

- `project.yaml`（SSOT — `verification.status = completed` が前提）
- コミット範囲（BASE_SHA..HEAD_SHA）
- `docs/{target_repo}/design/`: 設計成果物（設計準拠性チェック用）

**成果物:**

- `docs/{target_repo}/code-review/round-01.md`（以降 round-02.md, ...）: レビュー結果
- `project.yaml` の `code_review` セクション更新（チェックリスト結果・指摘・ラウンド）

**説明:**

- 8カテゴリのチェックリスト（設計準拠性、静的解析、言語別ベストプラクティス、セキュリティ、テスト・CI、パフォーマンス、ドキュメント、Git作法）でレビューを実施
- **ゼロトレランス方針**: Minorを含む全指摘の修正が必須。「後で対応」は許容しない
- プロジェクト内の静的解析ツール（prettier / eslint / black / flake8 等）を検出・実行
- 指摘と修正案の提示が責務（修正自体は code-review-fix が担当）
- `project.yaml` の `code_review.review_checklist` にチェック項目と結果を構造化記録

---

## 9a. code-review-fix（レビュー指摘修正）

**インプット:**

- `project.yaml`（SSOT — `code_review.issues` から未解決指摘を取得）
- `docs/{target_repo}/code-review/round-{NN}.md`: レビュー結果

**成果物:**

- 修正コード・コミット
- `project.yaml` の `code_review.issues` 更新（fixed / disputed）

**説明:**

- 各指摘を技術的に検証し、妥当な場合は修正、不適切な場合は技術的理由で反論
- 修正後にテスト・リント・型チェックを実行して確認
- 完了後 code-review で再レビュー

---

## 10. finishing-branch（ブランチ完了）

**インプット:**

- `project.yaml`（SSOT — `code_review.status = approved` が前提）

**成果物:**

- マージ / PR / ブランチ保持 / 破棄
- `project.yaml` の `finishing` セクション更新

**説明:**

- テスト検証後、4つの選択肢を提示（ローカルマージ / PR作成 / ブランチ保持 / 破棄）
- 選択されたワークフローを実行し、worktreeクリーンアップを実施
