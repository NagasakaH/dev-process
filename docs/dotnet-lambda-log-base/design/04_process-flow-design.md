# 処理フロー設計

## メイン処理フロー

```mermaid
sequenceDiagram
    participant LH as Lambda Handler
    participant DI as ServiceProvider
    participant LP as CloudWatchLoggerProvider
    participant LG as CloudWatchLogger
    participant BF as LogBuffer
    participant FT as JsonLogFormatter
    participant LS as CloudWatchLogSender
    participant CW1 as CW Logs (All - Delivery)
    participant CW2 as CW Logs (Error - Standard)

    Note over LH,CW2: Lambda 初期化フェーズ
    LH->>DI: BuildServiceProvider()
    DI->>LP: new CloudWatchLoggerProvider(options)
    LP->>BF: new LogBuffer(maxSize)
    LP->>LS: new CloudWatchLogSender(client, options)
    DI-->>LH: ILogger<Function>

    Note over LH,CW2: リクエスト処理フェーズ
    LH->>LG: LogInformation("Processing...")
    LG->>FT: Format(entry)
    FT-->>LG: JSON string
    LG->>BF: Add(logEntry)

    LH->>LG: LogError(ex, "Error occurred")
    LG->>FT: Format(entry)
    LG->>BF: Add(logEntry)

    Note over LH,CW2: Flush フェーズ（Lambda 終了時）
    LH->>LP: FlushAsync()
    LP->>BF: Drain()
    BF-->>LP: List<LogEntry>

    LP->>LS: SendAsync(allEntries, allLogsGroup)
    LS->>CW1: PutLogEvents

    LP->>LS: SendAsync(errorEntries, errorLogsGroup)
    LS->>CW2: PutLogEvents
```

## ログ振り分けフロー

```mermaid
flowchart TD
    A[LogEntry 受信] --> B{Level >= MinimumLevel?}
    B -->|No| C[破棄]
    B -->|Yes| D[LogBuffer に追加]
    D --> E[Flush 実行時]
    E --> F[全エントリを Drain]
    F --> G[全ログ用グループに送信]
    F --> H{Level >= ErrorThreshold?}
    H -->|Yes| I[異常系グループにも送信]
    H -->|No| J[スキップ]
```

## エラーハンドリングフロー

```mermaid
flowchart TD
    A[PutLogEvents 呼び出し] --> B{成功?}
    B -->|Yes| C[完了]
    B -->|No| D{リトライ可能?}
    D -->|Yes| E[1回リトライ]
    E --> F{成功?}
    F -->|Yes| C
    F -->|No| G[Console.Error に出力]
    D -->|No| G
    G --> H[処理続行<br/>例外は飲む]
```

## Lambda ライフサイクルとの統合

```mermaid
stateDiagram-v2
    [*] --> Init: Lambda コールドスタート
    Init --> Ready: ServiceProvider 構築完了
    Ready --> Processing: リクエスト受信
    Processing --> Processing: ログ出力 → バッファ追加
    Processing --> Flushing: try-finally の finally
    Flushing --> Ready: FlushAsync 完了
    Ready --> [*]: Lambda シャットダウン
    
    note right of Flushing
        全バッファをDrain
        All Logs グループに送信
        Error ログを異常系グループに送信
    end note
```

## ストリーム名生成ロジック

```
パターン: {yyyy/MM/dd}/{FunctionName}/{Guid}
例: 2026/02/15/my-function/a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

- 日付プレフィックスで CloudWatch Logs コンソールでの視認性向上
- Guid で Lambda 実行インスタンスごとの一意性確保
- 同一ストリームへの並列書き込みを回避
