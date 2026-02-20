# elsa

> 最終更新: 2026-02-20

## 概要

Elsa Workflow Engine をベースとした NagasakaEventSystem。
Elsa Server（ワークフロー実行エンジン + REST API）と Elsa Studio（Blazor WebAssembly ワークフローデザイナー）の2アプリケーションで構成される。
RabbitMQ + MassTransit によるメッセージ連携、PostgreSQL でのワークフロー定義/実行データ永続化を想定。

---

## 優先度A（必須情報）

### 1. プロジェクト構成

```
elsa/
├── NagasakaEventSystem.sln          # ソリューションファイル
├── compose.yml                       # Docker Compose (PostgreSQL + RabbitMQ)
├── docs/                             # 設計ドキュメント群
│   ├── api-design.md
│   ├── architecture.md
│   ├── configuration.md
│   ├── custom-activities.md
│   ├── database-design.md
│   ├── development-guide.md
│   ├── elsa-studio-import-json.md
│   ├── implementation-plan.md
│   └── startup-import-and-run.md
├── src/
│   ├── Common/
│   │   └── RabbitMQService/          # RabbitMQ メッセージングサービス
│   ├── ElsaServer/                   # ワークフロー実行エンジン + API
│   └── ElsaStudio/                   # Blazor WASM ワークフローデザイナー
└── tests/                            # テストプロジェクト（空の .gitkeep のみ）
```

**主要ファイル:**
- `src/ElsaServer/Program.cs` — Elsa Server のエントリポイント。カスタム Activity 定義（PublishMessage, WaitMessage）、DI 設定、MassTransit/RabbitMQ 設定を含む
- `src/ElsaStudio/Program.cs` — Elsa Studio (Blazor WebAssembly) のエントリポイント。Elsa Server の API URL をクライアント設定から取得
- `src/Common/RabbitMQService/Class1.cs` — IMessageService インターフェースと RabbitMQService 実装（publish/subscribe）
- `compose.yml` — PostgreSQL 15 + RabbitMQ 3 (management) のコンテナ定義

### 2. 外部公開インターフェース/API

**ElsaServer HTTP API:**
- Elsa Workflows API（`UseWorkflowsApi()` で自動公開）
  - `POST /workflow-definitions/{definitionId}/dispatch` — ワークフロー非同期実行
  - `POST /workflow-definitions/{definitionId}/execute` — ワークフロー同期実行
  - ワークフロー定義 CRUD、インスタンス管理等の Elsa 標準 API
- HTTP エンドポイント（`UseHttp()` でワークフロー内 HTTP トリガー対応）

**ElsaStudio:**
- Blazor WebAssembly SPA。ElsaServer API に接続してワークフローの設計・管理 UI を提供
- ベース URL は `wwwroot/appsettings.json` の `apiUrl` で指定

**RabbitMQService:**
- `IMessageService` インターフェース: `connect()`, `disconnect()`, `PublishMessage(string)`, `SubscribeToQueue(string, Action<string>)`

**カスタム Activity:**
- `PublishMessage` — RabbitMQ にメッセージをパブリッシュ
- `WaitMessage` — RabbitMQ からメッセージ受信待ち（未実装）

### 3. テスト実行方法

```bash
# 現状テストプロジェクトなし（tests/.gitkeep のみ）
# tmp ブランチには xUnit テストプロジェクトが存在する
dotnet test NagasakaEventSystem.sln
```

現在の master ブランチにはテストプロジェクトが存在しない。tmp ブランチに以下のテストプロジェクトがある：
- `ElsaServer.UnitTests` — Consumer, Services のユニットテスト
- `ElsaServer.IntegrationTests` — ワークフロー起動統合テスト
- `Activities.Templates.CustomActivityTemplate.UnitTests` — カスタム Activity テスト
- `Activities.Testing` — テストフィクスチャ共通基盤

### 4. ビルド実行方法

```bash
dotnet build NagasakaEventSystem.sln
```

- ElsaServer: `dotnet run --project src/ElsaServer` (https://localhost:5001)
- ElsaStudio: ElsaServer に含まれる（`UseBlazorFrameworkFiles()` + `MapFallbackToPage("/_Host")`）
- Docker 環境: `docker compose up -d` で PostgreSQL + RabbitMQ を起動

### 5. 依存関係

#### ElsaServer 本番依存
| パッケージ | バージョン | 用途 |
|---|---|---|
| Elsa | 3.4.2 | コアワークフローエンジン |
| Elsa.CSharp | 3.4.2 | C# スクリプトサポート |
| Elsa.EntityFrameworkCore | 3.4.2 | EF Core 永続化 |
| Elsa.EntityFrameworkCore.Sqlite | 3.4.2 | SQLite プロバイダ（現状使用、PostgreSQLへ移行予定） |
| Elsa.Identity | 3.4.2 | 認証・認可 |
| Elsa.JavaScript | 3.4.2 | JavaScript スクリプトサポート |
| Elsa.Liquid | 3.4.2 | Liquid テンプレートサポート |
| Elsa.MassTransit.RabbitMq | 3.4.2 | MassTransit RabbitMQ 統合 |
| Elsa.Scheduling | 3.4.2 | スケジューリング |
| Elsa.Workflows.Api | 3.4.2 | REST API |

#### ElsaStudio 本番依存
| パッケージ | バージョン | 用途 |
|---|---|---|
| Elsa.Api.Client | 3.4.2 | API クライアント |
| Elsa.Studio | 3.4.0 | Studio コア |
| Elsa.Studio.Core.BlazorWasm | 3.4.0 | Blazor WASM ホスト |
| Elsa.Studio.Login.BlazorWasm | 3.4.0 | ログインモジュール |

#### RabbitMQService 依存
| パッケージ | バージョン | 用途 |
|---|---|---|
| RabbitMQ.Client | 7.1.2 | RabbitMQ クライアント |

### 6. 技術スタック

| カテゴリ | 技術 |
|---|---|
| 言語 | C# (.NET 8) |
| フレームワーク | ASP.NET Core 8, Elsa Workflows 3.4.x, Blazor WebAssembly |
| ビルドツール | dotnet CLI, MSBuild |
| テストフレームワーク | xUnit（tmp ブランチ） |
| メッセージング | RabbitMQ + MassTransit |
| データベース | SQLite（現状）→ PostgreSQL（移行予定） |
| コンテナ | Docker Compose |

---

## 優先度B（オプション情報）

### 7. 利用方法/Getting Started

1. Docker 環境起動: `docker compose up -d`（PostgreSQL + RabbitMQ）
2. ビルド: `dotnet build NagasakaEventSystem.sln`
3. ElsaServer 起動: `dotnet run --project src/ElsaServer`
4. ブラウザで https://localhost:5001 にアクセス（Studio UI）
5. デフォルト認証: admin ユーザー（UseAdminUserProvider()）

### 8. 環境変数/設定

| 設定項目 | 場所 | デフォルト値 | 備考 |
|---|---|---|---|
| Http:BaseUrl | appsettings.json | https://localhost:5001 | Elsa HTTP ベース URL |
| Http:BasePath | appsettings.json | /api/workflows | API ベースパス |
| JWT SigningKey | Program.cs (ハードコード) | large-signing-key-for-signing-JWT-tokens | TODO: appsettings へ移行 |
| RabbitMQ Host | Program.cs (ハードコード) | amqp://guest:guest@localhost:5672 | TODO: appsettings へ移行 |
| PostgreSQL | compose.yml | elsa_user/elsa_password@localhost:5432/elsa_workflows | Docker Compose で提供 |

### 10. 既知の制約・制限事項

- JWT SigningKey, RabbitMQ 接続情報がハードコーディングされている（appsettings 移行が TODO）
- WaitMessage Activity が未実装
- SQLite を使用中（PostgreSQL への移行が TODO）
- テストプロジェクトが master には存在しない
- `Microsoft.AspNetCore.Components.WebAssembly.Server` はバージョン 3.2.1 固定（上げるとビルド失敗）

### 11. バージョニング・互換性

- Elsa 3.4.x 系（Elsa.Studio は 3.4.0、Server 系は 3.4.2）
- .NET 8 (net8.0) ターゲット
- tmp ブランチには Elsa 3.5 対応の実装も存在
