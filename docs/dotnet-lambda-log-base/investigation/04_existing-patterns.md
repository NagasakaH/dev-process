# 既存パターン調査

## .NET Lambda プロジェクトの標準パターン

### Lambda ハンドラーパターン

```csharp
public class Function
{
    private readonly ILogger<Function> _logger;

    public Function()
    {
        // DI コンテナの構築
        var serviceProvider = new ServiceCollection()
            .AddLogging(builder => builder.AddCloudWatchLogger(options => {
                options.AllLogsGroupName = "/lambda/app/all-logs";
                options.ErrorLogsGroupName = "/lambda/shared/error-logs";
            }))
            .BuildServiceProvider();

        _logger = serviceProvider.GetRequiredService<ILogger<Function>>();
    }

    public async Task<string> FunctionHandler(object input, ILambdaContext context)
    {
        _logger.LogInformation("Processing request: {RequestId}", context.AwsRequestId);
        try
        {
            // ビジネスロジック
            return "Success";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing request");
            throw;
        }
        finally
        {
            // Lambda 終了前の確実な Flush
            await FlushLogsAsync();
        }
    }
}
```

### ILoggerProvider 実装パターン

```csharp
[ProviderAlias("CloudWatch")]
public class CloudWatchLoggerProvider : ILoggerProvider, IAsyncDisposable
{
    public ILogger CreateLogger(string categoryName)
    {
        return new CloudWatchLogger(categoryName, _buffer, _options);
    }

    public async ValueTask DisposeAsync()
    {
        await FlushAsync();
    }
}
```

### テストパターン

```csharp
public class CloudWatchLoggerTests
{
    [Fact]
    public void Log_WithInformationLevel_AddsToBuffer()
    {
        // Arrange
        var buffer = new LogBuffer(100);
        var logger = new CloudWatchLogger("TestCategory", buffer, options);

        // Act
        logger.LogInformation("Test message");

        // Assert
        Assert.Equal(1, buffer.Count);
    }
}
```

## コーディング規約

- C# 12 / .NET 8 の言語機能を活用
- nullable reference types 有効
- file-scoped namespace 使用
- primary constructor 使用（適切な場合）
- async/await パターンの徹底
