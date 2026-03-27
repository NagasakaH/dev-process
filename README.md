# Development Process Skills

Claude/Copilot向けの開発プロセス用スキル集とエージェント構成をまとめたリポジトリです。

## このリポジトリの目的

1. **汎用スキルの整備**: AIエージェントによる開発プロセスを体系化した汎用スキル群を提供します。各スキルはプロジェクト非依存で、単体でも利用可能です
2. **ワークフロー統合**: 10ステップワークフローとして汎用スキルを組み合わせ、project.yaml による進捗管理を行います
3. **修正対象リポジトリと独立した中間ドキュメント管理**: サブモジュールを活用し、設計・調査・計画・レビュー等の中間成果物を本リポジトリ側で管理します

---

## アーキテクチャ

3層構造でスキルとワークフローを分離しています:

```
┌─────────────────────────────────────────┐
│  dev-workflow エージェント               │  ← オーケストレーター
├─────────────────────────────────────────┤
│  prompts/workflow/*.md                   │  ← project.yaml 連携手順
│  project-state スキル                    │  ← 状態管理（読み書き）
├─────────────────────────────────────────┤
│  汎用スキル (.claude/skills/)            │  ← プロジェクト非依存
│  investigation, design, plan, etc.       │
└─────────────────────────────────────────┘
```

| レイヤー | 場所 | 役割 |
|---------|------|------|
| **汎用スキル** | `.claude/skills/*/SKILL.md` | コア機能（調査、設計、計画等）。project.yaml に依存しない |
| **ワークフロープロンプト** | `prompts/workflow/*.md` | 各ステップの project.yaml 連携手順（コンテキスト取得→スキル実行→結果書き戻し） |
| **project-state スキル** | `.claude/skills/project-state/` | project.yaml/setup.yaml の読み書きを一元管理 |

---

## 主な特徴

- **プロジェクト非依存の汎用スキル**: 各スキルは単体で利用可能。project.yaml なしでも動作
- **10ステップワークフロー**: 初期化 → ブレスト → 調査 → 設計 → 計画 → 実装 → 検証 → レビューの体系的プロセス
- **dev-workflow エージェント**: ワークフローを自律実行し、setup.yaml作成〜finishing-branchまで1プロンプトで完走
- **品質スキル統合**: TDD、検証、デバッグ、コードレビューの組み込み
- **並列実行対応**: 独立タスクの並列処理によるスループット向上

---

## 10ステップワークフロー

```mermaid
flowchart LR
    init[1. init-work-branch] --> overview[2. submodule-overview]
    overview --> brainstorm[3. brainstorming]
    brainstorm --> hc1{👤 3a. brainstorming_review}
    hc1 -->|✅ 承認| investigation[4. investigation]
    hc1 -->|🔄 差し戻し| brainstorm
    investigation --> design[5. design]
    design --> review_d[5a. review-design]
    review_d -->|✅ 承認| hc2{👤 5b. design_review}
    review_d -->|❌ 差し戻し| design
    hc2 -->|✅ 承認| plan[6. plan]
    hc2 -->|🔄 差し戻し| design
    plan --> review_p[6a. review-plan]
    review_p -->|✅ 承認| implement[7. implement]
    review_p -->|❌ 差し戻し| plan
    implement --> verification[8. verification]
    verification --> code_review[9. code-review]
    code_review -->|✅ 承認| finish[10. finishing-branch]
    code_review -->|❌⚠️ 指摘あり| code_review_fix[9a. code-review-fix]
    code_review_fix --> code_review
    finish -->|PR作成| hc3{👤 10a. pr_review}
    hc3 -->|✅ 承認| done[完了]
    hc3 -->|🔄 差し戻し| implement
```

| ステップ              | 説明                                                           |
| --------------------- | -------------------------------------------------------------- |
| 1. init-work-branch   | 入力情報を基に feature ブランチ・サブモジュールを初期化        |
| 2. submodule-overview | サブモジュールの技術スタック・API・依存関係を分析              |
| 3. brainstorming      | ユーザー対話で要件探索、テスト戦略確定                         |
| 👤 3a. brainstorming_review | brainstorming結果の人間レビュー（差し戻しあり）           |
| 4. investigation      | アーキテクチャ・データ構造・依存関係の詳細調査                 |
| 5. design             | API・データ構造・処理フローの詳細設計                          |
| 5a. review-design     | 設計の妥当性レビュー（差し戻しあり）                           |
| 👤 5b. design_review  | 設計レビュー完了後の人間レビュー（差し戻しあり）               |
| 6. plan               | タスク分割・依存関係整理・TDDプロンプト生成                    |
| 6a. review-plan       | 計画の妥当性レビュー（差し戻しあり）                           |
| 7. implement          | サブエージェントによる実装（2段階レビュー付き）                |
| 8. verification       | テスト・ビルド・リント・型チェック・受入基準照合               |
| 9. code-review        | 8カテゴリのチェックリストベースレビュー                        |
| 9a. code-review-fix   | レビュー指摘の修正対応                                         |
| 10. finishing-branch  | マージ / PR作成 / ブランチ保持 / 破棄                          |
| 👤 10a. pr_review     | PR発行後の人間レビュー（差し戻しあり）                         |

📄 各ステップの詳細（インプット/成果物/説明）→ [docs/workflow-details.md](docs/workflow-details.md)

---

## project.yaml — ワークフロー状態管理

ワークフロー利用時の進捗管理ファイルです。`brainstorming` ステップで生成され、以降のステップで `project-state` スキル経由で更新されます。

> **注意**: 各汎用スキル自体は project.yaml に依存しません。project.yaml との連携は `prompts/workflow/*.md` と `project-state` スキルが担当します。

📄 設計方針・セクション構成・ワークフロー図 → [docs/project-yaml.md](docs/project-yaml.md)

---

## スキル一覧

### 汎用スキル（プロジェクト非依存）

| カテゴリ | スキル |
|---------|--------|
| **ワークフロー** | brainstorming, investigation, design, plan, implement, verification, finishing-branch, init-work-branch, submodule-overview |
| **レビュー** | review-design, review-plan, code-review, code-review-fix |
| **品質ルール** | test-driven-development, systematic-debugging, verification-before-completion |
| **ユーティリティ** | commit, commit-multi-repo, writing-skills, gitlab-api, terraform, aws-knowledge, aws-documentation |

### プロジェクト固有スキル

| スキル | 説明 |
|--------|------|
| project-state | project.yaml/setup.yaml の状態管理を一元化 |
| create-setup-yaml | 対話的に setup.yaml を作成 |
| issue-to-setup-yaml | GitHub Issue から setup.yaml を生成 |
| skill-usage-protocol | スキル利用プロトコル |

📄 全スキルの詳細一覧 → [docs/skills.md](docs/skills.md)

---

## 実行例

```bash
# 典型的な開発フロー（セッション内で順次実行）
claude "setup.yaml を使って作業ブランチを初期化してください"    # → init-work-branch
claude "サブモジュールの概要を作成してください"                  # → submodule-overview
claude "ブレストしましょう"                                      # → brainstorming → project.yaml 生成
claude "詳細調査を実行してください"                              # → investigation
claude "設計してください"                                        # → design
claude "設計をレビューしてください"                              # → review-design
claude "タスク計画を作成してください"                            # → plan
claude "計画をレビューしてください"                              # → review-plan
claude "実装を開始してください"                                  # → implement
claude "検証してください"                                        # → verification
claude "コードレビューしてください"                              # → code-review
claude "レビュー指摘を修正してください"                          # → code-review-fix（指摘がある場合）
claude "ブランチを完了してください"                              # → finishing-branch
```

---

## 詳細ドキュメント

| ドキュメント                                                 | 内容                                                    |
| ------------------------------------------------------------ | ------------------------------------------------------- |
| [docs/workflow-details.md](docs/workflow-details.md)         | 10ステップの各ステップ詳細（インプット/成果物/説明）    |
| [docs/project-yaml.md](docs/project-yaml.md)                 | project.yaml の設計方針・セクション構成・ワークフロー図 |
| [docs/skills.md](docs/skills.md)                             | 全スキル一覧と分類                                      |
| [docs/operations-guide.md](docs/operations-guide.md)         | TDD方針・検証ルール・並列化判断フロー                   |
| [docs/subagent-development.md](docs/subagent-development.md) | サブエージェント駆動開発の手順・2段階レビュー           |
| [docs/finishing-branch.md](docs/finishing-branch.md)         | ブランチ完了の自動化フロー・スクリプト例                |
| [docs/code-review-guide.md](docs/code-review-guide.md)       | SHAベースコードレビュー手順・テンプレート・運用例       |
| [docs/directory-structure.md](docs/directory-structure.md)   | ディレクトリ構成例・依存関係グラフ                      |

---

## 関連ドキュメント

- **[AGENTS.md](AGENTS.md)**: プロジェクト固有の運用ルールとモデル指定
- **[setup-template.yaml](setup-template.yaml)**: セットアップYAMLのテンプレート
- **[docs/templates/pr-template.md](docs/templates/pr-template.md)**: PRテンプレート
