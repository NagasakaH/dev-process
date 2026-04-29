# floci-apigateway-csharp

> 最終更新: 2025-04-29

## 概要

floci（LocalStack 派生のローカル AWS エミュレータ）上で動作する .NET 8 製の Todo API サンプル。
API Gateway REST v1 + AWS Lambda + Step Functions + DynamoDB を Terraform で構築し、floci が未対応な provider Read API は `terraform_data` + AWS CLI で回避する構成。
本リポジトリは `submodules/editable/` 配下に配置されており、本 dev-process リポジトリから編集可能なサブモジュールとして扱う。

アーキテクチャ:

```
Client --POST/GET /todos--> API Gateway REST v1
                              -> Lambda (TodoApi.Lambda, .NET 8)
                                 -> Step Functions (ValidateTodo / PersistTodo)
                                    -> Lambda
                                       -> DynamoDB (Todos table)
```

---

## 優先度A（必須情報）

### 1. プロジェクト構成

```
floci-apigateway-csharp/
├── README.md                  # プロジェクト概要・利用方法
├── floci-apigateway-csharp.sln  # ソリューションファイル
├── .gitlab-ci.yml             # GitLab CI 定義 (lint → unit → integration → e2e)
├── compose/
│   └── docker-compose.yml     # ローカル floci 起動用
├── infra/                     # Terraform IaC
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── lambda/                # ビルド済み Lambda zip 出力先
├── scripts/                   # デプロイ・E2E・検証スクリプト群
│   ├── deploy-local.sh        # floci 起動→package→terraform apply 一括実行
│   ├── e2e.sh                 # E2E 実行
│   ├── warmup-lambdas.sh      # E2E 前の Lambda ウォームアップ
│   ├── apply-api-deployment.sh / apply-state-machine.sh
│   ├── local-endpoint.sh / verify-local-endpoint.sh
│   └── verify-ci-yaml.sh / verify-readme-*.sh / verify-terraform-plan.sh
├── src/
│   └── TodoApi.Lambda/        # Lambda 関数本体 (.NET 8)
│       ├── Function.cs                  # ApiHandler エントリポイント
│       ├── Function.ValidateTodo.cs     # SFN ValidateTodo タスク
│       ├── Function.PersistTodo.cs      # SFN PersistTodo タスク
│       ├── JsonOpts.cs / LambdaJsonSerializer.cs
│       ├── Aws/AwsClientFactory.cs
│       ├── Models/                      # Todo, TodoStatus, CreateTodoRequest, StepFunctionsContracts
│       ├── Repositories/                # ITodoRepository, TodoRepository, TodoMapper
│       ├── Validation/TodoValidator.cs
│       └── aws-lambda-tools-defaults.json
└── tests/
    ├── TodoApi.UnitTests/        # 依存無し単体テスト
    ├── TodoApi.IntegrationTests/ # floci 必須の結合テスト (FlociFixture, SkipIfNoFlociFact)
    └── TodoApi.E2ETests/         # terraform apply 後の HTTP E2E (E2EFixture)
```

**主要ファイル:**

- `src/TodoApi.Lambda/Function.cs` — `ApiHandler` (REST → ルーティング: `POST /todos`, `GET /todos/{id}`)。`HandleCreate` で id/status/timestamps を採番し Step Functions を `StartExecutionAsync` で起動。
- `src/TodoApi.Lambda/Function.ValidateTodo.cs` / `Function.PersistTodo.cs` — Step Functions から呼び出される個別タスクハンドラ。
- `infra/main.tf` — API Gateway / Lambda / Step Functions / DynamoDB のリソース定義。SFN State Machine と APIGW Deployment/Stage は floci 未対応 API 回避のため `terraform_data` + AWS CLI で作成。
- `scripts/deploy-local.sh` — 開発者の主入口。floci 起動 → ヘルスチェック → `dotnet lambda package` → `terraform init/apply` を冪等に実行。

### 2. 外部公開インターフェース/API

HTTP API (API Gateway REST v1, stage URL は `terraform output -raw invoke_url` で取得):

| Method | Path | リクエスト | 正常レスポンス | エラー |
|---|---|---|---|---|
| `POST` | `/todos` | `application/json`<br>`{"title": string, "description"?: string}` | `201 Created`<br>`{"id": "<uuid>", "executionArn": "<sfn-arn>"}` | `400` バリデーション (`{"errors": [...]}`)、`500` 内部エラー (`{"error": "internal error"}`) |
| `GET` | `/todos/{id}` | — | `200 OK`<br>Todo オブジェクト (`id`, `title`, `description`, `status`, `createdAt`, `updatedAt`) | `400` id 必須、`404` `{"error": "not found"}` |

その他公開インターフェース（同一 Lambda の異なるエントリポイント）:

- `Function.ApiHandler(APIGatewayProxyRequest, ILambdaContext)` — API Gateway Lambda Proxy 統合。
- `Function.ValidateTodo(...)` — Step Functions タスク。`TodoValidator` を呼び出し正規化済み Todo を返す。
- `Function.PersistTodo(...)` — Step Functions タスク。DynamoDB に永続化する。
- アプリ仕様上、id/status/timestamps の採番は `ApiHandler` 側で確定する（DR-002）。

内部公開（テスト用、`InternalsVisibleTo` で `TodoApi.UnitTests` / `TodoApi.IntegrationTests` / `TodoApi.E2ETests` に開放）:

- `internal Function(ITodoRepository, IAmazonStepFunctions, string stateMachineArn)` — DI 用コンストラクタ。

環境契約:

- 必須環境変数 `STATE_MACHINE_ARN`（未設定だと `ApiHandler` 起動時に `InvalidOperationException`）。
- AWS 接続は `AWS_ENDPOINT_URL` 必須（未設定だと起動失敗）。実 AWS 接続は禁止（DR-001）。

### 3. テスト実行方法

```bash
# Unit (依存無し)
dotnet test tests/TodoApi.UnitTests -c Release

# Integration (要 floci 起動 + AWS_ENDPOINT_URL)
docker compose -f compose/docker-compose.yml up -d
AWS_ENDPOINT_URL=http://localhost:4566 \
  dotnet test tests/TodoApi.IntegrationTests -c Release

# E2E (要 terraform apply 済 + invoke_url)
bash scripts/e2e.sh
```

- テストフレームワーク: **xUnit 2.9.2** + `Microsoft.NET.Test.Sdk` 17.11.1 + `xunit.runner.visualstudio` 2.8.2。
- モック: **Moq 4.20.72**、Lambda テスト補助に **Amazon.Lambda.TestUtilities 2.0.0**。
- `AWS_ENDPOINT_URL` が未設定の場合、Integration / E2E はテスト側で `SkipIfNoFlociFact` などにより **Skip** される（実 AWS への流出防止）。
- 主要なテストフィクスチャ: `tests/TodoApi.IntegrationTests/FlociFixture.cs`、`tests/TodoApi.E2ETests/E2EFixture.cs`。
- CI ステージ: `lint(format) → unit → integration → e2e`（`.gitlab-ci.yml`）。

### 4. ビルド実行方法

```bash
# 通常ビルド
dotnet build floci-apigateway-csharp.sln -c Release

# Lambda zip パッケージング (Amazon.Lambda.Tools が必要)
dotnet tool install -g Amazon.Lambda.Tools
dotnet lambda package \
  --project-location src/TodoApi.Lambda \
  --output-package infra/lambda/TodoApi.Lambda.zip

# ローカル一括デプロイ (floci 起動 + package + terraform apply)
bash scripts/deploy-local.sh

# Terraform 単体
cd infra
terraform init -input=false
terraform fmt -check
terraform validate
terraform apply -var "endpoint=http://localhost:4566"
```

- `var.endpoint` は default なしの required 変数（DR-001 / DR-006）。実 AWS フォールバックを禁止するため、明示指定がなければ `apply` は失敗する。
- Lambda zip は Docker server architecture に合わせて `x86_64` / `arm64` を自動選択（`scripts/deploy-local.sh`）。`LAMBDA_ARCHITECTURE` で上書き可。
- devcontainer + dood 環境では `ENDPOINT=http://host.docker.internal:4566` を自動利用。

### 5. 依存関係

#### 本番依存（`src/TodoApi.Lambda/TodoApi.Lambda.csproj`）

| パッケージ | バージョン | 用途 |
|---|---|---|
| `Amazon.Lambda.Core` | 2.5.0 | Lambda 実行ランタイム |
| `Amazon.Lambda.APIGatewayEvents` | 2.7.1 | API Gateway Proxy イベント型 |
| `Amazon.Lambda.Serialization.SystemTextJson` | 2.4.4 | JSON シリアライザ |
| `AWSSDK.DynamoDBv2` | 3.7.402 | DynamoDB クライアント |
| `AWSSDK.StepFunctions` | 3.7.402 | Step Functions クライアント |

#### 開発依存（`tests/TodoApi.*Tests/*.csproj`）

| パッケージ | バージョン |
|---|---|
| `Microsoft.NET.Test.Sdk` | 17.11.1 |
| `xunit` | 2.9.2 |
| `xunit.runner.visualstudio` | 2.8.2 |
| `Moq` | 4.20.72（Unit / Integration のみ） |
| `Amazon.Lambda.TestUtilities` | 2.0.0（Unit / Integration のみ） |

#### ツール / 外部依存

- .NET SDK 8.0+
- Docker / Docker Compose v2+
- Terraform 1.6+
- Amazon.Lambda.Tools 5.x（`dotnet tool install -g Amazon.Lambda.Tools`）
- AWS CLI 2.x（任意、`terraform_data` 内部で利用）
- floci（同梱 `compose/docker-compose.yml` で起動、ベースは `localstack/localstack:latest`）

### 6. 技術スタック

| カテゴリ | 技術 |
|---|---|
| 言語 | C# (.NET 8 / `net8.0`, `Nullable=enable`, `ImplicitUsings=enable`) |
| ランタイム | AWS Lambda (.NET 8 マネージドランタイム) |
| アーキテクチャ | API Gateway REST v1 + Lambda + Step Functions (ASL) + DynamoDB |
| IaC | Terraform 1.6+ (hashicorp/aws v6.x) |
| ローカル AWS エミュレータ | floci (`localstack/localstack:latest` ベース) |
| ビルドツール | dotnet CLI / Amazon.Lambda.Tools |
| テストフレームワーク | xUnit + Moq + Amazon.Lambda.TestUtilities |
| CI | GitLab CI (DinD ベース、shell executor フォールバック対応) |

---

## 優先度B（オプション情報）

### 7. 利用方法/Getting Started

```bash
git clone <this-repo>
cd floci-apigateway-csharp

# 1) floci 起動
docker compose -f compose/docker-compose.yml up -d

# 2) Lambda zip + Terraform apply（一括実行）
bash scripts/deploy-local.sh

# 3) 動作確認
curl -s -X POST "$(cd infra && terraform output -raw invoke_url)/todos" \
  -H 'Content-Type: application/json' \
  -d '{"title":"buy milk"}'
```

後始末: `cd infra && terraform destroy -var "endpoint=http://localhost:4566"`。

### 8. 環境変数/設定

| 変数名 | 説明 | デフォルト値 |
|---|---|---|
| `AWS_ENDPOINT_URL` | floci エンドポイント。**未設定だと Integration/E2E は Skip、本番モードの Lambda 起動は失敗** | 未設定 |
| `ENDPOINT` | `scripts/deploy-local.sh` が利用する floci エンドポイント（dood 検出時は `http://host.docker.internal:4566`、それ以外 `http://localhost:4566`） | 自動判定 |
| `LAMBDA_ENDPOINT` | Lambda 実行コンテナから floci に接続する用のエンドポイント（CI では `http://floci:4566`） | 環境依存 |
| `LAMBDA_ARCHITECTURE` | Lambda zip のアーキテクチャ（`x86_64` / `arm64`） | Docker server arch から自動 |
| `STATE_MACHINE_ARN` | Lambda 実行時の Step Functions ARN。**ApiHandler 必須** | Terraform から設定 |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_DEFAULT_REGION` | floci 接続用ダミー認証 | CI では `test` / `test` / `us-east-1` |
| `FLOCI_HOSTNAME` | CI 用の floci ホスト名（`docker`） | CI のみ |
| `FLOCI_SERVICES_DOCKER_NETWORK` | Lambda コンテナが参加する Docker ネットワーク | `floci-net`（推奨） |
| `DOCKER_MODE` | `dood` 指定で host.docker.internal を経由 | 未設定 |

### 9. 他submoduleとの連携

- 動作対象の AWS エミュレータとして **`submodules/readonly/floci`**（同 `submodules/floci.md` 参照）を利用する。compose ファイルは `localstack/localstack:latest` を直接参照しているが、floci は同等の AWS Wire Protocol を提供するため API 互換性検証の参照実装として位置づけられる。
- 本リポジトリの設計ドキュメントは親リポジトリの `docs/floci-apigateway-csharp/design/` (00_overview〜06_side-effect-verification) に格納される想定。

### 10. 既知の制約・制限事項

- **実 AWS への接続は禁止**（DR-001）。`AWS_ENDPOINT_URL` 未設定時はアプリが `InvalidOperationException` で失敗する。
- **API スコープ**: `POST /todos` と `GET /todos/{id}` のみ。Update / Delete / List、認証/認可は **out of scope**（DR-003）。
- **Step Functions provider 互換性**: floci は `ValidateStateMachineDefinition` / `ListStateMachineVersions` を未サポート。State Machine は `terraform_data` + AWS CLI 経由で作成する。
- **API Gateway provider 互換性**: floci は `GetDeployment` に JSON 以外の 404 応答を返すことがあるため、Deployment/Stage も `terraform_data` + AWS CLI で作成する。
- **SFN polling timeout**: `DescribeExecution` は 1 秒間隔で最大 30 秒 polling（E2E-1）。遅い環境では `WaitForSucceededAsync` のタイムアウトを延長する必要あり。
- **コールドスタート**: .NET Lambda は cold start が長く、E2E 前に `scripts/warmup-lambdas.sh` の実行が必要。Lambda timeout は 120 秒。
- **macOS Docker Desktop**: VM 経由のため Lambda I/O が遅い。CPU 4 以上推奨。

### 11. バージョニング・互換性

- `Terraform AWS provider` v6.x 系（`hashicorp/aws`）を利用。
- カバー対象 AWS サービス: `apigateway` (REST v1), `lambda`, `stepfunctions`, `dynamodb`, `iam`, `cloudwatch logs`。
- 互換 flag: `s3_use_path_style = true`、`skip_credentials_validation = true`、`skip_metadata_api_check = true`、`skip_requesting_account_id = true`。
- floci 環境固有の挙動差は本サンプルでは out of scope（必要に応じて実 AWS で別途検証）。

### 13. トラブルシューティング

主要事象（README §8 より抜粋）:

| 症状 | 対処 |
|---|---|
| `Port 4566 already in use` | 既存 LocalStack を停止: `docker rm -f $(docker ps -aq --filter publish=4566)` |
| `API_BASE_URL` に `localhost` 混入 | CI では `FLOCI_HOSTNAME=docker` / `ENDPOINT=http://docker:4566` を必ず設定（DR-016 によりテストが拒否） |
| API Gateway 経由 E2E が 502 | Terraform に `lambda_endpoint=http://floci:4566`、compose に `FLOCI_SERVICES_DOCKER_NETWORK=floci-net` を設定 |
| 初回 APIGW 呼び出しが 502 | `scripts/warmup-lambdas.sh` で Lambda を事前 invoke。Lambda timeout は 120 秒 |
| `terraform destroy` hang | `docker compose down -v && up -d` 後に `terraform state rm` で状態クリア |
| `dotnet lambda package` 不在 | `dotnet tool install -g Amazon.Lambda.Tools && export PATH="$PATH:$HOME/.dotnet/tools"` |
| `Could not find the specified handler assembly` | Lambda zip と実行コンテナの architecture 不一致。`scripts/deploy-local.sh` 経由か `LAMBDA_ARCHITECTURE` 明示 |
