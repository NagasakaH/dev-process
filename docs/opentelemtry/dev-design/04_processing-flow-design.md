# 処理フロー設計

## 1. 概要

トレーシングライブラリの各コンポーネントにおける処理フローを定義します。

## 2. 全体アーキテクチャ

```mermaid
graph TB
    subgraph Application Layer
        A[ユーザーコード]
        B[DIサービス]
        C[Staticメソッド]
    end
    
    subgraph Tracing Library
        D[TracingProxy]
        E[TraceHelper]
        F[TraceContext]
        G[ParallelTraceHelper]
    end
    
    subgraph OpenTelemetry
        H[ActivitySource]
        I[Activity]
        J[Exporter]
    end
    
    subgraph Backend
        K[Jaeger]
    end
    
    A --> B
    A --> C
    B --> D
    C --> E
    D --> H
    E --> H
    E --> F
    G --> F
    H --> I
    I --> J
    J --> K
```

## 3. 主要処理フロー

### 3.1 DIサービス経由のトレースフロー

```mermaid
sequenceDiagram
    participant Caller as 呼び出し元
    participant Proxy as TracingProxy
    participant Cache as MethodTraceInfoCache
    participant AS as ActivitySource
    participant Activity as Activity
    participant Target as 実装クラス
    participant Export as Exporter
    
    Caller->>Proxy: メソッド呼び出し
    Proxy->>Cache: GetOrCreate(method)
    Cache-->>Proxy: MethodTraceInfo
    
    alt [Trace]属性あり
        Proxy->>AS: StartActivity(name, kind)
        AS-->>Proxy: Activity
        
        Proxy->>Activity: SetTag(method.name)
        Proxy->>Activity: SetTag(parameters)
        
        Proxy->>Target: メソッド実行
        
        alt 同期メソッド
            Target-->>Proxy: 結果
            Proxy->>Activity: SetTag(return.value)
            Proxy->>Activity: SetStatus(Ok)
            Proxy->>Activity: Dispose()
        else 非同期メソッド
            Target-->>Proxy: Task
            Proxy-->>Caller: WrappedTask
            Note over Proxy: Task完了後にActivityをDispose
        end
    else [Trace]属性なし
        Proxy->>Target: メソッド実行（トレースなし）
        Target-->>Proxy: 結果
    end
    
    Proxy-->>Caller: 結果
    Activity->>Export: バッチ送信
```

### 3.2 TraceHelper経由のトレースフロー

```mermaid
sequenceDiagram
    participant Caller as 呼び出し元
    participant TH as TraceHelper
    participant TC as TraceContext
    participant AS as ActivitySource
    participant Activity as Activity
    
    Caller->>TH: StartTrace(name)
    TH->>AS: StartActivity(name, kind)
    AS-->>TH: Activity
    TH->>TH: TraceScope作成
    TH-->>Caller: TraceScope
    
    Note over Caller: using スコープ内で処理
    
    Caller->>Caller: SetTag()
    Caller->>Caller: AddEvent()
    Caller->>Caller: 業務処理
    
    Caller->>TH: Dispose (using終了)
    TH->>Activity: SetStatus()
    TH->>Activity: Dispose()
```

### 3.3 親コンテキスト伝播フロー

```mermaid
sequenceDiagram
    participant T1 as Thread 1
    participant TC as TraceContext
    participant T2 as Thread 2
    participant TH as TraceHelper
    participant AS as ActivitySource
    
    T1->>T1: 処理開始
    T1->>TC: Capture()
    TC->>TC: Activity.Current?.Context
    TC-->>T1: ActivityContext
    
    T1->>T2: new Thread with context
    
    activate T2
    T2->>TC: Restore(context)
    TC->>AS: StartActivity("Restore", parent=context)
    TC-->>T2: ContextRestorationScope
    
    T2->>TH: StartTrace("ChildOp")
    Note over TH: 親はRestoreしたcontext
    TH-->>T2: TraceScope
    
    T2->>T2: 処理
    
    T2->>TH: Dispose
    T2->>TC: Dispose (ContextRestorationScope)
    deactivate T2
```

### 3.4 並列処理トレースフロー

```mermaid
sequenceDiagram
    participant Caller as 呼び出し元
    participant PTH as ParallelTraceHelper
    participant TC as TraceContext
    participant AS as ActivitySource
    
    Caller->>PTH: ForEachAsync(items, action)
    PTH->>TC: Capture()
    TC-->>PTH: parentContext
    
    par 各アイテム並列処理
        PTH->>AS: StartActivity("Item-1", parent)
        PTH->>PTH: action(item1)
        PTH->>AS: Dispose Activity
    and
        PTH->>AS: StartActivity("Item-2", parent)
        PTH->>PTH: action(item2)
        PTH->>AS: Dispose Activity
    and
        PTH->>AS: StartActivity("Item-3", parent)
        PTH->>PTH: action(item3)
        PTH->>AS: Dispose Activity
    end
    
    PTH-->>Caller: 完了
```

## 4. 詳細処理フロー

### 4.1 TraceHelper.StartTrace

```mermaid
flowchart TD
    A[StartTrace呼び出し] --> B{ActivitySource設定済?}
    B -->|No| C[例外 or NoOpScope返却]
    B -->|Yes| D{親コンテキスト指定?}
    
    D -->|Yes| E[StartActivity with parent]
    D -->|No| F[StartActivity]
    
    E --> G{Activity作成成功?}
    F --> G
    
    G -->|Yes| H[タグ設定]
    G -->|No| I[NoOpScope返却]
    
    H --> J[TraceScope作成]
    J --> K[TraceScope返却]
```

**実装詳細**:

```csharp
public static IDisposable StartTrace(
    string name,
    ActivityKind kind = ActivityKind.Internal)
{
    if (DefaultActivitySource == null)
    {
        // ActivitySourceが未設定の場合は何もしないスコープを返す
        return NoOpScope.Instance;
    }

    var activity = DefaultActivitySource.StartActivity(name, kind);
    
    return new TraceScope(activity, Activity.Current?.Context, TracingOptions.Default);
}

public static IDisposable StartTrace(
    string name,
    ActivityContext parentContext,
    ActivityKind kind = ActivityKind.Internal)
{
    if (DefaultActivitySource == null)
    {
        return NoOpScope.Instance;
    }

    var activity = DefaultActivitySource.StartActivity(
        name,
        kind,
        parentContext);
    
    return new TraceScope(activity, parentContext, TracingOptions.Default);
}
```

### 4.2 TraceContext.Capture と Restore

```mermaid
flowchart TD
    subgraph Capture
        A1[Capture呼び出し] --> B1{Activity.Current存在?}
        B1 -->|Yes| C1[Activity.Current.Context取得]
        B1 -->|No| D1[default ActivityContext返却]
        C1 --> E1[ActivityContext返却]
    end
    
    subgraph Restore
        A2[Restore呼び出し] --> B2{Context有効?}
        B2 -->|No| C2[NoOpScope返却]
        B2 -->|Yes| D2[ContextRestorationScope作成]
        D2 --> E2[親としてActivity開始]
        E2 --> F2[Scope返却]
    end
```

**実装詳細**:

```csharp
public static ActivityContext Capture()
{
    return Activity.Current?.Context ?? default;
}

public static IDisposable Restore(ActivityContext context)
{
    if (!context.IsValid())
    {
        return NoOpScope.Instance;
    }

    return new ContextRestorationScope(context, DefaultActivitySource);
}
```

### 4.3 非同期メソッドのActivity管理

```mermaid
flowchart TD
    A[async メソッド開始] --> B[Activity開始]
    B --> C[メソッド実行開始]
    C --> D[Task返却]
    D --> E{Task<T>?}
    
    E -->|Yes| F[ContinueWithResult<T>]
    E -->|No| G[ContinueWithTask]
    
    F --> H[await task]
    G --> H
    
    H --> I{例外発生?}
    I -->|Yes| J[RecordException]
    I -->|No| K[RecordReturnValue]
    
    J --> L[SetStatus Error]
    K --> M[SetStatus Ok]
    
    L --> N[Activity.Dispose]
    M --> N
    
    N --> O[結果/例外を伝播]
```

### 4.4 ParallelTraceHelper.ForEachAsync

```mermaid
flowchart TD
    A[ForEachAsync呼び出し] --> B[親コンテキストキャプチャ]
    B --> C[SemaphoreSlim作成]
    C --> D[タスクリスト初期化]
    
    D --> E{items残り?}
    E -->|Yes| F[セマフォ待機]
    F --> G[タスク生成]
    
    G --> H[親コンテキスト復元]
    H --> I[Activity開始]
    I --> J[action実行]
    J --> K[Activity終了]
    K --> L[セマフォ解放]
    L --> E
    
    E -->|No| M[Task.WhenAll]
    M --> N[完了]
```

**実装詳細**:

```csharp
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
```

## 5. 例外処理フロー

### 5.1 同期メソッドでの例外

```mermaid
flowchart TD
    A[メソッド呼び出し] --> B[Activity開始]
    B --> C[try: メソッド実行]
    C --> D{例外発生?}
    
    D -->|No| E[戻り値記録]
    E --> F[SetStatus Ok]
    F --> G[Activity.Dispose]
    G --> H[結果返却]
    
    D -->|Yes| I[catch: 例外キャッチ]
    I --> J{RecordException有効?}
    J -->|Yes| K[例外情報記録]
    J -->|No| L[スキップ]
    K --> M[SetStatus Error]
    L --> M
    M --> N[Activity.Dispose]
    N --> O[例外再throw]
```

### 5.2 非同期メソッドでの例外

```mermaid
flowchart TD
    A[async メソッド呼び出し] --> B[Activity開始]
    B --> C[メソッド実行]
    C --> D[Task返却]
    D --> E[ContinueWith登録]
    
    E --> F{await完了}
    F --> G{例外発生?}
    
    G -->|No| H[戻り値記録]
    H --> I[SetStatus Ok]
    
    G -->|Yes| J{TaskCanceledException?}
    J -->|Yes| K[SetStatus Error "Canceled"]
    J -->|No| L[例外情報記録]
    L --> M[SetStatus Error]
    
    K --> N[finally: Activity.Dispose]
    M --> N
    I --> N
    
    N --> O[結果/例外伝播]
```

## 6. Fire-and-Forget対応

### 6.1 推奨パターン

```mermaid
sequenceDiagram
    participant Parent as 親処理
    participant TC as TraceContext
    participant Child as 子タスク
    participant Link as TraceLink
    
    Parent->>Parent: Activity開始
    Parent->>TC: Capture()
    TC-->>Parent: parentContext
    
    Parent->>Child: Task起動(Fire-and-Forget)
    Note over Parent,Child: Link経由で関連付け
    
    Parent->>Parent: Activity終了
    
    activate Child
    Child->>Child: 新しいルートActivity開始
    Child->>Link: AddLink(parentContext)
    Note over Child: 親子ではなくリンク関係
    Child->>Child: 処理
    Child->>Child: Activity終了
    deactivate Child
```

**実装例**:

```csharp
public static class TraceHelper
{
    /// <summary>
    /// Fire-and-Forget用のトレース開始
    /// 親子関係ではなく、リンク関係でトレースを関連付けます
    /// </summary>
    public static IDisposable StartLinkedTrace(
        string name,
        ActivityContext linkedContext)
    {
        if (DefaultActivitySource == null)
            return NoOpScope.Instance;

        // 新しいルートトレースとして開始
        var activity = DefaultActivitySource.StartActivity(name, ActivityKind.Internal);
        
        // リンクとして関連付け（親子ではない）
        activity?.AddLink(new ActivityLink(linkedContext));
        
        return new TraceScope(activity, null, TracingOptions.Default);
    }
}
```

## 7. サンプリング制御フロー

```mermaid
flowchart TD
    A[トレース開始要求] --> B{サンプリング有効?}
    B -->|No| C[常にトレース]
    B -->|Yes| D{サンプルレート判定}
    
    D --> E[乱数生成 0.0-1.0]
    E --> F{乱数 <= SamplingRate?}
    
    F -->|Yes| G[トレース実行]
    F -->|No| H[スキップ NoOpScope]
    
    C --> G
    G --> I[Activity作成]
    H --> J[処理のみ実行]
```

## 8. ログ統合フロー

```mermaid
sequenceDiagram
    participant App as アプリケーション
    participant Logger as ILogger
    participant OTelLog as OpenTelemetry Logging
    participant Activity as Activity.Current
    participant Exporter as Exporter
    
    App->>App: Activity.Current設定済み
    App->>Logger: LogInformation("処理開始")
    
    Logger->>OTelLog: ログレコード作成
    OTelLog->>Activity: TraceId/SpanId取得
    Activity-->>OTelLog: Context情報
    OTelLog->>OTelLog: ログにContext付与
    
    OTelLog->>Exporter: ログ送信
    Note over Exporter: TraceIdでトレースと関連付け
```

## 9. 初期化フロー

### 9.1 アプリケーション起動時

```mermaid
flowchart TD
    A[アプリケーション起動] --> B[Host.CreateApplicationBuilder]
    B --> C[AddTracingHelpers呼び出し]
    
    C --> D[ActivitySource作成]
    D --> E[DIコンテナ登録]
    E --> F[TraceHelper.DefaultActivitySource設定]
    
    F --> G[AddOpenTelemetry設定]
    G --> H[AddSource登録]
    H --> I[Exporter設定]
    
    I --> J[Host.Build]
    J --> K[Host.StartAsync]
    K --> L[トレーシング準備完了]
```

### 9.2 初期化コード例

```csharp
var builder = Host.CreateApplicationBuilder(args);

// トレーシングヘルパー初期化
builder.Services.AddTracingHelpers("MyApplication");

// OpenTelemetry設定
builder.Services.AddOpenTelemetry()
    .ConfigureResource(r => r.AddService("MyApplication"))
    .WithTracing(tracing =>
    {
        tracing
            .AddSource("MyApplication")
            .AddOtlpExporter();
    });

// トレース有効なサービス登録
builder.Services.AddTracedScoped<IOrderService, OrderService>();

var host = builder.Build();
await host.RunAsync();
```

## 10. 終了フロー

```mermaid
flowchart TD
    A[アプリケーション終了要求] --> B[CancellationToken発火]
    B --> C[進行中のタスク待機]
    
    C --> D{未完了Activity存在?}
    D -->|Yes| E[Activity.Dispose]
    D -->|No| F[次へ]
    E --> F
    
    F --> G[TracerProvider.ForceFlush]
    G --> H[未送信スパン送信]
    H --> I[Exporter待機]
    I --> J[Host.StopAsync]
    J --> K[アプリケーション終了]
```

## 11. エラーリカバリーフロー

### 11.1 ActivitySource未設定時

```mermaid
flowchart TD
    A[TraceHelper.StartTrace] --> B{DefaultActivitySource != null?}
    B -->|No| C[警告ログ出力]
    C --> D[NoOpScope返却]
    D --> E[処理は継続]
    B -->|Yes| F[通常のトレース処理]
```

### 11.2 シリアライズエラー時

```mermaid
flowchart TD
    A[パラメータシリアライズ] --> B{シリアライズ成功?}
    B -->|Yes| C[タグとして設定]
    B -->|No| D[例外キャッチ]
    D --> E["[Serialization Error: ...]"として設定]
    E --> F[処理継続]
    C --> F
```

## 12. 次のステップ

1. テスト計画策定
2. 副作用検証計画策定
