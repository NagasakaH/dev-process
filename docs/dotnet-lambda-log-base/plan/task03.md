# タスク: task03 - CloudWatchLogSender 実装

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task03 |
| タスク名 | CloudWatchLogSender 実装 |
| 前提条件タスク | task02-01, task02-02 |
| 並列実行可否 | 不可 |
| 推定所要時間 | 15分 |

## 作業内容

### 目的

AWS SDK を使用して CloudWatch Logs にログを送信するコンポーネントを実装する。

### 設計参照

- [design/02_interface-api-design.md](../design/02_interface-api-design.md) - ILogSender
- [design/04_process-flow-design.md](../design/04_process-flow-design.md) - エラーハンドリングフロー

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `src/DotnetLambdaLogBase.Logging/ILogSender.cs` | 新規作成 | 送信インターフェース |
| `src/DotnetLambdaLogBase.Logging/CloudWatchLogSender.cs` | 新規作成 | 送信実装 |
| `tests/.../CloudWatchLogSenderTests.cs` | 新規作成 | テスト |

## テスト方針（TDD: RED-GREEN-REFACTOR）

### RED: 失敗するテストケース

```csharp
public class CloudWatchLogSenderTests
{
    private readonly Mock<IAmazonCloudWatchLogs> _mockClient = new();

    [Fact]
    public async Task SendAsync_WithEntries_CallsPutLogEvents()
    {
        _mockClient.Setup(c => c.PutLogEventsAsync(It.IsAny<PutLogEventsRequest>(), default))
            .ReturnsAsync(new PutLogEventsResponse());
        var sender = new CloudWatchLogSender(_mockClient.Object);
        var entries = new List<LogEntry> { CreateInfoEntry() };

        await sender.SendAsync(entries, "/test/group", "test-stream");

        _mockClient.Verify(c => c.PutLogEventsAsync(It.IsAny<PutLogEventsRequest>(), default), Times.Once);
    }

    [Fact]
    public async Task SendAsync_EmptyList_DoesNotCallApi()
    {
        var sender = new CloudWatchLogSender(_mockClient.Object);
        await sender.SendAsync(new List<LogEntry>(), "/test/group", "test-stream");
        _mockClient.Verify(c => c.PutLogEventsAsync(It.IsAny<PutLogEventsRequest>(), default), Times.Never);
    }

    [Fact]
    public async Task SendAsync_ApiFailure_DoesNotThrow()
    {
        _mockClient.Setup(c => c.PutLogEventsAsync(It.IsAny<PutLogEventsRequest>(), default))
            .ThrowsAsync(new AmazonCloudWatchLogsException("error"));
        var sender = new CloudWatchLogSender(_mockClient.Object);
        var entries = new List<LogEntry> { CreateInfoEntry() };

        var ex = await Record.ExceptionAsync(() => sender.SendAsync(entries, "/test/group", "test-stream"));
        Assert.Null(ex);
    }

    [Fact]
    public async Task EnsureLogStreamExistsAsync_CallsCreateLogStream()
    {
        _mockClient.Setup(c => c.CreateLogStreamAsync(It.IsAny<CreateLogStreamRequest>(), default))
            .ReturnsAsync(new CreateLogStreamResponse());
        var sender = new CloudWatchLogSender(_mockClient.Object);

        await sender.EnsureLogStreamExistsAsync("/test/group", "test-stream");

        _mockClient.Verify(c => c.CreateLogStreamAsync(It.IsAny<CreateLogStreamRequest>(), default), Times.Once);
    }

    [Fact]
    public async Task EnsureLogStreamExistsAsync_AlreadyExists_IgnoresException()
    {
        _mockClient.Setup(c => c.CreateLogStreamAsync(It.IsAny<CreateLogStreamRequest>(), default))
            .ThrowsAsync(new ResourceAlreadyExistsException("exists"));
        var sender = new CloudWatchLogSender(_mockClient.Object);

        var ex = await Record.ExceptionAsync(() => sender.EnsureLogStreamExistsAsync("/test/group", "test-stream"));
        Assert.Null(ex);
    }
}
```

## 完了条件

- [ ] ILogSender インターフェースが定義されていること
- [ ] CloudWatchLogSender が PutLogEvents でバッチ送信すること
- [ ] 送信失敗時に例外を飲んでフォールバックすること
- [ ] ResourceAlreadyExistsException を無視すること
- [ ] テスト UT-19〜UT-23 が全て通過すること
