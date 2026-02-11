---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch `code-reviewer` agent to catch issues before they cascade.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After each task in subagent-driven development
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Dispatch code-reviewer agent:**

Provide the following context to the `code-reviewer` agent:

| Placeholder            | Description         |
| ---------------------- | ------------------- |
| `WHAT_WAS_IMPLEMENTED` | What you just built |
| `PLAN_OR_REQUIREMENTS` | What it should do   |
| `BASE_SHA`             | Starting commit     |
| `HEAD_SHA`             | Ending commit       |
| `DESCRIPTION`          | Brief summary       |

**3. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code-reviewer agent]
  WHAT_WAS_IMPLEMENTED: Verification and repair functions for conversation index
  PLAN_OR_REQUIREMENTS: Task 2 from docs/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types

[Agent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## project.yaml Integration

Update `project.yaml` with:
```yaml
code_review:
  status: approved  # or revision_required
  rounds:
    - { round: 1, result: revision_required, issues: 2 }
    - { round: 2, result: approved, issues: 0 }
```

Commit: `docs: code review 結果を記録`

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

## Integration

**Position in flow:** `verification-before-completion` → **requesting-code-review** → `receiving-code-review`

**Related:**
- `code-reviewer` agent (`.github/agents/code-reviewer.agent.md`)
- `review-design` / `review-plan` — for design/plan phase reviews
