# インターフェース・API設計

## 1. 概要

ハイブリッド方式（Phase 1）で追加する新規APIのインターフェース設計を定義します。

## 2. 名前空間構成

```
TracingSample.Tracing/
├── Attributes/
│   └── TraceAttribute.cs              # 既存
├── Extensions/
│   ├── ServiceCollectionExtensions.cs  # 既存
│   └── ActivityContextExtensions.cs    # 新規
├── Interceptors/
│   └── TracingProxy.cs                 # 既存
└── Helpers/                            # 新規追加
    ├── TraceHelper.cs
    ├── TraceContext.cs
    └── ParallelTraceHelper.cs
```

## 3. 新規API設計

### 3.1 TraceHelper クラス

**目的**: staticメソッドやDI外のコードで手動トレースを実現

```csharp
namespace TracingSample.Tracing.Helpers;

/// <summary>
/// 手動トレース作成用のヘルパークラス。
/// DIを使用しないstaticメソッドやユーティリティで使用します。
/// </summary>
public static class TraceHelper
{
    /// <summary>
    /// デフォルトのActivitySourceを取得または設定します。
    /// </summary>
    public static ActivitySource DefaultActivitySource { get; set; }

    /// <summary>
    /// トレースを開始します。
    /// usingステートメントと併用して自動終了させます。
    /// </summary>
    /// <param name="name">トレース名</param>
    /// <param name="kind">Activityの種類（デフォルト: Internal）</param>
    /// <returns>Dispose時にトレースを終了するオブジェクト</returns>
    /// <example>
    /// using (TraceHelper.StartTrace("MyOperation"))
    /// {
    ///     // 処理
    /// }
    /// </example>
    public static IDisposable StartTrace(
        string name,
        ActivityKind kind = ActivityKind.Internal);

    /// <summary>
    /// 親コンテキストを指定してトレースを開始します。
    /// </summary>
    /// <param name="name">トレース名</param>
    /// <param name="parentContext">親のActivityContext</param>
    /// <param name="kind">Activityの種類</param>
    /// <returns>Dispose時にトレースを終了するオブジェクト</returns>
    /// <example>
    /// var parentContext = TraceContext.Capture();
    /// // 別スレッドで
    /// using (TraceHelper.StartTrace("ChildOperation", parentContext))
    /// {
    ///     // 処理
    /// }
    /// </example>
    public static IDisposable StartTrace(
        string name,
        ActivityContext parentContext,
        ActivityKind kind = ActivityKind.Internal);

    /// <summary>
    /// トレースをラップした非同期処理を実行します。
    /// </summary>
    /// <typeparam name="T">戻り値の型</typeparam>
    /// <param name="name">トレース名</param>
    /// <param name="func">実行する非同期関数</param>
    /// <returns>関数の実行結果</returns>
    /// <example>
    /// var result = await TraceHelper.WrapAsync("ProcessData", async () =>
    /// {
    ///     return await ProcessDataAsync();
    /// });
    /// </example>
    public static Task<T> WrapAsync<T>(
        string name,
        Func<Task<T>> func);

    /// <summary>
    /// トレースをラップした非同期処理を実行します（戻り値なし）。
    /// </summary>
    /// <param name="name">トレース名</param>
    /// <param name="action">実行する非同期アクション</param>
    /// <example>
    /// await TraceHelper.WrapAsync("SendNotification", async () =>
    /// {
    ///     await SendNotificationAsync();
    /// });
    /// </example>
    public static Task WrapAsync(
        string name,
        Func<Task> action);

    /// <summary>
    /// トレースをラップした同期処理を実行します。
    /// </summary>
    /// <typeparam name="T">戻り値の型</typeparam>
    /// <param name="name">トレース名</param>
    /// <param name="func">実行する関数</param>
    /// <returns>関数の実行結果</returns>
    public static T Wrap<T>(
        string name,
        Func<T> func);

    /// <summary>
    /// トレースをラップした同期処理を実行します（戻り値なし）。
    /// </summary>
    /// <param name="name">トレース名</param>
    /// <param name="action">実行するアクション</param>
    public static void Wrap(
        string name,
        Action action);

    /// <summary>
    /// 現在のActivityにタグを追加します。
    /// </summary>
    /// <param name="key">タグキー</param>
    /// <param name="value">タグ値</param>
    public static void SetTag(string key, object? value);

    /// <summary>
    /// 現在のActivityにイベントを追加します。
    /// </summary>
    /// <param name="name">イベント名</param>
    /// <param name="tags">追加タグ（オプション）</param>
    public static void AddEvent(
        string name,
        IDictionary<string, object?>? tags = null);

    /// <summary>
    /// 現在のActivityに例外を記録します。
    /// </summary>
    /// <param name="exception">記録する例外</param>
    public static void RecordException(Exception exception);
}
```

### 3.2 TraceContext クラス

**目的**: トレースコンテキストのキャプチャと復元を管理

```csharp
namespace TracingSample.Tracing.Helpers;

/// <summary>
/// トレースコンテキストの管理と伝播を行うクラス。
/// スレッド間やTask間でのコンテキスト受け渡しに使用します。
/// </summary>
public static class TraceContext
{
    /// <summary>
    /// 現在のActivityContextを取得します。
    /// </summary>
    public static ActivityContext Current { get; }

    /// <summary>
    /// 現在のActivityContextをキャプチャします。
    /// 別スレッドやTaskに渡す際に使用します。
    /// </summary>
    /// <returns>キャプチャしたActivityContext</returns>
    /// <example>
    /// var context = TraceContext.Capture();
    /// await Task.Run(() =>
    /// {
    ///     using (TraceContext.Restore(context))
    ///     {
    ///         // この中のトレースはcontextを親とする
    ///     }
    /// });
    /// </example>
    public static ActivityContext Capture();

    /// <summary>
    /// 指定したActivityContextを現在のコンテキストとして復元します。
    /// </summary>
    /// <param name="context">復元するActivityContext</param>
    /// <returns>Dispose時に元のコンテキストに戻すオブジェクト</returns>
    public static IDisposable Restore(ActivityContext context);

    /// <summary>
    /// 指定したコンテキストで同期処理を実行します。
    /// </summary>
    /// <param name="context">親コンテキスト</param>
    /// <param name="action">実行するアクション</param>
    public static void Run(ActivityContext context, Action action);

    /// <summary>
    /// 指定したコンテキストで同期処理を実行します。
    /// </summary>
    /// <typeparam name="T">戻り値の型</typeparam>
    /// <param name="context">親コンテキスト</param>
    /// <param name="func">実行する関数</param>
    /// <returns>関数の実行結果</returns>
    public static T Run<T>(ActivityContext context, Func<T> func);

    /// <summary>
    /// 指定したコンテキストで非同期処理を実行します。
    /// </summary>
    /// <param name="context">親コンテキスト</param>
    /// <param name="func">実行する非同期関数</param>
    public static Task RunAsync(ActivityContext context, Func<Task> func);

    /// <summary>
    /// 指定したコンテキストで非同期処理を実行します。
    /// </summary>
    /// <typeparam name="T">戻り値の型</typeparam>
    /// <param name="context">親コンテキスト</param>
    /// <param name="func">実行する非同期関数</param>
    /// <returns>関数の実行結果</returns>
    public static Task<T> RunAsync<T>(
        ActivityContext context,
        Func<Task<T>> func);

    /// <summary>
    /// 現在のコンテキストを伝播してTaskを実行します。
    /// Task.Runの代替として使用します。
    /// </summary>
    /// <param name="action">実行するアクション</param>
    /// <returns>Taskオブジェクト</returns>
    /// <example>
    /// // Task.Runの代わりに使用
    /// await TraceContext.RunWithContext(async () =>
    /// {
    ///     // 親コンテキストが自動的に伝播される
    ///     await DoWorkAsync();
    /// });
    /// </example>
    public static Task RunWithContext(Func<Task> action);

    /// <summary>
    /// 現在のコンテキストを伝播してTaskを実行します。
    /// </summary>
    /// <typeparam name="T">戻り値の型</typeparam>
    /// <param name="func">実行する関数</param>
    /// <returns>関数の実行結果</returns>
    public static Task<T> RunWithContext<T>(Func<Task<T>> func);
}
```

### 3.3 ParallelTraceHelper クラス

**目的**: 並列処理でのトレースを簡潔に記述

```csharp
namespace TracingSample.Tracing.Helpers;

/// <summary>
/// 並列処理でのトレース管理を支援するヘルパークラス。
/// Parallel.ForEachやTask.WhenAllの代替として使用します。
/// </summary>
public static class ParallelTraceHelper
{
    /// <summary>
    /// 並列処理の各要素にトレースを付与して実行します。
    /// </summary>
    /// <typeparam name="T">要素の型</typeparam>
    /// <param name="items">処理対象のコレクション</param>
    /// <param name="traceNameFunc">トレース名を生成する関数</param>
    /// <param name="action">各要素に対する処理</param>
    /// <param name="options">並列オプション（オプション）</param>
    /// <example>
    /// ParallelTraceHelper.ForEach(
    ///     orders,
    ///     order => $"ProcessOrder-{order.Id}",
    ///     order => ProcessOrder(order));
    /// </example>
    public static void ForEach<T>(
        IEnumerable<T> items,
        Func<T, string> traceNameFunc,
        Action<T> action,
        ParallelOptions? options = null);

    /// <summary>
    /// 並列処理の各要素にトレースを付与して非同期実行します。
    /// </summary>
    /// <typeparam name="T">要素の型</typeparam>
    /// <param name="items">処理対象のコレクション</param>
    /// <param name="traceNameFunc">トレース名を生成する関数</param>
    /// <param name="action">各要素に対する非同期処理</param>
    /// <param name="maxDegreeOfParallelism">最大並列度（デフォルト: -1=無制限）</param>
    /// <example>
    /// await ParallelTraceHelper.ForEachAsync(
    ///     orders,
    ///     order => $"ProcessOrder-{order.Id}",
    ///     async order => await ProcessOrderAsync(order));
    /// </example>
    public static Task ForEachAsync<T>(
        IEnumerable<T> items,
        Func<T, string> traceNameFunc,
        Func<T, Task> action,
        int maxDegreeOfParallelism = -1);

    /// <summary>
    /// 複数のタスクを並列実行し、各タスクにトレースを付与します。
    /// 現在のコンテキストを親として伝播します。
    /// </summary>
    /// <param name="tasks">実行するタスクの配列</param>
    /// <returns>すべてのタスクが完了するTask</returns>
    /// <example>
    /// await ParallelTraceHelper.WhenAll(
    ///     ("Task1", ProcessTask1Async()),
    ///     ("Task2", ProcessTask2Async()),
    ///     ("Task3", ProcessTask3Async()));
    /// </example>
    public static Task WhenAll(
        params (string Name, Task Task)[] tasks);

    /// <summary>
    /// 複数のタスクを並列実行し、各タスクにトレースを付与します。
    /// 結果を配列で返します。
    /// </summary>
    /// <typeparam name="T">結果の型</typeparam>
    /// <param name="tasks">実行するタスクの配列</param>
    /// <returns>すべてのタスクの結果</returns>
    public static Task<T[]> WhenAll<T>(
        params (string Name, Task<T> Task)[] tasks);

    /// <summary>
    /// 各要素に対してトレース付きでタスクを生成し、すべて完了を待機します。
    /// </summary>
    /// <typeparam name="TSource">入力要素の型</typeparam>
    /// <typeparam name="TResult">結果の型</typeparam>
    /// <param name="items">処理対象のコレクション</param>
    /// <param name="traceNameFunc">トレース名を生成する関数</param>
    /// <param name="func">各要素に対する非同期処理</param>
    /// <returns>すべてのタスクの結果</returns>
    /// <example>
    /// var results = await ParallelTraceHelper.WhenAllWithTrace(
    ///     orderIds,
    ///     id => $"FetchOrder-{id}",
    ///     async id => await FetchOrderAsync(id));
    /// </example>
    public static Task<TResult[]> WhenAllWithTrace<TSource, TResult>(
        IEnumerable<TSource> items,
        Func<TSource, string> traceNameFunc,
        Func<TSource, Task<TResult>> func);
}
```

### 3.4 ActivityContextExtensions クラス

**目的**: ActivityContextの操作を簡潔にする拡張メソッド

```csharp
namespace TracingSample.Tracing.Extensions;

/// <summary>
/// ActivityContext操作用の拡張メソッドを提供します。
/// </summary>
public static class ActivityContextExtensions
{
    /// <summary>
    /// 指定したActivityContextを親として設定します。
    /// </summary>
    /// <param name="context">親コンテキスト</param>
    /// <returns>Dispose時に元のコンテキストに戻すオブジェクト</returns>
    /// <example>
    /// var parentContext = Activity.Current?.Context ?? default;
    /// using (parentContext.AsParent())
    /// {
    ///     // この中のトレースはparentContextを親とする
    /// }
    /// </example>
    public static IDisposable AsParent(this ActivityContext context);

    /// <summary>
    /// 現在のActivityからActivityContextをキャプチャします。
    /// </summary>
    /// <param name="activity">対象のActivity</param>
    /// <returns>キャプチャしたActivityContext</returns>
    public static ActivityContext CaptureContext(this Activity? activity);

    /// <summary>
    /// ActivityContextが有効かどうかを確認します。
    /// </summary>
    /// <param name="context">確認するコンテキスト</param>
    /// <returns>有効な場合はtrue</returns>
    public static bool IsValid(this ActivityContext context);
}
```

## 4. 使用例

### 4.1 staticメソッドでのトレース

```csharp
public static class OrderUtils
{
    public static decimal CalculateTotal(List<OrderItem> items)
    {
        using (TraceHelper.StartTrace("OrderUtils.CalculateTotal"))
        {
            TraceHelper.SetTag("item.count", items.Count);
            
            var total = items.Sum(i => i.Quantity * i.UnitPrice);
            
            TraceHelper.SetTag("calculated.total", total);
            return total;
        }
    }
}
```

### 4.2 新規スレッドでの親子関係維持

```csharp
public async Task ProcessWithNewThread()
{
    // 現在のコンテキストをキャプチャ
    var parentContext = TraceContext.Capture();
    
    // 新しいスレッドで処理
    var thread = new Thread(() =>
    {
        // 親コンテキストを復元
        using (TraceContext.Restore(parentContext))
        using (TraceHelper.StartTrace("ProcessInNewThread"))
        {
            // この中のトレースはparentContextを親とする
            DoWork();
        }
    });
    
    thread.Start();
    await Task.Run(() => thread.Join());
}
```

### 4.3 Parallel.ForEachの置き換え

```csharp
// Before: 親子関係が正しく設定されない可能性
Parallel.ForEach(orders, order =>
{
    ProcessOrder(order);
});

// After: 各並列タスクが適切に親子関係を持つ
ParallelTraceHelper.ForEach(
    orders,
    order => $"ProcessOrder-{order.Id}",
    order => ProcessOrder(order));
```

### 4.4 Task.WhenAllの置き換え

```csharp
// Before
await Task.WhenAll(
    ProcessTask1Async(),
    ProcessTask2Async(),
    ProcessTask3Async());

// After: 各タスクに名前付きトレースが付与される
await ParallelTraceHelper.WhenAll(
    ("ProcessTask1", ProcessTask1Async()),
    ("ProcessTask2", ProcessTask2Async()),
    ("ProcessTask3", ProcessTask3Async()));
```

### 4.5 DIサービスとstaticの混在

```csharp
public class OrderService : IOrderService
{
    [Trace]
    public async Task<Order> ProcessOrder(string customerId, List<OrderItem> items)
    {
        // DIサービス経由のトレース（自動）
        await _inventoryService.CheckStock(items);
        
        // staticメソッドのトレース（手動）
        var total = OrderUtils.CalculateTotal(items);
        
        // DIサービス経由のトレース（自動）
        await _paymentService.ProcessPayment(customerId, total);
        
        return CreateOrder(customerId, items, total);
    }
}

public static class OrderUtils
{
    public static decimal CalculateTotal(List<OrderItem> items)
    {
        // TraceHelperで手動トレース
        return TraceHelper.Wrap("OrderUtils.CalculateTotal", () =>
        {
            return items.Sum(i => i.Quantity * i.UnitPrice);
        });
    }
}
```

## 5. DI登録の拡張

```csharp
/// <summary>
/// トレーシング用のDI拡張メソッド
/// </summary>
public static class TracingServiceCollectionExtensions
{
    /// <summary>
    /// トレーシングヘルパーを初期化します。
    /// </summary>
    /// <param name="services">サービスコレクション</param>
    /// <param name="activitySourceName">ActivitySource名</param>
    /// <returns>サービスコレクション</returns>
    public static IServiceCollection AddTracingHelpers(
        this IServiceCollection services,
        string activitySourceName = "TracingSample.Core")
    {
        var activitySource = new ActivitySource(activitySourceName);
        services.AddSingleton(activitySource);
        
        // TraceHelperにデフォルトActivitySourceを設定
        TraceHelper.DefaultActivitySource = activitySource;
        
        return services;
    }
}
```

## 6. 設計上の考慮事項

### 6.1 スレッドセーフティ

- `TraceHelper.DefaultActivitySource`は初期化時に一度だけ設定
- `TraceContext`の操作は`AsyncLocal<T>`を使用してスレッドセーフを確保
- 各メソッドは副作用のない純粋関数として設計

### 6.2 パフォーマンス

- リフレクション使用を最小限に抑制
- オブジェクトの生成を抑えるためにstruct活用を検討
- ホットパスではActivityのnullチェックを最適化

### 6.3 エラーハンドリング

- トレースの失敗がビジネスロジックに影響しないよう設計
- 例外発生時も確実にActivityをDispose
- デフォルトActivitySourceが未設定の場合の graceful degradation

## 7. 次のステップ

1. データ構造設計の詳細化
2. 処理フロー設計
3. テスト計画策定
