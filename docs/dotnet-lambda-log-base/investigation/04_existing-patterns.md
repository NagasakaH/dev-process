# 既存パターン調査

## Lambda ハンドラーパターン

- ServiceCollection で DI コンテナをコンストラクタで構築
- `try-catch-finally` で `FlushAsync()` を確実に呼び出し
- **ServiceProvider.DisposeAsync() は使用禁止**（Lambda コンテナ再利用時にエラー）

## ILoggerProvider パターン

- `ConcurrentDictionary` でカテゴリ別ロガーをキャッシュ
- ログストリーム命名: `{yyyy/MM/dd}/{FunctionName}/{GUID}`
- FlushAsync で all-logs（全ログ）と error-logs（Error以上）に振り分け送信

## テストパターン

- Arrange-Act-Assert パターン
- Moq で `IAmazonCloudWatchLogs` をモック
- `LogBuffer.Drain()` でバッファ内容を直接検証

## コーディング規約

- C# 12 / .NET 8.0
- Nullable reference types 有効
- File-scoped namespaces
- ImplicitUsings 有効
