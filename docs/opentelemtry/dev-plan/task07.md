# タスク: task07 - 副作用検証・ベンチマーク

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task07 |
| タスク名 | 副作用検証・ベンチマーク |
| 前提条件タスク | task06 |
| 並列実行可否 | 不可 |
| 推定所要時間 | 2時間 |
| 優先度 | 中 |

---

## 作業環境

- **作業ディレクトリ（worktree）**: /tmp/opentelemetry-issue-1-task07/
- **ブランチ**: opentelemetry-issue-1-task07
- **対象リポジトリ**: TracingSample
- **重要**: 必ず上記の作業ディレクトリ内で作業を行ってください

---

## 前提条件

### 前提タスク成果物

| タスク | 成果物パス | 参照内容 |
|--------|------------|----------|
| task06 | 統合テスト完了 | 全パターンテスト通過 |
| task05 | DI統合完了 | 全機能が使用可能 |

### 確認事項

- [ ] task06が完了していること
- [ ] 全統合テストが通過していること

---

## 作業内容

### 目的

トレーシングライブラリ拡張による既存機能・パフォーマンスへの副作用を検証する。ベンチマークを実施し、許容範囲内であることを確認する。

### 設計参照

- [dev-design/06_side-effect-verification.md](../dev-design/06_side-effect-verification.md)

### 実装ステップ

1. **ベンチマークプロジェクト作成**
   - BenchmarkDotNet設定
   - 基本ベンチマーク実装

2. **パフォーマンス測定**
   - TraceHelper オーバーヘッド測定
   - 並列処理オーバーヘッド測定
   - メモリ使用量測定

3. **後方互換性検証**
   - 既存テストの実行確認
   - 既存APIの動作確認

4. **副作用検証レポート作成**

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `tests/TracingSample.Benchmarks/` | 新規作成 | ベンチマークプロジェクト |
| `tests/TracingSample.Benchmarks/TracingBenchmarks.cs` | 新規作成 | ベンチマーク実装 |
| `tests/TracingSample.Tracing.Tests/SideEffect/` | 新規作成 | 副作用テスト |

---

## テスト方針

### ベンチマーク実装

**ファイル**: `tests/TracingSample.Benchmarks/TracingBenchmarks.cs`

```csharp
using BenchmarkDotNet.Attributes;
using BenchmarkDotNet.Diagnosers;
using BenchmarkDotNet.Jobs;
using System.Diagnostics;
using TracingSample.Tracing.Helpers;

namespace TracingSample.Benchmarks;

[MemoryDiagnoser]
[SimpleJob(RuntimeMoniker.Net80)]
public class TracingBenchmarks
{
    private ActivitySource _activitySource = null!;
    private ActivityListener _listener = null!;

    [GlobalSetup]
    public void Setup()
    {
        _activitySource = new ActivitySource("Benchmark");
        TraceHelper.DefaultActivitySource = _activitySource;
        TraceContext.DefaultActivitySource = _activitySource;

        _listener = new ActivityListener
        {
            ShouldListenTo = _ => true,
            Sample = (ref ActivityCreationOptions<ActivityContext> _) => ActivitySamplingResult.AllDataAndRecorded
        };
        ActivitySource.AddActivityListener(_listener);
    }

    [GlobalCleanup]
    public void Cleanup()
    {
        _listener.Dispose();
        _activitySource.Dispose();
    }

    [Benchmark(Baseline = true)]
    public void DirectCall_NoTracing()
    {
        // トレースなしの直接呼び出し
        var result = 1 + 1;
    }

    [Benchmark]
    public void TraceHelper_StartTrace()
    {
        using (TraceHelper.StartTrace("BenchmarkOp"))
        {
            var result = 1 + 1;
        }
    }

    [Benchmark]
    public void TraceHelper_Wrap()
    {
        TraceHelper.Wrap("BenchmarkOp", () =>
        {
            var result = 1 + 1;
        });
    }

    [Benchmark]
    public async Task TraceHelper_WrapAsync()
    {
        await TraceHelper.WrapAsync("BenchmarkAsyncOp", async () =>
        {
            await Task.CompletedTask;
        });
    }

    [Benchmark]
    public void TraceContext_CaptureAndRestore()
    {
        using (TraceHelper.StartTrace("Parent"))
        {
            var context = TraceContext.Capture();
            using (TraceContext.Restore(context))
            {
                var result = 1 + 1;
            }
        }
    }

    [Benchmark]
    public async Task ParallelTraceHelper_ForEachAsync_10Items()
    {
        var items = Enumerable.Range(1, 10);
        await ParallelTraceHelper.ForEachAsync(
            items,
            i => $"Item-{i}",
            async _ => await Task.CompletedTask);
    }
}
```

### メモリ/GCテスト

**ファイル**: `tests/TracingSample.Tracing.Tests/SideEffect/MemoryTests.cs`

```csharp
namespace TracingSample.Tracing.Tests.SideEffect;

public class MemoryTests : IDisposable
{
    private readonly ActivitySource _activitySource;
    private readonly ActivityListener _listener;

    public MemoryTests()
    {
        _activitySource = new ActivitySource("MemoryTest");
        TraceHelper.DefaultActivitySource = _activitySource;
        TraceContext.DefaultActivitySource = _activitySource;

        _listener = new ActivityListener
        {
            ShouldListenTo = _ => true,
            Sample = (ref ActivityCreationOptions<ActivityContext> _) => ActivitySamplingResult.AllDataAndRecorded
        };
        ActivitySource.AddActivityListener(_listener);
    }

    public void Dispose()
    {
        _listener.Dispose();
        _activitySource.Dispose();
    }

    [Fact]
    public async Task HighConcurrency_NoMemoryLeak()
    {
        // Arrange
        var initialMemory = GC.GetTotalMemory(true);

        // Act
        for (int i = 0; i < 10000; i++)
        {
            using (TraceHelper.StartTrace($"Operation-{i}"))
            {
                await Task.Delay(1);
            }
        }

        // Force GC
        GC.Collect();
        GC.WaitForPendingFinalizers();
        GC.Collect();

        var finalMemory = GC.GetTotalMemory(true);

        // Assert
        var memoryIncrease = finalMemory - initialMemory;
        Assert.True(memoryIncrease < 10 * 1024 * 1024, // 10MB以下
            $"Memory increased by {memoryIncrease / 1024 / 1024}MB");
    }

    [Fact]
    public void LongRunning_NoActivityLeak()
    {
        // Arrange
        var activityCount = 0;
        using var countListener = new ActivityListener
        {
            ShouldListenTo = _ => true,
            Sample = (ref ActivityCreationOptions<ActivityContext> _) => ActivitySamplingResult.AllData,
            ActivityStarted = _ => Interlocked.Increment(ref activityCount),
            ActivityStopped = _ => Interlocked.Decrement(ref activityCount)
        };
        ActivitySource.AddActivityListener(countListener);

        // Act
        for (int i = 0; i < 1000; i++)
        {
            using (TraceHelper.StartTrace($"Op-{i}"))
            {
                // 処理
            }
        }

        // Assert
        Assert.Equal(0, activityCount); // 全てDisposed
    }
}
```

### 後方互換性テスト

**ファイル**: `tests/TracingSample.Tracing.Tests/SideEffect/BackwardCompatibilityTests.cs`

```csharp
namespace TracingSample.Tracing.Tests.SideEffect;

public class BackwardCompatibilityTests
{
    [Fact]
    public void ExistingTracingProxy_StillWorks()
    {
        // Arrange
        var services = new ServiceCollection();
        services.AddTracingHelpers("CompatTest");
        services.AddTracedScoped<IOrderService, OrderService>();
        using var provider = services.BuildServiceProvider();

        // Act
        using var scope = provider.CreateScope();
        var service = scope.ServiceProvider.GetRequiredService<IOrderService>();
        
        // Assert - 例外が発生しないこと
        var exception = Record.Exception(() => service.ProcessOrder("test", new List<OrderItem>(), "address").Wait());
        Assert.Null(exception);
    }

    [Fact]
    public void ExistingTraceAttribute_StillRecordsParameters()
    {
        // Arrange
        var activities = new List<Activity>();
        var activitySource = new ActivitySource("CompatTest");
        using var listener = new ActivityListener
        {
            ShouldListenTo = _ => true,
            Sample = (ref ActivityCreationOptions<ActivityContext> _) => ActivitySamplingResult.AllDataAndRecorded,
            ActivityStarted = a => activities.Add(a)
        };
        ActivitySource.AddActivityListener(listener);

        var services = new ServiceCollection();
        services.AddTracingHelpers("CompatTest");
        services.AddTracedScoped<IOrderService, OrderService>();
        using var provider = services.BuildServiceProvider();

        // Act
        using var scope = provider.CreateScope();
        var service = scope.ServiceProvider.GetRequiredService<IOrderService>();
        service.ProcessOrder("CUST-001", new List<OrderItem>(), "address").Wait();

        // Assert
        Assert.NotEmpty(activities);
        var activity = activities.First(a => a.DisplayName.Contains("ProcessOrder"));
        Assert.Contains(activity.Tags, t => t.Key.StartsWith("parameter."));
    }

    [Fact]
    public void DIRegistration_AllMethods_Work()
    {
        // Arrange
        var services = new ServiceCollection();

        // Act & Assert - 例外が発生しないこと
        Assert.Null(Record.Exception(() =>
        {
            services.AddTracingHelpers("Test");
            services.AddTracedScoped<ITestService, TestService>();
            services.AddTracedTransient<ITestService, TestService>();
            services.AddTracedSingleton<ITestService, TestService>();
        }));
    }
}
```

---

## パフォーマンス許容基準

| メトリクス | 許容値 | 警告値 | 失敗値 |
|-----------|--------|--------|--------|
| StartTraceオーバーヘッド | < 1ms | 1-5ms | > 5ms |
| Wrapオーバーヘッド | < 1ms | 1-5ms | > 5ms |
| メモリ/呼び出し | < 1KB | 1-10KB | > 10KB |
| 並列処理オーバーヘッド | < 5% | 5-10% | > 10% |

---

## 成果物

| 成果物 | パス | 説明 |
|--------|------|------|
| TracingBenchmarks.cs | `tests/TracingSample.Benchmarks/` | ベンチマーク |
| MemoryTests.cs | `tests/.../SideEffect/` | メモリテスト |
| BackwardCompatibilityTests.cs | `tests/.../SideEffect/` | 互換性テスト |
| result.md | `docs/opentelemtry/dev-plan/results/task07-result.md` | 副作用検証レポート |

---

## 完了条件

### 機能的条件

- [ ] ベンチマークが実行できる
- [ ] パフォーマンスが許容範囲内である
- [ ] メモリリークがない
- [ ] 既存機能が正常に動作する

### 品質条件

- [ ] 全テストが通過すること
- [ ] パフォーマンス劣化が20%以下であること

### ドキュメント条件

- [ ] 副作用検証レポートが作成されていること
- [ ] ベンチマーク結果が記録されていること

---

## result.md テンプレート

```markdown
# 副作用検証レポート

## 実施日: YYYY-MM-DD
## バージョン: Issue #1 Phase 1

### 1. パフォーマンス測定結果

| メトリクス | 測定値 | 許容値 | 判定 |
|-----------|--------|--------|------|
| StartTraceオーバーヘッド | XXμs | < 1ms | ✅/❌ |
| Wrapオーバーヘッド | XXμs | < 1ms | ✅/❌ |
| メモリ/呼び出し | XXB | < 1KB | ✅/❌ |

### 2. メモリ検証結果

- 10000回連続実行後のメモリ増加: XX MB
- Activity漏れ: なし/あり
- 判定: ✅/❌

### 3. 後方互換性検証結果

- 既存TracingProxy: ✅ 動作確認
- 既存TraceAttribute: ✅ 動作確認
- DI登録メソッド: ✅ 動作確認

### 4. 総合判定

**PASS / FAIL**

### 5. 備考

（特記事項があれば記載）
```

---

## コミット

```bash
cd /tmp/opentelemetry-issue-1-task07/TracingSample

git add -A
git commit -m "task07: 副作用検証・ベンチマーク

- TracingBenchmarks: パフォーマンスベンチマーク
- MemoryTests: メモリリーク検証
- BackwardCompatibilityTests: 後方互換性検証
- 副作用検証レポート作成"

git rev-parse HEAD
```

---

## 注意事項

- ベンチマークはReleaseビルドで実行すること
- メモリテストはGC.Collect()を適切に使用すること
- 既存コードを変更しないこと
