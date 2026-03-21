# Task 10: Dockerfile アプリ層 + compose.yaml

## タスク情報

| 項目 | 内容 |
|------|------|
| ID | 10 |
| タスク名 | Dockerfile アプリ層 + compose.yaml |
| 前提タスク | 02, 06, 07, 08, 09 |
| 並列実行 | 不可（統合タスク） |
| 見積時間 | 30分 |

## 作業環境

- **worktree**: `/tmp/viewer-container-local-10/`
- **ブランチ**: `task/10-dockerfile-compose`
- **サブモジュール**: `submodules/copilot-session-viewer/`

## 前提条件

- Task 02: `next.config.ts` に standalone 出力、`.dockerignore` 存在
- Task 06: `.env.example` が存在（compose.yaml の `env_file` 参照の前提）
- Task 07: `scripts/start-viewer.sh` が存在
- Task 08: `scripts/cplt` が存在
- Task 09: `.devcontainer/devcontainer.json` が存在

## 作業内容

### 目的

アプリ層の `Dockerfile` と `compose.yaml` を作成し、コンテナとしての起動を可能にする。

### 設計参照

- `docs/copilot-session-viewer/design/02_interface-api-design.md` — セクション 5 (Dockerfile), セクション 3 (compose.yaml)
- `docs/copilot-session-viewer/design/01_implementation-approach.md` — セクション 3.3 (アプリ層ビルド)
- `docs/copilot-session-viewer/design/04_process-flow-design.md` — セクション 1.2 (コンテナ起動フロー), セクション 6 (ビルドフロー)

### 実装ステップ

1. **`Dockerfile` を作成**

   ```dockerfile
   ARG BASE_IMAGE=copilot-session-viewer:base
   FROM ${BASE_IMAGE}

   # Install tini for proper PID 1 zombie reaping
   RUN apt-get update && apt-get install -y --no-install-recommends tini && rm -rf /var/lib/apt/lists/*

   # Build tmux 3.6a from source (upgrade from apt version)
   RUN apt-get update && apt-get install -y --no-install-recommends \
         libevent-dev ncurses-dev build-essential bison pkg-config \
       && cd /tmp \
       && curl -fsSL https://github.com/tmux/tmux/releases/download/3.6a/tmux-3.6a.tar.gz | tar xz \
       && cd tmux-3.6a \
       && ./configure && make -j$(nproc) && make install \
       && cd / && rm -rf /tmp/tmux-3.6a \
       && apt-get purge -y build-essential bison && apt-get autoremove -y \
       && rm -rf /var/lib/apt/lists/*

   WORKDIR /app
   ENV NEXT_TELEMETRY_DISABLED=1

   # Copy Next.js standalone build artifacts
   COPY .next/standalone/ ./
   COPY .next/static ./.next/static
   COPY public ./public

   # Copy entrypoint and tools
   COPY scripts/start-viewer.sh /usr/local/bin/start-viewer
   COPY scripts/cplt /usr/local/bin/cplt
   RUN chmod +x /usr/local/bin/start-viewer /usr/local/bin/cplt

   EXPOSE 3000

   # Ensure named volume mount point exists with correct ownership
   RUN mkdir -p /home/node/.copilot && chown node:node /home/node/.copilot

   USER node

   ENTRYPOINT ["tini", "--"]
   CMD ["start-viewer"]
   ```

2. **`compose.yaml` を作成**

   ```yaml
   services:
     viewer:
       build:
         context: .
         dockerfile: Dockerfile
         args:
           BASE_IMAGE: copilot-session-viewer:base
       ports:
         - "${PORT:-3000}:3000"
       volumes:
         - copilot-data:/home/node/.copilot
       env_file:
         - .env
       environment:
         - DISABLE_DOCKER_DETECTION=true
         - ENABLE_DEV_PROCESS=false
         - NODE_ENV=production
       tty: true
       stdin_open: true
       init: false
       healthcheck:
         test: ["CMD", "curl", "-f", "http://localhost:3000/api/sessions"]
         interval: 30s
         timeout: 10s
         retries: 3
         start_period: 30s

   volumes:
     copilot-data:
   ```

3. **構文チェック**
   ```bash
   # Dockerfile lint (hadolint 利用可能な場合)
   hadolint Dockerfile || true

   # compose.yaml 構文チェック
   docker compose config --quiet
   ```

### 対象ファイル

| ファイル | 操作 |
|---------|------|
| `submodules/copilot-session-viewer/Dockerfile` | 新規作成 |
| `submodules/copilot-session-viewer/compose.yaml` | 新規作成 |

## TDD アプローチ

### RED (失敗するテストを書く)

```bash
# Dockerfile 構文チェック (docker build --check が利用可能な場合)
docker build --check -f Dockerfile . 2>&1 || echo "Expected: Dockerfile does not exist"

# compose.yaml 構文チェック
docker compose config --quiet 2>&1 || echo "Expected: compose.yaml does not exist"
```

### GREEN (最小実装)

1. `Dockerfile` を作成
2. `compose.yaml` を作成
3. `.env` テンプレートをコピーして `.env` を作成 (compose config 用)
   ```bash
   cp .env.example .env
   ```
4. `docker compose config --quiet` で構文チェック PASS

### REFACTOR (改善)

- Dockerfile のレイヤーキャッシュ最適化
- compose.yaml のコメント追加
- 不要なパッケージの削除確認

## 期待される成果物

- `submodules/copilot-session-viewer/Dockerfile`
- `submodules/copilot-session-viewer/compose.yaml`

## 完了条件

- [ ] `Dockerfile` が存在し、2層構成 (FROM base) になっている
- [ ] `compose.yaml` が存在し、`docker compose config` が成功する
- [ ] tini, tmux 3.6a ビルド、standalone コピーが Dockerfile に含まれる
- [ ] healthcheck が定義されている
- [ ] Named volume `copilot-data` が定義されている
- [ ] `DISABLE_DOCKER_DETECTION=true` が environment に含まれる

## コミット

```bash
git add -A
git commit -m "feat: add Dockerfile (app layer) and compose.yaml

- Dockerfile: FROM base, tini, tmux 3.6a, Next.js standalone
- compose.yaml: service with healthcheck, named volume, env
- ENTRYPOINT tini -- start-viewer

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```
