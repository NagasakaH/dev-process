# 05. 統合ポイント調査

## 背景

コンテナ化で変更が必要な外部システムとの接点を特定する。特に Docker 検出ロジックの無効化範囲と start-copilot API の変更範囲を明確化する。

## Docker 検出ロジック（terminal.ts）

### 全体フロー

```mermaid
sequenceDiagram
    participant API as API Route<br/>(active-sessions)
    participant T as terminal.ts<br/>(getActiveSessions)
    participant PS as ps command<br/>(local)
    participant Tmux as tmux CLI<br/>(local)
    participant Docker as docker CLI
    participant Container as Docker Container

    API->>T: getActiveSessions()
    
    par Local Detection
        T->>PS: ps -eo pid,tty,command | grep copilot
        PS-->>T: CopilotProcess[]
        T->>Tmux: tmux list-panes -a
        Tmux-->>T: TmuxPane[]
    and Docker Detection
        T->>Docker: docker ps --format '{{.ID}}'
        Docker-->>T: container IDs
        loop Each Container
            T->>Docker: docker exec {cid} ps -eo pid,tty,command
            Docker->>Container: Execute ps
            Container-->>Docker: process list
            Docker-->>T: copilot processes
            T->>Docker: docker exec {cid} find /tmp -name 'tmux-*'
            Docker->>Container: Find tmux sockets
            Container-->>T: tmux dirs
            T->>Docker: docker exec -u {uid} {cid} tmux list-panes -a
            Docker->>Container: List panes
            Container-->>T: TmuxPane[]
            T->>Docker: docker exec {cid} readlink /proc/{pid}/cwd
            Docker->>Container: Get CWD
            Container-->>T: working directory
        end
    end

    T->>T: Match sessions (PID + lock files)
    T-->>API: ActiveSession[]
```

### 無効化の影響範囲

Docker 検出を無効化するために変更が必要な関数:

| 関数 | 行数 | 説明 | 無効化方法 |
|------|------|------|----------|
| `findDockerContainers()` | L126-137 | `docker ps` でコンテナ ID 一覧取得 | 環境変数チェックで空配列返却 |
| `findContainerCopilotSessions()` | L139-226 | コンテナ内 Copilot セッション検出 | 上記に依存（自動無効化） |
| `getActiveSessions()` | L421-551 | メイン検出関数（ローカル + コンテナ統合） | コンテナ部分スキップ |

### 推奨実装

```typescript
// 環境変数による Docker 検出無効化
const DISABLE_DOCKER_DETECTION = 
  process.env.DISABLE_DOCKER_DETECTION?.trim() === "true";

function findDockerContainers(): string[] {
  if (DISABLE_DOCKER_DETECTION) return [];
  // ... existing logic
}
```

## ローカル tmux 検出（terminal.ts）

### フロー

```mermaid
sequenceDiagram
    participant T as terminal.ts
    participant PS as ps command
    participant Tmux as tmux CLI
    participant FS as File System

    T->>PS: ps -eo pid,tty,command | grep copilot
    PS-->>T: pid, tty, command
    T->>T: Extract PID, TTY from output
    
    loop Each copilot process
        T->>FS: readlink /proc/{pid}/cwd
        FS-->>T: working directory (CWD)
    end

    T->>Tmux: tmux list-panes -a -F '...'
    Tmux-->>T: session:window.pane pid tty command

    T->>T: Match process to pane by TTY
    T->>FS: Read ~/.copilot/session-state/
    FS-->>T: Session directories + lock files

    T->>T: Match lock PID to process PID
    T-->>T: ActiveSession[] (local only)
```

**コンテナ内での動作**: そのまま動作する。tmux がコンテナ内で起動していれば、ローカルと同じロジックで検出可能。

## start-copilot API（dev-process/start-copilot/route.ts）

### 現在のフロー

```mermaid
sequenceDiagram
    participant Client as Browser
    participant API as start-copilot API
    participant Docker as docker CLI
    participant Container as Dev Container
    participant Git as git CLI

    Note over Client,Git: GET: 現在の状態取得
    Client->>API: GET /api/dev-process/start-copilot
    API->>API: getConfig() - ENABLE_DEV_PROCESS check
    API->>Docker: docker ps --filter name=^{container}$
    Docker-->>API: container status
    API->>Docker: docker exec ... tmux list-sessions
    Docker-->>API: tmux sessions
    API-->>Client: { enabled, containerRunning, agents[], ... }

    Note over Client,Git: POST: Copilot セッション開始
    Client->>API: POST { model, agent, branchName, worktreePath }
    API->>API: getConfig() check
    
    alt Worktree 作成が必要
        API->>Docker: docker exec git worktree add
        Docker->>Container: Create worktree
        Container-->>API: worktree path
    end

    API->>Docker: docker exec tmux new-window -n copilot
    Docker->>Container: Create tmux window
    API->>Docker: docker exec tmux send-keys 'cd {path} && cplt ...'
    Docker->>Container: Start copilot in tmux

    opt Trust folder 設定
        API->>Docker: docker exec python3 -c '...' (config.json update)
    end

    API-->>Client: { success: true, ... }

    Note over Client,Git: DELETE: Worktree 削除
    Client->>API: DELETE { worktreePath }
    API->>Docker: docker exec git worktree remove
    Docker->>Container: Remove worktree
    API-->>Client: { success: true }
```

### コンテナ化での変更影響

start-copilot API はホスト側から別コンテナを管理するロジック。単一コンテナモードでは:

1. **コンテナ起動**: 不要（自身がコンテナ）
2. **Worktree 作成**: ローカル git 操作に変更
3. **tmux 操作**: docker exec 経由 → ローカル tmux 直接操作
4. **trust folder**: ローカルの config.json を直接更新

**推奨**: `ENABLE_DEV_PROCESS=false` で無効化し、コンテナ内では別の起動メカニズムを用意。

## 環境変数の統合マップ

```mermaid
graph TD
    subgraph EnvVars["Environment Variables"]
        HOME["HOME<br/>(system)"]
        BASIC_USER["BASIC_AUTH_USER"]
        BASIC_PASS["BASIC_AUTH_PASS"]
        ENABLE_DP["ENABLE_DEV_PROCESS"]
        DP_PATH["DEV_PROCESS_PATH"]
        DP_CMD["DEV_PROCESS_COPILOT_CMD"]
        DISABLE_DD["DISABLE_DOCKER_DETECTION<br/>(NEW - proposed)"]
    end

    subgraph Files["Source Files"]
        MW["middleware.ts"]
        SESS["sessions.ts"]
        TERM["terminal.ts"]
        SC["start-copilot/route.ts"]
        FILES["files/route.ts"]
        EVENTS["event-count/route.ts"]
    end

    HOME --> SESS
    HOME --> TERM
    HOME --> FILES
    HOME --> EVENTS
    BASIC_USER --> MW
    BASIC_PASS --> MW
    ENABLE_DP --> SC
    DP_PATH --> SC
    DP_CMD --> SC
    DISABLE_DD -.->|proposed| TERM
```

### 環境変数一覧

| 変数名 | 使用箇所 | 必須 | デフォルト | コンテナ内の値 |
|--------|---------|------|----------|-------------|
| `HOME` | sessions.ts, terminal.ts, files/route.ts, event-count/route.ts | 自動 | — | `/home/vscode` |
| `BASIC_AUTH_USER` | middleware.ts | No | なし (認証無効) | .env から注入 |
| `BASIC_AUTH_PASS` | middleware.ts | No | なし (認証無効) | .env から注入 |
| `ENABLE_DEV_PROCESS` | start-copilot/route.ts | No | `false` | `false` (無効化) |
| `DEV_PROCESS_PATH` | start-copilot/route.ts | 条件付き | `""` | 不要 |
| `DEV_PROCESS_COPILOT_CMD` | start-copilot/route.ts | No | `copilot --yolo --agent dev-workflow` | 不要 |
| `DISABLE_DOCKER_DETECTION` | terminal.ts (提案) | No | `false` | `true` |

## ユーザー入力フロー

### ask_user 応答

```mermaid
sequenceDiagram
    participant Browser as Browser
    participant API as /api/sessions/[id]/respond
    participant Terminal as terminal.ts
    participant Tmux as tmux

    Browser->>API: POST { action, choiceIndex/text }
    API->>Terminal: getActiveSessions()
    Terminal-->>API: ActiveSession (with containerId?)
    
    alt action = "choice"
        API->>Terminal: sendAskUserChoice(pane, index, containerId?)
        Terminal->>Tmux: send-keys (navigate + enter)
    else action = "freeform"
        API->>Terminal: sendAskUserFreeform(pane, text, containerId?)
        Terminal->>Tmux: send-keys (text + submit)
    else action = "text"
        API->>Terminal: sendTextInput(pane, text, containerId?)
        Terminal->>Tmux: send-keys (text + enter)
    end

    Tmux-->>Terminal: success
    Terminal-->>API: { success: true }
    API-->>Browser: 200 OK
```

**コンテナ内動作**: `containerId` が `undefined` の場合、ローカル tmux を使用するため、コンテナ内でもそのまま動作する。

## dev-process の参考実装

### Dockerfile パターン

```
Base Image (nagasakah/dev-process:base)
  └── tini (PID 1 プロセスマネージャ)
  └── tmux 3.6a (ソースビルド)
  └── Playwright (グローバルインストール)
  └── start-tmux.sh (エントリポイント)
  └── cplt (Copilot CLI ラッパー)
  └── .tmux.conf (設定)
```

### start-tmux.sh のキーパターン

1. **UID/GID 同期**: ホストのファイル所有者に合わせて vscode ユーザーを調整
2. **3 ウィンドウ作成**: editor, copilot, bash
3. **キープアライブ**: `while true; wait; sleep 60; done`
4. **PROJECT_NAME 環境変数**: tmux セッション名のカスタマイズ

### cplt のキーパターン

1. **自動 pane 分割**: 単一ペインの場合 40/60 で分割
2. **ウィンドウ名変更**: 実行中は "copilot" に変更
3. **デフォルトコマンド**: `copilot --allow-all --agent general-purpose`
