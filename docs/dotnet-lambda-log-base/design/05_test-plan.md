# テスト計画

## テスト方針

- xUnit + Moq による単体テストのみ（スコープ内）
- AWS SDK の IAmazonCloudWatchLogs を Mock 化
- 目標カバレッジ: 80% 以上

## 単体テストケース

### CloudWatchLogger テスト

| No | テスト内容 | 期待結果 |
|----|------------|----------|
| UT-01 | Information レベルのログ出力 | バッファに1件追加される |
| UT-02 | MinimumLevel 未満のログ出力 | バッファに追加されない |
| UT-03 | Error レベルのログ出力 | バッファに追加される |
| UT-04 | IsEnabled が MinimumLevel 以上で true | true を返す |
| UT-05 | IsEnabled が MinimumLevel 未満で false | false を返す |
| UT-06 | Exception 付きログ出力 | ExceptionDetail が設定される |
| UT-07 | BeginScope の動作 | IDisposable を返す |

### LogBuffer テスト

| No | テスト内容 | 期待結果 |
|----|------------|----------|
| UT-08 | エントリ追加で Count 増加 | Count が1増加 |
| UT-09 | Drain で全エントリ取得 | 全件返却、バッファ空 |
| UT-10 | MaxSize 超過時の動作 | 最古エントリが破棄される |
| UT-11 | 空バッファの Drain | 空リスト返却 |
| UT-12 | Clear の動作 | Count が0になる |
| UT-13 | 複数スレッドからの同時追加 | データ破損なし |

### JsonLogFormatter テスト

| No | テスト内容 | 期待結果 |
|----|------------|----------|
| UT-14 | 基本エントリのフォーマット | 有効な JSON 文字列 |
| UT-15 | Exception 付きエントリ | exception フィールドにスタックトレース |
| UT-16 | Properties 付きエントリ | properties フィールドにシリアライズ |
| UT-17 | null Properties | properties が null |
| UT-18 | 特殊文字を含むメッセージ | 正しくエスケープ |

### CloudWatchLogSender テスト

| No | テスト内容 | 期待結果 |
|----|------------|----------|
| UT-19 | 正常送信 | PutLogEvents が呼ばれる |
| UT-20 | 空リスト送信 | PutLogEvents が呼ばれない |
| UT-21 | 送信失敗時のフォールバック | 例外を飲んでコンソール出力 |
| UT-22 | LogStream 作成 | CreateLogStream が呼ばれる |
| UT-23 | LogStream 既存時 | ResourceAlreadyExistsException を無視 |

### CloudWatchLoggerProvider テスト

| No | テスト内容 | 期待結果 |
|----|------------|----------|
| UT-24 | CreateLogger | CloudWatchLogger インスタンス返却 |
| UT-25 | FlushAsync で全ログ送信 | 2グループに振り分けて送信 |
| UT-26 | FlushAsync で Error 振り分け | Error以上のみ異常系グループ |
| UT-27 | DisposeAsync で Flush 実行 | FlushAsync が呼ばれる |

### DI 拡張メソッドテスト

| No | テスト内容 | 期待結果 |
|----|------------|----------|
| UT-28 | AddCloudWatchLogger 登録 | ILoggerProvider が登録される |
| UT-29 | オプション設定反映 | 設定値が反映される |

## テストデータ

```csharp
public static class TestData
{
    public static LogEntry CreateInfoEntry() => new()
    {
        Timestamp = DateTime.UtcNow,
        Level = LogLevel.Information,
        Category = "Test.Category",
        Message = "Test message",
        FunctionName = "test-function"
    };

    public static LogEntry CreateErrorEntry() => new()
    {
        Timestamp = DateTime.UtcNow,
        Level = LogLevel.Error,
        Category = "Test.Category",
        Message = "Error occurred",
        ExceptionDetail = "System.Exception: Test exception",
        FunctionName = "test-function"
    };
}
```
