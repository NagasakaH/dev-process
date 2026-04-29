#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${REPO_ROOT}/.devcontainer/devcontainer.json"

python3 - "$CONFIG" <<'PY'
import json
import sys

config_path = sys.argv[1]
with open(config_path, "r", encoding="utf-8") as f:
    config = json.load(f)

errors = []
container_env = config.get("containerEnv", {})
mounts = config.get("mounts", [])

if "GITLAB_TOKEN" in container_env:
    errors.append("containerEnv.GITLAB_TOKEN should not be used; mount ~/.config/skills instead")

if "GITLAB_URL" in container_env:
    errors.append("containerEnv.GITLAB_URL should not be used; mount ~/.config/skills instead")

if "GITHUB_TOKEN" in container_env:
    errors.append("containerEnv.GITHUB_TOKEN should not be used; preserve the environment name via su whitelist instead")

if container_env.get("DOCKER_MODE") != "dood":
    errors.append("containerEnv.DOCKER_MODE must be dood for host Docker based E2E")

expected_mount = "source=${localEnv:HOME}/.config/skills,target=/home/vscode/.config/skills,type=bind,consistency=cached"
if expected_mount not in mounts:
    errors.append("mounts must include ~/.config/skills so GitLab API skill can read .env config")

if errors:
    for error in errors:
        print(f"FAIL: {error}", file=sys.stderr)
    sys.exit(1)

print("devcontainer JSON checks passed")
PY
