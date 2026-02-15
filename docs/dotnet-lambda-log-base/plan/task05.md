# タスク: task05 - Lambda ハンドラーテンプレート + Flush 統合

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task05 |
| タスク名 | Lambda ハンドラーテンプレート + Flush 統合 |
| 前提条件タスク | task04 |
| 並列実行可否 | 不可 |
| 推定所要時間 | 10分 |

## 作業内容

### 目的

Lambda 関数のテンプレートハンドラーを作成し、ログプロバイダーとの統合と確実な Flush を実装する。

### 設計参照

- [design/04_process-flow-design.md](../design/04_process-flow-design.md) - Lambda ライフサイクル

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `src/DotnetLambdaLogBase/Function.cs` | 新規作成 | Lambda ハンドラー |
| `src/DotnetLambdaLogBase/aws-lambda-tools-defaults.json` | 新規作成 | Lambda ツール設定 |

## 実装ステップ

1. `Function.cs` に Lambda ハンドラーのテンプレートを作成
2. DI で CloudWatchLoggerProvider を登録
3. try-finally で FlushAsync を確実に呼び出し
4. `aws-lambda-tools-defaults.json` を作成

### テンプレートコード

```csharp
public class Function
{
    private readonly ServiceProvider _serviceProvider;
    private readonly ILogger<Function> _logger;

    public Function()
    {
        _serviceProvider = new ServiceCollection()
            .AddLogging(builder =>
            {
                builder.AddCloudWatchLogger(options =>
                {
                    options.AllLogsGroupName = Environment.GetEnvironmentVariable("ALL_LOGS_GROUP") 
                        ?? "/lambda/app/all-logs";
                    options.ErrorLogsGroupName = Environment.GetEnvironmentVariable("ERROR_LOGS_GROUP") 
                        ?? "/lambda/shared/error-logs";
                    options.FunctionName = Environment.GetEnvironmentVariable("AWS_LAMBDA_FUNCTION_NAME");
                });
            })
            .BuildServiceProvider();

        _logger = _serviceProvider.GetRequiredService<ILogger<Function>>();
    }

    public async Task<string> FunctionHandler(object input, ILambdaContext context)
    {
        try
        {
            _logger.LogInformation("Processing request: {RequestId}", context.AwsRequestId);
            // ビジネスロジックをここに実装
            _logger.LogInformation("Request completed: {RequestId}", context.AwsRequestId);
            return "OK";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing request: {RequestId}", context.AwsRequestId);
            throw;
        }
        finally
        {
            await _serviceProvider.DisposeAsync();
        }
    }
}
```

## 完了条件

- [ ] Function.cs が Lambda ハンドラーパターンに準拠していること
- [ ] DI で CloudWatchLoggerProvider が登録されていること
- [ ] try-finally で DisposeAsync（Flush 含む）が確実に呼ばれること
- [ ] 環境変数からロググループ名を取得できること
- [ ] `dotnet build` が成功すること
