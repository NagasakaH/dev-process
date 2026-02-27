# インターフェース/API設計

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | WEB-DESIGN-001 |
| タスク名 | ウェブデザイン要件定義プロジェクト環境構築 |
| 作成日 | 2026-02-27 |

---

## 1. スクリプトインターフェース

本プロジェクトはWebアプリケーションのAPI設計ではなく、開発環境構築のためスクリプトのCLIインターフェースを設計する。

### 1.1 dev-container.sh

dev-processから移植するコンテナ管理スクリプト。

```bash
# コマンド体系
scripts/dev-container.sh <command> [options]

# コマンド一覧
scripts/dev-container.sh up      # コンテナ起動
scripts/dev-container.sh down    # コンテナ停止・削除
scripts/dev-container.sh status  # コンテナ状態確認
scripts/dev-container.sh shell   # コンテナにshellアタッチ
scripts/dev-container.sh logs    # コンテナログ表示
```

#### 環境変数インターフェース

| 環境変数 | デフォルト値 | 説明 |
|----------|-------------|------|
| `DOCKER_MODE` | `dind` | Docker動作モード (`dind` / `dood`) |
| `DEV_CONTAINER_IMAGE` | `nagasakah/web-design:latest` | 使用するDockerイメージ |
| `CODE_SERVER_PORT` | `8080` | code-serverのポート |
| `VITE_PORT` | `5173` | Vite dev serverのポート |

#### ポートマッピング

| ホスト | コンテナ | サービス |
|--------|----------|----------|
| 8080 | 8080 | code-server |
| 5173 | 5173 | Vite dev server |

### 1.2 start-code-server.sh

コンテナ内で実行される起動スクリプト。

```bash
# 起動フロー
start-code-server [workspace_dir]

# 引数
#   workspace_dir: ワークスペースディレクトリ (デフォルト: /workspaces/web-design)
```

#### 内部関数

```bash
# UID/GID調整（root実行時）
adjust_uid_gid() {
  # パラメータ: なし（環境から自動検出）
  # 副作用: vscodeユーザーのUID/GIDをワークスペース所有者に合わせる
}

# Docker socketパーミッション修正
fix_docker_socket() {
  # パラメータ: なし
  # 副作用: /var/run/docker.sock を chmod 666
}

# code-server起動
start_server() {
  # パラメータ: workspace_dir
  # 起動コマンド: code-server --bind-addr 0.0.0.0:8080 --auth none <workspace_dir>
}
```

### 1.3 build-and-push-devcontainer.sh

プリビルドイメージの作成・プッシュスクリプト。

```bash
# 使用方法
scripts/build-and-push-devcontainer.sh [options]

# オプション
#   --no-push     プッシュをスキップ（ローカルビルドのみ）
#   --platform    ビルドプラットフォーム (デフォルト: linux/amd64)
```

#### ビルドステップ

| ステップ | コマンド | 出力 |
|----------|---------|------|
| Step 1 (base) | `devcontainer build --image-name nagasakah/web-design:base` | `nagasakah/web-design:base` |
| Step 2 (latest) | `docker buildx build -t nagasakah/web-design:latest` | `nagasakah/web-design:latest` |
| Push base | `docker push nagasakah/web-design:base` | Docker Hub |
| Push latest | `docker push nagasakah/web-design:latest` | Docker Hub |

---

## 2. devcontainer.json 設計

### 2.1 構造

```jsonc
{
  "name": "web-design",
  "image": "mcr.microsoft.com/devcontainers/javascript-node:lts",
  "features": {
    "ghcr.io/devcontainers/features/github-cli:1": {},
    "ghcr.io/schlich/devcontainer-features/playwright:0": {},
    "ghcr.io/larsnieuwenhuizen/features/jqyq:0": {},
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/jungaretti/features/ripgrep:1": {},
    "ghcr.io/devcontainers-community/npm-features/prettier:1": {},
    "ghcr.io/devcontainers-extra/features/shfmt:1": {},
    "ghcr.io/devcontainers/features/copilot-cli:1": {},
    "ghcr.io/stu-bell/devcontainer-features/claude-code:0": {}
  },
  "forwardPorts": [8080, 5173],
  "customizations": {
    "vscode": {
      "extensions": [
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode",
        "bradlc.vscode-tailwindcss",
        "redhat.vscode-yaml",
        "dsznajder.es7-react-js-snippets"
      ],
      "settings": {
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "editor.codeActionsOnSave": {
          "source.fixAll.eslint": "explicit"
        }
      }
    }
  },
  "postCreateCommand": "echo '--- Tool versions ---' && node --version && npm --version && npx playwright --version 2>/dev/null && yq --version && gh --version | head -1",
  "remoteUser": "vscode"
}
```

### 2.2 features一覧（9個）

| Feature | バージョン | 用途 |
|---------|-----------|------|
| `github-cli:1` | 1.x | GitHub CLI (gh) |
| `playwright:0` | 0.x | E2Eテスト + ブラウザ依存ライブラリ |
| `jqyq:0` | 0.x | JSON/YAML操作 (project.yaml) |
| `docker-in-docker:2` | 2.x | DinDサポート |
| `ripgrep:1` | 1.x | 高速テキスト検索 |
| `prettier:1` | 1.x | コードフォーマッター |
| `shfmt:1` | 1.x | シェルスクリプトフォーマッター |
| `copilot-cli:1` | 1.x | GitHub Copilot CLI |
| `claude-code:0` | 0.x | Claude Code |

---

## 3. Dockerfile 設計

> **MRD-001対応**: code-serverは公式devcontainer featureが存在しないため、Dockerfileで手動インストールする。setup.yamlの機能要件「devcontainerのfeatureとしてcode-serverを追加」は、この手段（Dockerfileでのcurl install）で実現する。devcontainer featureとして公式に提供されていないため、feature相当の組み込みをDockerfileレイヤーで行う方式を採用する。

> **MRD-002対応（Copilot拡張機能）**: GitHub Copilot拡張機能はOpen VSX Registryに公開されていないため、code-serverへのインストールは不可能である。代替として **Copilot CLI**（devcontainer feature `ghcr.io/devcontainers/features/copilot-cli:1` で導入済み）を使用する。Dockerfileからは `|| true` のCopilot拡張インストール行を除去し、acceptance_criteriaの「Copilot拡張機能がインストールされている」は「Copilot CLIが使用可能」に修正を提案する。

```dockerfile
FROM --platform=linux/amd64 nagasakah/web-design:base

# iptables修正（DinD対応）
RUN update-alternatives --set iptables /usr/sbin/iptables-nft && \
    update-alternatives --set ip6tables /usr/sbin/ip6tables-nft

# code-server インストール
RUN curl -fsSL https://code-server.dev/install.sh | sh

# VS Code拡張機能プリインストール（Open VSX対応のもの）
RUN code-server --install-extension dbaeumer.vscode-eslint && \
    code-server --install-extension esbenp.prettier-vscode && \
    code-server --install-extension bradlc.vscode-tailwindcss && \
    code-server --install-extension redhat.vscode-yaml && \
    code-server --install-extension dsznajder.es7-react-js-snippets

# NOTE: GitHub Copilot拡張機能はOpen VSXに非公開のためインストール不可。
# Copilot CLIで代替する（devcontainer feature copilot-cli:1 で導入済み）。

# 起動スクリプト配置
COPY scripts/start-code-server.sh /usr/local/bin/start-code-server
RUN chmod +x /usr/local/bin/start-code-server

# code-server設定ディレクトリの権限設定
RUN mkdir -p /home/vscode/.local/share/code-server && \
    chown -R vscode:vscode /home/vscode/.local

# DinD対応エントリポイント
ENTRYPOINT ["/usr/local/share/docker-init.sh"]
CMD ["start-code-server"]
```

---

## 4. docker-compose.yml 設計

本プロジェクトではdocker-compose.ymlは使用せず、`dev-container.sh` で `docker run` を直接実行する（dev-processパターンを踏襲）。

dev-container.shが生成する `docker run` コマンドのパラメータ:

```bash
docker run -d \
  --name "web-design-${PATH_HASH}" \
  --label "managed-by=dev-container-sh" \
  --label "workspace-path=${WORKSPACE_DIR}" \
  -p 8080:8080 \
  -p 5173:5173 \
  -v "${WORKSPACE_DIR}:/workspaces/web-design" \
  -v "${HOME}/.gitconfig:/home/vscode/.gitconfig:ro" \
  -v "${HOME}/.ssh:/home/vscode/.ssh:ro" \
  -v "${HOME}/.claude:/home/vscode/.claude:cached" \
  -v "${HOME}/.claude.json:/home/vscode/.claude.json:cached" \
  -v "${HOME}/.copilot:/home/vscode/.copilot:cached" \
  ${DOCKER_MODE_FLAGS} \
  nagasakah/web-design:latest
```

---

## 5. code-server設定

### 5.1 code-server起動パラメータ

| パラメータ | 値 | 説明 |
|------------|-----|------|
| `--bind-addr` | `0.0.0.0:8080` | 全インターフェースでリッスン |
| `--auth` | `none` | 認証なし（ローカル開発用） |
| `--disable-telemetry` | - | テレメトリ無効化 |
| 引数 | `/workspaces/web-design` | ワークスペースディレクトリ |

### 5.2 code-server設定ファイル（~/.config/code-server/config.yaml）

```yaml
bind-addr: 0.0.0.0:8080
auth: none
disable-telemetry: true
```

### 5.3 セキュリティガイドライン（MRD-005対応）

> **⚠️ セキュリティに関する重要な注意事項**

| 項目 | ガイドライン |
|------|-------------|
| **利用環境** | **ローカル開発環境専用**。公開ネットワーク上での使用は厳禁 |
| **認証設定** | `--auth none` はローカル開発に限定して使用する。リモートアクセスが必要な場合は `--auth password` に変更すること |
| **ポート公開** | ポート8080/5173は `localhost` へのフォワーディングのみを想定。ファイアウォールで外部からのアクセスをブロックすること |
| **`--privileged`** | DinD/DooDに必要だが、信頼できるローカル環境でのみ使用すること |
| **Docker socket (DooD)** | ホストDockerへの完全アクセスが付与される。共有環境での使用時は注意 |

**禁止事項:**
- 公開ネットワーク（インターネット）上でcode-serverを `--auth none` のまま起動しないこと
- VPN/トンネル等で外部にポートを公開する際は必ず認証を有効にすること
- 本番環境やステージング環境での使用は想定していない

---

## 6. エラーハンドリング

### 6.1 dev-container.sh エラー種別

| エラー種別 | 発生条件 | 対応 |
|------------|----------|------|
| Docker未起動 | Docker Engine が停止中 | エラーメッセージを表示して終了 |
| イメージ未取得 | `nagasakah/web-design:latest` が存在しない | `docker pull` を試行 |
| ポート競合 | 8080 or 5173 が使用中 | エラーメッセージでポート番号を表示 |
| DooD socket不在 | `/var/run/docker.sock` が存在しない | DooDモードからDinDモードへの切替を推奨 |

### 6.2 start-code-server.sh エラー種別

| エラー種別 | 発生条件 | 対応 |
|------------|----------|------|
| code-server未インストール | `code-server` コマンドが見つからない | エラーメッセージを表示して終了 |
| UID/GID調整失敗 | usermod/groupmod が失敗 | 警告を出して続行 |
| ワークスペース不在 | 指定ディレクトリが存在しない | デフォルトディレクトリを使用 |

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-02-27 | 1.0 | 初版作成 | Copilot |
