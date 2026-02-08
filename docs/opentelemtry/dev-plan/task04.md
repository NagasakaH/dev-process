# タスク: task04 - ParallelTraceHelper実装

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task04 |
| タスク名 | ParallelTraceHelper実装 |
| 前提条件タスク | task03-01 |
| 並列実行可否 | 不可 |
| 推定所要時間 | 2.5時間 |
| 優先度 | 高 |

---

## 作業環境

- **作業ディレクトリ（worktree）**: /tmp/opentelemetry-issue-1-task04/
- **ブランチ**: opentelemetry-issue-1-task04
- **対象リポジトリ**: TracingSample
- **重要**: 必ず上記の作業ディレクトリ内で作業を行ってください

---

## 前提条件

### 前提タスク成果物

| タスク | 成果物パス | 参照内容 |
|--------|------------|----------|
| task03-01 | `src/TracingSample.Tracing/Helpers/TraceHelper.cs` | TraceHelper.StartTrace() |
| task02 | `src/TracingSample.Tracing/Helpers/TraceContext.cs` | TraceContext.Capture() |

### 確認事項

- [ ] task03-01が完了していること
- [ ] TraceHelper, TraceContextが実装されていること
- [ ] task03-01のコミットがcherry-pick済みであること

---

## 作業内容

### 目的

並列処理（Parallel.ForEach、Task.WhenAll等）でのトレース管理を支援する`ParallelTraceHelper`を実装する。これにより、並列タスク間で親子関係を正しく維持できる。

### 設計参照

- [dev-design/02_interface-api-design.md](../dev-design/02_interface-api-design.md) - 3.3 ParallelTraceHelper クラス
- [dev-design/04_processing-flow-design.md](../dev-design/04_processing-flow-design.md) - 3.4 並列処理トレースフロー
- [dev-design/03_data-structure-design.md](../dev-design/03_data-structure-design.md) - 3.4 ParallelTraceOptions

### 実装ステップ

1. **ParallelTraceOptions クラス作成**
   - 並列トレースオプション設定

2. **ParallelTraceHelper 静的クラス作成**
   - ForEach メソッド（同期版）
   - ForEachAsync メソッド（非同期版）
   - WhenAll メソッド（名前付きタスク）
   - WhenAllWithTrace メソッド（コレクション処理）

3. **単体テスト実装**
   - 並列処理の親子関係確認
   - 最大並列度の確認

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `src/TracingSample.Tracing/Helpers/ParallelTraceOptions.cs` | 新規作成 | 並列オプション |
| `src/TracingSample.Tracing/Helpers/ParallelTraceHelper.cs` | 新規作成 | 並列処理ヘルパー |
| `tests/TracingSample.Tracing.Tests/Unit/ParallelTraceHelperTests.cs` | 新規作成 | 単体テスト |

---

## テスト方針（TDD: RED-GREEN-REFACTOR）

### RED: 失敗するテストケース

**テストファイル**: `tests/TracingSample.Tracing.Tests/Unit/ParallelTraceHelperTests.cs`

```csharp
namespace TracingSample.Tracing.Tests.Unit;

public class ParallelTraceHelperTests : IDisposable
{
    private readonly ActivitySource _activitySource;
    private readonly ActivityListener _listener;
    private readonly List<Activity> _activities = new();

    public ParallelTraceHelperTests()
    {
        _activitySource = new ActivitySource("ParallelTest");
        TraceHelper.DefaultActivitySource = _activitySource;
        TraceContext.DefaultActivitySource = _activitySource;
        
        _listener = new ActivityListener
        {
            ShouldListenTo = _ => true,
            Sample = (ref ActivityCreationOptions<ActivityContext> _) => ActivitySamplingResult.AllDataAndRecorded,
            ActivityStarted = a => _activities.Add(a)
        };
        ActivitySource.AddActivityListener(_listener);
    }

    public void Dispose()
    {
        _listener.Dispose();
        _activitySource.Dispose();
    }

    [Fact]
    public async Task ForEachAsync_AllItemsHaveSameParent()
    {
        // Arrange
        var items = new[] { 1, 2, 3 };
        ActivityContext parentContext;
        
        using (var parent = _activitySource.StartActivity("Parent"))
        {
            parentContext = parent!.Context;
            _activities.Clear();

            // Act
            await ParallelTraceHelper.ForEachAsync(
                items,
                item => $"Process-{item}",
                async item =>
                {
                    await Task.Delay(10);
                });
        }

        // Assert
        Assert.Equal(3, _activities.Count);
        Assert.All(_activities, a => Assert.Equal(parentContext.TraceId, a.Context.TraceId));
    }

    [Fact]
    public async Task ForEachAsync_MaxDegreeOfParallelism_LimitsConcurrency()
    {
        // Arrange
        var concurrent = 0;
        var maxConcurrent = 0;
        var items = Enumerable.Range(1, 10).ToList();

        // Act
        await ParallelTraceHelper.ForEachAsync(
            items,
            i => $"Item-{i}",
            async _ =>
            {
                var current = Interlocked.Increment(ref concurrent);
                maxConcurrent = Math.Max(maxConcurrent, current);
                await Task.Delay(50);
                Interlocked.Decrement(ref concurrent);
            },
            maxDegreeOfParallelism: 2);

        // Assert
        Assert.True(maxConcurrent <= 2);
    }

    [Fact]
    public void ForEach_ExecutesAllItems()
    {
        // Arrange
        var items = new[] { 1, 2, 3 };
        var processed = new ConcurrentBag<int>();

        // Act
        ParallelTraceHelper.ForEach(
            items,
            item => $"Process-{item}",
            item => processed.Add(item));

        // Assert
        Assert.Equal(3, processed.Count);
        Assert.Contains(1, processed);
        Assert.Contains(2, processed);
        Assert.Contains(3, processed);
    }

    [Fact]
    public async Task WhenAll_NamedTasks_CreatesSpanForEach()
    {
        // Arrange
        _activities.Clear();

        // Act
        await ParallelTraceHelper.WhenAll(
            ("Task1", Task.Delay(10)),
            ("Task2", Task.Delay(10)),
            ("Task3", Task.Delay(10)));

        // Assert
        Assert.Equal(3, _activities.Count);
        Assert.Contains(_activities, a => a.DisplayName == "Task1");
        Assert.Contains(_activities, a => a.DisplayName == "Task2");
        Assert.Contains(_activities, a => a.DisplayName == "Task3");
    }

    [Fact]
    public async Task WhenAll_WithResult_ReturnsAllResults()
    {
        // Act
        var results = await ParallelTraceHelper.WhenAll(
            ("Task1", Task.FromResult(1)),
            ("Task2", Task.FromResult(2)),
            ("Task3", Task.FromResult(3)));

        // Assert
        Assert.Equal(3, results.Length);
        Assert.Contains(1, results);
        Assert.Contains(2, results);
        Assert.Contains(3, results);
    }

    [Fact]
    public async Task WhenAllWithTrace_ProcessesAllItems()
    {
        // Arrange
        var items = new[] { 1, 2, 3 };
        _activities.Clear();

        // Act
        var results = await ParallelTraceHelper.WhenAllWithTrace(
            items,
            i => $"Double-{i}",
            async i =>
            {
                await Task.Delay(10);
                return i * 2;
            });

        // Assert
        Assert.Equal(3, results.Length);
        Assert.Contains(2, results);
        Assert.Contains(4, results);
        Assert.Contains(6, results);
        Assert.Equal(3, _activities.Count);
    }
}
```

---

### GREEN: 最小限の実装

**実装ファイル1**: `src/TracingSample.Tracing/Helpers/ParallelTraceOptions.cs`

```csharp
namespace TracingSample.Tracing.Helpers;

/// <summary>
/// 並列トレースのオプション設定
/// </summary>
public class ParallelTraceOptions
{
    /// <summary>
    /// 最大並列度（-1 = 無制限）
    /// </summary>
    public int MaxDegreeOfParallelism { get; set; } = -1;

    /// <summary>
    /// キャンセルトークン
    /// </summary>
    public CancellationToken CancellationToken { get; set; } = CancellationToken.None;

    /// <summary>
    /// 親トレースを作成するかどうか
    /// </summary>
    public bool CreateParentSpan { get; set; } = true;

    /// <summary>
    /// 親トレースの名前
    /// </summary>
    public string? ParentSpanName { get; set; }

    /// <summary>
    /// 各並列タスクのトレースオプション
    /// </summary>
    public TracingOptions TracingOptions { get; set; } = TracingOptions.Default;
}
```

**実装ファイル2**: `src/TracingSample.Tracing/Helpers/ParallelTraceHelper.cs`

```csharp
using System.Diagnostics;

namespace TracingSample.Tracing.Helpers;

/// <summary>
/// 並列処理でのトレース管理を支援するヘルパークラス。
/// </summary>
public static class ParallelTraceHelper
{
    /// <summary>
    /// 並列処理の各要素にトレースを付与して実行します。
    /// </summary>
    public static void ForEach<T>(
        IEnumerable<T> items,
        Func<T, string> traceNameFunc,
        Action<T> action,
        ParallelOptions? options = null)
    {
        var parentContext = TraceContext.Capture();
        
        Parallel.ForEach(items, options ?? new ParallelOptions(), item =>
        {
            using (TraceHelper.StartTrace(traceNameFunc(item), parentContext))
            {
                action(item);
            }
        });
    }

    /// <summary>
    /// 並列処理の各要素にトレースを付与して非同期実行します。
    /// </summary>
    public static async Task ForEachAsync<T>(
        IEnumerable<T> items,
        Func<T, string> traceNameFunc,
        Func<T, Task> action,
        int maxDegreeOfParallelism = -1)
    {
        var parentContext = TraceContext.Capture();
        
        var semaphore = maxDegreeOfParallelism > 0 
            ? new SemaphoreSlim(maxDegreeOfParallelism) 
            : null;

        var tasks = items.Select(async item =>
        {
            if (semaphore != null)
                await semaphore.WaitAsync();

            try
            {
                using (TraceHelper.StartTrace(traceNameFunc(item), parentContext))
                {
                    await action(item);
                }
            }
            finally
            {
                semaphore?.Release();
            }
        });

        await Task.WhenAll(tasks);
    }

    /// <summary>
    /// 複数のタスクを並列実行し、各タスクにトレースを付与します。
    /// </summary>
    public static async Task WhenAll(params (string Name, Task Task)[] tasks)
    {
        var parentContext = TraceContext.Capture();
        
        var tracedTasks = tasks.Select(async t =>
        {
            using (TraceHelper.StartTrace(t.Name, parentContext))
            {
                await t.Task;
            }
        });

        await Task.WhenAll(tracedTasks);
    }

    /// <summary>
    /// 複数のタスクを並列実行し、結果を配列で返します。
    /// </summary>
    public static async Task<T[]> WhenAll<T>(params (string Name, Task<T> Task)[] tasks)
    {
        var parentContext = TraceContext.Capture();
        
        var tracedTasks = tasks.Select(async t =>
        {
            using (TraceHelper.StartTrace(t.Name, parentContext))
            {
                return await t.Task;
            }
        });

        return await Task.WhenAll(tracedTasks);
    }

    /// <summary>
    /// 各要素に対してトレース付きでタスクを生成し、すべて完了を待機します。
    /// </summary>
    public static async Task<TResult[]> WhenAllWithTrace<TSource, TResult>(
        IEnumerable<TSource> items,
        Func<TSource, string> traceNameFunc,
        Func<TSource, Task<TResult>> func)
    {
        var parentContext = TraceContext.Capture();
        
        var tasks = items.Select(async item =>
        {
            using (TraceHelper.StartTrace(traceNameFunc(item), parentContext))
            {
                return await func(item);
            }
        });

        return await Task.WhenAll(tasks);
    }
}
```

---

### REFACTOR: コード改善

**改善ポイント**:

- [ ] CancellationToken対応の追加
- [ ] 例外処理の強化
- [ ] オーバーロードの追加

---

## 成果物

| 成果物 | パス | 説明 |
|--------|------|------|
| ParallelTraceOptions.cs | `src/TracingSample.Tracing/Helpers/ParallelTraceOptions.cs` | オプション |
| ParallelTraceHelper.cs | `src/TracingSample.Tracing/Helpers/ParallelTraceHelper.cs` | ヘルパー |
| テストコード | `tests/TracingSample.Tracing.Tests/Unit/ParallelTraceHelperTests.cs` | 単体テスト |
| result.md | `docs/opentelemtry/dev-plan/results/task04-result.md` | 結果レポート |

---

## 完了条件

### 機能的条件

- [ ] ForEach で並列処理にトレースを付与できる
- [ ] ForEachAsync で非同期並列処理にトレースを付与できる
- [ ] maxDegreeOfParallelism で並列度を制限できる
- [ ] WhenAll で名前付きタスクを並列実行できる
- [ ] WhenAllWithTrace でコレクション処理を並列実行できる
- [ ] 全ての並列タスクが同じ親を持つ

### 品質条件

- [ ] 全テストが通過すること
- [ ] 並列度制限が機能すること

---

## コミット

```bash
cd /tmp/opentelemetry-issue-1-task04/TracingSample

git add -A
git commit -m "task04: ParallelTraceHelper実装

- ParallelTraceOptions: 並列トレースオプション
- ParallelTraceHelper: 並列処理用ヘルパー
- ForEach/ForEachAsync: 並列ループトレース
- WhenAll/WhenAllWithTrace: 並列タスクトレース
- 単体テスト追加"

git rev-parse HEAD
```

---

## 注意事項

- TraceHelper.StartTrace()とTraceContext.Capture()を活用すること
- 親コンテキストのキャプチャタイミングに注意すること
- SemaphoreSlimの適切なDispose処理
