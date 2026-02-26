#!/bin/bash
# Start tmux session with 3 windows for development

# Ensure UTF-8 locale for proper icon display
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Get workspace directory (first directory in /workspaces/)
WORKSPACE_DIR=$(ls -d /workspaces/*/ 2>/dev/null | head -n 1)

if [ -z "$WORKSPACE_DIR" ]; then
	echo "Error: No workspace directory found in /workspaces/"
	exit 1
fi

# Remove trailing slash
WORKSPACE_DIR=${WORKSPACE_DIR%/}

SESSION_NAME="${PROJECT_NAME:-dev}"

# If running as root, adjust vscode UID/GID to match workspace owner
RUN_USER="vscode"
if [ "$(id -u)" = "0" ] && id "$RUN_USER" &>/dev/null; then
  # Detect UID/GID of the workspace directory
  HOST_UID=$(stat -c '%u' "$WORKSPACE_DIR" 2>/dev/null || echo "")
  HOST_GID=$(stat -c '%g' "$WORKSPACE_DIR" 2>/dev/null || echo "")
  CURRENT_UID=$(id -u "$RUN_USER")
  CURRENT_GID=$(id -g "$RUN_USER")

  if [ -n "$HOST_UID" ] && [ "$HOST_UID" != "0" ] && [ "$HOST_UID" != "$CURRENT_UID" ]; then
    echo "Adjusting vscode UID: $CURRENT_UID -> $HOST_UID"
    usermod -u "$HOST_UID" "$RUN_USER" 2>/dev/null
  fi
  if [ -n "$HOST_GID" ] && [ "$HOST_GID" != "0" ] && [ "$HOST_GID" != "$CURRENT_GID" ]; then
    echo "Adjusting vscode GID: $CURRENT_GID -> $HOST_GID"
    groupmod -g "$HOST_GID" "$RUN_USER" 2>/dev/null
  fi

  # Fix home directory ownership if UID/GID changed
  if [ "$HOST_UID" != "$CURRENT_UID" ] || [ "$HOST_GID" != "$CURRENT_GID" ]; then
    chown -R "$RUN_USER":"$RUN_USER" /home/"$RUN_USER" 2>/dev/null
  fi

  # Fix docker socket permissions for DooD mode
  if [ -S /var/run/docker.sock ]; then
    chmod 666 /var/run/docker.sock 2>/dev/null || true
  fi

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
