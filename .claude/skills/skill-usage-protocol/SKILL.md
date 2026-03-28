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

📖 フロー図の詳細は references/skill-flow-diagram.md を参照

## Available Skills

📖 全スキル一覧は references/available-skills.md を参照

- **汎用スキル**: brainstorming, code-review, commit, design, implement, plan, verification 等
- **プロジェクト固有スキル**: project-state, create-setup-yaml, issue-to-setup-yaml
- **ワークフロープロンプト**: `prompts/workflow/*.md`（project.yaml連携手順）

## Development Flow

```
issue-to-setup-yaml → init-work-branch → submodule-overview →
brainstorming → investigation → design → review-design →
plan → review-plan → implement (+ test-driven-development) →
verification → code-review → [code-review-fix → code-review]* →
finishing-branch
```

## Project Context (ワークフロー利用時)

📖 詳細は references/project-context.md を参照

- `project.yaml`: ワークフローの進捗管理ファイル（読み書きは `project-state` スキルが担当）
- `setup.yaml`: プロジェクトの初期入力ファイル（チケット情報、要件など）
- 各汎用スキル自体は project.yaml に依存しない

## Red Flags

📖 詳細は references/red-flags-and-guidelines.md を参照

"This is just a simple question" "I need more context first" "This doesn't need a formal skill" → これらの思考はスキルチェックを回避する合理化。**スキル確認が最優先。**

## Skill Priority & Types

📖 詳細は references/red-flags-and-guidelines.md を参照

1. **Process skills first** (brainstorming, systematic-debugging) → タスクのアプローチを決定
2. **Implementation skills second** (implement, design) → 実行をガイド

- **Rigid** (test-driven-development, systematic-debugging): 厳密に従う
- **Flexible** (design, brainstorming): コンテキストに合わせて適用

## User Instructions

Instructions say WHAT, not HOW. "Add X" or "Fix Y" doesn't mean skip workflows.
