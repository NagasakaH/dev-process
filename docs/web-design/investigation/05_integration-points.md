# 統合ポイント調査

## 概要

web-designの開発環境における統合ポイントを分析する。主な統合ポイントは、code-serverとVite dev server間のポートフォワード、Docker Engine との DooD/DinD 連携、および code-server の VS Code 拡張機能連携である。

## ポート構成

| サービス | ポート | 用途 | アクセス方法 |
|----------|--------|------|-------------|
| code-server | 8080 | ブラウザベースVS Code | `http://localhost:8080` |
| Vite dev server | 5173 | React ホットリロード | code-server内ポートフォワード or `http://localhost:5173` |
| Vite HMR WebSocket | 5173 | Hot Module Replacement | 自動接続 |

## シーケンス図

### コンテナ起動フロー（DinDモード）

```mermaid
sequenceDiagram
    participant U as User
    participant DS as dev-container.sh
    participant DE as Docker Engine
    participant DI as docker-init.sh
    participant CS as start-code-server.sh
    participant SV as code-server
    
    U->>DS: scripts/dev-container.sh up
    DS->>DS: DOCKER_MODE=dind 確認
    DS->>DS: build_mounts() 動的マウント構築
    DS->>DE: docker run --privileged
    DE->>DI: ENTRYPOINT: docker-init.sh
    DI->>DI: dockerd 起動 (DinD)
    DI->>CS: CMD: start-code-server
    CS->>CS: UID/GID 調整 (root→vscode)
    CS->>CS: Docker socket パーミッション修正
    CS->>SV: code-server --bind-addr 0.0.0.0:8080
    SV-->>U: ブラウザで http://localhost:8080 にアクセス
```

### コンテナ起動フロー（DooDモード）

```mermaid
sequenceDiagram
    participant U as User
    participant DS as dev-container.sh
    participant DE as Docker Engine (Host)
    participant CS as start-code-server.sh
    participant SV as code-server
    
    U->>DS: DOCKER_MODE=dood scripts/dev-container.sh up
    DS->>DS: Docker socket パス確認
    DS->>DS: socket GID 取得
    DS->>DE: docker run --privileged -v docker.sock --entrypoint start-code-server
    Note over DE: ENTRYPOINT上書き<br/>(docker-init.sh をスキップ)
    DE->>CS: start-code-server 直接実行
    CS->>CS: UID/GID 調整 (root→vscode)
    CS->>CS: Docker socket chmod 666
    CS->>SV: code-server --bind-addr 0.0.0.0:8080
    SV-->>U: ブラウザで http://localhost:8080 にアクセス
```

### React開発ワークフロー

```mermaid
sequenceDiagram
    participant U as User (Browser)
    participant CS as code-server :8080
    participant T as Terminal (in code-server)
    participant V as Vite :5173
    participant R as React App
    
    U->>CS: ブラウザでcode-serverにアクセス
    CS-->>U: VS Code Web UIを表示
    U->>T: ターミナルを開く
    T->>V: npm run dev
    V-->>T: Local: http://localhost:5173
    
    Note over U,V: ポートフォワード設定
    U->>V: http://localhost:5173 にアクセス
    V-->>U: React Appを表示
    
    U->>CS: コードを編集
    CS->>V: ファイル変更検知
    V->>R: HMR Update
    R-->>U: 画面更新（ホットリロード）
```

### プリビルドイメージ作成フロー

```mermaid
sequenceDiagram
    participant D as Developer
    participant S as build-and-push.sh
    participant DC as devcontainer CLI
    participant DX as docker buildx
    participant DH as Docker Hub
    
    D->>S: ./scripts/build-and-push-devcontainer.sh
    
    Note over S,DC: Step 1: base イメージ
    S->>DC: devcontainer build --image-name web-design:base
    DC->>DC: devcontainer.json の features をインストール
    DC-->>S: web-design:base 作成完了
    
    S->>DH: docker push web-design:base
    
    Note over S,DX: Step 2: latest イメージ  
    S->>DX: docker buildx build -f Dockerfile
    DX->>DX: code-server インストール
    DX->>DX: VS Code拡張機能インストール
    DX->>DX: start-code-server.sh コピー
    DX-->>S: web-design:latest 作成完了
    
    S->>DH: docker push web-design:latest
```

## 統合ポイント一覧

### code-server ↔ Vite Dev Server

| 項目 | 詳細 |
|------|------|
| 連携方式 | ポートフォワード |
| code-server側 | `forwardPorts` 設定、またはターミナルからアクセス |
| Vite側 | `--host 0.0.0.0` オプションでコンテナ外からアクセス可能に |
| HMR | WebSocket接続で自動更新 |

### code-server ↔ VS Code拡張機能

| 項目 | 詳細 |
|------|------|
| インストール方法 | Dockerfile内で `code-server --install-extension <id>` |
| 設定ファイル | `~/.local/share/code-server/User/settings.json` |
| 拡張機能ディレクトリ | `~/.local/share/code-server/extensions/` |

### Docker Engine ↔ dev-container.sh

| 項目 | DinD | DooD |
|------|------|------|
| Docker daemon | コンテナ内dockerd | ホストのdockerd |
| Socket | 自動生成 | ホストからマウント |
| ENTRYPOINT | `docker-init.sh` → `start-code-server` | `start-code-server` (直接) |
| 特権 | `--privileged` | `--privileged` |
| ソケットパーミッション | 自動 | `chmod 666` or `--group-add` |

### dev-container.sh ↔ ホストファイルシステム

| マウント | ソース | ターゲット | モード | 用途 |
|----------|--------|------------|--------|------|
| ワークスペース | `${WORKSPACE_DIR}` | `/workspaces/${PROJECT_NAME}` | rw | ソースコード |
| Git設定 | `~/.gitconfig` | `/home/vscode/.gitconfig` | ro | Git認証 |
| SSH鍵 | `~/.ssh` | `/home/vscode/.ssh` | ro | Git SSH |
| Claude設定 | `~/.claude` | `/home/vscode/.claude` | cached | Claude Code |
| Claude JSON | `~/.claude.json` | `/home/vscode/.claude.json` | cached | Claude Code |
| Copilot設定 | `~/.copilot` | `/home/vscode/.copilot` | cached | Copilot認証 |
| Docker socket | `/var/run/docker.sock` | `/var/run/docker.sock` | rw | DooD時のみ |

## 外部サービス連携

| サービス | 連携方式 | 用途 | 設定方法 |
|----------|----------|------|----------|
| Docker Hub | HTTP API | プリビルドイメージpush/pull | `docker login` |
| GitHub | SSH/HTTPS | ソースコード管理 | `~/.ssh`, `~/.gitconfig` マウント |
| GitHub Copilot | VS Code拡張機能 | AIコード補完 | `~/.copilot` マウント |
| MSW (ローカル) | Service Worker | APIモック | ブラウザ内で完結 |

## 連携図

```mermaid
graph LR
    subgraph "Host Machine"
        H1["Docker Engine"]
        H2["File System"]
        H3["Browser"]
    end
    
    subgraph "Dev Container"
        subgraph "code-server :8080"
            CS["VS Code Web UI"]
            EXT["Extensions"]
            TERM["Terminal"]
        end
        
        subgraph "Vite :5173"
            REACT["React App"]
            MSW_W["MSW Worker"]
        end
        
        subgraph "Docker (DinD/DooD)"
            DOCK["docker CLI"]
        end
    end
    
    subgraph "External"
        GH["GitHub"]
        DH["Docker Hub"]
        CP["GitHub Copilot API"]
    end
    
    H3 -->|":8080"| CS
    H3 -->|":5173"| REACT
    H2 -->|"bind mount"| CS
    H1 -->|"DooD socket"| DOCK
    
    EXT -.-> CP
    DOCK -.-> DH
    TERM -.-> GH
```

## 備考

- code-serverのポートフォワード機能により、Vite dev serverのポート(5173)をcode-server経由でアクセスすることも可能
- DooD/DinDの切り替えはコンテナ起動時に決定され、実行中の切り替えは不可
- MSWはService Workerとしてブラウザ内で動作するため、外部サービスとの通信は発生しない
- `docker run` 時に `-p 8080:8080 -p 5173:5173` のポートマッピングが必要（dev-container.shに追加）
