---
name: implement
description: タスク計画に従って実装を実行するスキル。タスク一覧・依存関係・プロンプトを入力として、タスク実装管理、worktree管理、コミット管理、cherry-pick統合を行う。「implement」「実装を実行」「タスク実装」「計画を実行」「実装開始」などのフレーズで発動。タスク計画作成後に使用。
---

# 開発実装スキル（implement）

タスク計画に従い、サブエージェントへの実装依頼、worktree管理、コミット・cherry-pick統合を行う。

> **品質ガイドライン**: `test-driven-development` と `verification-before-completion` スキルの原則に従う。

## 実現すること

1. タスク計画からコンテキスト・タスク一覧・依存関係を取得
2. 依存関係から実行順序・並列グループを特定
3. 単一/並列タスクを判別し、適切な処理に振り分け
4. Worktreeライフサイクル管理（並列タスク時: 作成→使用→cherry-pick→破棄）
5. サブエージェントへの実装依頼と2段階レビュー
6. 各タスク完了時に進捗記録・全タスク完了後に検証フェーズへ連携

## 入力

- **タスク計画**（必須）: チケットID、対象リポジトリ、ブランチ名、タスク一覧（ID・依存関係・ステータス）、レビュー承認状態
- **タスクプロンプト**（必須）: `plan/` 配下の各タスク実装指示ファイル（task01.md, task02-01.md 等）

## 出力

- **実装進捗**: 全体ステータス（`in_progress` → `completed`）、各タスクのステータス・コミットハッシュ
- **実行ログ**: `implement/execution-log.md`

## タスク処理方式

| 方式 | 作業環境 | Worktree | コミット |
|------|---------|----------|---------|
| 単一実行 | feature/{ticket_id} ブランチ | 不要 | 直接実行 |
| 並列実行 | feature/{ticket_id}-{task_id} | `.worktrees/` 配下に作成 | cherry-pick で統合 |

## サブエージェント2段階レビュー

各タスク完了時に成果物をレビュー：
- **Stage 1（仕様準拠）**: プロンプト要件充足、完了条件クリア、設計準拠
- **Stage 2（コード品質）**: TDD原則、テスト全通過（単体/結合/E2E）、リント・型チェックパス

> **テストが未実行のままタスクを完了にしてはならない**

## 並列化判断

以下を全て満たす場合に並列実行：3つ以上の独立タスク、ファイル編集の衝突なし、独立テストファイル

## 注意事項

- **前提**: タスク計画が作成済み、かつレビュー承認済みであること
- **コミット順序**: 依存関係を尊重してcherry-pick
- **エラー時**: ロールバック・手動介入オプションを提示
- **品質**: 各タスク完了時にテスト・リント・型チェックを確認
- **進捗記録**: 各タスク完了時に実装進捗を更新してコミット
- **検証連携**: 全タスク完了後は検証フェーズでテスト・ビルド・リントを実行
- **テスト戦略の遵守**: テスト計画で定義されたテスト範囲を実装に反映する

## 参照ファイル

- 📖 詳細は [references/execution-procedure.md](references/execution-procedure.md) を参照 — 実行手順・コミット管理・処理フロー図
- 📖 詳細は [references/subagent-delegation.md](references/subagent-delegation.md) を参照 — 依頼テンプレート・エラーハンドリング・レビュー詳細
- 📖 詳細は [references/task-orchestration.md](references/task-orchestration.md) を参照 — 実行追跡・完了レポート・ワークフロー・I/Oリファレンス
- 📖 詳細は [references/worktree-management-guide.md](references/worktree-management-guide.md) を参照 — Worktree管理ガイド
- 📖 詳細は [references/parallel-execution-guide.md](references/parallel-execution-guide.md) を参照 — 並列実行管理ガイド
- 品質原則: `test-driven-development` — TDDサイクル
- 品質原則: `verification-before-completion` — 完了前検証
