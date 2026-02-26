#!/usr/bin/env bash
# build-and-push-devcontainer.sh
# devcontainer イメージのビルドと Docker Hub への push を行うスクリプト
#
# 使い方:
#   ./scripts/build-and-push-devcontainer.sh [IMAGE_NAME]
#
# デフォルト IMAGE_NAME: nagasakah/dev-process
# ビルドは常に linux/amd64 ターゲット

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

IMAGE_NAME="${1:-nagasakah/dev-process}"
PLATFORM="linux/amd64"

echo "=== Step 1: devcontainer ビルド (base タグ, ${PLATFORM}) ==="
devcontainer build \
  --workspace-folder "$REPO_ROOT" \
  --image-name "${IMAGE_NAME}:base" \
  --platform "$PLATFORM"

echo ""
echo "=== Step 2: base イメージを push ==="
docker push "${IMAGE_NAME}:base"

echo ""
echo "=== Step 3: Dockerfile ビルド (latest タグ, ${PLATFORM}) ==="
docker buildx build \
  --platform "$PLATFORM" \
  --load \
  -t "${IMAGE_NAME}:latest" \
  -f "$REPO_ROOT/.devcontainer/Dockerfile" \
  "$REPO_ROOT/.devcontainer"

echo ""
echo "=== Step 4: latest イメージを push ==="
docker push "${IMAGE_NAME}:latest"

echo ""
echo "=== 完了 ==="
echo "  ${IMAGE_NAME}:base   - devcontainer features のみ (${PLATFORM})"
echo "  ${IMAGE_NAME}:latest - base + pip ツール + tmux/cplt/dotfiles (${PLATFORM})"
