# タスク: task06 - 統合テスト実装

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task06 |
| タスク名 | 統合テスト実装 |
| 前提条件タスク | task05 |
| 並列実行可否 | 不可 |
| 推定所要時間 | 3時間 |
| 優先度 | 高 |

---

## 作業環境

- **作業ディレクトリ（worktree）**: /tmp/opentelemetry-issue-1-task06/
- **ブランチ**: opentelemetry-issue-1-task06
- **対象リポジトリ**: TracingSample
- **重要**: 必ず上記の作業ディレクトリ内で作業を行ってください

---

## 前提条件

### 前提タスク成果物

| タスク | 成果物パス | 参照内容 |
|--------|------------|----------|
| task05 | DI統合完了 | 全ヘルパーがDI経由で使用可能 |
| task01-05 | 全ヘルパー実装 | TraceHelper, TraceContext, ParallelTraceHelper等 |

### 確認事項

- [ ] task05が完了していること
- [ ] 全ヘルパークラスがDI経由で使用可能であること

---

## 作業内容

### 目的

設計で定義された15種類の呼び出しパターンに対する統合テストを実装する。これにより、実際の使用シナリオでのトレース動作を検証する。

### 設計参照

- [dev-design/05_test-plan.md](../dev-design/05_test-plan.md) - 3. 呼び出しパターン別テストケース
- [dev-design/06_side-effect-verification.md](../dev-design/06_side-effect-verification.md) - 3. 機能的副作用検証

### 実装ステップ

1. **同期メソッドパターンテスト**
   - 通常メソッド呼び出し
   - ネスト呼び出し
   - staticメソッド

2. **非同期メソッドパターンテスト**
   - async/await
   - Task<T>戻り値
   - Task戻り値（void相当）

3. **並列処理パターンテスト**
   - Task.Run
   - Parallel.ForEach
   - Task.WhenAll
   - PLINQ

4. **スレッド間パターンテスト**
   - new Thread
   - ThreadPool
   - Fire-and-Forget

5. **特殊パターンテスト**
   - 例外発生
   - キャンセル

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `tests/TracingSample.Tracing.Tests/Integration/SyncPatternTests.cs` | 新規作成 | 同期パターンテスト |
| `tests/TracingSample.Tracing.Tests/Integration/AsyncPatternTests.cs` | 新規作成 | 非同期パターンテスト |
| `tests/TracingSample.Tracing.Tests/Integration/ParallelPatternTests.cs` | 新規作成 | 並列パターンテスト |
| `tests/TracingSample.Tracing.Tests/Integration/ThreadPatternTests.cs` | 新規作成 | スレッドパターンテスト |
| `tests/TracingSample.Tracing.Tests/Integration/ExceptionPatternTests.cs` | 新規作成 | 例外パターンテスト |

---

## テスト方針（TDD: RED-GREEN-REFACTOR）

### 同期メソッドパターンテスト

```csharp
namespace TracingSample.Tracing.Tests.Integration;

public class SyncPatternTests : IntegrationTestBase
{
    [Fact]
    public void SyncMethod_DirectCall_CreatesSpan()
    {
        // Act
        using (TraceHelper.StartTrace("SyncMethod"))
        {
            // 同期処理
            Thread.Sleep(10);
        }

        // Assert
        Assert.Single(Activities);
        Assert.Equal("SyncMethod", Activities[0].DisplayName);
    }

    [Fact]
    public void SyncMethod_NestedCall_CreatesParentChild()
    {
        // Act
        using (TraceHelper.StartTrace("Parent"))
        {
            using (TraceHelper.StartTrace("Child"))
            {
                Thread.Sleep(10);
            }
        }

        // Assert
        Assert.Equal(2, Activities.Count);
        var parent = Activities.First(a => a.DisplayName == "Parent");
        var child = Activities.First(a => a.DisplayName == "Child");
        Assert.Equal(parent.Context.TraceId, child.Context.TraceId);
        Assert.Equal(parent.Context.SpanId, child.ParentSpanId);
    }

    [Fact]
    public void StaticMethod_WithTraceHelper_CreatesSpan()
    {
        // Act
        var result = StaticCalculator.Add(1, 2);

        // Assert
        Assert.Equal(3, result);
        Assert.Single(Activities);
        Assert.Equal("StaticCalculator.Add", Activities[0].DisplayName);
    }
}

// テスト用staticクラス
public static class StaticCalculator
{
    public static int Add(int a, int b)
    {
        return TraceHelper.Wrap("StaticCalculator.Add", () => a + b);
    }
}
```

### 非同期メソッドパターンテスト

```csharp
namespace TracingSample.Tracing.Tests.Integration;

public class AsyncPatternTests : IntegrationTestBase
{
    [Fact]
    public async Task AsyncMethod_MaintainsContextAcrossAwait()
    {
        // Act
        string? traceIdBefore = null;
        string? traceIdAfter = null;

        await TraceHelper.WrapAsync("AsyncMethod", async () =>
        {
            traceIdBefore = Activity.Current?.TraceId.ToString();
            await Task.Delay(10);
            traceIdAfter = Activity.Current?.TraceId.ToString();
        });

        // Assert
        Assert.NotNull(traceIdBefore);
        Assert.Equal(traceIdBefore, traceIdAfter);
    }

    [Fact]
    public async Task TaskWithResult_RecordsReturnValue()
    {
        // Act
        var result = await TraceHelper.WrapAsync("Calculate", async () =>
        {
            await Task.Delay(10);
            return 42;
        });

        // Assert
        Assert.Equal(42, result);
        Assert.Single(Activities);
    }

    [Fact]
    public async Task NestedAsync_CreatesParentChild()
    {
        // Act
        await TraceHelper.WrapAsync("Parent", async () =>
        {
            await TraceHelper.WrapAsync("Child", async () =>
            {
                await Task.Delay(10);
            });
        });

        // Assert
        Assert.Equal(2, Activities.Count);
        var parent = Activities.First(a => a.DisplayName == "Parent");
        var child = Activities.First(a => a.DisplayName == "Child");
        Assert.Equal(parent.Context.TraceId, child.Context.TraceId);
    }
}
```

### 並列処理パターンテスト

```csharp
namespace TracingSample.Tracing.Tests.Integration;

public class ParallelPatternTests : IntegrationTestBase
{
    [Fact]
    public async Task TaskRun_WithContext_MaintainsParent()
    {
        // Arrange
        ActivityContext parentContext;

        // Act
        using (TraceHelper.StartTrace("Parent"))
        {
            parentContext = TraceContext.Capture();
            Activities.Clear();

            await Task.Run(async () =>
            {
                using (TraceContext.Restore(parentContext))
                using (TraceHelper.StartTrace("ChildInTaskRun"))
                {
                    await Task.Delay(10);
                }
            });
        }

        // Assert
        Assert.Single(Activities);
        Assert.Equal(parentContext.TraceId, Activities[0].Context.TraceId);
    }

    [Fact]
    public async Task ParallelForEach_AllHaveSameParent()
    {
        // Arrange
        var items = new[] { 1, 2, 3, 4, 5 };
        ActivityContext parentContext;

        using (TraceHelper.StartTrace("Parent"))
        {
            parentContext = TraceContext.Capture();
            Activities.Clear();

            // Act
            await ParallelTraceHelper.ForEachAsync(
                items,
                i => $"Item-{i}",
                async i => await Task.Delay(10));
        }

        // Assert
        Assert.Equal(5, Activities.Count);
        Assert.All(Activities, a => Assert.Equal(parentContext.TraceId, a.Context.TraceId));
    }

    [Fact]
    public async Task TaskWhenAll_EachHasSpan()
    {
        // Act
        await ParallelTraceHelper.WhenAll(
            ("Task1", Task.Delay(10)),
            ("Task2", Task.Delay(10)),
            ("Task3", Task.Delay(10)));

        // Assert
        Assert.Equal(3, Activities.Count);
    }

    [Fact]
    public void Plinq_WithContext_MaintainsParent()
    {
        // Arrange
        var items = Enumerable.Range(1, 5);
        ActivityContext parentContext;

        using (TraceHelper.StartTrace("Parent"))
        {
            parentContext = TraceContext.Capture();
            Activities.Clear();

            // Act
            var results = items.AsParallel()
                .Select(i =>
                {
                    using (TraceContext.Restore(parentContext))
                    using (TraceHelper.StartTrace($"Item-{i}"))
                    {
                        return i * 2;
                    }
                })
                .ToList();

            // Assert
            Assert.Equal(5, results.Count);
        }

        Assert.All(Activities, a => Assert.Equal(parentContext.TraceId, a.Context.TraceId));
    }
}
```

### スレッドパターンテスト

```csharp
namespace TracingSample.Tracing.Tests.Integration;

public class ThreadPatternTests : IntegrationTestBase
{
    [Fact]
    public void NewThread_WithContext_MaintainsParent()
    {
        // Arrange
        var completed = new ManualResetEvent(false);
        ActivityContext parentContext;

        using (TraceHelper.StartTrace("Parent"))
        {
            parentContext = TraceContext.Capture();
            Activities.Clear();

            // Act
            var thread = new Thread(() =>
            {
                using (TraceContext.Restore(parentContext))
                using (TraceHelper.StartTrace("ChildThread"))
                {
                    Thread.Sleep(10);
                }
                completed.Set();
            });
            thread.Start();
            completed.WaitOne();
        }

        // Assert
        Assert.Single(Activities);
        Assert.Equal(parentContext.TraceId, Activities[0].Context.TraceId);
    }

    [Fact]
    public void ThreadPool_WithContext_MaintainsParent()
    {
        // Arrange
        var completed = new ManualResetEvent(false);
        ActivityContext parentContext;

        using (TraceHelper.StartTrace("Parent"))
        {
            parentContext = TraceContext.Capture();
            Activities.Clear();

            // Act
            ThreadPool.QueueUserWorkItem(_ =>
            {
                using (TraceContext.Restore(parentContext))
                using (TraceHelper.StartTrace("ThreadPoolChild"))
                {
                    Thread.Sleep(10);
                }
                completed.Set();
            });
            completed.WaitOne();
        }

        // Assert
        Assert.Single(Activities);
        Assert.Equal(parentContext.TraceId, Activities[0].Context.TraceId);
    }

    [Fact]
    public async Task FireAndForget_WithLinkedTrace_CreatesLink()
    {
        // Arrange
        var completed = new TaskCompletionSource<bool>();
        ActivityContext linkedContext;

        using (TraceHelper.StartTrace("Parent"))
        {
            linkedContext = TraceContext.Capture();
        }
        Activities.Clear();

        // Act - Fire-and-forget with link
        _ = Task.Run(async () =>
        {
            using (TraceHelper.StartLinkedTrace("FireAndForget", linkedContext))
            {
                await Task.Delay(10);
            }
            completed.SetResult(true);
        });

        await completed.Task;

        // Assert
        Assert.Single(Activities);
        Assert.NotEqual(linkedContext.TraceId, Activities[0].Context.TraceId); // 新しいTrace
        Assert.Contains(Activities[0].Links, l => l.Context.TraceId == linkedContext.TraceId); // リンクあり
    }
}
```

### 例外パターンテスト

```csharp
namespace TracingSample.Tracing.Tests.Integration;

public class ExceptionPatternTests : IntegrationTestBase
{
    [Fact]
    public void SyncException_RecordsError()
    {
        // Act & Assert
        Assert.Throws<InvalidOperationException>(() =>
        {
            TraceHelper.Wrap("FailingOp", () =>
            {
                throw new InvalidOperationException("Test error");
            });
        });

        Assert.Single(Activities);
        Assert.Equal(ActivityStatusCode.Error, Activities[0].Status);
    }

    [Fact]
    public async Task AsyncException_RecordsError()
    {
        // Act & Assert
        await Assert.ThrowsAsync<InvalidOperationException>(async () =>
        {
            await TraceHelper.WrapAsync("FailingAsyncOp", async () =>
            {
                await Task.Delay(10);
                throw new InvalidOperationException("Test error");
            });
        });

        Assert.Single(Activities);
        Assert.Equal(ActivityStatusCode.Error, Activities[0].Status);
    }

    [Fact]
    public async Task Cancellation_RecordsError()
    {
        // Arrange
        var cts = new CancellationTokenSource();
        cts.Cancel();

        // Act & Assert
        await Assert.ThrowsAsync<OperationCanceledException>(async () =>
        {
            await TraceHelper.WrapAsync("CancelledOp", async () =>
            {
                cts.Token.ThrowIfCancellationRequested();
                await Task.Delay(100);
            });
        });

        Assert.Single(Activities);
        Assert.Equal(ActivityStatusCode.Error, Activities[0].Status);
    }
}
```

### 共通テストベースクラス

```csharp
namespace TracingSample.Tracing.Tests.Integration;

public abstract class IntegrationTestBase : IDisposable
{
    protected readonly ActivitySource ActivitySource;
    protected readonly ActivityListener Listener;
    protected readonly List<Activity> Activities = new();

    protected IntegrationTestBase()
    {
        ActivitySource = new ActivitySource("IntegrationTest");
        TraceHelper.DefaultActivitySource = ActivitySource;
        TraceContext.DefaultActivitySource = ActivitySource;

        Listener = new ActivityListener
        {
            ShouldListenTo = _ => true,
            Sample = (ref ActivityCreationOptions<ActivityContext> _) => ActivitySamplingResult.AllDataAndRecorded,
            ActivityStarted = a => Activities.Add(a)
        };
        ActivitySource.AddActivityListener(Listener);
    }

    public void Dispose()
    {
        Listener.Dispose();
        ActivitySource.Dispose();
    }
}
```

---

## 成果物

| 成果物 | パス | 説明 |
|--------|------|------|
| SyncPatternTests.cs | `tests/.../Integration/` | 同期パターン |
| AsyncPatternTests.cs | `tests/.../Integration/` | 非同期パターン |
| ParallelPatternTests.cs | `tests/.../Integration/` | 並列パターン |
| ThreadPatternTests.cs | `tests/.../Integration/` | スレッドパターン |
| ExceptionPatternTests.cs | `tests/.../Integration/` | 例外パターン |
| IntegrationTestBase.cs | `tests/.../Integration/` | 共通ベース |
| result.md | `docs/opentelemtry/dev-plan/results/task06-result.md` | 結果レポート |

---

## 完了条件

### 機能的条件

- [ ] 15種類の呼び出しパターンがテストされている
- [ ] 全パターンで親子関係が正しく維持される
- [ ] 例外時にエラーステータスが記録される

### 品質条件

- [ ] 全テストが通過すること
- [ ] テストカバレッジが80%以上であること

---

## コミット

```bash
cd /tmp/opentelemetry-issue-1-task06/TracingSample

git add -A
git commit -m "task06: 統合テスト実装

- SyncPatternTests: 同期メソッドパターン
- AsyncPatternTests: 非同期メソッドパターン
- ParallelPatternTests: 並列処理パターン
- ThreadPatternTests: スレッド間パターン
- ExceptionPatternTests: 例外・キャンセルパターン
- IntegrationTestBase: 共通テストベース
- 15種類の呼び出しパターンをカバー"

git rev-parse HEAD
```

---

## 注意事項

- 全てのパターンで親子関係の確認を行うこと
- 非同期テストではawaitを忘れないこと
- スレッドテストでは確実に完了を待機すること
