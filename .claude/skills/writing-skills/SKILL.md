---
name: writing-skills
description: Use when creating or modifying skill files (.claude/skills/*/SKILL.md) - guides skill authoring with proper structure, testing approach, and naming conventions
---

# Writing Skills

## Overview

Skills are instructions for AI agents. Treat skill creation like TDD: define what behavior you want, write the skill, test it with scenarios.

## Skill Structure

Every skill lives in `.claude/skills/<skill-name>/SKILL.md`.

### YAML Frontmatter (Required)

```yaml
---
name: skill-name
description: Use when [trigger condition] - [what the skill does]
---
```

**Description rules:**
- Start with "Use when" — this is how the agent matches skills to tasks
- Include trigger phrases in description for better matching
- Keep under 200 characters
- Be specific about WHEN, not just WHAT

### File Content

```markdown
# Skill Title

## Overview
[1-2 sentences. What this skill does and why.]

## When to Use
[Specific triggers and conditions]

## The Process
[Step-by-step instructions]

## Integration
[How this connects to other skills]
```

## Skill Types

| Type          | Purpose             | Example                   |
| ------------- | ------------------- | ------------------------- |
| **Technique** | HOW to do something | `test-driven-development` |
| **Pattern**   | Reusable approach   | `systematic-debugging`    |
| **Process**   | Workflow steps      | `init-work-branch`        |
| **Protocol**  | Rules to follow     | `skill-usage-protocol`    |
| **Reference** | Information lookup  | `submodule-overview`      |

## Naming Conventions

- Use kebab-case: `my-skill-name`
- Be descriptive: `verification-before-completion` not `verify`
- Avoid abbreviations: `test-driven-development` not `tdd`
- No version numbers: `brainstorming` not `brainstorming-v2`

## Writing Effective Skills

### DO:
- **Be prescriptive** — "Do X" not "Consider doing X"
- **Use tables** — Quick reference, rationalizations, red flags
- **Include examples** — Good/Bad comparisons
- **Add integration notes** — How this connects to other skills
- **Define red flags** — When the agent is going wrong
- **Keep sections short** — 200-300 words max per section

### DON'T:
- Write essays — agents don't need persuasion
- Use vague language — "try to", "consider", "might want to"
- Assume context — be explicit about prerequisites
- Mix concerns — one skill per concept
- Use passive voice — direct instructions only

## Testing Your Skill

### Scenario Testing

Before committing, test with these scenarios:

1. **Happy path** — Does the agent follow the skill correctly?
2. **Edge case** — Does the skill handle unusual situations?
3. **Conflict** — What happens when this skill conflicts with another?
4. **Skip attempt** — Does the agent try to rationalize skipping it?

### Quality Checklist

- [ ] Frontmatter has `name` and `description`
- [ ] Description starts with "Use when"
- [ ] Overview is ≤ 2 sentences
- [ ] Process steps are numbered and clear
- [ ] Red flags section exists
- [ ] Integration section references related skills
- [ ] No vague language ("consider", "try to", "might")
- [ ] Examples included (Good/Bad format)

## Content Principles

### Conciseness
- If it can be a table, make it a table
- If it can be a bullet, don't make it a paragraph
- Cut "obvious" content — agents don't need motivation
- Every sentence must earn its place

### Clarity
- One instruction per bullet
- Active voice, imperative mood
- Specific actions, not general advice
- "Run `npm test`" not "verify tests pass"

### Completeness
- Cover error cases
- Include "When Stuck" section if applicable
- Document integration with other skills
- List red flags / rationalizations

## Directory Organization

```
.claude/skills/
├── my-skill/
│   ├── SKILL.md            # Main skill file (required)
│   └── references/         # Supporting files (optional)
│       ├── template.md
│       └── examples/
```

## Integration

**This skill is:**
- Used when creating new skills for the dev-process
- Referenced by `skill-usage-protocol` for skill discovery
