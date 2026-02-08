# タスク: task02 - TraceContext/TraceScope実装

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task02 |
| タスク名 | TraceContext/TraceScope実装 |
| 前提条件タスク | task01 |
| 並列実行可否 | 不可 |
| 推定所要時間 | 2.5時間 |
| 優先度 | 高 |

---

## 作業環境

- **作業ディレクトリ（worktree）**: /tmp/opentelemetry-issue-1-task02/
- **ブランチ**: opentelemetry-issue-1-task02
- **対象リポジトリ**: TracingSample
- **重要**: 必ず上記の作業ディレクトリ内で作業を行ってください

---

## 前提条件

### 前提タスク成果物

| タスク | 成果物パス | 参照内容 |
|--------|------------|----------|
| task01 | `src/TracingSample.Tracing/Helpers/TracingOptions.cs` | TracingOptionsクラス |
| task01 | `src/TracingSample.Tracing/Internal/NoOpScope.cs` | NoOpScopeクラス |

### 確認事項

- [ ] task01が完了していること
- [ ] task01の成果物（TracingOptions, NoOpScope）が存在すること
- [ ] task01のコミットがcherry-pick済みであること

---

## 作業内容

### 目的

トレースコンテキストの管理と伝播を行う`TraceContext`クラスと、トレーススコープを表す`TraceScope`クラスを実装する。これらは他のヘルパークラスの基盤となる。

### 設計参照

- [dev-design/02_interface-api-design.md](../dev-design/02_interface-api-design.md) - 3.2 TraceContext クラス
- [dev-design/03_data-structure-design.md](../dev-design/03_data-structure-design.md) - 3.1 TraceScope, 3.3 ContextRestorationScope
- [dev-design/04_processing-flow-design.md](../dev-design/04_processing-flow-design.md) - 4.2 TraceContext.Capture と Restore

### 実装ステップ

1. **TraceScope クラス実装**
   - IDisposable実装
   - Activityのラップ
   - タグ追加、イベント追加、例外記録メソッド
   - 状態管理（IsDisposed）

2. **ContextRestorationScope クラス実装**
   - コンテキスト復元のスコープ管理
   - Dispose時の元コンテキスト復元

3. **TraceContext 静的クラス実装**
   - Current プロパティ
   - Capture() メソッド
   - Restore() メソッド
   - Run/RunAsync メソッド
   - RunWithContext メソッド

4. **単体テスト実装**
   - TraceScope のライフサイクルテスト
   - TraceContext のコンテキスト伝播テスト

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `src/TracingSample.Tracing/Helpers/TraceScope.cs` | 新規作成 | トレーススコープクラス |
| `src/TracingSample.Tracing/Helpers/TraceContext.cs` | 新規作成 | コンテキスト管理静的クラス |
| `src/TracingSample.Tracing/Internal/ContextRestorationScope.cs` | 新規作成 | コンテキスト復元スコープ |
| `tests/TracingSample.Tracing.Tests/Unit/TraceScopeTests.cs` | 新規作成 | TraceScopeテスト |
| `tests/TracingSample.Tracing.Tests/Unit/TraceContextTests.cs` | 新規作成 | TraceContextテスト |

---

## テスト方針（TDD: RED-GREEN-REFACTOR）

### RED: 失敗するテストケース

**テストファイル1**: `tests/TracingSample.Tracing.Tests/Unit/TraceScopeTests.cs`

```csharp
namespace TracingSample.Tracing.Tests.Unit;

public class TraceScopeTests : IDisposable
{
    private readonly ActivitySource _activitySource;
    private readonly ActivityListener _listener;
    private readonly List<Activity> _activities = new();

    public TraceScopeTests()
    {
        _activitySource = new ActivitySource("Test");
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
    public void TraceScope_WithActivity_DisposesActivityOnDispose()
    {
        // Arrange
        var activity = _activitySource.StartActivity("Test");
        var scope = new TraceScope(activity, null, TracingOptions.Default);

        // Act
        scope.Dispose();

        // Assert
        Assert.True(scope.IsDisposed);
    }

    [Fact]
    public void TraceScope_SetTag_AddsTagToActivity()
    {
        // Arrange
        var activity = _activitySource.StartActivity("Test");
        var scope = new TraceScope(activity, null, TracingOptions.Default);

        // Act
        scope.SetTag("test.key", "test.value");
        scope.Dispose();

        // Assert
        Assert.Contains(activity.Tags, t => t.Key == "test.key" && t.Value == "test.value");
    }

    [Fact]
    public void TraceScope_RecordException_SetsErrorStatus()
    {
        // Arrange
        var activity = _activitySource.StartActivity("Test");
        var scope = new TraceScope(activity, null, TracingOptions.Default);

        // Act
        scope.RecordException(new InvalidOperationException("Test error"));
        scope.Dispose();

        // Assert
        Assert.Equal(ActivityStatusCode.Error, activity.Status);
    }

    [Fact]
    public void TraceScope_Dispose_CanBeCalledMultipleTimes()
    {
        // Arrange
        var activity = _activitySource.StartActivity("Test");
        var scope = new TraceScope(activity, null, TracingOptions.Default);

        // Act & Assert (should not throw)
        scope.Dispose();
        scope.Dispose();
    }
}
```

**テストファイル2**: `tests/TracingSample.Tracing.Tests/Unit/TraceContextTests.cs`

```csharp
namespace TracingSample.Tracing.Tests.Unit;

public class TraceContextTests : IDisposable
{
    private readonly ActivitySource _activitySource;
    private readonly ActivityListener _listener;

    public TraceContextTests()
    {
        _activitySource = new ActivitySource("Test");
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
    public void Current_WithNoActivity_ReturnsDefault()
    {
        // Arrange
        Activity.Current = null;

        // Act
        var context = TraceContext.Current;

        // Assert
        Assert.Equal(default, context);
    }

    [Fact]
    public void Capture_WithActiveActivity_ReturnsActivityContext()
    {
        // Arrange
        using var activity = _activitySource.StartActivity("Test");

        // Act
        var context = TraceContext.Capture();

        // Assert
        Assert.NotEqual(default, context);
        Assert.Equal(activity.Context.TraceId, context.TraceId);
    }

    [Fact]
    public void Restore_WithValidContext_SetsParentContext()
    {
        // Arrange
        using var parentActivity = _activitySource.StartActivity("Parent");
        var parentContext = TraceContext.Capture();
        parentActivity.Dispose();

        // Act
        using (TraceContext.Restore(parentContext))
        {
            using var childActivity = _activitySource.StartActivity("Child");
            
            // Assert
            Assert.Equal(parentContext.TraceId, childActivity.Context.TraceId);
        }
    }

    [Fact]
    public async Task RunAsync_ExecutesActionWithContext()
    {
        // Arrange
        using var parentActivity = _activitySource.StartActivity("Parent");
        var parentContext = TraceContext.Capture();
        var executed = false;

        // Act
        await TraceContext.RunAsync(parentContext, async () =>
        {
            executed = true;
            await Task.Delay(1);
        });

        // Assert
        Assert.True(executed);
    }
}
```

**確認コマンド**:

```bash
cd /tmp/opentelemetry-issue-1-task02/TracingSample
dotnet test --filter "FullyQualifiedName~TraceScopeTests|FullyQualifiedName~TraceContextTests"
# 結果: FAIL（まだ実装がないため）
```

---

### GREEN: 最小限の実装

**実装ファイル1**: `src/TracingSample.Tracing/Helpers/TraceScope.cs`

```csharp
using System.Diagnostics;
using System.Text.Json;

namespace TracingSample.Tracing.Helpers;

/// <summary>
/// トレースのスコープを表すオブジェクト。
/// </summary>
public sealed class TraceScope : IDisposable
{
    public Activity? Activity { get; }
    public ActivityContext? PreviousContext { get; }
    public DateTimeOffset StartTime { get; }
    public bool IsDisposed { get; private set; }
    public TracingOptions Options { get; }

    public TraceScope(
        Activity? activity,
        ActivityContext? previousContext,
        TracingOptions options)
    {
        Activity = activity;
        PreviousContext = previousContext;
        StartTime = DateTimeOffset.UtcNow;
        Options = options;
        IsDisposed = false;
    }

    public TraceScope SetTag(string key, object? value)
    {
        Activity?.SetTag(key, SerializeValue(value));
        return this;
    }

    public TraceScope AddEvent(string name, IDictionary<string, object?>? tags = null)
    {
        if (Activity != null)
        {
            var eventTags = tags != null
                ? new ActivityTagsCollection(
                    tags.Select(kv => new KeyValuePair<string, object?>(kv.Key, kv.Value)))
                : null;
            Activity.AddEvent(new ActivityEvent(name, DateTimeOffset.UtcNow, eventTags));
        }
        return this;
    }

    public TraceScope RecordException(Exception ex)
    {
        if (Activity != null && Options.RecordException)
        {
            Activity.SetTag("exception.type", ex.GetType().FullName);
            Activity.SetTag("exception.message", ex.Message);
            Activity.SetTag("exception.stacktrace", ex.StackTrace);
            Activity.SetStatus(ActivityStatusCode.Error, ex.Message);
        }
        return this;
    }

    public TraceScope SetSuccess()
    {
        Activity?.SetStatus(ActivityStatusCode.Ok);
        return this;
    }

    public TraceScope SetError(string? description = null)
    {
        Activity?.SetStatus(ActivityStatusCode.Error, description);
        return this;
    }

    public void Dispose()
    {
        if (IsDisposed) return;
        IsDisposed = true;
        Activity?.Dispose();
    }

    private static string SerializeValue(object? value)
    {
        if (value == null) return "null";
        var type = value.GetType();
        if (type.IsPrimitive || type == typeof(string) || 
            type == typeof(decimal) || type == typeof(DateTime))
        {
            return value.ToString() ?? "null";
        }
        try
        {
            return JsonSerializer.Serialize(value, new JsonSerializerOptions
            {
                MaxDepth = 5,
                WriteIndented = false
            });
        }
        catch
        {
            return value.ToString() ?? type.Name;
        }
    }
}
```

**実装ファイル2**: `src/TracingSample.Tracing/Internal/ContextRestorationScope.cs`

```csharp
using System.Diagnostics;

namespace TracingSample.Tracing.Internal;

internal sealed class ContextRestorationScope : IDisposable
{
    private readonly Activity? _restoredActivity;
    private bool _isDisposed;

    internal ContextRestorationScope(ActivityContext context, ActivitySource? activitySource)
    {
        if (activitySource == null)
        {
            _restoredActivity = null;
            return;
        }

        _restoredActivity = activitySource.StartActivity(
            "ContextRestoration",
            ActivityKind.Internal,
            context);
    }

    public void Dispose()
    {
        if (_isDisposed) return;
        _isDisposed = true;
        _restoredActivity?.Dispose();
    }
}
```

**実装ファイル3**: `src/TracingSample.Tracing/Helpers/TraceContext.cs`

```csharp
using System.Diagnostics;
using TracingSample.Tracing.Internal;

namespace TracingSample.Tracing.Helpers;

/// <summary>
/// トレースコンテキストの管理と伝播を行うクラス。
/// </summary>
public static class TraceContext
{
    public static ActivitySource? DefaultActivitySource { get; set; }

    public static ActivityContext Current => Activity.Current?.Context ?? default;

    public static ActivityContext Capture() => Activity.Current?.Context ?? default;

    public static IDisposable Restore(ActivityContext context)
    {
        if (!context.IsValid() || DefaultActivitySource == null)
        {
            return NoOpScope.Instance;
        }
        return new ContextRestorationScope(context, DefaultActivitySource);
    }

    public static void Run(ActivityContext context, Action action)
    {
        using (Restore(context))
        {
            action();
        }
    }

    public static T Run<T>(ActivityContext context, Func<T> func)
    {
        using (Restore(context))
        {
            return func();
        }
    }

    public static async Task RunAsync(ActivityContext context, Func<Task> func)
    {
        using (Restore(context))
        {
            await func();
        }
    }

    public static async Task<T> RunAsync<T>(ActivityContext context, Func<Task<T>> func)
    {
        using (Restore(context))
        {
            return await func();
        }
    }

    public static async Task RunWithContext(Func<Task> action)
    {
        var context = Capture();
        await Task.Run(async () =>
        {
            using (Restore(context))
            {
                await action();
            }
        });
    }

    public static async Task<T> RunWithContext<T>(Func<Task<T>> func)
    {
        var context = Capture();
        return await Task.Run(async () =>
        {
            using (Restore(context))
            {
                return await func();
            }
        });
    }
}
```

**確認コマンド**:

```bash
cd /tmp/opentelemetry-issue-1-task02/TracingSample
dotnet test --filter "FullyQualifiedName~TraceScopeTests|FullyQualifiedName~TraceContextTests"
# 結果: PASS
```

---

### REFACTOR: コード改善

**改善ポイント**:

- [ ] XMLドキュメントの充実
- [ ] ActivityContext.IsValid() 拡張メソッドの確認
- [ ] スレッドセーフティの確認

**確認コマンド**:

```bash
cd /tmp/opentelemetry-issue-1-task02/TracingSample
dotnet build
dotnet test
```

---

## 成果物

### 期待される出力

| 成果物 | パス | 説明 |
|--------|------|------|
| TraceScope.cs | `src/TracingSample.Tracing/Helpers/TraceScope.cs` | スコープクラス |
| TraceContext.cs | `src/TracingSample.Tracing/Helpers/TraceContext.cs` | コンテキスト管理 |
| ContextRestorationScope.cs | `src/TracingSample.Tracing/Internal/ContextRestorationScope.cs` | 復元スコープ |
| テストコード | `tests/TracingSample.Tracing.Tests/Unit/` | 単体テスト |
| result.md | `docs/opentelemtry/dev-plan/results/task02-result.md` | 結果レポート |

---

## 完了条件

### 機能的条件

- [ ] TraceScopeがActivity管理とDispose処理を行う
- [ ] TraceScopeでタグ・イベント・例外の記録ができる
- [ ] TraceContext.Capture()で現在のコンテキストをキャプチャできる
- [ ] TraceContext.Restore()でコンテキストを復元できる
- [ ] Run/RunAsyncでコンテキスト付き処理を実行できる

### 品質条件

- [ ] 全テストが通過すること
- [ ] ビルドエラーがないこと
- [ ] 型安全であること

### ドキュメント条件

- [ ] result.md が作成されていること
- [ ] XMLドキュメントが記載されていること

---

## コミット

```bash
cd /tmp/opentelemetry-issue-1-task02/TracingSample

git add -A
git status
git diff --staged

git commit -m "task02: TraceContext/TraceScope実装

- TraceScope: トレーススコープ管理クラス
- TraceContext: コンテキスト伝播管理静的クラス
- ContextRestorationScope: コンテキスト復元スコープ
- 単体テスト追加"

git rev-parse HEAD
```

---

## 注意事項

- task01のNoOpScopeとTracingOptionsを活用すること
- DefaultActivitySourceが未設定の場合のグレースフルな動作を保証すること
- 複数回のDispose呼び出しに対応すること
