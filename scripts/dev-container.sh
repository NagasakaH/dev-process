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
# Docker mode:
#   DOCKER_MODE=dind  (default) Docker-in-Docker: --privileged, isolated daemon
#   DOCKER_MODE=dood  Docker-out-of-Docker: mount host socket, shared daemon
#
set -euo pipefail

IMAGE_NAME="${DEV_CONTAINER_IMAGE:-nagasakah/dev-process:latest}"
DOCKER_MODE="${DOCKER_MODE:-dind}"
WORKSPACE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_NAME="$(basename "$WORKSPACE_DIR")"
PATH_HASH="$(echo -n "${WORKSPACE_DIR}" | md5sum 2>/dev/null | head -c 6 || echo -n "${WORKSPACE_DIR}" | md5 -q 2>/dev/null | head -c 6)"
CONTAINER_NAME="${PROJECT_NAME}-${PATH_HASH}"
LABEL_MANAGED="managed-by=dev-container-sh"
LABEL_WORKSPACE="workspace-path=${WORKSPACE_DIR}"

# ---------------------------------------------------------------
# Docker API version negotiation
# ---------------------------------------------------------------
detect_docker_api_version() {
  # ユーザーが明示指定している場合はそれを尊重
  if [ -n "${DOCKER_API_VERSION:-}" ]; then
    echo "  docker API version: ${DOCKER_API_VERSION} (user-specified)"
    return
  fi

  local host_version
  host_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "")

  if [ -z "$host_version" ]; then
    echo "  docker API version: (unable to detect host Docker version)"
    return
  fi

  echo "  host docker version: ${host_version}"

  # Docker API version mapping (major.minor → API version)
  # See: https://docs.docker.com/reference/api/engine/version-history/
  local major minor api_version=""
  major=$(echo "$host_version" | cut -d. -f1)
  minor=$(echo "$host_version" | cut -d. -f2)

  if [ "$major" -lt 20 ] 2>/dev/null; then
    # Docker 19.03.x → API 1.40
    api_version="1.40"
  elif [ "$major" -eq 20 ] && [ "$minor" -le 10 ] 2>/dev/null; then
    # Docker 20.10.x → API 1.41
    api_version="1.41"
  fi
  # Docker 23+ / 24+ / 25+ → API negotiation works, no override needed

  if [ -n "$api_version" ]; then
    export DOCKER_API_VERSION="$api_version"
    echo "  docker API version: ${api_version} (auto-detected for Docker ${host_version})"
  else
    echo "  docker API version: (auto-negotiate, Docker ${host_version})"
  fi
}

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
  echo "  docker mode: ${DOCKER_MODE}"
  echo "Mounts:"

  # Build mount flags
  local mount_flags
  mount_flags=$(build_mounts)

  # Docker mode specific flags
  local docker_flags=()

  # Detect and set API version for old Docker hosts
  detect_docker_api_version
  if [ -n "${DOCKER_API_VERSION:-}" ]; then
    docker_flags+=(-e "DOCKER_API_VERSION=${DOCKER_API_VERSION}")
  fi

  case "${DOCKER_MODE}" in
    dind)
      docker_flags+=(--privileged)
      ;;
    dood)
      local docker_sock="${DOCKER_HOST_SOCK:-/var/run/docker.sock}"
      if [ ! -S "$docker_sock" ]; then
        echo "Error: Docker socket not found at ${docker_sock}"
        echo "Set DOCKER_HOST_SOCK to the correct path."
        exit 1
      fi
      # Get socket GID so vscode user can access it
      local sock_gid
      sock_gid=$(stat -f '%g' "$docker_sock" 2>/dev/null || stat -c '%g' "$docker_sock" 2>/dev/null)
      docker_flags+=(
        --privileged
        -v "${docker_sock}:/var/run/docker.sock"
        --entrypoint start-tmux
      )
      if [ -n "$sock_gid" ]; then
        docker_flags+=(--group-add "$sock_gid")
      fi
      echo "  docker socket: ${docker_sock} (gid=${sock_gid})"
      ;;
    *)
      echo "Error: DOCKER_MODE must be 'dind' or 'dood' (got: ${DOCKER_MODE})"
      exit 1
      ;;
  esac

  # shellcheck disable=SC2086
  docker run -it \
    --name "${CONTAINER_NAME}" \
    --hostname "${PROJECT_NAME}" \
    --platform linux/amd64 \
    --label "${LABEL_MANAGED}" \
    --label "${LABEL_WORKSPACE}" \
    --label "project=${PROJECT_NAME}" \
    --label "docker-mode=${DOCKER_MODE}" \
    -e "PROJECT_NAME=${PROJECT_NAME}" \
    "${docker_flags[@]}" \
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
  while IFS=$'\t' read -r name status project workspace mode; do
    has_containers=true
    echo "  ${name}  ${status}  mode=${mode}  project=${project}  workspace=${workspace}"
  done < <(docker ps -a --filter "label=${LABEL_MANAGED}" \
    --format "{{.Names}}\t{{.Status}}\t{{.Label \"project\"}}\t{{.Label \"workspace-path\"}}\t{{.Label \"docker-mode\"}}" 2>/dev/null)
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
    echo "  DOCKER_MODE          dind (default) or dood"
    echo "  DOCKER_HOST_SOCK     Docker socket path for dood (default: /var/run/docker.sock)"
    echo "  DOCKER_API_VERSION   Override Docker API version (auto-detected if unset)"
    exit 1
    ;;
esac
