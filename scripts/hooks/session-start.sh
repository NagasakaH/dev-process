#!/usr/bin/env bash
# session-start.sh
# Shared session start hook for Claude Code and GitHub Copilot.
# Injects skill-usage-protocol as additional context at session start.
#
# Claude Code:     stdin = JSON event, output = JSON with additionalContext
# GitHub Copilot:  stdin may be empty or JSON, output = JSON with additionalContext

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SKILL_FILE="$REPO_ROOT/.claude/skills/skill-usage-protocol/SKILL.md"

if [ ! -f "$SKILL_FILE" ]; then
  echo '{}' # No skill file found, return empty
  exit 0
fi

# Read the skill content
SKILL_CONTENT=$(cat "$SKILL_FILE")

# Check if project.yaml exists and append it
PROJECT_YAML="$REPO_ROOT/project.yaml"
if [ -f "$PROJECT_YAML" ]; then
  PROJECT_CONTENT=$(cat "$PROJECT_YAML")
  SKILL_CONTENT="$SKILL_CONTENT

---
# Project Context (project.yaml)
$PROJECT_CONTENT"
fi

# Escape for JSON
ESCAPED_CONTENT=$(echo "$SKILL_CONTENT" | python3 -c "
import sys, json
content = sys.stdin.read()
print(json.dumps(content))
")

# Output JSON with hookSpecificOutput.additionalContext
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $ESCAPED_CONTENT
  }
}
EOF
