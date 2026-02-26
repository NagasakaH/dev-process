#!/bin/bash
# dev-container.sh — Launch/stop dev containers with dynamic mounts
#
# Usage:
#   scripts/dev-container.sh up      Start the container (attach to tmux)
#   scripts/dev-container.sh down    Stop and remove the container
#   scripts/dev-container.sh status  Show container status
#   scripts/dev-container.sh shell   Attach to existing container
#   scripts/dev-container.sh list    List all dev containers
#
# Container name is derived from project name + workspace path hash.
# Multiple clones of the same repo can run simultaneously.
#
set -euo pipefail

IMAGE_NAME="${DEV_CONTAINER_IMAGE:-nagasakah/dev-process:latest}"
WORKSPACE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_NAME="$(basename "$WORKSPACE_DIR")"
PATH_HASH="$(echo -n "${WORKSPACE_DIR}" | md5sum 2>/dev/null | head -c 6 || echo -n "${WORKSPACE_DIR}" | md5 -q 2>/dev/null | head -c 6)"
CONTAINER_NAME="${PROJECT_NAME}-${PATH_HASH}"
LABEL_MANAGED="managed-by=dev-container-sh"
LABEL_WORKSPACE="workspace-path=${WORKSPACE_DIR}"

# Find container for current workspace by label
find_container() {
  docker ps -a --filter "label=${LABEL_MANAGED}" --filter "label=${LABEL_WORKSPACE}" --format '{{.Names}}' | head -1
}

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
  local existing
  existing=$(find_container)

  if [ -n "$existing" ] && docker ps --format '{{.Names}}' | grep -q "^${existing}$"; then
    echo "Container '${existing}' is already running for this workspace."
    echo "Use: $0 shell   to attach"
    echo "Use: $0 down    to stop"
    exit 0
  fi

  # Clean up stopped container for this workspace
  if [ -n "$existing" ]; then
    echo "Removing stopped container '${existing}'..."
    docker rm "${existing}" >/dev/null
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
    --hostname "${PROJECT_NAME}" \
    --privileged \
    --platform linux/amd64 \
    --label "${LABEL_MANAGED}" \
    --label "${LABEL_WORKSPACE}" \
    --label "project=${PROJECT_NAME}" \
    -e "PROJECT_NAME=${PROJECT_NAME}" \
    ${mount_flags} \
    "${IMAGE_NAME}"
}

cmd_down() {
  local target
  target=$(find_container)

  if [ -z "$target" ]; then
    echo "No container found for workspace: ${WORKSPACE_DIR}"
    exit 0
  fi

  if docker ps --format '{{.Names}}' | grep -q "^${target}$"; then
    echo "Stopping container '${target}'..."
    docker stop "${target}" >/dev/null
  fi

  echo "Removing container '${target}'..."
  docker rm "${target}" >/dev/null
  echo "Done."
}

cmd_status() {
  local target
  target=$(find_container)

  if [ -z "$target" ]; then
    echo "No container found for workspace: ${WORKSPACE_DIR}"
    exit 0
  fi

  if docker ps --format '{{.Names}}' | grep -q "^${target}$"; then
    echo "Container '${target}' is running."
    docker ps --filter "name=^${target}$" --format "table {{.ID}}\t{{.Image}}\t{{.Status}}"
  else
    echo "Container '${target}' exists but is stopped."
    docker ps -a --filter "name=^${target}$" --format "table {{.ID}}\t{{.Image}}\t{{.Status}}"
  fi
}

cmd_shell() {
  local target
  target=$(find_container)

  if [ -z "$target" ]; then
    echo "No container found for workspace: ${WORKSPACE_DIR}"
    echo "Use: $0 up"
    exit 1
  fi

  if ! docker ps --format '{{.Names}}' | grep -q "^${target}$"; then
    echo "Container '${target}' is not running. Use: $0 up"
    exit 1
  fi

  docker exec -it "${target}" tmux attach-session -t "${PROJECT_NAME}" 2>/dev/null \
    || docker exec -it "${target}" bash
}

cmd_list() {
  echo "Dev containers (managed by dev-container.sh):"
  local has_containers=false
  while IFS=$'\t' read -r name image status project workspace; do
    if [ "$name" = "NAMES" ]; then continue; fi
    has_containers=true
    echo "  ${name}  ${status}  project=${project}  workspace=${workspace}"
  done < <(docker ps -a --filter "label=${LABEL_MANAGED}" \
    --format "{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Label \"project\"}}\t{{.Label \"workspace-path\"}}" 2>/dev/null)
  if [ "$has_containers" = false ]; then
    echo "  (none)"
  fi
}

# ---------------------------------------------------------------
# Main
# ---------------------------------------------------------------
case "${1:-help}" in
  up)     cmd_up ;;
  down)   cmd_down ;;
  status) cmd_status ;;
  shell)  cmd_shell ;;
  list)   cmd_list ;;
  *)
    echo "Usage: $0 {up|down|status|shell|list}"
    echo ""
    echo "  up      Start the dev container (attach to tmux)"
    echo "  down    Stop and remove the container"
    echo "  status  Show container status"
    echo "  shell   Attach to running container"
    echo "  list    List all dev containers"
    echo ""
    echo "Container: ${CONTAINER_NAME}"
    echo "Workspace: ${WORKSPACE_DIR}"
    echo ""
    echo "Environment variables:"
    echo "  DEV_CONTAINER_IMAGE  Override image (default: ${IMAGE_NAME})"
    exit 1
    ;;
esac
