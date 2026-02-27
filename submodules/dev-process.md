# dev-process

> 最終更新: 2026-02-27

## 概要

Claude向けの開発プロセス用スキル集とエージェント構成をまとめたリポジトリ。AIエージェントによる開発プロセスを10ステップワークフローとして体系化し、各ステップに対応するスキル・品質ルール・レビュー機構を一元管理する。サブモジュールを活用して設計・調査・計画・レビュー等の中間成果物を管理し、修正対象リポジトリには実装コードのみが反映される。

---

## 優先度A（必須情報）

### 1. プロジェクト構成

```
dev-process/
├── .claude/
│   ├── agents/
│   │   └── dev-workflow.md          # dev-workflowエージェント定義
│   ├── hooks.json                   # Claude hooks設定
│   └── skills/                      # 26個のスキル定義
│       ├── _registry.yaml           # セクション⇔スキル対応表
│       ├── brainstorming/
│       ├── code-review/
│       ├── commit/
│       ├── design/
│       ├── implement/
│       ├── investigation/
│       ├── plan/
│       └── ... (他20スキル)
├── .devcontainer/
│   ├── devcontainer.json            # devcontainer設定（DinD対応）
│   ├── Dockerfile                   # カスタムイメージ定義
│   ├── dotfiles/                    # tmux設定等
│   ├── mssql-mcp/                   # MSSQL MCP feature
│   └── scripts/                     # cplt, start-tmux
├── docs/
│   ├── templates/
│   │   └── pr-template.md
│   ├── workflow-details.md
│   ├── project-yaml.md
│   ├── skills.md
│   ├── operations-guide.md
│   ├── subagent-development.md
│   ├── finishing-branch.md
│   ├── code-review-guide.md
│   └── directory-structure.md
├── scripts/
│   ├── build-and-push-devcontainer.sh  # イメージビルド&push
│   ├── dev-container.sh                # コンテナ起動/停止管理
│   ├── generate-metrics.sh             # メトリクス生成
│   ├── hooks/
│   │   └── session-start.sh
│   ├── project-yaml-helper.sh          # project.yaml操作CLI
│   └── validate-project-yaml.sh        # スキーマバリデーション
├── submodules/                      # 作業対象リポジトリ配置先
├── AGENTS.md                        # エージェント運用ガイド
├── README.md
├── preconditions.yaml               # ワークフロー前提条件定義
├── project-yaml.schema.yaml         # project.yamlスキーマ
├── setup-template.yaml              # setup.yamlテンプレート
└── setup-yaml.schema.yaml           # setup.yamlスキーマ
```

**主要ファイル:**
- `AGENTS.md` / `CLAUDE.md` — エージェント運用ルール（CLAUDE.mdはAGENTS.mdへのシンボリックリンク）
- `scripts/project-yaml-helper.sh` — project.yaml操作の中心CLI（status / validate / init-section / update）
- `scripts/dev-container.sh` — devcontainerの起動・停止・管理スクリプト（DinD/DooD切り替え対応）
- `.claude/skills/_registry.yaml` — セクション⇔スキルの対応表（SSOT）
- `preconditions.yaml` — 各ワークフローステップの実行前提条件定義

### 2. 外部公開インターフェース/API

ライブラリではなく開発プロセス管理リポジトリのため、外部公開APIは存在しない。

**主要CLIインターフェース:**

| コマンド | 説明 |
|---|---|
| `scripts/project-yaml-helper.sh status` | 全セクションのステータス一覧表示 |
| `scripts/project-yaml-helper.sh validate` | スキーマバリデーション + 前提条件チェック |
| `scripts/project-yaml-helper.sh init-section <section>` | セクション雛形の生成 |
| `scripts/project-yaml-helper.sh update <section>` | セクションの更新（--status, --summary, --artifacts） |
| `scripts/validate-project-yaml.sh [--preconditions]` | project.yamlバリデーション |
| `scripts/dev-container.sh up\|down\|status\|shell\|list` | devコンテナ管理 |
| `scripts/build-and-push-devcontainer.sh [IMAGE_NAME]` | devcontainerイメージのビルド&push |

**10ステップワークフロー（スキル）:**

1. `init-work-branch` → 2. `submodule-overview` → 3. `brainstorming` → 4. `investigation` → 5. `design` (+`review-design`) → 6. `plan` (+`review-plan`) → 7. `implement` → 8. `verification` → 9. `code-review` (+`code-review-fix`) → 10. `finishing-branch`

### 3. テスト実行方法

```bash
scripts/validate-project-yaml.sh [project.yaml]
scripts/validate-project-yaml.sh --preconditions [project.yaml]
```

スキーマバリデーションと前提条件チェックによるワークフロー検証。ユニットテストフレームワークは使用していない（YAML/Bashベースのプロセス管理リポジトリ）。

### 4. ビルド実行方法

```bash
# devcontainerイメージのビルド
scripts/build-and-push-devcontainer.sh [IMAGE_NAME]
```

- Step 1: `devcontainer build` でbaseタグ作成（linux/amd64）
- Step 2: Docker Hub へ base push
- Step 3: Dockerfile で latest タグ作成（pip ツール + tmux/cplt/dotfiles 追加）
- Step 4: Docker Hub へ latest push
- デフォルトイメージ名: `nagasakah/dev-process`

### 5. 依存関係

#### 本番依存
- `yq` — YAML操作（project-yaml-helper.sh で使用）
- `jsonschema` (Python) — YAMLスキーマバリデーション
- `pyyaml` (Python) — YAML解析

#### 開発依存
- `mcr.microsoft.com/devcontainers/dotnet:8.0` — ベースイメージ
- Node.js (LTS), Python 3.12, .NET 8.0 — 多言語対応
- Docker-in-Docker — コンテナ内開発
- Playwright — E2Eテスト
- Terraform, AWS CLI — IaC対応
- ripgrep, jq/yq, uv, Deno — ツールチェーン
- tmux, neovim — ターミナル環境
- Claude Code, GitHub Copilot CLI — AIアシスタント

### 6. 技術スタック

| カテゴリ | 技術 |
|---|---|
| 言語 | Bash, YAML, Python |
| フレームワーク | Claude Skills/Agents フレームワーク |
| ビルドツール | devcontainer CLI, Docker buildx |
| テストフレームワーク | check-jsonschema（スキーマバリデーション） |
| コンテナ | Docker (DinD/DooD切り替え対応) |
| CI/CD | GitHub Actions（想定） |

---

## 優先度B（オプション情報）

### 7. 利用方法/Getting Started

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
claude "ブランチを完了してください"                              # → finishing-branch
```

### 8. 環境変数/設定

| 変数名 | 説明 | デフォルト値 |
|---|---|---|
| `DEV_CONTAINER_IMAGE` | 使用するdevcontainerイメージ名 | `nagasakah/dev-process:latest` |
| `DOCKER_MODE` | Docker動作モード | `dind`（Docker-in-Docker） |
| `DOCKER_API_VERSION` | Docker API バージョン指定 | 自動検出 |

### 9. 他submoduleとの連携

本リポジトリ自体が開発プロセスの親リポジトリとして機能し、`submodules/` 配下に修正対象・参照用リポジトリを配置する。`setup.yaml` で `related_repositories`（参照用）と `target_repositories`（修正対象）を定義し、`init-work-branch` スキルがサブモジュールのセットアップを自動実行する。

### 10. 既知の制約・制限事項

- project.yaml の直接参照は禁止。`scripts/project-yaml-helper.sh` 経由でのみ操作する
- ワークフロー遵守が絶対強制：どのようなタスクであっても setup.yaml → project.yaml のプロセスに従う必要がある
- devcontainerイメージは `linux/amd64` プラットフォームのみ対応
