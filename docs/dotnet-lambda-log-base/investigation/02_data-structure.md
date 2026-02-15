# データ構造調査

## LogEntry（ログエントリモデル）

```mermaid
classDiagram
    class LogEntry {
        +DateTime Timestamp
        +LogLevel Level
        +string Category
        +string Message
        +string? ExceptionDetail
        +Dictionary~string,object~? Properties
    }

    class CloudWatchLoggerOptions {
        +string AllLogsGroupName
        +string ErrorLogsGroupName
        +string? FunctionName
        +LogLevel MinimumLevel
        +LogLevel ErrorGroupMinimumLevel
        +int MaxBufferSize
    }

    class LogBuffer {
        -ConcurrentQueue~LogEntry~ _queue
        -int _maxSize
        +int Count
        +Add(LogEntry)
        +List~LogEntry~ Drain()
        +Clear()
    }

    class CloudWatchLogger {
        -string _category
        -LogBuffer _buffer
        -CloudWatchLoggerOptions _options
        +IsEnabled(LogLevel) bool
        +Log(LogLevel, EventId, TState, Exception, Func)
    }

    class CloudWatchLoggerProvider {
        -CloudWatchLoggerOptions _options
        -ILogSender _sender
        -LogBuffer _buffer
        -string _logStreamName
        +CreateLogger(string) ILogger
        +FlushAsync() Task
    }

    class CloudWatchLogSender {
        -IAmazonCloudWatchLogs _client
        -ILogFormatter _formatter
        +SendAsync(entries, group, stream) Task
        +EnsureLogStreamExistsAsync(group, stream) Task
        -SplitIntoBatches(events) List
        -TruncateUtf8(input, maxBytes) string
    }

    class JsonLogFormatter {
        -JsonSerializerOptions s_options
        +Format(LogEntry) string
    }

    CloudWatchLoggerProvider --> CloudWatchLogger : creates
    CloudWatchLoggerProvider --> LogBuffer : owns
    CloudWatchLoggerProvider --> CloudWatchLogSender : uses
    CloudWatchLogger --> LogBuffer : writes to
    CloudWatchLogSender --> JsonLogFormatter : uses
    LogBuffer --> LogEntry : stores
```

## JSON 出力フォーマット

```json
{
  "timestamp": "2026-02-15T06:00:00.0000000Z",
  "level": "Error",
  "category": "DotnetLambdaLogBase.Function",
  "message": "Error processing request: abc-123",
  "exception": "System.InvalidOperationException: ...",
  "properties": { "key": "value" }
}
```

## PutLogEvents API 制約

| 制限 | 値 | 対応方法 |
|---|---|---|
| バッチサイズ | 最大 1 MB | `SplitIntoBatches` で自動分割 |
| バッチイベント数 | 最大 10,000 件 | `SplitIntoBatches` で自動分割 |
| 個別イベントサイズ | 最大 256 KB | `TruncateUtf8` で UTF-8 安全に切り詰め |
| イベントオーバーヘッド | 26 bytes/イベント | バッチサイズ計算に含める |
