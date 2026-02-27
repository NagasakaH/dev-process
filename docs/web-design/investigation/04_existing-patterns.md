# 既存パターン調査

## 概要

dev-processリポジトリから移植・参考にすべきパターンを分析する。web-designは新規リポジトリのため、dev-processの実績あるパターンを踏襲しつつ、code-server・React固有のパターンを定義する。

## dev-process のコーディングパターン

### Dockerfile パターン

dev-processのDockerfileは以下のパターンを採用：

```dockerfile
# 2段階ビルド: base → latest
FROM --platform=linux/amd64 nagasakah/dev-process:base

# ツールインストール
RUN pip install jsonschema pyyaml

# RHEL系のiptables修正（DinD対応）
RUN update-alternatives --set iptables /usr/sbin/iptables-nft && \
    update-alternatives --set ip6tables /usr/sbin/ip6tables-nft

# dotfiles・スクリプトの埋め込み
COPY dotfiles/.tmux.conf /home/vscode/.tmux.conf
COPY scripts/start-tmux.sh /usr/local/bin/start-tmux

# パーミッション設定
RUN chmod +x /usr/local/bin/start-tmux && \
    chown -R vscode:vscode /home/vscode/.tmux.conf

# docker-init.shをENTRYPOINTに
ENTRYPOINT ["/usr/local/share/docker-init.sh"]
CMD ["start-tmux"]
```

**web-designで踏襲するポイント:**
- `FROM --platform=linux/amd64` でアーキテクチャ固定
- `ENTRYPOINT ["/usr/local/share/docker-init.sh"]` でDinD初期化を保持
- `CMD` で起動コマンドを指定（tmux → code-server に変更）
- iptables修正（DinD対応）の維持

### start-tmux.sh の起動パターン

dev-processの起動スクリプトには以下の重要なパターンがある：

```bash
# パターン1: UID/GID調整（DooD時のパーミッション問題対策）
if [ "$(id -u)" = "0" ] && id "$RUN_USER" &>/dev/null; then
  HOST_UID=$(stat -c '%u' "$WORKSPACE_DIR" 2>/dev/null || echo "")
  HOST_GID=$(stat -c '%g' "$WORKSPACE_DIR" 2>/dev/null || echo "")
  # UID/GIDがホスト側と異なる場合に調整
  if [ "$HOST_UID" != "$CURRENT_UID" ]; then
    usermod -u "$HOST_UID" "$RUN_USER"
  fi
  # Docker socketのパーミッション修正
  if [ -S /var/run/docker.sock ]; then
    chmod 666 /var/run/docker.sock 2>/dev/null || true
  fi
  # vscodeユーザーとして再実行
  exec su -l "$RUN_USER" -c "$0 $*"
fi
```

**このパターンはweb-designでもそのまま必要** — DooD時にワークスペースのファイルにアクセスするため。

### dev-container.sh のDooD/DinD切り替えパターン

```bash
# パターン2: DooD/DinDモード分岐
case "${DOCKER_MODE}" in
  dind)
    docker_flags+=(--privileged)
    ;;
  dood)
    docker_flags+=(
      --privileged
      -v "${docker_sock}:/var/run/docker.sock"
      --entrypoint start-tmux  # ← web-designでは start-code-server に変更
    )
    # ソケットGIDの取得と設定
    sock_gid=$(stat -f '%g' "$docker_sock" 2>/dev/null || stat -c '%g' "$docker_sock")
    docker_flags+=(--group-add "$sock_gid")
    ;;
esac
```

**変更点:**
- `--entrypoint start-tmux` → `--entrypoint start-code-server`
- DooD時のENTRYPOINT上書きが重要：DinDではDockerfileのENTRYPOINT（`docker-init.sh`）がdockerdを起動するが、DooD時はdockerdが不要なためstart-*を直接実行

### dev-container.sh のマウントパターン

```bash
# パターン3: 動的マウント — 存在するパスのみマウント
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
  fi
done
```

**web-designでは`.aws`マウントを削除** し、その他はそのまま維持。

### build-and-push-devcontainer.sh のビルドパターン

```bash
# パターン4: 2段階ビルド
# Step 1: devcontainer build (features含む)
devcontainer build \
  --workspace-folder "$REPO_ROOT" \
  --image-name "${IMAGE_NAME}:base" \
  --platform "$PLATFORM"

# Step 2: docker buildx build (カスタムレイヤー)
docker buildx build \
  --platform "$PLATFORM" \
  --load \
  -t "${IMAGE_NAME}:latest" \
  -f "$REPO_ROOT/.devcontainer/Dockerfile" \
  "$REPO_ROOT/.devcontainer"
```

### コンテナ名生成パターン

```bash
# パターン5: ワークスペースパスのハッシュで一意性保証
PATH_HASH="$(echo -n "${WORKSPACE_DIR}" | md5sum | head -c 6)"
CONTAINER_NAME="${PROJECT_NAME}-${PATH_HASH}"
```

同一リポジトリの複数クローンが共存可能。

### ラベルベースのコンテナ管理パターン

```bash
# パターン6: ラベルでコンテナを特定
LABEL_MANAGED="managed-by=dev-container-sh"
LABEL_WORKSPACE="workspace-path=${WORKSPACE_DIR}"

# 検索
docker ps -a --filter "label=${LABEL_MANAGED}" --filter "label=${LABEL_WORKSPACE}"
```

## devcontainer.json パターン

### dev-process の VS Code拡張機能設定

```json
"customizations": {
  "vscode": {
    "extensions": [
      "ms-dotnettools.csharp",
      "ms-dotnettools.csdevkit",
      // ...
    ],
    "settings": {
      "dotnet.server.useOmnisharp": false
    }
  }
}
```

**web-designでの変更:**
- dotnet系拡張機能を削除
- React/TypeScript系拡張機能に置換
- ただしcode-serverで起動する場合、`customizations.vscode.extensions` はDevContainers拡張機能経由でのみ適用される。code-server起動時はDockerfile内で `code-server --install-extension` を使用する必要がある

### postCreateCommand パターン

```json
"postCreateCommand": "pip install jsonschema pyyaml && echo '--- Tool versions ---' && dotnet --version && ..."
```

**web-designでの変更:**
```json
"postCreateCommand": "echo '--- Tool versions ---' && node --version && npm --version && npx playwright --version && yq --version && gh --version | head -1"
```

## テストパターン

### E2Eテスト（Playwright）

brainstormingで決定されたテスト戦略に基づき、E2Eテストのみを実施：

```
e2e/
├── playwright.config.ts        # Playwright設定
├── devcontainer-build.spec.ts  # devcontainerビルドテスト
├── code-server.spec.ts         # code-serverアクセステスト
├── react-preview.spec.ts       # Reactプレビューテスト
├── extensions.spec.ts          # 拡張機能インストール確認テスト
└── docker-mode.spec.ts         # DooD/DinD切り替えテスト
```

## 命名規則（dev-processに準拠）

| 対象 | 規則 | 例 |
|------|------|-----|
| スクリプト名 | kebab-case | `dev-container.sh`, `start-code-server.sh` |
| 環境変数 | UPPER_SNAKE_CASE | `DOCKER_MODE`, `DEV_CONTAINER_IMAGE` |
| Dockerイメージ | lowercase/hyphen | `nagasakah/web-design` |
| ラベル | kebab-case | `managed-by=dev-container-sh` |
| Reactコンポーネント | PascalCase | `App.tsx` |
| TypeScriptファイル | kebab-case or camelCase | `vite.config.ts` |

## 備考

- dev-processの6つのパターン（2段階ビルド、UID/GID調整、DooD/DinD切替、動的マウント、ハッシュ命名、ラベル管理）はすべてweb-designでも有効
- code-server固有のパターンとして、`--install-extension` による拡張機能プリインストールが追加される
- DooD時の `--entrypoint` 上書きパターンは `start-code-server` に変更が必要
