# タスク: task04 - CloudWatchLogger + Provider + DI 実装

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task04 |
| タスク名 | CloudWatchLogger + Provider + DI 実装 |
| 前提条件タスク | task03 |
| 並列実行可否 | 不可 |
| 推定所要時間 | 15分 |

## 作業内容

### 目的

ILogger / ILoggerProvider 実装と DI 拡張メソッドを作成する。Flush 時の2グループ振り分けロジックを含む。

### 設計参照

- [design/02_interface-api-design.md](../design/02_interface-api-design.md) - 全インターフェース
- [design/04_process-flow-design.md](../design/04_process-flow-design.md) - 振り分けフロー

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `src/.../CloudWatchLoggerOptions.cs` | 新規作成 | 設定オプション |
| `src/.../CloudWatchLogger.cs` | 新規作成 | ILogger 実装 |
| `src/.../CloudWatchLoggerProvider.cs` | 新規作成 | ILoggerProvider 実装 |
| `src/.../LoggingServiceCollectionExtensions.cs` | 新規作成 | DI 拡張 |
| `tests/.../CloudWatchLoggerTests.cs` | 新規作成 | テスト |
| `tests/.../CloudWatchLoggerProviderTests.cs` | 新規作成 | テスト |

## テスト方針（TDD: RED-GREEN-REFACTOR）

### RED: 失敗するテストケース

```csharp
// CloudWatchLoggerTests
public class CloudWatchLoggerTests
{
    [Fact]
    public void Log_InformationLevel_AddsToBuffer()
    {
        var buffer = new LogBuffer(100);
        var options = new CloudWatchLoggerOptions();
        var logger = new CloudWatchLogger("Test", buffer, options);
        logger.LogInformation("Hello");
        Assert.Equal(1, buffer.Count);
    }

    [Fact]
    public void Log_BelowMinimumLevel_DoesNotAddToBuffer()
    {
        var buffer = new LogBuffer(100);
        var options = new CloudWatchLoggerOptions { MinimumLevel = LogLevel.Warning };
        var logger = new CloudWatchLogger("Test", buffer, options);
        logger.LogInformation("Hello");
        Assert.Equal(0, buffer.Count);
    }

    [Fact]
    public void IsEnabled_AboveMinimum_ReturnsTrue()
    {
        var options = new CloudWatchLoggerOptions { MinimumLevel = LogLevel.Information };
        var logger = new CloudWatchLogger("Test", new LogBuffer(100), options);
        Assert.True(logger.IsEnabled(LogLevel.Warning));
    }

    [Fact]
    public void IsEnabled_BelowMinimum_ReturnsFalse()
    {
        var options = new CloudWatchLoggerOptions { MinimumLevel = LogLevel.Warning };
        var logger = new CloudWatchLogger("Test", new LogBuffer(100), options);
        Assert.False(logger.IsEnabled(LogLevel.Information));
    }
}

// CloudWatchLoggerProviderTests
public class CloudWatchLoggerProviderTests
{
    [Fact]
    public async Task FlushAsync_SendsToAllLogsGroup()
    {
        var mockSender = new Mock<ILogSender>();
        // Verify PutLogEvents called for all-logs group
    }

    [Fact]
    public async Task FlushAsync_ErrorLogs_SentToErrorGroup()
    {
        // Verify Error level logs also sent to error group
    }

    [Fact]
    public async Task FlushAsync_InfoLogs_NotSentToErrorGroup()
    {
        // Verify Info level logs NOT sent to error group
    }
}
```

## 完了条件

- [ ] CloudWatchLogger が ILogger を正しく実装していること
- [ ] CloudWatchLoggerProvider が FlushAsync で2グループに振り分けること
- [ ] Error 以上のログのみ異常系グループに送信されること
- [ ] DI 拡張メソッドで ILoggerProvider が登録できること
- [ ] テスト UT-01〜UT-07, UT-24〜UT-29 が全て通過すること
