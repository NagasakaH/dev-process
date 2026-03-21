# 02. データ構造調査

## 背景

セッション管理の全データ構造を把握し、コンテナ内での `$HOME/.copilot` 分離設計に活用する。

## ファイルシステム上のデータ構造

### セッションストレージ

```
~/.copilot/
├── session-state/                    # セッションメタデータ・イベント
│   └── {session-id}/
│       ├── workspace.yaml            # Git/プロジェクトメタデータ
│       ├── events.jsonl              # セッションイベントログ (JSONL)
│       └── inuse.{PID}.lock          # プロセスロックファイル
├── logs/                             # Copilot プロセスログ
│   └── process-{timestamp}-{PID}.log
└── config.json                       # Copilot 設定
```

### パス構築パターン

```typescript
// sessions.ts, terminal.ts で共通
const SESSION_STATE_DIR = path.join(
  process.env.HOME || "~",
  ".copilot",
  "session-state"
);

const COPILOT_LOGS_DIR = path.join(
  process.env.HOME || "~",
  ".copilot",
  "logs"
);
```

**コンテナ化への影響**: `process.env.HOME` に依存しているため、コンテナ内では自動的に分離される。追加の変更は不要。

## TypeScript 型定義

### セッション関連（sessions.ts）

```mermaid
classDiagram
    class SessionMeta {
        +string id
        +string cwd
        +string git_root
        +string repository
        +string branch
        +string host_type
        +string summary
        +number summary_count
        +string created_at
        +string updated_at
    }

    class SessionDetail {
        +SessionMeta meta
        +ConversationEntry[] conversation
        +ToolExecution[] toolExecutions
        +SubagentEvent[] subagents
        +SessionShutdown shutdown
        +RunningUsage runningUsage
        +ContextWindowInfo contextWindow
        +ModelChange[] modelChanges
        +string currentIntent
        +TodoItem[] todos
        +SessionStats stats
    }

    class ConversationEntry {
        +string type
        +string timestamp
        +string content
        +ToolRequest[] toolRequests
        +string reasoningText
        +string toolName
        +boolean toolSuccess
        +string agentName
    }

    class ToolRequest {
        +string toolCallId
        +string name
        +Record arguments
        +string intentionSummary
        +boolean success
        +string result
        +string errorMessage
    }

    class ToolExecution {
        +string toolCallId
        +string toolName
        +Record arguments
        +boolean success
        +string result
        +string startTimestamp
        +string endTimestamp
    }

    class SessionShutdown {
        +string shutdownType
        +number totalPremiumRequests
        +number totalApiDurationMs
        +number currentTokens
        +CodeChanges codeChanges
        +Record modelMetrics
        +string currentModel
    }

    class RunningUsage {
        +number totalOutputTokens
        +Record modelOutputTokens
        +Record modelRequestCounts
        +string currentModel
        +number premiumRequests
    }

    class ContextWindowInfo {
        +TokenSnapshot current
        +TokenBreakdown breakdown
        +CacheEfficiency cacheEfficiency
        +ContextWindowSnapshot[] history
    }

    class TodoItem {
        +string id
        +string title
        +string status
    }

    SessionDetail --> SessionMeta
    SessionDetail --> ConversationEntry
    SessionDetail --> ToolExecution
    SessionDetail --> SubagentEvent
    SessionDetail --> SessionShutdown
    SessionDetail --> RunningUsage
    SessionDetail --> ContextWindowInfo
    SessionDetail --> TodoItem
    ConversationEntry --> ToolRequest
```

### アクティブセッション関連（terminal.ts）

```mermaid
classDiagram
    class ActiveSession {
        +string id
        +string summary
        +string cwd
        +string repository
        +string branch
        +string lastActivity
        +number pid
        +string tty
        +string tmuxPane
        +string containerId
        +string containerUser
        +SessionState sessionState
        +PendingAskUser pendingAskUser
        +string currentModel
        +string currentAgent
        +string currentIntent
        +RunningTask[] runningTasks
        +Todo[] todos
    }

    class PendingAskUser {
        +string toolCallId
        +string question
        +string[] choices
        +boolean allowFreeform
        +string timestamp
    }

    class CopilotProcess {
        +number pid
        +string tty
        +string cwd
    }

    class TmuxPane {
        +string target
        +number pid
        +string tty
        +string command
    }

    class ContainerCopilotInfo {
        +string containerId
        +string containerUser
        +number pid
        +string cwd
        +string tmuxPane
    }

    ActiveSession --> PendingAskUser
    ActiveSession ..> ContainerCopilotInfo : matched from
    ActiveSession ..> CopilotProcess : matched from
    ActiveSession ..> TmuxPane : matched from
```

### セッション状態遷移

```mermaid
stateDiagram-v2
    [*] --> working : Copilot CLI 起動
    working --> ask_user_waiting : ask_user ツール呼び出し
    ask_user_waiting --> working : ユーザー応答送信
    working --> idle : 処理完了 (入力待ち)
    idle --> working : ユーザーメッセージ送信
    working --> [*] : session.shutdown イベント
    ask_user_waiting --> [*] : terminateCopilotSession()
    idle --> [*] : terminateCopilotSession()
```

## workspace.yaml フォーマット

```yaml
# ~/.copilot/session-state/{session-id}/workspace.yaml
cwd: "/path/to/project"
git_root: "/path/to/project"
repository: "org/repo-name"
branch: "feature/some-branch"
host_type: "cli"
```

## events.jsonl フォーマット

各行は JSON オブジェクト:

```jsonl
{"type":"session.init","id":"evt-1","timestamp":"2024-01-01T00:00:00Z","parentId":null,"data":{...}}
{"type":"user.message","id":"evt-2","timestamp":"...","parentId":"evt-1","data":{"content":"..."}}
{"type":"assistant.message","id":"evt-3","timestamp":"...","parentId":"evt-2","data":{"content":"...","toolRequests":[...]}}
{"type":"tool.execution","id":"evt-4","timestamp":"...","parentId":"evt-3","data":{"toolCallId":"...","toolName":"bash",...}}
{"type":"session.shutdown","id":"evt-N","timestamp":"...","parentId":null,"data":{"shutdownType":"normal",...}}
```

## コンテナ化における考慮事項

1. **`$HOME/.copilot` の分離**: コンテナ内で `HOME=/home/vscode` → 自動的に `/home/vscode/.copilot/` に分離
2. **ログファイルのアクセス**: `process-{timestamp}-{PID}.log` はコンテナ内で生成・参照完結
3. **ロックファイル**: `inuse.{PID}.lock` はコンテナ内 PID を使用するため、ホストとの衝突なし
4. **better-sqlite3**: package.json に含まれるが**未使用**。コンテナ化でのネイティブビルド懸念は現時点で影響なし
