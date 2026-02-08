# opentelemtry

> 最終更新: 2025-01-20

## 概要

OpenTelemetryを使用した.NET 8向け分散トレーシングのサンプルプロジェクト。メソッドに`[Trace]`アトリビュートを付与するだけで、パラメータ・戻り値・例外・実行時間を自動的にJaegerで可視化できる実践的なトレーシング機能を提供します。

---

## 優先度A（必須情報）

### 1. プロジェクト構成

```
opentelemtry/
├── .devcontainer/                        # DevContainer設定（Jaeger自動起動）
│   ├── devcontainer.json
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── README.md
├── TracingSample/                        # メインソリューション
│   ├── TracingSample.sln
│   ├── docker/
│   │   └── docker-compose.yml            # Jaeger単体起動設定
│   ├── src/
│   │   ├── TracingSample.Console/        # コンソールアプリケーション（エントリーポイント）
│   │   ├── TracingSample.Core/           # ビジネスロジック（EC注文処理サンプル）
│   │   ├── TracingSample.MultithreadedWorker/  # マルチスレッドワーカーサンプル
│   │   └── TracingSample.Tracing/        # トレーシング機能（再利用可能ライブラリ）
│   └── README.md
└── test-trace.cs
```

**主要ファイル:**
- `TracingSample.sln` - ソリューションファイル
- `src/TracingSample.Tracing/` - 他プロジェクトで再利用可能なトレーシングライブラリ
- `src/TracingSample.Console/Program.cs` - アプリケーションエントリーポイント

### 2. 外部公開インターフェース/API

#### TracingSample.Tracing（トレーシングライブラリ）

**TraceAttribute** - メソッドトレース用アトリビュート
```csharp
[Trace]                                    // 基本使用
[Trace(Name = "カスタム名")]                // トレース名指定
[Trace(RecordParameters = false)]          // パラメータ記録無効化
[Trace(RecordReturnValue = false)]         // 戻り値記録無効化
[Trace(RecordException = false)]           // 例外記録無効化
```

**ServiceCollectionExtensions** - DI拡張メソッド
```csharp
services.AddTracedScoped<TInterface, TImplementation>();     // Scopedライフタイム
services.AddTracedTransient<TInterface, TImplementation>();  // Transientライフタイム
services.AddTracedSingleton<TInterface, TImplementation>();  // Singletonライフタイム
```

#### TracingSample.Core（ビジネスロジック）

| インターフェース | 説明 |
|---|---|
| `IOrderService` | 注文処理（ProcessOrder） |
| `IInventoryService` | 在庫管理（CheckAndReserveStock, ReleaseStock） |
| `IPaymentService` | 決済処理（ProcessPayment, RefundPayment） |
| `IShippingService` | 配送手配（CreateShipment, CancelShipment） |

### 3. テスト実行方法

```bash
# テストプロジェクトは未実装
# ソリューション全体のビルドで構文チェック
dotnet build TracingSample/TracingSample.sln
```

現時点ではユニットテストプロジェクトは含まれていません。

### 4. ビルド実行方法

```bash
# ソリューション全体のビルド
cd TracingSample
dotnet restore
dotnet build

# リリースビルド
dotnet build -c Release
```

### 5. 依存関係

#### 本番依存
| パッケージ | バージョン | 用途 |
|---|---|---|
| Microsoft.Extensions.Hosting | 10.0.1 | ホスティング基盤 |
| Microsoft.Extensions.DependencyInjection.Abstractions | 10.0.1 | DI抽象化 |
| OpenTelemetry | 1.14.0 | 分散トレーシング基盤 |
| OpenTelemetry.Exporter.OpenTelemetryProtocol | 1.14.0 | OTLPエクスポーター |
| OpenTelemetry.Extensions.Hosting | 1.14.0 | ホスティング統合 |
| System.Text.Json | 10.0.1 | JSONシリアライズ |

#### 開発依存
- Jaeger（Docker経由）- トレース可視化

### 6. 技術スタック

| カテゴリ | 技術 |
|---|---|
| 言語 | C# 12 |
| フレームワーク | .NET 8 |
| ビルドツール | dotnet CLI / MSBuild |
| テストフレームワーク | 未設定 |
| トレーシング | OpenTelemetry |
| 可視化 | Jaeger |
| コンテナ | Docker / Docker Compose |

---

## 優先度B（オプション情報）

### 7. 利用方法/Getting Started

#### 1. Jaegerを起動
```bash
cd TracingSample/docker
docker-compose up -d
```

#### 2. アプリケーションを実行
```bash
cd TracingSample/src/TracingSample.Console
dotnet run
```

#### 3. Jaeger UIで確認
- URL: http://localhost:16686
- Service: `TracingSample` を選択
- Find Traces をクリック

#### 他プロジェクトへの導入
```csharp
// 1. TracingSample.Tracing を参照追加

// 2. OpenTelemetry設定
builder.Services.AddOpenTelemetry()
    .WithTracing(tracing => tracing
        .AddSource("YourServiceName")
        .AddOtlpExporter(o => o.Endpoint = new Uri("http://localhost:4317")));

// 3. サービス登録を変更
services.AddTracedScoped<IYourService, YourService>();

// 4. インターフェースに[Trace]を追加
public interface IYourService
{
    [Trace]
    Task YourMethod(string param);
}
```

### 8. 環境変数/設定

| 変数名 | 説明 | デフォルト値 |
|---|---|---|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLPエクスポーターのエンドポイント | `http://localhost:4317` |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | OTLPプロトコル | `grpc` |
| `OTEL_SERVICE_NAME` | サービス名 | `TracingSample` |

### 10. 既知の制約・制限事項

- **DispatchProxyの制限**: インターフェースベースのプロキシのみサポート。クラスベースのプロキシが必要な場合はCastle.DynamicProxyへの切り替えを検討
- **パフォーマンスオーバーヘッド**: リフレクション使用により1メソッド呼び出しあたり約0.1-0.5msのオーバーヘッド
- **機密情報**: パスワードやトークンなどの機密情報を含むパラメータは`RecordParameters = false`で無効化するか、カスタムシリアライザでマスク処理が必要

### 13. トラブルシューティング

#### Jaegerにトレースが表示されない
```bash
# Jaegerが起動しているか確認
docker ps | grep jaeger

# ポート4317が開いているか確認
netstat -an | grep 4317
```

#### コンテナが起動しない場合
```bash
# ログの確認
docker-compose -f docker/docker-compose.yml logs

# コンテナの再ビルド
docker-compose -f docker/docker-compose.yml build --no-cache
docker-compose -f docker/docker-compose.yml up -d
```

### 14. ライセンス情報

このサンプルコードは自由に使用・改変できます。

**参考リンク:**
- [OpenTelemetry .NET](https://github.com/open-telemetry/opentelemetry-dotnet)
- [Jaeger](https://www.jaegertracing.io/)
- [DispatchProxy](https://learn.microsoft.com/dotnet/api/system.reflection.dispatchproxy)
