# エージェント運用ガイド

作業完了後に確実にユーザーに作業を終えてよいか確認してください  
確認の際には下記の項目を提示し、ユーザーの指示があれば追加の作業を行ってください

- 推奨する次のタスク（複数案があれば複数選択肢を提示)
- タスク終了
- ユーザーの任意の入力

本リポジトリ固有の運用ルールを示す（詳細はREADME.mdを参照）。

## 最重要ルール

このプロジェクトはsetup.yamlを元にproject.yamlを生成、その後の作業状況を全てproject.yamlで管理します

project.yamlの直接参照は禁止、代わりにscripts/project-yaml-helper.shを使用してください

## 10ステップワークフロー

1. **init-work-branch** - ブランチ・サブモジュール・設計ドキュメント初期化
2. **submodule-overview** - サブモジュール概要作成
3. **brainstorming** - 要件探索・project.yaml 生成（全プロセスのSSOT）
4. **investigation** - 詳細調査（UML図含む）
5. **design** (+review-design) - 詳細設計（API、データ構造、処理フロー）
6. **plan** (+review-plan) - タスク分割・プロンプト生成
7. **implement** - 実装実行（並列化対応）
8. **verification** - テスト・ビルド・リント実行確認
9. **code-review** (+code-review-fix) - チェックリストベース実装レビュー
10. **finishing-branch** - マージ/PR/クリーンアップ

## 品質ルール

- **TDD**: 失敗するテストなしにコードを書かない
- **verification**: 検証証拠なしに完了を主張しない
- **並列化**: 独立タスク→並列、依存タスク→順次

## エージェント

| エージェント                                   | 説明                                                                                    |
| ---------------------------------------------- | --------------------------------------------------------------------------------------- |
| [dev-workflow](.claude/agents/dev-workflow.md) | 10ステップワークフローを自律実行。setup.yaml作成〜finishing-branchまで1プロンプトで完走 |

## setup.yaml の作成

setup.yaml がない場合は以下のいずれかで作成：
- `create-setup-yaml` スキル — ユーザーと対話して0から作成
- `issue-to-setup-yaml` スキル — GitHub Issue から自動抽出
