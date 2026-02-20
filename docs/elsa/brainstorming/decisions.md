# ブレインストーミング結果

## 設計方針

tmpブランチのプロトタイプ実装を踏襲しつつ、以下の方針で整理・改善する。

### アーキテクチャ

```
ElsaServer (ASP.NET Core + Elsa 3.4.x)
├── Activities.Contracts — プラグイン契約 (IActivityModule)
├── Activities.Loader — DLL 動的読み込み (AssemblyLoadContext)
├── Activities.Templates/CustomActivityTemplate — サンプル Activity DLL
├── WorkflowCatalog + WorkflowCatalogLoader — JSON ワークフロー管理
├── StartWorkflowConsumer — MassTransit Consumer（ワークフロー起動）
├── WorkflowLauncher — ワークフロー実行エンジン
├── WorkflowStatusPublisher — ステータスイベント発行
└── PostgreSQL (EF Core) + RabbitMQ (Elsa標準MassTransit)

ElsaStudio (Blazor WebAssembly)
└── ワークフロー GUI 編集（Elsa Studio 標準機能）

テストプロジェクト群:
├── ElsaServer.UnitTests — DLL Loader, Catalog, Consumer, Launcher 等
├── ElsaServer.IntegrationTests — Elsa 結合テスト (Docker 必要)
├── Activities.Templates.CustomActivityTemplate.UnitTests — サンプル Activity
├── Activities.Testing — 共通テストフィクスチャ
└── ElsaServer.E2ETests — Playwright GUI テスト
```

### 主要な決定事項

| # | 質問 | 決定 |
|---|------|------|
| 1 | 設計方針 | tmpブランチの設計を踏襲しつつ整理・改善 |
| 2 | DB | PostgreSQLへ移行（SQLiteから） |
| 3 | MassTransit | Elsa標準拡張を使用（独自改造なし） |
| 4 | E2Eテスト | C# Playwright (xUnit) で dotnet test 統一 |

### tmpブランチとの差分

| コンポーネント | tmp | 今回の方針 |
|---|---|---|
| Elsa.ServiceBus.MassTransit | 独自内包・改造 | 不要（Elsa標準使用） |
| RpcService | あり | スコープ外 |
| Subscribe | あり | スコープ外 |
| E2Eテスト | なし | Playwright で新規追加 |
| DB | PostgreSQL | PostgreSQL（同じ） |

### テスト戦略

- **単体テスト**: xUnit。DLL Loader, WorkflowCatalog, Consumer, PayloadMapper 等
- **結合テスト**: xUnit + Docker Compose。Elsa 結合ワークフロー登録・実行・完了
- **E2Eテスト**: xUnit + Playwright。Studio GUI 操作（アクティビティ表示、ワークフロー編集・保存、実行確認）
