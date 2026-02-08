# タスク: task08 - ドキュメント・使用例作成

## タスク情報

| 項目 | 値 |
|------|-----|
| タスク識別子 | task08 |
| タスク名 | ドキュメント・使用例作成 |
| 前提条件タスク | task07 |
| 並列実行可否 | 不可 |
| 推定所要時間 | 1時間 |
| 優先度 | 中 |

---

## 作業環境

- **作業ディレクトリ（worktree）**: /tmp/opentelemetry-issue-1-task08/
- **ブランチ**: opentelemetry-issue-1-task08
- **対象リポジトリ**: TracingSample
- **重要**: 必ず上記の作業ディレクトリ内で作業を行ってください

---

## 前提条件

### 前提タスク成果物

| タスク | 成果物パス | 参照内容 |
|--------|------------|----------|
| task07 | 副作用検証完了 | 全検証PASS |
| task01-07 | 全実装完了 | 全機能実装済み |

### 確認事項

- [ ] task07が完了していること
- [ ] 副作用検証がPASSしていること

---

## 作業内容

### 目的

新規追加したトレーシングヘルパーの使用方法を文書化し、開発者が簡単に導入できるようにする。

### 設計参照

- [dev-design/02_interface-api-design.md](../dev-design/02_interface-api-design.md) - 4. 使用例

### 実装ステップ

1. **README更新**
   - 新機能の概要追加
   - クイックスタートガイド

2. **使用例ドキュメント作成**
   - 各パターンの使用例
   - ベストプラクティス

3. **APIリファレンス**
   - 主要クラスの説明
   - メソッド一覧

### 対象ファイル

| ファイル | 操作 | 説明 |
|----------|------|------|
| `TracingSample/README.md` | 修正 | 新機能セクション追加 |
| `TracingSample/docs/TraceHelper-Guide.md` | 新規作成 | ヘルパー使用ガイド |
| `TracingSample/docs/Patterns-Guide.md` | 新規作成 | パターン別ガイド |

---

## ドキュメント内容

### README.md に追加するセクション

```markdown
## 新機能: トレーシングヘルパー

### 概要

TracingSample v2.0では、staticメソッドや並列処理でもトレースを簡単に取得できるヘルパークラスを追加しました。

### クイックスタート

```csharp
// 1. DIでセットアップ
services.AddTracingHelpers("MyApplication");
services.AddTracedScoped<IMyService, MyService>();

// 2. staticメソッドでトレース
public static class MyUtils
{
    public static int Calculate(int a, int b)
    {
        return TraceHelper.Wrap("MyUtils.Calculate", () => a + b);
    }
}

// 3. 並列処理でトレース
await ParallelTraceHelper.ForEachAsync(
    items,
    item => $"Process-{item.Id}",
    async item => await ProcessAsync(item));
```

### 詳細ドキュメント

- [TraceHelper使用ガイド](docs/TraceHelper-Guide.md)
- [パターン別ガイド](docs/Patterns-Guide.md)
```

### TraceHelper-Guide.md

```markdown
# TraceHelper 使用ガイド

## 概要

`TraceHelper`は、DIを使用しないstaticメソッドやユーティリティクラスで手動トレースを実現するためのヘルパークラスです。

## セットアップ

```csharp
// Program.cs
var builder = Host.CreateApplicationBuilder(args);
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
```

## 基本的な使い方

### 1. シンプルなトレース

```csharp
// using文でスコープ管理
using (TraceHelper.StartTrace("MyOperation"))
{
    // 処理
}

// Wrapメソッドで簡潔に
TraceHelper.Wrap("MyOperation", () =>
{
    // 処理
});
```

### 2. 戻り値のあるトレース

```csharp
var result = TraceHelper.Wrap("Calculate", () =>
{
    return ComputeValue();
});
```

### 3. 非同期トレース

```csharp
await TraceHelper.WrapAsync("AsyncOperation", async () =>
{
    await DoWorkAsync();
});

var result = await TraceHelper.WrapAsync("FetchData", async () =>
{
    return await FetchDataAsync();
});
```

### 4. タグとイベントの追加

```csharp
using (TraceHelper.StartTrace("ProcessOrder"))
{
    TraceHelper.SetTag("order.id", orderId);
    TraceHelper.AddEvent("ValidationStarted");
    
    // 処理
    
    TraceHelper.AddEvent("ValidationCompleted");
}
```

### 5. 例外の記録

```csharp
try
{
    using (TraceHelper.StartTrace("RiskyOperation"))
    {
        DoRiskyWork();
    }
}
catch (Exception ex)
{
    TraceHelper.RecordException(ex);
    throw;
}
```

## 高度な使い方

### 親コンテキストの伝播

```csharp
// 親コンテキストをキャプチャ
var parentContext = TraceContext.Capture();

// 別スレッドで使用
await Task.Run(() =>
{
    using (TraceContext.Restore(parentContext))
    using (TraceHelper.StartTrace("ChildOperation"))
    {
        // 親子関係が維持される
    }
});
```

### Fire-and-Forgetパターン

```csharp
var linkedContext = TraceContext.Capture();

// Fire-and-forget（親子ではなくリンク関係）
_ = Task.Run(() =>
{
    using (TraceHelper.StartLinkedTrace("BackgroundJob", linkedContext))
    {
        DoBackgroundWork();
    }
});
```

## ベストプラクティス

1. **トレース名は意味のある名前を使用**
   - ✅ `OrderService.ProcessOrder`
   - ❌ `Method1`

2. **重要なパラメータをタグに追加**
   - 顧客ID、注文ID、処理件数など

3. **例外は必ず記録**
   - `RecordException`を使用

4. **機密情報はマスク**
   - パスワード、トークンなどはタグに追加しない
```

### Patterns-Guide.md

```markdown
# パターン別トレーシングガイド

## 1. staticメソッド

```csharp
public static class OrderUtils
{
    public static decimal CalculateTotal(List<OrderItem> items)
    {
        return TraceHelper.Wrap("OrderUtils.CalculateTotal", () =>
        {
            TraceHelper.SetTag("item.count", items.Count);
            return items.Sum(i => i.Quantity * i.UnitPrice);
        });
    }
}
```

## 2. 並列処理 (Parallel.ForEach)

```csharp
// ParallelTraceHelperを使用
await ParallelTraceHelper.ForEachAsync(
    orders,
    order => $"ProcessOrder-{order.Id}",
    async order => await ProcessOrderAsync(order),
    maxDegreeOfParallelism: 4);
```

## 3. Task.WhenAll

```csharp
await ParallelTraceHelper.WhenAll(
    ("FetchCustomer", FetchCustomerAsync(customerId)),
    ("FetchOrders", FetchOrdersAsync(customerId)),
    ("FetchPreferences", FetchPreferencesAsync(customerId)));
```

## 4. 新規スレッド

```csharp
var context = TraceContext.Capture();

var thread = new Thread(() =>
{
    using (TraceContext.Restore(context))
    using (TraceHelper.StartTrace("ThreadWork"))
    {
        DoWork();
    }
});
thread.Start();
```

## 5. ThreadPool

```csharp
var context = TraceContext.Capture();

ThreadPool.QueueUserWorkItem(_ =>
{
    using (TraceContext.Restore(context))
    using (TraceHelper.StartTrace("ThreadPoolWork"))
    {
        DoWork();
    }
});
```

## 6. Task.Run

```csharp
await TraceContext.RunWithContext(async () =>
{
    // 親コンテキストが自動的に伝播
    await DoWorkAsync();
});
```

## 7. PLINQ

```csharp
var context = TraceContext.Capture();

var results = items.AsParallel()
    .Select(item =>
    {
        using (TraceContext.Restore(context))
        using (TraceHelper.StartTrace($"Process-{item.Id}"))
        {
            return ProcessItem(item);
        }
    })
    .ToList();
```

## 8. DIサービスとstaticの混在

```csharp
public class OrderService : IOrderService
{
    [Trace]  // DIサービスは自動トレース
    public async Task<Order> ProcessOrder(string customerId, List<OrderItem> items)
    {
        await _inventoryService.CheckStock(items);  // 自動
        
        var total = OrderUtils.CalculateTotal(items);  // TraceHelper使用
        
        await _paymentService.ProcessPayment(customerId, total);  // 自動
        
        return CreateOrder(customerId, items, total);
    }
}
```

## 9. 例外処理

```csharp
try
{
    await TraceHelper.WrapAsync("RiskyOperation", async () =>
    {
        await DoRiskyWorkAsync();
    });
}
catch (Exception ex)
{
    // WrapAsyncは自動的に例外を記録してrethrowする
    _logger.LogError(ex, "Operation failed");
    throw;
}
```

## 10. キャンセル対応

```csharp
await ParallelTraceHelper.ForEachAsync(
    items,
    item => $"Process-{item.Id}",
    async item =>
    {
        cancellationToken.ThrowIfCancellationRequested();
        await ProcessAsync(item);
    });
```
```

---

## 成果物

| 成果物 | パス | 説明 |
|--------|------|------|
| README.md更新 | `TracingSample/README.md` | 新機能セクション |
| TraceHelper-Guide.md | `TracingSample/docs/TraceHelper-Guide.md` | ヘルパーガイド |
| Patterns-Guide.md | `TracingSample/docs/Patterns-Guide.md` | パターン別ガイド |
| result.md | `docs/opentelemtry/dev-plan/results/task08-result.md` | 結果レポート |

---

## 完了条件

### 機能的条件

- [ ] READMEに新機能セクションが追加されている
- [ ] TraceHelper使用ガイドが作成されている
- [ ] パターン別ガイドが作成されている

### 品質条件

- [ ] コード例がコンパイル可能であること
- [ ] 日本語/英語の表記が統一されていること

### ドキュメント条件

- [ ] 全使用パターンがカバーされていること
- [ ] ベストプラクティスが記載されていること

---

## コミット

```bash
cd /tmp/opentelemetry-issue-1-task08/TracingSample

git add -A
git commit -m "task08: ドキュメント・使用例作成

- README.md: 新機能セクション追加
- docs/TraceHelper-Guide.md: ヘルパー使用ガイド
- docs/Patterns-Guide.md: パターン別ガイド
- ベストプラクティス記載"

git rev-parse HEAD
```

---

## 注意事項

- コード例は実際にコンパイル可能なものにすること
- 既存のREADMEの構成を壊さないこと
- 初心者にも分かりやすい説明を心がけること
