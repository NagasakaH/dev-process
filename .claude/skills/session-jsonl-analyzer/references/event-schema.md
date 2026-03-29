# イベントスキーマリファレンス

セッションJSONL (`events.jsonl`) の各イベント型の詳細スキーマ。

## 共通構造

すべてのイベントは以下の共通フィールドを持つ:

```json
{
  "type": "イベント型",
  "data": { ... },
  "id": "uuid-string",
  "timestamp": "ISO 8601形式のタイムスタンプ",
  "parentId": "uuid-string or null"
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `type` | string | イベント型識別子 |
| `data` | object | イベント型固有のデータ |
| `id` | string (UUID) | イベントの一意識別子 |
| `timestamp` | string | イベント発生時刻（ISO 8601） |
| `parentId` | string (UUID) \| null | 因果関係の親イベントID。ルートイベントでは `null` |

## イベント型別スキーマ

### session.start

セッション開始時に記録される。セッションの識別と環境情報を含む。

```json
{
  "type": "session.start",
  "timestamp": "2025-01-01T00:00:00.000Z",
  "data": {
    "sessionId": "uuid-string",
    "copilotVersion": "x.y.z",
    "context": {
      "cwd": "/path/to/working/directory",
      "os": "Darwin",
      "shell": "/bin/zsh"
    }
  }
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `data.sessionId` | string | セッション固有のUUID |
| `data.copilotVersion` | string | Copilot CLIのバージョン |
| `data.context` | object | 実行環境情報（cwd, OS, shell等） |

### session.shutdown

セッション終了時に記録される。

```json
{
  "type": "session.shutdown",
  "timestamp": "2025-01-01T01:00:00.000Z",
  "data": {}
}
```

### session.plan_changed

プランの変更が発生した際に記録される。

```json
{
  "type": "session.plan_changed",
  "timestamp": "2025-01-01T00:10:00.000Z",
  "data": {
    "plan": "プラン内容"
  }
}
```

### user.message

ユーザーからの入力メッセージ。

```json
{
  "type": "user.message",
  "timestamp": "2025-01-01T00:01:00.000Z",
  "data": {
    "content": "ユーザーの入力テキスト",
    "role": "user"
  }
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `data.content` | string | ユーザーの入力内容 |
| `data.role` | string | メッセージロール (`user`) |

### assistant.message

アシスタントの応答メッセージ。ツール呼び出し要求を含む場合がある。

```json
{
  "type": "assistant.message",
  "timestamp": "2025-01-01T00:01:05.000Z",
  "data": {
    "content": "アシスタントの応答テキスト",
    "role": "assistant",
    "toolRequests": [
      {
        "toolCallId": "tooluse_xxx",
        "name": "bash",
        "arguments": { ... },
        "type": "function"
      }
    ]
  }
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `data.content` | string | アシスタントの応答テキスト |
| `data.role` | string | メッセージロール (`assistant`) |
| `data.toolRequests` | array | ツール呼び出し要求のリスト（省略可） |

### assistant.turn_start

アシスタントのターン開始。

```json
{
  "type": "assistant.turn_start",
  "timestamp": "2025-01-01T00:01:00.000Z",
  "data": {}
}
```

### assistant.turn_end

アシスタントのターン終了。

```json
{
  "type": "assistant.turn_end",
  "timestamp": "2025-01-01T00:02:00.000Z",
  "data": {}
}
```

### tool.execution_start

ツール実行の開始。ツール名と引数を含む。

```json
{
  "type": "tool.execution_start",
  "timestamp": "2025-01-01T00:01:10.000Z",
  "data": {
    "toolCallId": "tooluse_xxx",
    "toolName": "skill",
    "arguments": {
      "skill": "project-state"
    }
  }
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `data.toolCallId` | string | ツール呼び出しの一意識別子 |
| `data.toolName` | string | 実行されたツール名 |
| `data.arguments` | object | ツールに渡された引数 |

### tool.execution_complete

ツール実行の完了。成功/失敗と結果を含む。

成功時:

```json
{
  "type": "tool.execution_complete",
  "data": {
    "toolCallId": "tooluse_xxx",
    "model": "claude-sonnet-4.5",
    "interactionId": "uuid-string",
    "success": true,
    "result": {
      "content": "ツール実行結果（短縮版）",
      "detailedContent": "ツール実行結果（詳細版）"
    },
    "toolTelemetry": {}
  },
  "id": "uuid-string",
  "timestamp": "2025-01-01T00:01:15.000Z",
  "parentId": "uuid-string"
}
```

失敗時:

```json
{
  "type": "tool.execution_complete",
  "data": {
    "toolCallId": "tooluse_xxx",
    "model": "claude-sonnet-4.5",
    "interactionId": "uuid-string",
    "success": false,
    "error": {
      "message": "エラーメッセージ",
      "code": "failure"
    }
  },
  "id": "uuid-string",
  "timestamp": "2025-01-01T00:01:15.000Z",
  "parentId": "uuid-string"
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `data.toolCallId` | string | 対応する `tool.execution_start` の `toolCallId` |
| `data.model` | string | 使用されたモデル名 |
| `data.interactionId` | string (UUID) | インタラクション識別子 |
| `data.success` | boolean | 実行成功: `true` / 失敗: `false` |
| `data.result` | object | 成功時のツール実行結果 |
| `data.result.content` | string | 結果の短縮表示 |
| `data.result.detailedContent` | string | 結果の詳細内容 |
| `data.error` | object | 失敗時のエラー情報 |
| `data.error.message` | string | エラーメッセージ |
| `data.error.code` | string | エラーコード（例: `"failure"`） |
| `data.toolTelemetry` | object | ツールのテレメトリ情報（省略可） |
| `data.parentToolCallId` | string | サブエージェント内での実行時、親のツール呼び出しID（省略可） |

### subagent.started

サブエージェントの開始。

```json
{
  "type": "subagent.started",
  "data": {
    "toolCallId": "tooluse_xxx",
    "agentName": "general-purpose",
    "agentDisplayName": "General Purpose Agent",
    "agentDescription": "エージェントの説明文"
  },
  "id": "uuid-string",
  "timestamp": "2025-01-01T00:05:00.000Z",
  "parentId": "uuid-string"
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `data.toolCallId` | string | サブエージェントを起動したツール呼び出しID |
| `data.agentName` | string | エージェント種別名（`general-purpose`, `explore` 等） |
| `data.agentDisplayName` | string | エージェントの表示名 |
| `data.agentDescription` | string | エージェントの説明文 |

### subagent.completed

サブエージェントの完了。実行結果は対応する `tool.execution_complete` イベントに記録される。

```json
{
  "type": "subagent.completed",
  "data": {
    "toolCallId": "tooluse_xxx",
    "agentName": "general-purpose",
    "agentDisplayName": "General Purpose Agent"
  },
  "id": "uuid-string",
  "timestamp": "2025-01-01T00:10:00.000Z",
  "parentId": "uuid-string"
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `data.toolCallId` | string | 対応する `subagent.started` の `toolCallId` |
| `data.agentName` | string | エージェント種別名 |
| `data.agentDisplayName` | string | エージェントの表示名 |

### skill.invoked

スキルが発動された際に記録される。スキルの名前・パス・内容・説明を含む。

```json
{
  "type": "skill.invoked",
  "data": {
    "name": "project-state",
    "path": "/path/to/.claude/skills/project-state/SKILL.md",
    "content": "スキルファイルの全内容",
    "description": "スキルの説明文"
  },
  "id": "uuid-string",
  "timestamp": "2025-01-01T00:01:00.000Z",
  "parentId": "uuid-string"
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `data.name` | string | スキル名 |
| `data.path` | string | SKILL.md ファイルの絶対パス |
| `data.content` | string | スキルファイルの全内容 |
| `data.description` | string | スキルの説明文 |

### hook.start

フック実行の開始。

```json
{
  "type": "hook.start",
  "timestamp": "2025-01-01T00:01:00.000Z",
  "data": {
    "hookName": "フック名"
  }
}
```

### hook.end

フック実行の完了。

```json
{
  "type": "hook.end",
  "timestamp": "2025-01-01T00:01:05.000Z",
  "data": {
    "hookName": "フック名",
    "success": true
  }
}
```

### system.notification

システムからの通知。

```json
{
  "type": "system.notification",
  "timestamp": "2025-01-01T00:15:00.000Z",
  "data": {
    "message": "通知メッセージ"
  }
}
```

### abort

セッションの中断。

```json
{
  "type": "abort",
  "timestamp": "2025-01-01T00:20:00.000Z",
  "data": {}
}
```

## イベント間の関係性

### toolCallId による対応付け

`tool.execution_start` と `tool.execution_complete` は `toolCallId` で紐づく:

```
tool.execution_start  (toolCallId: "tooluse_abc") → ツール実行開始
tool.execution_complete (toolCallId: "tooluse_abc") → 同一ツール実行の完了
```

### toolCallId によるサブエージェント対応付け

`subagent.started` / `subagent.completed` の `toolCallId` は、サブエージェントを起動したツール呼び出しIDを示す:

```
tool.execution_start (toolCallId: "tooluse_xyz", toolName: "task")
  └── subagent.started (toolCallId: "tooluse_xyz")
      └── subagent.completed (toolCallId: "tooluse_xyz")
```

サブエージェント内のツール実行は `parentToolCallId` で親を参照する:

```
subagent.started (toolCallId: "tooluse_xyz")
  ├── tool.execution_start (toolCallId: "tooluse_child1")
  ├── tool.execution_complete (toolCallId: "tooluse_child1", parentToolCallId: "tooluse_xyz")
  └── ...
subagent.completed (toolCallId: "tooluse_xyz")
```

### ターンの構造

```
assistant.turn_start
  ├── assistant.message (toolRequests を含む場合がある)
  ├── tool.execution_start
  ├── tool.execution_complete
  └── ...
assistant.turn_end
```

一つのターン内で複数のツール呼び出しが並列実行される場合がある。
