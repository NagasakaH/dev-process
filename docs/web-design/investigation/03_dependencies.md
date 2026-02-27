# 依存関係調査

## 概要

web-designリポジトリの構築に必要な依存関係を、devcontainer構成・Reactプロジェクト・開発ツールの3つの観点から分析する。

## 外部依存関係

### devcontainer features 依存

| Feature | バージョン | 提供元 | 用途 |
|---------|-----------|--------|------|
| `javascript-node:lts` | LTS | mcr.microsoft.com | ベースイメージ (Node.js含む) |
| `github-cli:1` | 1.x | ghcr.io/devcontainers | GitHub CLI |
| `playwright:0` | 0.x | ghcr.io/schlich | E2Eテスト |
| `jqyq:0` | 0.x | ghcr.io/larsnieuwenhuizen | JSON/YAML操作 |
| `docker-in-docker:2` | 2.x | ghcr.io/devcontainers | Docker DinD |
| `ripgrep:1` | 1.x | ghcr.io/jungaretti | 高速検索 |
| `prettier:1` | 1.x | ghcr.io/devcontainers-community | コードフォーマット |
| `shfmt:1` | 1.x | ghcr.io/devcontainers-extra | シェルフォーマット |
| `copilot-cli:1` | 1.x | ghcr.io/devcontainers | Copilot CLI |
| `claude-code:0` | 0.x | ghcr.io/stu-bell | Claude Code |

### Reactプロジェクト本番依存（dependencies）

| パッケージ | バージョン | 用途 |
|------------|-----------|------|
| `react` | ^19.x | UIフレームワーク |
| `react-dom` | ^19.x | React DOM レンダリング |
| `msw` | ^2.x | Mock Service Worker (APIモック) |

### Reactプロジェクト開発依存（devDependencies）

| パッケージ | バージョン | 用途 |
|------------|-----------|------|
| `typescript` | ^5.x | TypeScriptコンパイラ |
| `vite` | ^6.x | ビルドツール |
| `@vitejs/plugin-react` | ^4.x | Vite React プラグイン |
| `tailwindcss` | ^4.x | CSSフレームワーク |
| `@tailwindcss/vite` | ^4.x | Tailwind Vite統合 |
| `eslint` | ^9.x | リンター |
| `@playwright/test` | ^1.x | E2Eテスト |
| `@types/react` | ^19.x | React型定義 |
| `@types/react-dom` | ^19.x | ReactDOM型定義 |

### code-server 依存

| パッケージ | インストール方法 | 用途 |
|------------|-----------------|------|
| `code-server` | `curl -fsSL https://code-server.dev/install.sh \| sh` | ブラウザベースVS Code |

## 依存関係図

```mermaid
graph TD
    subgraph "Container Layer"
        BASE["mcr.microsoft.com/devcontainers/javascript-node:lts"]
        CS["code-server"]
        DIND["docker-in-docker"]
        PW["Playwright"]
    end
    
    subgraph "DevContainer Features"
        F1["github-cli"]
        F2["copilot-cli"]
        F3["claude-code"]
        F4["prettier"]
        F5["jq/yq"]
        F6["ripgrep"]
        F7["shfmt"]
    end
    
    subgraph "React Project"
        R1["react + react-dom"]
        R2["vite + @vitejs/plugin-react"]
        R3["typescript"]
        R4["tailwindcss"]
        R5["msw"]
        R6["@playwright/test"]
    end
    
    subgraph "VS Code Extensions"
        E1["GitHub Copilot"]
        E2["Copilot Chat"]
        E3["ES7+ React Snippets"]
        E4["ESLint"]
        E5["Prettier"]
        E6["Tailwind IntelliSense"]
        E7["YAML"]
    end
    
    BASE --> CS
    BASE --> DIND
    BASE --> PW
    BASE --> F1
    BASE --> F2
    BASE --> F3
    BASE --> F4
    BASE --> F5
    BASE --> F6
    BASE --> F7
    
    CS --> E1
    CS --> E2
    CS --> E3
    CS --> E4
    CS --> E5
    CS --> E6
    CS --> E7
    
    R2 --> R1
    R2 --> R3
    R2 --> R4
    R6 --> PW
```

## 内部モジュール依存関係

### dev-container.sh の依存関係

```mermaid
graph LR
    subgraph "scripts/"
        DC["dev-container.sh"]
        BP["build-and-push-devcontainer.sh"]
    end
    
    subgraph ".devcontainer/"
        DJ["devcontainer.json"]
        DF["Dockerfile"]
        SC["start-code-server.sh"]
    end
    
    subgraph "External"
        DH["Docker Hub<br/>nagasakah/web-design"]
        DE["Docker Engine"]
    end
    
    DC -->|"docker run"| DF
    DC -->|"DinD/DooD"| DE
    BP -->|"devcontainer build"| DJ
    BP -->|"docker buildx build"| DF
    BP -->|"docker push"| DH
    DF -->|"COPY"| SC
    DF -->|"FROM"| DH
```

### スクリプト間の依存

| モジュール | 依存先 | 依存理由 |
|------------|--------|----------|
| `dev-container.sh` | Docker Engine | コンテナ起動・管理 |
| `dev-container.sh` | `nagasakah/web-design:latest` | コンテナイメージ |
| `build-and-push-devcontainer.sh` | `devcontainer` CLI | ベースイメージビルド |
| `build-and-push-devcontainer.sh` | Docker Hub | イメージpush |
| `start-code-server.sh` | `code-server` | Web IDE起動 |
| `start-code-server.sh` | `/usr/local/share/docker-init.sh` | DinD初期化 |

## 循環依存の有無

- [x] 循環依存なし

新規プロジェクトのため循環依存は発生しない。依存関係は一方向の階層構造。

## バージョン制約・注意点

| 項目 | 制約内容 | 理由 |
|------|----------|------|
| Node.js | LTS (20.x or 22.x) | ベースイメージで決定 |
| Docker | 20.10+ | docker-in-docker feature要件 |
| Platform | linux/amd64 | dev-processと同様 |
| code-server | 最新安定版 | install.shで自動取得 |
| Playwright | ブラウザ依存バージョン | devcontainer featureで管理 |

## 備考

- dev-processは23個のfeaturesを使用しているが、web-designでは9個に絞り込み（Python, AWS, Terraform, tmux, Neovim, Deno, mssql-mcpを除外）
- code-serverはdevcontainer featureとしては公式提供されていないため、Dockerfile内でインストールする
- MSW (Mock Service Worker) はブラウザのService Workerを利用するため、code-server環境でのHTTPS要件に注意
