# Available Skills（全スキル一覧）

## 汎用スキル（プロジェクト非依存）

```
.claude/skills/
├── brainstorming/               # 要件探索・デザイン
├── code-review/                 # コードレビュー（チェックリストベース）
├── code-review-fix/             # コードレビュー指摘の修正対応
├── commit/                      # コミットメッセージ生成
├── commit-multi-repo/           # マルチリポジトリコミット
├── design/                      # 設計
├── finishing-branch/            # ブランチ完了管理
├── implement/                   # 実装
├── init-work-branch/            # 作業ブランチ初期化
├── investigation/               # 詳細調査
├── plan/                        # 計画
├── review-design/               # 設計レビュー
├── review-plan/                 # 計画レビュー
├── submodule-overview/          # サブモジュール概要
├── systematic-debugging/        # 体系的デバッグ
├── test-driven-development/     # TDD
├── verification/                # 検証（テスト・ビルド・リント実行確認）
├── verification-before-completion/  # 完了前検証（汎用品質ルール）
└── writing-skills/              # スキル作成ガイド
```

## プロジェクト固有スキル（ワークフロー状態管理）

```
.claude/skills/
├── project-state/               # project.yaml/setup.yaml 状態管理
├── create-setup-yaml/           # 対話的にsetup.yamlを作成
├── issue-to-setup-yaml/         # Issue → setup.yaml
└── skill-usage-protocol/        # このスキル
```

## ワークフロープロンプト（project.yaml連携手順）

```
prompts/workflow/
├── init-work-branch.md          # ブランチ初期化 + setup.yaml連携
├── brainstorming.md             # 要件探索 + project.yaml生成
├── investigation.md             # 調査 + project.yaml更新
├── design.md                    # 設計 + project.yaml更新
├── review-design.md             # 設計レビュー + project.yaml更新
├── plan.md                      # 計画 + project.yaml更新
├── review-plan.md               # 計画レビュー + project.yaml更新
├── implement.md                 # 実装 + project.yaml更新
├── verification.md              # 検証 + project.yaml更新
├── code-review.md               # コードレビュー + project.yaml更新
├── code-review-fix.md           # レビュー修正 + project.yaml更新
└── finishing-branch.md          # ブランチ完了 + project.yaml更新
```
