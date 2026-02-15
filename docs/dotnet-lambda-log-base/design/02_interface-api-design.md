# インターフェース / API 設計

## 公開インターフェース

### CloudWatchLoggerProvider

```csharp
namespace DotnetLambdaLogBase.Logging;

[ProviderAlias("CloudWatch")]
public sealed class CloudWatchLoggerProvider : ILoggerProvider, IAsyncDisposable
{
    public CloudWatchLoggerProvider(CloudWatchLoggerOptions options);
    public CloudWatchLoggerProvider(CloudWatchLoggerOptions options, IAmazonCloudWatchLogs client);
    
    public ILogger CreateLogger(string categoryName);
    public void Dispose();
    public ValueTask DisposeAsync();
    public Task FlushAsync(CancellationToken cancellationToken = default);
}
```

### CloudWatchLogger

```csharp
namespace DotnetLambdaLogBase.Logging;

public sealed class CloudWatchLogger : ILogger
{
    public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, 
        Exception? exception, Func<TState, Exception?, string> formatter);
    public bool IsEnabled(LogLevel logLevel);
    public IDisposable? BeginScope<TState>(TState state) where TState : notnull;
}
```

### CloudWatchLoggerOptions

```csharp
namespace DotnetLambdaLogBase.Logging;

public sealed class CloudWatchLoggerOptions
{
    /// <summary>全ログ用 CloudWatch Logs グループ名</summary>
    public string AllLogsGroupName { get; set; } = "/lambda/app/all-logs";
    
    /// <summary>異常系用 CloudWatch Logs グループ名</summary>
    public string ErrorLogsGroupName { get; set; } = "/lambda/shared/error-logs";
    
    /// <summary>全ログ用ストリームのプレフィックス</summary>
    public string AllLogsStreamPrefix { get; set; } = "";
    
    /// <summary>異常系用ストリームのプレフィックス</summary>
    public string ErrorLogsStreamPrefix { get; set; } = "";
    
    /// <summary>最小ログレベル</summary>
    public LogLevel MinimumLevel { get; set; } = LogLevel.Information;
    
    /// <summary>異常系グループに送信するログレベル閾値</summary>
    public LogLevel ErrorThresholdLevel { get; set; } = LogLevel.Error;
    
    /// <summary>バッファ最大サイズ</summary>
    public int MaxBufferSize { get; set; } = 5000;
    
    /// <summary>Lambda 関数名（ストリーム名に使用）</summary>
    public string? FunctionName { get; set; }
}
```

### DI 拡張メソッド

```csharp
namespace DotnetLambdaLogBase.Logging;

public static class LoggingServiceCollectionExtensions
{
    public static ILoggingBuilder AddCloudWatchLogger(
        this ILoggingBuilder builder, 
        Action<CloudWatchLoggerOptions> configure);
    
    public static ILoggingBuilder AddCloudWatchLogger(
        this ILoggingBuilder builder, 
        Action<CloudWatchLoggerOptions> configure,
        IAmazonCloudWatchLogs client);
}
```

## 内部インターフェース

### ILogSender

```csharp
namespace DotnetLambdaLogBase.Logging;

internal interface ILogSender
{
    Task SendAsync(IReadOnlyList<LogEntry> entries, string logGroupName, 
        string logStreamName, CancellationToken cancellationToken = default);
    Task EnsureLogStreamExistsAsync(string logGroupName, string logStreamName, 
        CancellationToken cancellationToken = default);
}
```

### ILogFormatter

```csharp
namespace DotnetLambdaLogBase.Logging;

internal interface ILogFormatter
{
    string Format(LogEntry entry);
}
```

## エラーハンドリング方針

| エラー種別 | 対応 |
|------------|------|
| PutLogEvents 失敗 | Console.Error に出力してフォールバック、例外を飲む |
| CreateLogStream 失敗 | ResourceAlreadyExistsException は無視、それ以外はフォールバック |
| バッファオーバーフロー | 最古のエントリを破棄（ログ警告出力） |
| シリアライゼーション失敗 | エントリをスキップ、エラーをコンソール出力 |
