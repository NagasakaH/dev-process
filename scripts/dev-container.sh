#!/bin/bash
# dev-container.sh — Launch/stop the dev-process container with dynamic mounts
#
# Usage:
#   scripts/dev-container.sh up      Start the container (attach to tmux)
#   scripts/dev-container.sh down    Stop and remove the container
#   scripts/dev-container.sh status  Show container status
#   scripts/dev-container.sh shell   Attach to existing container
#
set -euo pipefail

CONTAINER_NAME="dev-process"
IMAGE_NAME="${DEV_CONTAINER_IMAGE:-nagasakah/dev-process:latest}"
WORKSPACE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_NAME="$(basename "$WORKSPACE_DIR")"

# ---------------------------------------------------------------
# Dynamic mount builder — only mounts paths that exist on host
# ---------------------------------------------------------------
build_mounts() {
  local mounts=()

  # Workspace (always)
  mounts+=(-v "${WORKSPACE_DIR}:/workspaces/${PROJECT_NAME}")

  # Optional host paths: source|target[:options]
  local entries=(
    "${HOME}/.aws|/home/vscode/.aws:cached"
    "${HOME}/.gitconfig|/home/vscode/.gitconfig:ro"
    "${HOME}/.ssh|/home/vscode/.ssh:ro"
    "${HOME}/.claude|/home/vscode/.claude:cached"
    "${HOME}/.claude.json|/home/vscode/.claude.json:cached"
    "${HOME}/.copilot|/home/vscode/.copilot:cached"
  )

  for entry in "${entries[@]}"; do
    local src="${entry%%|*}"
    local tgt="${entry#*|}"
    if [ -e "$src" ]; then
      mounts+=(-v "${src}:${tgt}")
    else
      echo "  skip: ${src} (not found)"
    fi
  done

  echo "${mounts[@]}"
}

# ---------------------------------------------------------------
# Commands
# ---------------------------------------------------------------
cmd_up() {
  if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container '${CONTAINER_NAME}' is already running."
    echo "Use: $0 shell   to attach"
    echo "Use: $0 down    to stop"
    exit 0
  fi

  # Clean up stopped container with same name
  if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing stopped container '${CONTAINER_NAME}'..."
    docker rm "${CONTAINER_NAME}" >/dev/null
  fi

  echo "Starting container '${CONTAINER_NAME}'..."
  echo "  image: ${IMAGE_NAME}"
  echo "  workspace: ${WORKSPACE_DIR}"
  echo "Mounts:"

  # Build mount flags
  local mount_flags
  mount_flags=$(build_mounts)

  # shellcheck disable=SC2086
  docker run -it \
    --name "${CONTAINER_NAME}" \
    --hostname "${CONTAINER_NAME}" \
    --privileged \
    --platform linux/amd64 \
    -e "PROJECT_NAME=${PROJECT_NAME}" \
    ${mount_flags} \
    "${IMAGE_NAME}"
}

cmd_down() {
  if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Stopping container '${CONTAINER_NAME}'..."
    docker stop "${CONTAINER_NAME}" >/dev/null
  fi

  if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing container '${CONTAINER_NAME}'..."
    docker rm "${CONTAINER_NAME}" >/dev/null
  fi

  echo "Done."
}

cmd_status() {
  if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container '${CONTAINER_NAME}' is running."
    docker ps --filter "name=^${CONTAINER_NAME}$" --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
  elif docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container '${CONTAINER_NAME}' exists but is stopped."
    docker ps -a --filter "name=^${CONTAINER_NAME}$" --format "table {{.ID}}\t{{.Image}}\t{{.Status}}"
  else
    echo "Container '${CONTAINER_NAME}' does not exist."
  fi
}

cmd_shell() {
  if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container '${CONTAINER_NAME}' is not running. Use: $0 up"
    exit 1
  fi
  docker exec -it "${CONTAINER_NAME}" tmux attach-session -t "${PROJECT_NAME}" 2>/dev/null \
    || docker exec -it "${CONTAINER_NAME}" bash
}

# ---------------------------------------------------------------
# Main
# ---------------------------------------------------------------
case "${1:-help}" in
  up)     cmd_up ;;
  down)   cmd_down ;;
  status) cmd_status ;;
  shell)  cmd_shell ;;
  *)
    echo "Usage: $0 {up|down|status|shell}"
    echo ""
    echo "  up      Start the dev container (attach to tmux)"
    echo "  down    Stop and remove the container"
    echo "  status  Show container status"
    echo "  shell   Attach to running container"
    echo ""
    echo "Environment variables:"
    echo "  DEV_CONTAINER_IMAGE  Override image (default: ${IMAGE_NAME})"
    exit 1
    ;;
esac
