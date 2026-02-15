# データ構造設計

## LogEntry

```csharp
namespace DotnetLambdaLogBase.Logging;

public sealed class LogEntry
{
    public required DateTime Timestamp { get; init; }
    public required LogLevel Level { get; init; }
    public required string Category { get; init; }
    public required string Message { get; init; }
    public string? TraceId { get; init; }
    public string? RequestId { get; init; }
    public string? FunctionName { get; init; }
    public Dictionary<string, object>? Properties { get; init; }
    public string? ExceptionDetail { get; init; }
}
```

## JSON 出力フォーマット

```json
{
  "timestamp": "2026-02-15T00:00:00.0000000Z",
  "level": "Information",
  "category": "MyApp.Handlers.OrderHandler",
  "message": "Processing order {OrderId}",
  "traceId": "1-abc-def",
  "requestId": "lambda-request-id-123",
  "functionName": "my-lambda-function",
  "properties": {
    "orderId": "12345"
  },
  "exception": null
}
```

## LogBuffer

```csharp
namespace DotnetLambdaLogBase.Logging;

internal sealed class LogBuffer
{
    private readonly ConcurrentQueue<LogEntry> _entries = new();
    private readonly int _maxSize;
    
    public LogBuffer(int maxSize);
    
    public int Count { get; }
    public void Add(LogEntry entry);
    public IReadOnlyList<LogEntry> Drain();
    public void Clear();
}
```

### バッファ動作

| 操作 | 説明 |
|------|------|
| `Add` | エントリ追加。maxSize 超過時は最古を破棄 |
| `Drain` | 全エントリを取り出してバッファをクリア |
| `Clear` | バッファを空にする |
| `Count` | 現在のバッファ内エントリ数 |

## Terraform リソース構造

### CloudWatch Logs グループ

| リソース | 名前パターン | クラス | 保持期間 |
|----------|-------------|--------|----------|
| 全ログ用 | `/lambda/{app_name}/all-logs` | DELIVERY | 2日（固定） |
| 異常系用 | `/lambda/shared/error-logs` | STANDARD | 7日（変数） |

### S3 バケット

| リソース | 名前パターン | 用途 |
|----------|-------------|------|
| ログ保存 | `{prefix}-lambda-logs-{account_id}` | Delivery Class ログの S3 配信先 |

### Terraform 変数

```hcl
variable "app_name" {
  description = "Lambda アプリケーション名"
  type        = string
}

variable "aws_region" {
  description = "AWS リージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "error_log_retention_days" {
  description = "異常系ログの保持日数"
  type        = number
  default     = 7
}

variable "s3_bucket_prefix" {
  description = "S3 バケット名プレフィックス"
  type        = string
  default     = "app"
}

variable "alarm_email" {
  description = "アラーム通知先メールアドレス（仮実装）"
  type        = string
  default     = ""
}
```
