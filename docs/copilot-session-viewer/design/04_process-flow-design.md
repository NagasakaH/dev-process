# 04. 処理フロー設計

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | viewer-container-local |
| タスク名 | container |
| 作成日 | 2026-03-21 |
| 調査結果参照 | [investigation/](../investigation/) |

---

## 1. コンテナ起動フロー

### 1.1 修正前（ホスト直接起動）

```mermaid
sequenceDiagram
    participant User as User
    participant Shell as Terminal
    participant Next as Next.js Dev Server
    participant Term as terminal.ts
    participant Docker as Docker CLI
    participant Tmux as Local tmux

    Note over User,Tmux: 【修正前】ホスト直接起動

    User->>Shell: npm run dev
    Shell->>Next: next dev (port 3000)
    Next-->>User: http://localhost:3000

    User->>Next: GET /api/active-sessions
    Next->>Term: getActiveSessions()
    par Local Detection
        Term->>Tmux: tmux list-panes -a
        Tmux-->>Term: TmuxPane[]
    and Docker Detection
        Term->>Docker: docker ps --format '{{.ID}}'
        Docker-->>Term: container IDs
        loop Each container
            Term->>Docker: docker exec ... ps/tmux
            Docker-->>Term: CopilotProcess[]
        end
    end
    Term-->>Next: ActiveSession[] (local + container)
    Next-->>User: JSON response
```

### 1.2 修正後（コンテナ起動）

```mermaid
sequenceDiagram
    participant User as User
    participant Compose as docker compose
    participant Tini as tini (PID 1)
    participant Script as start-viewer.sh
    participant Tmux as tmux
    participant Next as Next.js Standalone
    participant Term as terminal.ts

    Note over User,Term: 【修正後】コンテナ起動

    User->>Compose: docker compose up -d
    Compose->>Tini: tini -- start-viewer
    Tini->>Script: start-viewer.sh

    Note over Script: UID/GID sync (if root)

    Script->>Tmux: tmux new-session -d -s viewer
    Script->>Tmux: tmux new-window "viewer"
    Script->>Tmux: send-keys "node server.js" (viewer window)
    Tmux->>Next: node .next/standalone/server.js
    Script->>Tmux: tmux new-window "copilot"
    Script->>Tmux: tmux new-window "bash"

    Note over Script: Keep-alive loop (while true; wait; sleep 60)

    Next-->>User: http://localhost:3000

    User->>Next: GET /api/active-sessions
    Next->>Term: getActiveSessions()

    Note over Term: DISABLE_DOCKER_DETECTION=true

    Term->>Tmux: tmux list-panes -a (local only)
    Tmux-->>Term: TmuxPane[]
    Note over Term: Docker detection SKIPPED
    Term-->>Next: ActiveSession[] (local tmux only)
    Next-->>User: JSON response
```

### 1.3 変更点サマリー

| 項目 | 修正前 | 修正後 | 理由 |
|------|--------|--------|------|
| 起動方法 | `npm run dev` | `docker compose up -d` | コンテナ化 |
| PID 1 | Node.js | tini | ゾンビプロセス回収 |
| Next.js 実行 | `next dev` | `node server.js` (standalone) | プロダクション実行 |
| tmux 管理 | ユーザー手動 | start-viewer.sh が自動起動 | self-contained |
| Docker 検出 | 有効 | 無効 (`DISABLE_DOCKER_DETECTION=true`) | コンテナ内では不要 |
| セッション検出 | ローカル + Docker | ローカルのみ | self-contained |

---

## 2. start-viewer.sh 詳細フロー

```mermaid
flowchart TD
    A[start-viewer.sh 起動] --> B{root で実行?}
    B -->|Yes| C[UID/GID 同期]
    C --> D[su -l node で再実行]
    B -->|No| E{tmux セッション存在?}
    D --> E
    E -->|Yes| F[既存セッション使用]
    E -->|No| G[tmux new-session viewer]
    G --> H[Window 1: viewer]
    H --> I["send-keys: HOSTNAME=0.0.0.0 PORT=3000<br/>node .next/standalone/server.js"]
    I --> J[Window 2: copilot]
    J --> K[Window 3: bash]
    K --> L[select-window viewer]
    F --> M[Keep-alive loop]
    L --> M
    M --> N{"wait -n / sleep 60"}
    N --> M
```

---

## 3. セッション検出フロー（コンテナ内）

```mermaid
flowchart TD
    A["getActiveSessions()"] --> B["findLocalCopilotProcesses()"]
    B --> C["ps -eo pid,tty,command | grep copilot"]
    C --> D["CopilotProcess[] (PID + TTY)"]

    A --> E{"DISABLE_DOCKER_DETECTION?"}
    E -->|true| F["return [] (skip Docker)"]
    E -->|false| G["findDockerContainers()"]
    G --> H["findContainerCopilotSessions()"]

    D --> I["getTmuxPanes()"]
    I --> J["tmux list-panes -a"]
    J --> K["TmuxPane[] (target + PID + TTY)"]

    K --> L["Match PID to session-state lock files"]
    F --> L
    D --> L
    L --> M["Build ActiveSession[]"]
    M --> N["Enrich: summary, workspace, pendingAskUser"]
    N --> O["Return ActiveSession[]"]
```

---

## 4. ask_user 応答フロー（コンテナ内）

```mermaid
sequenceDiagram
    participant Browser as Browser
    participant API as /api/sessions/[id]/respond
    participant Term as terminal.ts
    participant Tmux as Local tmux
    participant Copilot as Copilot CLI

    Browser->>API: POST { action, choiceIndex/text }
    API->>Term: getActiveSessions()
    Term->>Tmux: tmux list-panes -a
    Tmux-->>Term: TmuxPane[]
    Term-->>API: ActiveSession (containerId = undefined)

    Note over API: containerId が undefined → ローカル tmux 使用

    alt action = "choice"
        API->>Term: sendAskUserChoice(pane, index)
        Term->>Tmux: send-keys (arrow + enter)
    else action = "freeform"
        API->>Term: sendAskUserFreeform(pane, text)
        Term->>Tmux: send-keys (text + submit)
    else action = "text"
        API->>Term: sendTextInput(pane, text)
        Term->>Tmux: send-keys (text + enter)
    end

    Tmux->>Copilot: Input forwarded
    Copilot-->>Tmux: Processing...
    API-->>Browser: 200 OK { success: true }
```

**コンテナ内の動作**: `containerId` が `undefined` の場合、`execFileSync("tmux", ...)` で
ローカル tmux に直接送信。Docker exec 経由の送信はスキップ。既存ロジックがそのまま動作する。

---

## 5. Copilot CLI セッションライフサイクル（コンテナ内）

```mermaid
stateDiagram-v2
    [*] --> ContainerStart : docker compose up

    state ContainerStart {
        [*] --> TiniInit : tini (PID 1)
        TiniInit --> StartViewer : start-viewer.sh
        StartViewer --> TmuxReady : tmux session created
    }

    TmuxReady --> ViewerRunning : viewer window: node server.js
    TmuxReady --> CopilotReady : copilot window: interactive shell

    state CopilotReady {
        [*] --> WaitingForUser : copilot window idle
        WaitingForUser --> CopilotRunning : user runs "cplt" or "copilot ..."
        CopilotRunning --> Working : session.init event
        Working --> AskUserWaiting : ask_user tool call
        AskUserWaiting --> Working : user responds via viewer UI
        Working --> Idle : processing complete
        Idle --> Working : user sends new message
        Working --> SessionEnd : session.shutdown event
        SessionEnd --> WaitingForUser : ready for next session
    }

    ViewerRunning --> ViewerRunning : serves HTTP requests

    state ViewerDetection {
        ViewerRunning --> DetectSessions : GET /api/active-sessions
        DetectSessions --> LocalTmuxScan : ps + tmux list-panes
        LocalTmuxScan --> MatchLockFiles : PID → session-state
        MatchLockFiles --> ReturnSessions : ActiveSession[]
    }

    ContainerStart --> [*] : docker compose down
```

---

## 6. ビルドフロー

```mermaid
flowchart TD
    subgraph Layer1["Layer 1: ベースイメージ (devcontainer)"]
        A["devcontainer.json"]
        B["mcr.microsoft.com/devcontainers/javascript-node:22"]
        C["features: git, github-cli, copilot-cli,<br/>playwright, tmux-apt-get, ripgrep"]
        D["devcontainer build<br/>→ copilot-session-viewer:base"]
        A --> B --> C --> D
    end

    subgraph Layer2["Layer 2: アプリ層 (Dockerfile)"]
        E["FROM copilot-session-viewer:base"]
        F["Install tini + tmux 3.6a ソースビルド"]
        G["COPY Next.js standalone + static + public"]
        H["COPY scripts/start-viewer.sh + cplt"]
        I["ENTRYPOINT: tini -- start-viewer"]
        E --> F --> G --> H --> I
    end

    subgraph HostBuild["ホスト側ビルド (事前実行)"]
        J["npm ci"]
        K["next build (output: standalone)"]
        J --> K
    end

    Layer1 --> Layer2
    HostBuild --> G
```

> **NOTE**: Next.js の standalone ビルドはホスト側（またはCI）で事前に実行し、
> アプリ層 Dockerfile では COPY のみ行う。ベースイメージの再ビルドは features 変更時のみ。

---

## 7. ローカル開発フロー（非コンテナ）

```mermaid
sequenceDiagram
    participant User as User
    participant Shell as Terminal
    participant Next as Next.js Dev Server
    participant Term as terminal.ts
    participant Tmux as Local tmux

    Note over User,Tmux: 【ローカル開発】変更なし

    User->>Shell: npm run dev
    Shell->>Next: next dev (port 3000)
    Next-->>User: http://localhost:3000

    Note over Term: DISABLE_DOCKER_DETECTION 未設定 → Docker 検出有効

    User->>Next: GET /api/active-sessions
    Next->>Term: getActiveSessions()
    Term->>Tmux: tmux list-panes -a
    Tmux-->>Term: TmuxPane[]
    Term-->>Next: ActiveSession[] (local + container if available)
    Next-->>User: JSON response
```

**重要**: ローカル開発時は `DISABLE_DOCKER_DETECTION` が未設定のため、従来通り Docker 検出も有効。
既存の動作に影響なし。

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-03-21 | 1.0 | 初版作成 | Copilot |
| 2026-03-21 | 1.1 | ビルドフローを devcontainer ベース + アプリ層の2層構成に変更 | Copilot |
