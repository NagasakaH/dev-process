---
name: skill-usage-protocol
description: Use when starting any conversation - establishes how to find and use skills, requiring skill invocation before ANY response including clarifying questions
---

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. This is not optional. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## How to Access Skills

**In Claude Code:** Use the `Skill` tool. When you invoke a skill, its content is loaded and presented to you—follow it directly. Never use the Read tool on skill files.

**In GitHub Copilot / other environments:** Read `.claude/skills/*/SKILL.md` files directly.

# Using Skills

## The Rule

**Invoke relevant or requested skills BEFORE any response or action.** Even a 1% chance a skill might apply means that you should invoke the skill to check. If an invoked skill turns out to be wrong for the situation, you don't need to use it.

```dot
digraph skill_flow {
    "User message received" [shape=doublecircle];
    "Might any skill apply?" [shape=diamond];
    "Read SKILL.md" [shape=box];
    "Announce: 'Using [skill] to [purpose]'" [shape=box];
    "Has checklist?" [shape=diamond];
    "Create todo per item" [shape=box];
    "Follow skill exactly" [shape=box];
    "Respond (including clarifications)" [shape=doublecircle];

    "User message received" -> "Might any skill apply?";
    "Might any skill apply?" -> "Read SKILL.md" [label="yes, even 1%"];
    "Might any skill apply?" -> "Respond (including clarifications)" [label="definitely not"];
    "Read SKILL.md" -> "Announce: 'Using [skill] to [purpose]'";
    "Announce: 'Using [skill] to [purpose]'" -> "Has checklist?";
    "Has checklist?" -> "Create todo per item" [label="yes"];
    "Has checklist?" -> "Follow skill exactly" [label="no"];
    "Create todo per item" -> "Follow skill exactly";
}
```

## Available Skills

```
.claude/skills/
├── brainstorming/               # 要件探索・デザイン
├── commit/                      # コミットメッセージ生成
├── commit-multi-repo/           # マルチリポジトリコミット
├── design/                      # 設計
├── finishing-branch/            # ブランチ完了管理
├── implement/                   # 実装
├── init-work-branch/            # 作業ブランチ初期化
├── investigation/               # 詳細調査
├── issue-to-setup-yaml/         # Issue → setup.yaml
├── plan/                        # 計画
├── receiving-code-review/       # レビュー対応
├── requesting-code-review/      # レビュー依頼
├── review-design/               # 設計レビュー
├── review-plan/                 # 計画レビュー
├── skill-usage-protocol/        # このスキル
├── submodule-overview/          # サブモジュール概要
├── systematic-debugging/        # 体系的デバッグ
├── test-driven-development/     # TDD
├── verification-before-completion/  # 完了前検証
└── writing-skills/              # スキル作成ガイド
```

## Development Flow

```
issue-to-setup-yaml → init-work-branch → submodule-overview →
brainstorming → investigation → design → review-design →
plan → review-plan → implement (+ test-driven-development) →
verification-before-completion → requesting-code-review →
receiving-code-review → finishing-branch
```

## Project Context

### project.yaml について

`project.yaml` はプロジェクトの進捗管理のためのSSOT（Single Source of Truth）です。

**存在する場合は必ず最初に読み込んでください**。各スキルは対応するセクションを更新します。

```yaml
# project.yaml の主要セクション
setup:           # setup.yamlの内容（初期設定）
investigation:   # 調査フェーズの結果
design:          # 設計フェーズの結果
plan:            # 計画フェーズの結果
implementation:  # 実装進捗
verification:    # 検証結果
code_review:     # コードレビュー進捗
finishing:       # 完了アクション
```

### スキルとproject.yamlセクションの対応

| スキル                           | 更新セクション        |
| -------------------------------- | --------------------- |
| `investigation`                  | `investigation`       |
| `design`                         | `design`              |
| `review-design`                  | `design.review`       |
| `plan`                           | `plan`                |
| `review-plan`                    | `plan.review`         |
| `implement`                      | `implementation`      |
| `verification-before-completion` | `verification`        |
| `requesting-code-review`         | `code_review`（開始） |
| `receiving-code-review`          | `code_review`（更新） |
| `finishing-branch`               | `finishing`           |

### ワークフロー

1. **project.yamlが存在する場合**: 現在のステータスを確認し、適切なフェーズから継続
2. **存在しない場合**: `setup.yaml` から開始し、必要に応じて `project.yaml` を生成

### setup.yaml

`setup.yaml` はプロジェクトの初期入力ファイルです（チケット情報、要件など）。

## Red Flags

These thoughts mean STOP—you're rationalizing:

| Thought                             | Reality                                        |
| ----------------------------------- | ---------------------------------------------- |
| "This is just a simple question"    | Questions are tasks. Check for skills.         |
| "I need more context first"         | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first.   |
| "This doesn't need a formal skill"  | If a skill exists, use it.                     |
| "I remember this skill"             | Skills evolve. Read current version.           |
| "The skill is overkill"             | Simple things become complex. Use it.          |
| "I'll just do this one thing first" | Check BEFORE doing anything.                   |

## Skill Priority

When multiple skills could apply, use this order:

1. **Process skills first** (brainstorming, systematic-debugging) - these determine HOW to approach the task
2. **Implementation skills second** (implement, design) - these guide execution

"Let's build X" → brainstorming first, then implementation skills.
"Fix this bug" → systematic-debugging first, then domain-specific skills.

## Skill Types

**Rigid** (test-driven-development, systematic-debugging): Follow exactly. Don't adapt away discipline.

**Flexible** (design, brainstorming): Adapt principles to context.

The skill itself tells you which.

## User Instructions

Instructions say WHAT, not HOW. "Add X" or "Fix Y" doesn't mean skip workflows.
