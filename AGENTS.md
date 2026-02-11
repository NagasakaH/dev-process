# エージェント一覧と運用ガイド

このドキュメントは本リポジトリで提供する主要エージェントの一覧と、短い運用ガイドを示します。

## 目的
- ユーザーが利用する呼び出し用エージェント（call-*）と、実行を行うエージェントを明確に整理する。
- call-* はユーザーが直接呼ぶラッパーで、実行ロジックはラッパーが実行エージェントを呼び出す形にする。

## 維持するエージェント（必須）
- call-general-purpose.agent.md
  - 役割: ユーザーが単発のタスクや小規模作業を依頼するためのラッパー。
  - 備考: 既存のワークフローと互換性あり。
- general-purpose.agent.md
  - 役割: 汎用実行エージェント。スキルを実行し成果物を作成する。
  - 運用ルール: サブエージェント呼び出し時は Opus-4.5 を利用すること。

## 本運用で追加したエージェント
- environment-setup.agent.md
  - 役割: 開発環境の構築（サブモジュール追加・初期セットアップまで自動化）。
  - ラッパー: call-environment-setup.agent.md
- pre-implementation-planning.agent.md
  - 役割: 実装前の調査と設計、setup.yaml の生成補助、タスク分割の下準備。
  - ラッパー: call-pre-implementation-planning.agent.md
- plan-migration.agent.md
  - 役割: 生成された計画（docs/plan）をリポジトリに移行し、ブランチとファイルを作成する。
  - ラッパー: call-plan-migration.agent.md

## 削除または統合したエージェント
- dev-planning-manager.agent.md（機能を pre-implementation-planning に統合）
- call-dev-planning-manager.agent.md（不要のため削除）
- code-reviewer.agent.md（不要のため削除）

## 呼び出しルール（簡潔）
- ユーザーは call-* ラッパーを呼ぶ。ラッパーは内部で該当実行エージェントを呼び出す。
- ラッパー側（call-*）は Opus-4.6 等を使って外部呼び出しのラップを行っても良いが、実際にサブエージェントを起動する際は必ず Opus-4.5 を指定する運用とする。
- 既存スキルやスクリプト内で "call-" 接頭辞で参照している箇所は、内部呼び出しを呼び出し先の実行エージェント名（call-を外した名前）に書き換えてある。

## 簡易利用例
- 環境構築:
  - ユーザー -> call-environment-setup.agent.md -> environment-setup.agent.md（内部で Opus-4.5 指定）
- 実装前計画:
  - ユーザー -> call-pre-implementation-planning.agent.md -> pre-implementation-planning.agent.md
- 計画移行:
  - ユーザー -> call-plan-migration.agent.md -> plan-migration.agent.md

## 変更履歴
- 2026-02-11: エージェント整理実行。不要エージェントを削除し、新規に3エージェントとラッパー3つを追加。

---

(約100行以内に収めています。詳細は各 agent.md を参照してください。)
