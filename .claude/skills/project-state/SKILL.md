---
name: project-state
description: project.yaml/setup.yamlの状態管理スキル。ワークフローの状態読み取り・セクション更新・前提条件チェックを一元管理する。「project.yaml更新」「ステータス更新」「セクション初期化」「前提条件チェック」「project-state」などのフレーズで発動。各種ワークフロースキル実行後のproject.yaml書き戻しに使用。
---

# project-state — ワークフロー状態管理スキル

project.yaml / setup.yaml の読み書きを一元管理するスキルです。
ワークフロースキル（investigation, design, plan 等）の実行前後に呼び出し、コンテキスト取得や結果書き戻しを行います。

## 概要

- **project.yaml**: 全プロセスの SSOT（Single Source of Truth）
- **setup.yaml**: タスクの初期設定ファイル（project.yaml 生成前に使用）
- **project-yaml-helper.sh**: project.yaml 操作用 CLI ヘルパー

> **重要**: project.yaml を直接 `cat` や `view` で参照してはならない。
> 必ず `scripts/project-yaml-helper.sh` 経由でアクセスすること。

## ヘルパーコマンド一覧

| コマンド | 説明 |
|---------|------|
| `status` | ステータス確認 |
| `validate` | スキーマ + 前提条件バリデーション |
| `init-section <section>` | セクション雛形生成 |
| `update <section>` | セクション更新（--status, --summary, --artifacts） |
| `checkpoint <name>` | 人間チェックポイント記録（--verdict, --feedback） |
| `resolve-checkpoint <name>` | チェックポイント解決記録（--summary） |
| `snapshot-section <section>` | セクションスナップショット |

📖 引数・オプションの詳細は [references/helper-command-reference.md](references/helper-command-reference.md) を参照

## セクション構造

project.yaml は `meta`, `setup`, `brainstorming`, `overview`, `investigation`, `design`, `plan`, `implement`, `verification`, `code_review`, `finishing`, `human_checkpoints` の各セクションで構成される。

📖 各セクションの説明・書き込み元は [references/section-and-preconditions.md](references/section-and-preconditions.md) を参照

## 操作パターン

| パターン | 概要 |
|---------|------|
| 1. コンテキスト読み取り | スキル実行前に `yq` でメタ情報・要件・成果物パスを抽出 |
| 2. セクション初期化+更新 | `init-section` → `update` → `meta.updated_at` 更新 |
| 3. 前提条件チェック | `validate` または `yq` で前提セクションのステータスを確認 |
| 4. 人間チェックポイント管理 | `checkpoint` で承認/差し戻し、`resolve-checkpoint` で対応完了 |

📖 各パターンのコード例は [references/operation-patterns.md](references/operation-patterns.md) を参照

## 前提条件マップ

各ステップの実行には前ステップの完了・承認が必要（`preconditions.yaml` で定義）。
例: investigation 実行には brainstorming.status=completed かつ brainstorming_review=approved が必要。

📖 全ステップの前提条件一覧は [references/section-and-preconditions.md](references/section-and-preconditions.md) を参照

## ステータス値

- **ライフサイクル**: `pending` → `in_progress` → `completed` / `failed` / `skipped`
- **レビュー**: `pending` → `approved` / `conditional` / `rejected`
- **チェック結果**: `pass` / `fail` / `skip` / `warning`
- **人間チェックポイント**: `pending` → `approved` / `revision_requested`

📖 指摘ステータス（code_review）等の詳細は [references/section-and-preconditions.md](references/section-and-preconditions.md) を参照

## コミットルール

project.yaml 更新時は `chore: {ticket_id} project.yaml {section}セクション更新` 形式でコミットする。

📖 コミットメッセージテンプレートは [references/operation-patterns.md](references/operation-patterns.md) を参照

## 注意事項

- project.yaml を直接 `cat`/`view` で読んではならない — `project-yaml-helper.sh` を使う
- `yq` コマンドで値を更新する際は `-i` フラグ（in-place）を使用
- `meta.updated_at` はセクション更新時に必ず更新する
- スキーマバリデーションは `$HELPER validate` で実行可能
