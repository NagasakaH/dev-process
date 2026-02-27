# 処理フロー設計

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | WEB-DESIGN-001 |
| タスク名 | ウェブデザイン要件定義プロジェクト環境構築 |
| 作成日 | 2026-02-27 |

---

## 1. シーケンス図（修正前/修正後対比）

### 1.1 修正前：dev-processの起動フロー（tmux）

```mermaid
sequenceDiagram
    participant U as User
    participant DS as dev-container.sh
    participant DE as Docker Engine
    participant DI as docker-init.sh
    participant ST as start-tmux.sh
    participant TM as tmux
    
    Note over U,TM: 【修正前】dev-process: tmux起動フロー
    
    U->>DS: scripts/dev-container.sh up
    DS->>DS: DOCKER_MODE判定 (dind/dood)
    DS->>DS: build_mounts() マウント構築
    
    alt DinDモード
        DS->>DE: docker run --privileged
        DE->>DI: ENTRYPOINT: docker-init.sh
        DI->>DI: dockerd 起動
        DI->>ST: CMD: start-tmux
    else DooDモード
        DS->>DE: docker run --entrypoint start-tmux -v docker.sock
        DE->>ST: start-tmux 直接実行
    end
    
    ST->>ST: UID/GID調整 (root→vscode)
    ST->>ST: Docker socket パーミッション修正
    ST->>ST: exec su -l vscode
    ST->>TM: tmux new-session
    TM->>TM: 3ウィンドウ作成 (editor, copilot, bash)
    
    Note over U,TM: ユーザーは docker exec -it ... /bin/bash でアタッチ
```

### 1.2 修正後：web-designの起動フロー（code-server）

```mermaid
sequenceDiagram
    participant U as User (Browser)
    participant DS as dev-container.sh
    participant DE as Docker Engine
    participant DI as docker-init.sh
    participant SC as start-code-server.sh
    participant CS as code-server :8080
    
    Note over U,CS: 【修正後】web-design: code-server起動フロー
    
    U->>DS: scripts/dev-container.sh up
    DS->>DS: DOCKER_MODE判定 (dind/dood)
    DS->>DS: build_mounts() マウント構築
    DS->>DS: ポートマッピング追加 (-p 8080:8080 -p 5173:5173)
    
    alt DinDモード
        DS->>DE: docker run --privileged -p 8080:8080 -p 5173:5173
        DE->>DI: ENTRYPOINT: docker-init.sh
        DI->>DI: dockerd 起動
        DI->>SC: CMD: start-code-server
    else DooDモード
        DS->>DE: docker run --entrypoint start-code-server -v docker.sock -p 8080:8080 -p 5173:5173
        DE->>SC: start-code-server 直接実行
    end
    
    SC->>SC: UID/GID調整 (root→vscode)
    SC->>SC: Docker socket パーミッション修正
    SC->>SC: exec su -l vscode
    SC->>CS: code-server --bind-addr 0.0.0.0:8080 --auth none
    
    Note over U,CS: 変更点: tmux→code-server、ポートマッピング追加
    
    U->>CS: ブラウザで http://localhost:8080 にアクセス
    CS-->>U: VS Code Web UI を表示
```

### 1.3 変更点サマリー

| 項目 | 修正前 (dev-process) | 修正後 (web-design) | 理由 |
|------|---------------------|---------------------|------|
| 起動スクリプト | `start-tmux.sh` | `start-code-server.sh` | tmuxの代わりにcode-server |
| ユーザーインターフェース | tmuxターミナル | ブラウザベースVS Code | 要件定義レビューに最適 |
| アクセス方法 | `docker exec -it` | `http://localhost:8080` | ブラウザで即アクセス |
| ポートマッピング | なし | `-p 8080:8080 -p 5173:5173` | code-server + Vite |
| CMD | `start-tmux` | `start-code-server` | 起動コマンド変更 |
| ENTRYPOINT上書き(DooD) | `--entrypoint start-tmux` | `--entrypoint start-code-server` | DooD時の直接起動 |
| マウント | `.aws`, `.gitconfig`, `.ssh`, etc. | `.gitconfig`, `.ssh`, `.claude`, `.copilot` | `.aws`削除 |

---

## 2. start-code-server.sh 詳細フロー

```mermaid
flowchart TD
    A[start-code-server.sh 起動] --> B{rootで実行?}
    
    B -->|Yes| C[ワークスペースの所有者UID/GID取得]
    C --> D{vscodeのUID/GIDと異なる?}
    D -->|Yes| E[usermod/groupmod でUID/GID変更]
    D -->|No| F[変更不要]
    E --> G{Docker socket存在?}
    F --> G
    G -->|Yes| H["chmod 666 /var/run/docker.sock"]
    G -->|No| I[スキップ]
    H --> J["exec su -l vscode -c '$0 $*'"]
    I --> J
    
    B -->|No| K[code-server設定ディレクトリ確認]
    K --> L["code-server 起動"]
    L --> M["--bind-addr 0.0.0.0:8080"]
    M --> N["--auth none"]
    N --> O["--disable-telemetry"]
    O --> P["/workspaces/web-design"]
    
    style A fill:#9cf
    style L fill:#9f9
    style J fill:#ff9
```

---

## 3. dev-container.sh up コマンドフロー

```mermaid
flowchart TD
    A["dev-container.sh up"] --> B{既存コンテナあり?}
    
    B -->|Yes| C{状態?}
    C -->|Running| D[既に起動中メッセージ]
    C -->|Stopped| E["docker start"]
    C -->|Exited| F["docker rm → 新規作成"]
    
    B -->|No| G[コンテナ名生成]
    G --> H["PATH_HASH = md5(WORKSPACE_DIR)[:6]"]
    H --> I["CONTAINER_NAME = web-design-{HASH}"]
    
    I --> J[マウント構築]
    J --> K["build_mounts()"]
    K --> L{各パス存在チェック}
    L -->|.gitconfig| M["-v ~/.gitconfig:/home/vscode/.gitconfig:ro"]
    L -->|.ssh| N["-v ~/.ssh:/home/vscode/.ssh:ro"]
    L -->|.claude| O["-v ~/.claude:/home/vscode/.claude:cached"]
    L -->|.copilot| P["-v ~/.copilot:/home/vscode/.copilot:cached"]
    
    M & N & O & P --> Q{DOCKER_MODE?}
    
    Q -->|dind| R["--privileged"]
    Q -->|dood| S["--privileged -v docker.sock --entrypoint start-code-server --group-add GID"]
    
    R --> T["-p 8080:8080 -p 5173:5173"]
    S --> T
    
    T --> U["docker run -d"]
    U --> V[コンテナ起動完了]
    V --> W["http://localhost:8080 でアクセス可能"]
    
    style A fill:#9cf
    style W fill:#9f9
```

---

## 4. プリビルドイメージ作成フロー

```mermaid
flowchart TD
    A["build-and-push-devcontainer.sh"] --> B["Step 1: devcontainer build"]
    
    B --> C["devcontainer build<br/>--workspace-folder .<br/>--image-name nagasakah/web-design:base<br/>--platform linux/amd64"]
    C --> D{成功?}
    D -->|No| E[エラー終了]
    D -->|Yes| F["docker push nagasakah/web-design:base"]
    
    F --> G["Step 2: docker buildx build"]
    G --> H["docker buildx build<br/>--platform linux/amd64<br/>--load<br/>-t nagasakah/web-design:latest<br/>-f .devcontainer/Dockerfile<br/>.devcontainer"]
    
    H --> I{成功?}
    I -->|No| J[エラー終了]
    I -->|Yes| K["docker push nagasakah/web-design:latest"]
    
    K --> L[完了]
    
    style A fill:#9cf
    style L fill:#9f9
    style E fill:#f66
    style J fill:#f66
```

---

## 5. React開発ワークフロー

```mermaid
sequenceDiagram
    participant U as User (Browser)
    participant CS as code-server :8080
    participant T as Terminal
    participant V as Vite :5173
    participant MSW as MSW Worker
    participant R as React App
    
    Note over U,R: React開発ワークフロー
    
    U->>CS: http://localhost:8080 でcode-serverにアクセス
    CS-->>U: VS Code Web UI を表示
    
    U->>T: ターミナルを開く
    T->>T: cd /workspaces/web-design
    T->>V: npm run dev
    V-->>T: Local: http://localhost:5173
    
    U->>R: http://localhost:5173 でReactアプリにアクセス
    R->>MSW: Service Worker登録
    MSW-->>R: APIモック準備完了
    
    R->>MSW: GET /api/health
    MSW-->>R: { status: "ok" }
    R-->>U: 画面表示
    
    loop 開発サイクル
        U->>CS: コンポーネントを編集
        CS->>V: ファイル変更検知 (usePolling)
        V->>R: HMR Update
        R-->>U: 画面即時更新
    end
```

---

## 6. DooD/DinD切り替え状態遷移

```mermaid
stateDiagram-v2
    [*] --> Stopped: コンテナ未作成
    
    Stopped --> Starting_DinD: dev-container.sh up (DOCKER_MODE=dind)
    Stopped --> Starting_DooD: dev-container.sh up (DOCKER_MODE=dood)
    
    Starting_DinD --> Running_DinD: docker-init.sh → dockerd → start-code-server
    Starting_DooD --> Running_DooD: start-code-server 直接実行
    
    Running_DinD --> CodeServerReady: code-server :8080 起動
    Running_DooD --> CodeServerReady: code-server :8080 起動
    
    CodeServerReady --> Stopped: dev-container.sh down
    
    state Running_DinD {
        [*] --> DockerDaemon: dockerd起動
        DockerDaemon --> InternalDocker: docker CLI利用可能
    }
    
    state Running_DooD {
        [*] --> SocketMounted: /var/run/docker.sock
        SocketMounted --> HostDocker: ホストDocker利用可能
    }
```

---

## 7. エラーフロー

### 7.1 コンテナ起動エラーフロー

```mermaid
flowchart TD
    A[dev-container.sh up] --> B{Docker Engine起動中?}
    B -->|No| C["エラー: Docker is not running"]
    B -->|Yes| D{イメージ存在?}
    D -->|No| E["docker pull nagasakah/web-design:latest"]
    E --> F{pull成功?}
    F -->|No| G["エラー: Image not found. Run build-and-push first"]
    F -->|Yes| H[docker run実行]
    D -->|Yes| H
    H --> I{起動成功?}
    I -->|No| J{ポート競合?}
    J -->|Yes| K["エラー: Port 8080/5173 already in use"]
    J -->|No| L["エラー: Container failed to start"]
    I -->|Yes| M[起動完了]
    
    style C fill:#f66
    style G fill:#f66
    style K fill:#f66
    style L fill:#f66
    style M fill:#9f9
```

### 7.2 code-server起動エラーフロー

```mermaid
flowchart TD
    A[start-code-server.sh] --> B{code-server コマンド存在?}
    B -->|No| C["エラー: code-server not found"]
    B -->|Yes| D{ワークスペース存在?}
    D -->|No| E["警告: workspace not found, using /home/vscode"]
    D -->|Yes| F[code-server起動]
    E --> F
    F --> G{起動成功?}
    G -->|No| H["エラー: code-server failed to start"]
    G -->|Yes| I["code-server :8080 ready"]
    
    style C fill:#f66
    style H fill:#f66
    style I fill:#9f9
```

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-02-27 | 1.0 | 初版作成 | Copilot |
