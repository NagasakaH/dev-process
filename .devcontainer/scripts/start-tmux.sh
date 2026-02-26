#!/bin/bash
# Start tmux session with 3 windows for development

# Ensure UTF-8 locale for proper icon display
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Start Docker daemon if docker-in-docker init script exists (requires --privileged)
DOCKER_INIT="/usr/local/share/docker-init.sh"
if [ -f "$DOCKER_INIT" ]; then
  echo "Starting Docker daemon..."
  "$DOCKER_INIT" dockerd &>/dev/null &
  # Wait briefly for dockerd to be ready
  for i in $(seq 1 10); do
    if docker info &>/dev/null 2>&1; then
      echo "Docker daemon ready."
      break
    fi
    sleep 1
  done
fi

# Get workspace directory (first directory in /workspaces/)
WORKSPACE_DIR=$(ls -d /workspaces/*/ 2>/dev/null | head -n 1)

if [ -z "$WORKSPACE_DIR" ]; then
	echo "Error: No workspace directory found in /workspaces/"
	exit 1
fi

# Remove trailing slash
WORKSPACE_DIR=${WORKSPACE_DIR%/}

SESSION_NAME="${PROJECT_NAME:-dev}"

# If running as root, switch to vscode for the tmux session
RUN_USER="vscode"
if [ "$(id -u)" = "0" ] && id "$RUN_USER" &>/dev/null; then
  exec su -l "$RUN_USER" -c "PROJECT_NAME='${PROJECT_NAME}' LC_ALL=C.UTF-8 LANG=C.UTF-8 $0 $*"
fi

# Check if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
	echo "Session '$SESSION_NAME' already exists. Attaching..."
	tmux attach-session -t "$SESSION_NAME"
	exit 0
fi

# Create new session with first window
tmux new-session -d -s "$SESSION_NAME" -n "editor" -c "$WORKSPACE_DIR"

# Create second window (Copilot CLI)
tmux new-window -t "$SESSION_NAME" -n "copilot" -c "$WORKSPACE_DIR"

# Create third window (Bash)
tmux new-window -t "$SESSION_NAME" -n "bash" -c "$WORKSPACE_DIR"

# Select first window by name and attach
tmux select-window -t "$SESSION_NAME:editor"
tmux attach-session -t "$SESSION_NAME"
