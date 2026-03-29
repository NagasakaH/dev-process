# エージェント運用ガイド

作業完了後に確実にユーザーに作業を終えてよいか確認してください  
確認の際には下記の項目を提示し、ユーザーの指示があれば追加の作業を行ってください
確認はテキストを出力するのではなく`ask_user`などのツールを使って確認を行うようにしてください

- 推奨する次のタスク（複数案があれば複数選択肢を提示)
- タスク終了
- ユーザーの任意の入力

本リポジトリ固有の運用ルールを示す（詳細はREADME.mdを参照）。

## スキル構成

本プロジェクトのスキルは以下の3層構造:

1. **汎用スキル** (`.claude/skills/`): プロジェクト非依存の汎用スキル
2. **プロジェクト固有スキル** (`project-state`, `create-setup-yaml`, `issue-to-setup-yaml`): project.yaml/setup.yaml 管理
3. **ワークフロープロンプト** (`prompts/workflow/*.md`): 汎用スキル実行前後の project.yaml 連携手順

## ワークフロー利用時のルール

project.yamlの直接参照は禁止、代わりにscripts/project-yaml-helper.shを使用してください

**ワークフロー遵守の絶対強制**: dev-workflow エージェントを選択している場合は setup.yaml → project.yaml のワークフロープロセスに従うこと

各ワークフローステップの手順:
1. `prompts/workflow/{step}.md` を参照しコンテキスト取得手順を確認
2. `project-state` スキルで project.yaml から情報を抽出
3. 汎用スキルを実行
4. `project-state` スキルで結果を project.yaml に書き戻し

## 10ステップワークフロー

1. **init-work-branch** - ブランチ・サブモジュール・設計ドキュメント初期化
2. **submodule-overview** - サブモジュール概要作成
3. **brainstorming** - 要件探索・テスト戦略確認・project.yaml 生成
   - 👤 **brainstorming_review** - project.yaml生成後の人間チェックポイント
4. **investigation** - 詳細調査（UML図含む）
5. **design** (+review-design) - 詳細設計（API、データ構造、処理フロー、テスト計画）
   - 5a. **review-design** - 設計の妥当性レビュー
   - 5b. **create-mr-pr** (DRモード) - 設計レビュー用 draft MR/PR 作成
   - 👤 **design_review** - MR/PR上での人間レビュー（承認後close）
6. **plan** (+review-plan) - タスク分割・プロンプト生成（E2Eタスク含む）
7. **implement** - 実装実行（並列化対応、定義されたテストの実行確認）
8. **verification** - テスト・ビルド・リント実行確認 + E2Eテスト + acceptance_criteria照合
9. **create-mr-pr** (Codeモード) - 各submoduleにdraft MR/PR作成
10. **code-review** (+code-review-fix) - チェックリストベース実装レビュー → draft解除
    - 👤 **pr_review** - MR/PR上での人間レビュー

## 人間チェックポイント

ワークフロー中の3箇所で人間の承認・差し戻しが発生する。差し戻し時は指摘内容と対応履歴が `human_checkpoints` セクションで管理される。

- `checkpoint` コマンドで承認・差し戻しを記録
- `resolve-checkpoint` コマンドで差し戻し対応完了を記録
- 詳細は [docs/project-yaml.md](docs/project-yaml.md) を参照

## API呼び出し安全性ルール

- **shell展開の禁止**: bash heredoc / echo / printf で API リクエストボディを構築しない。`$変数` やバッククォートが意図せず展開され、リクエストが壊れるリスクがある
- **推奨パターン**: `create` ツールで Python/Node.js スクリプトをファイルに書き出し → `bash` ツールで実行。マルチラインコンテンツやユーザー生成コンテンツを含む場合は必須
- **作成後の内容確認**: Issue / MR / PR 作成後は API で内容を再取得し、意図通りか確認してから完了とする。不一致があれば即座に修正する

📖 詳細は [.claude/skills/gitlab-api/SKILL.md](.claude/skills/gitlab-api/SKILL.md#shell展開防止ルール) を参照

## 品質ルール

- **TDD**: 失敗するテストなしにコードを書かない
- **verification**: 検証証拠なしに完了を主張しない
- **テスト戦略**: brainstormingでテスト範囲（単体/結合/E2E）を確認し、全工程で遵守する
- **並列化**: 独立タスク→並列、依存タスク→順次
- **ユーザー確認**: 対話は `ask_user` ツールで行い、テキスト出力だけで確認としない

## エージェント

| エージェント                                   | 説明                                                                                    |
| ---------------------------------------------- | --------------------------------------------------------------------------------------- |
| [dev-workflow](.claude/agents/dev-workflow.md) | 10ステップワークフローを自律実行。setup.yaml作成〜code-reviewまで1プロンプトで完走 |

## setup.yaml の作成

setup.yaml がない場合は以下のいずれかで作成：

- `create-setup-yaml` スキル — ユーザーと対話して0から作成
- `issue-to-setup-yaml` スキル — GitHub Issue から自動抽出
