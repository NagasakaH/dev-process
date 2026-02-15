# 統合ポイント調査

## AWS サービス統合

### CloudWatch Logs との統合

```mermaid
sequenceDiagram
    participant L as Lambda Function
    participant P as CloudWatchLoggerProvider
    participant B as LogBuffer
    participant S as CloudWatchLogSender
    participant CW1 as CW Logs (All - Delivery)
    participant CW2 as CW Logs (Error - Standard)
    participant S3 as S3 Bucket

    L->>P: ILogger.Log()
    P->>B: Add(LogEntry)
    
    Note over B: バッファが一定量に達した場合
    B->>S: Flush() → List<LogEntry>

    S->>CW1: PutLogEvents (全ログ)
    S->>CW2: PutLogEvents (Error以上のみ)

    Note over CW1: Delivery Class
    CW1-->>S3: 自動配信

    Note over L: Lambda 終了時
    L->>P: FlushAsync()
    P->>B: Flush()
    B->>S: 残りのログ送信
    S->>CW1: PutLogEvents
    S->>CW2: PutLogEvents (Error以上)
```

### ログ振り分けロジック

| ログレベル | 全ログ用グループ | 異常系グループ |
|------------|-----------------|----------------|
| Trace | ✅ | ❌ |
| Debug | ✅ | ❌ |
| Information | ✅ | ❌ |
| Warning | ✅ | ❌ |
| Error | ✅ | ✅ |
| Critical | ✅ | ✅ |

### CloudWatch Alarm 統合

```mermaid
sequenceDiagram
    participant CW as CW Logs (Error)
    participant MF as Metric Filter
    participant A as CloudWatch Alarm
    participant SNS as SNS Topic

    CW->>MF: ログイベント受信
    MF->>A: メトリクス発行
    Note over A: 閾値超過判定
    A->>SNS: アラーム通知
```

## Flush タイミング

| タイミング | トリガー | 実装方法 |
|------------|----------|----------|
| バッファフル | バッファサイズ到達 | LogBuffer.Add() 内で自動 Flush |
| タイマー | 一定間隔経過 | Timer による定期 Flush |
| Lambda 終了 | FunctionHandler の finally | FlushAsync() 明示呼び出し |
| Dispose | IAsyncDisposable | DisposeAsync() で Flush |
