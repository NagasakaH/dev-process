# タスク: task05 - DI統合・サービス登録拡張

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task05 |
| タスク名 | DI統合・サービス登録拡張 |
| 前提条件タスク | task03-02, task04 |
| 並列実行可否 | 不可 |
| 推定所要時間 | 2時間 |
| 優先度 | 高 |

---

## 作業環境

- **作業ディレクトリ（worktree）**: /tmp/opentelemetry-issue-1-task05/
- **ブランチ**: opentelemetry-issue-1-task05
- **対象リポジトリ**: TracingSample
- **重要**: 必ず上記の作業ディレクトリ内で作業を行ってください

---

## 前提条件

### 前提タスク成果物

| タスク | 成果物パス | 参照内容 |
|--------|------------|----------|
| task03-01 | `src/TracingSample.Tracing/Helpers/TraceHelper.cs` | TraceHelper |
| task02 | `src/TracingSample.Tracing/Helpers/TraceContext.cs` | TraceContext |
| task01 | `src/TracingSample.Tracing/Helpers/TracingOptions.cs` | TracingOptions |

### 確認事項

- [ ] task03-01, task03-02, task04が完了していること
- [ ] 全ヘルパークラスが実装されていること
- [ ] 前提タスクのコミットがcherry-pick済みであること

---

## 作業内容

### 目的

トレーシングヘルパーをDIコンテナに統合し、アプリケーション起動時に簡単に設定できるようにする。既存のServiceCollectionExtensionsを拡張する。

### 設計参照

- [dev-design/02_interface-api-design.md](../dev-design/02_interface-api-design.md) - 5. DI登録の拡張
- [dev-design/04_processing-flow-design.md](../dev-design/04_processing-flow-design.md) - 9. 初期化フロー

### 実装ステップ

1. **TracingServiceCollectionExtensions 作成**
   - AddTracingHelpers メソッド
   - ActivitySource初期化
   - TraceHelper/TraceContext初期設定

2. **既存ServiceCollectionExtensions の拡張**
   - 新規ヘルパーとの統合

3. **統合テスト実装**
   - DI統合の確認

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `src/TracingSample.Tracing/Extensions/TracingServiceCollectionExtensions.cs` | 新規作成 | DI統合拡張 |
| `src/TracingSample.Tracing/Extensions/ServiceCollectionExtensions.cs` | 修正 | 既存拡張の統合 |
| `tests/TracingSample.Tracing.Tests/Integration/DIIntegrationTests.cs` | 新規作成 | 統合テスト |

---

## テスト方針（TDD: RED-GREEN-REFACTOR）

### RED: 失敗するテストケース

**テストファイル**: `tests/TracingSample.Tracing.Tests/Integration/DIIntegrationTests.cs`

```csharp
namespace TracingSample.Tracing.Tests.Integration;

public class DIIntegrationTests : IDisposable
{
    private readonly ServiceProvider _provider;
    private readonly ActivityListener _listener;
    private readonly List<Activity> _activities = new();

    public DIIntegrationTests()
    {
        var services = new ServiceCollection();
        services.AddTracingHelpers("DIIntegrationTest");
        _provider = services.BuildServiceProvider();

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
        _provider.Dispose();
        _listener.Dispose();
    }

    [Fact]
    public void AddTracingHelpers_RegistersActivitySource()
    {
        // Act
        var activitySource = _provider.GetRequiredService<ActivitySource>();

        // Assert
        Assert.NotNull(activitySource);
        Assert.Equal("DIIntegrationTest", activitySource.Name);
    }

    [Fact]
    public void AddTracingHelpers_SetsTraceHelperDefaultActivitySource()
    {
        // Assert
        Assert.NotNull(TraceHelper.DefaultActivitySource);
        Assert.Equal("DIIntegrationTest", TraceHelper.DefaultActivitySource.Name);
    }

    [Fact]
    public void AddTracingHelpers_SetsTraceContextDefaultActivitySource()
    {
        // Assert
        Assert.NotNull(TraceContext.DefaultActivitySource);
        Assert.Equal("DIIntegrationTest", TraceContext.DefaultActivitySource.Name);
    }

    [Fact]
    public void TracedService_WithHelpers_CreatesActivity()
    {
        // Arrange
        var services = new ServiceCollection();
        services.AddTracingHelpers("TestApp");
        services.AddTracedScoped<ITestService, TestService>();
        using var provider = services.BuildServiceProvider();
        _activities.Clear();

        // Act
        using var scope = provider.CreateScope();
        var service = scope.ServiceProvider.GetRequiredService<ITestService>();
        service.DoWork();

        // Assert
        Assert.NotEmpty(_activities);
    }

    [Fact]
    public void TraceHelper_WithDI_CreatesActivity()
    {
        // Arrange
        _activities.Clear();

        // Act
        using (TraceHelper.StartTrace("DITraceTest"))
        {
            // 処理
        }

        // Assert
        Assert.Single(_activities);
        Assert.Equal("DITraceTest", _activities[0].DisplayName);
    }

    [Fact]
    public void AddTracingHelpers_WithOptions_ConfiguresOptions()
    {
        // Arrange
        var services = new ServiceCollection();
        services.AddTracingHelpers("TestApp", options =>
        {
            options.RecordParameters = false;
            options.SamplingRate = 0.5;
        });
        using var provider = services.BuildServiceProvider();

        // Act
        var options = provider.GetRequiredService<TracingOptions>();

        // Assert
        Assert.False(options.RecordParameters);
        Assert.Equal(0.5, options.SamplingRate);
    }
}

// テスト用インターフェース/クラス
public interface ITestService
{
    void DoWork();
}

public class TestService : ITestService
{
    [Trace]
    public void DoWork()
    {
        // 処理
    }
}
```

---

### GREEN: 最小限の実装

**実装ファイル**: `src/TracingSample.Tracing/Extensions/TracingServiceCollectionExtensions.cs`

```csharp
using System.Diagnostics;
using Microsoft.Extensions.DependencyInjection;
using TracingSample.Tracing.Helpers;

namespace TracingSample.Tracing.Extensions;

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
        return AddTracingHelpers(services, activitySourceName, null);
    }

    /// <summary>
    /// トレーシングヘルパーを初期化します（オプション設定付き）。
    /// </summary>
    /// <param name="services">サービスコレクション</param>
    /// <param name="activitySourceName">ActivitySource名</param>
    /// <param name="configureOptions">オプション設定アクション</param>
    /// <returns>サービスコレクション</returns>
    public static IServiceCollection AddTracingHelpers(
        this IServiceCollection services,
        string activitySourceName,
        Action<TracingOptions>? configureOptions)
    {
        // ActivitySource作成・登録
        var activitySource = new ActivitySource(activitySourceName);
        services.AddSingleton(activitySource);

        // オプション設定
        var options = new TracingOptions();
        configureOptions?.Invoke(options);
        services.AddSingleton(options);

        // TraceHelper/TraceContextにデフォルトActivitySourceを設定
        TraceHelper.DefaultActivitySource = activitySource;
        TraceContext.DefaultActivitySource = activitySource;

        return services;
    }

    /// <summary>
    /// トレーシングヘルパーを初期化し、OpenTelemetryと統合します。
    /// </summary>
    /// <param name="services">サービスコレクション</param>
    /// <param name="activitySourceName">ActivitySource名</param>
    /// <param name="configureOptions">オプション設定アクション</param>
    /// <returns>サービスコレクション</returns>
    public static IServiceCollection AddTracingHelpersWithOpenTelemetry(
        this IServiceCollection services,
        string activitySourceName,
        Action<TracingOptions>? configureOptions = null)
    {
        AddTracingHelpers(services, activitySourceName, configureOptions);

        // OpenTelemetry設定への追加ソース登録ヒント
        // 実際のOpenTelemetry設定はアプリケーション側で行う
        // services.AddOpenTelemetry().WithTracing(b => b.AddSource(activitySourceName));

        return services;
    }
}
```

**修正ファイル**: `src/TracingSample.Tracing/Extensions/ServiceCollectionExtensions.cs` に以下を追加：

```csharp
// ファイル末尾に追加（既存メソッドは変更しない）

/// <summary>
/// トレーシングヘルパーを初期化した上でサービスを登録します。
/// </summary>
/// <remarks>
/// このメソッドはAddTracingHelpersを内部で呼び出します。
/// 既にAddTracingHelpersを呼び出している場合は、AddTracedScopedのみを使用してください。
/// </remarks>
public static IServiceCollection AddTracedScopedWithHelpers<TInterface, TImplementation>(
    this IServiceCollection services,
    string activitySourceName = "TracingSample.Core")
    where TInterface : class
    where TImplementation : class, TInterface
{
    services.AddTracingHelpers(activitySourceName);
    return services.AddTracedScoped<TInterface, TImplementation>();
}
```

---

### REFACTOR: コード改善

**改善ポイント**:

- [ ] ActivitySourceの寿命管理（IDisposable対応）
- [ ] 重複登録の防止
- [ ] ログ出力の追加

---

## 成果物

| 成果物 | パス | 説明 |
|--------|------|------|
| TracingServiceCollectionExtensions.cs | `src/TracingSample.Tracing/Extensions/` | DI統合 |
| テストコード | `tests/TracingSample.Tracing.Tests/Integration/` | 統合テスト |
| result.md | `docs/opentelemtry/dev-plan/results/task05-result.md` | 結果レポート |

---

## 完了条件

### 機能的条件

- [ ] AddTracingHelpers でActivitySourceが登録される
- [ ] TraceHelper.DefaultActivitySourceが設定される
- [ ] TraceContext.DefaultActivitySourceが設定される
- [ ] オプション設定が反映される
- [ ] 既存のAddTracedScoped等と併用できる

### 品質条件

- [ ] 全テストが通過すること
- [ ] 既存テストに影響がないこと

---

## コミット

```bash
cd /tmp/opentelemetry-issue-1-task05/TracingSample

git add -A
git commit -m "task05: DI統合・サービス登録拡張

- TracingServiceCollectionExtensions: DI統合拡張メソッド
- AddTracingHelpers: ヘルパー初期化
- AddTracingHelpersWithOpenTelemetry: OpenTelemetry統合
- 統合テスト追加"

git rev-parse HEAD
```

---

## 注意事項

- 既存のServiceCollectionExtensionsのメソッドは変更しないこと
- 追加のみ行うこと
- TraceHelper/TraceContextへのActivitySource設定は1回のみ
