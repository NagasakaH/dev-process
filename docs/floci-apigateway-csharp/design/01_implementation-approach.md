# 実装方針

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | floci-apigateway-csharp-001 |
| タスク名 | API Gateway + Lambda(.NET) + Step Functions サンプルアプリと CI/CD 基盤の構築 |
| 作成日 | 2026-04-25 |

---

## 1. 選定したアプローチ

### 1.1 実装方針

**「最小構成サーバーレス3層 + 単一 .NET 8 Lambda アセンブリ + Terraform 単一スタック + GitLab CI 3 ジョブ」** を採用する。

- **アプリ層**: 1 つの .NET 8 ZIP アセンブリ（`TodoApi.Lambda`）に 3 つのハンドラ（`Function::ApiHandler`、`Function::ValidateTodo`、`Function::PersistTodo`）を実装し、Terraform 側で 3 つの `aws_lambda_function` として同一 zip を別エントリポイントで登録する。これにより、ビルド成果物を 1 つに保ち、サンプルとしての可読性を最大化する。
- **オーケストレーション層**: Step Functions ステートマシンは `ValidateTodo → Choice($.valid) → PersistTodo / Fail` の最小フロー。`POST /todos` Lambda は `StartExecution` のみ行い `executionArn` を即返却（同期完了は待たない）し、E2E 側が `DescribeExecution` を polling して SUCCEEDED を確認する。
- **永続化層**: DynamoDB シングルテーブル `Todos`（HASH: `id`、`PAY_PER_REQUEST`）。GSI / TTL / Streams は不採用。
- **IaC**: `infra/` 配下の単一 Terraform スタックで API Gateway / Lambda x3 / Step Functions / DynamoDB / IAM Role / Lambda Permission / API Gateway Deployment & Stage を宣言。`provider.tf` で floci endpoints を一括設定。
- **CI**: GitLab CI で `unit` → `integration` → `e2e` の 3 ジョブを順次実行。`e2e` ジョブのみ `services: docker:dind` + `docker compose up -d floci` + `terraform apply` を行い、`HttpClient` で API Gateway invoke URL を叩く。

### 1.2 技術選定

| 技術/ツール | 選定理由 | 備考 |
|-------------|----------|------|
| .NET 8 (LTS) | setup.yaml で確定済。Lambda runtime `dotnet8` を floci がサポート | `Nullable` / `ImplicitUsings` 有効 |
| ZIP パッケージ | `dotnet lambda package` 出力を `aws_lambda_function.filename` でそのまま参照可能。Terraform からの取り回しが最も単純 | コンテナイメージ方式は不採用 |
| API Gateway REST v1 | setup.yaml で確定済（HTTP API v2 不採用）。AWS_PROXY 統合が安定 | invoke URL は floci 固有形式 |
| Amazon.Lambda.APIGatewayEvents | API Gateway proxy 統合の標準型 (`APIGatewayProxyRequest/Response`) | NuGet ~> 2.x |
| AWSSDK.DynamoDBv2 ~> 4 / AWSSDK.StepFunctions ~> 4 | 最新の安定 v4 系。`AWS_ENDPOINT_URL` 経由で floci 接続可能 | — |
| Amazon.Lambda.Serialization.SystemTextJson | 標準シリアライザ。追加依存なし | — |
| xUnit + Amazon.Lambda.TestUtilities | setup.yaml で確定済。`TestLambdaContext` で結合テストが容易 | FluentAssertions は任意 |
| Terraform `hashicorp/aws ~> 6.0` | floci compat-terraform と同バージョン制約。breaking change 回避 | local backend |
| docker compose | floci 起動の公式推奨方式。CI/ローカル共通定義 | `compose/docker-compose.yml` |
| GitLab CI services: docker:dind | floci が Docker socket を要求するため、`privileged` Docker executor + DinD で対応 | runner 設定要件は README に記載 |

### 1.3 実装スコープと出力物

新規作成するディレクトリ・ファイル（investigation 01 §「想定ディレクトリ構成」を確定版とする）。

```
floci-apigateway-csharp/
├── README.md
├── floci-apigateway-csharp.sln
├── src/TodoApi.Lambda/
│   ├── TodoApi.Lambda.csproj
│   ├── aws-lambda-tools-defaults.json
│   ├── Function.cs                # ApiHandler + ValidateTodo + PersistTodo
│   ├── Models/Todo.cs
│   ├── Models/Dtos.cs             # CreateTodoRequest / ValidateTodoInput/Output / PersistTodoOutput
│   ├── Validation/TodoValidator.cs
│   ├── Repositories/ITodoRepository.cs
│   ├── Repositories/TodoRepository.cs
│   ├── Repositories/TodoMapper.cs
│   └── Aws/AwsClientFactory.cs
├── tests/
│   ├── TodoApi.UnitTests/
│   ├── TodoApi.IntegrationTests/
│   └── TodoApi.E2ETests/
├── infra/
│   ├── provider.tf
│   ├── variables.tf
│   ├── main.tf                    # DynamoDB / IAM / Lambda x3 / SFN / APIGW
│   ├── outputs.tf                 # invoke_url, state_machine_arn
│   └── lambda/                    # tf apply 直前に dotnet lambda package で生成された zip 配置先
├── compose/docker-compose.yml
├── scripts/
│   ├── deploy-local.sh
│   └── e2e.sh
└── .gitlab-ci.yml
```

---

## 2. 代替案の比較

| 案 | 概要 | メリット | デメリット | 採用 |
|----|------|----------|------------|------|
| 案1: 単一 .NET 8 ZIP に複数ハンドラ + REST v1 + 最小 SFN（本採用） | 同一アセンブリを 3 Lambda 関数で別エントリポイント登録 | ビルド成果物 1 つで可読性高、Terraform 単純 | 1 関数の更新で 3 関数全てを再デプロイ | ✅ |
| 案2: 関数ごとにプロジェクト分割（3 アセンブリ・3 zip） | 関数単位で関心分離 | 単一関数更新時のデプロイ単位が小さい | csproj 増加、build artifact 3 倍、サンプル簡素性が低下 | ❌ |
| 案3: HTTP API (v2) + Lambda コンテナイメージ | モダンな選択肢 | HTTP API は IAM/JWT 認可がシンプル | setup.yaml で REST v1 確定済、コンテナ image は floci ECR 設定が増える | ❌ |
| 案4: Step Functions を使わず Lambda 内同期処理のみ | 構成最小 | 実装が最短 | requirements「Step Functions ステートマシンを Terraform で定義し、Lambda と連携」を満たさない | ❌ |
| 案5: DynamoDB Local（floci ではなく） | ローカル単独で軽量 | 起動が早い | 「floci のみで完結」要件を満たさず、API GW/SFN を別途モックする必要 | ❌ |

---

## 3. 採用理由

### 3.1 決定要因

1. **要件適合性**: setup.yaml の確定事項（DynamoDB、REST v1、ZIP、SFN 2 ステート、floci のみで E2E 完結）を全て満たす最も直接的な構成。
2. **サンプルとしての可読性**: 1 つの .NET ソリューション、1 つの Terraform スタック、1 つの docker-compose で完結し、READMEから辿れる。
3. **CI 親和性**: GitLab CI 標準の `services: docker:dind` パターンに乗り、特殊な runner 設定を要求しない（README に最低要件を明記）。
4. **保守性**: AWS SDK v4 と Terraform AWS provider v6 の組み合わせは floci compat-terraform と整合し、将来の floci アップグレードに追従しやすい。

### 3.2 トレードオフ

| トレードオフ | 内容 | 受容理由 |
|--------------|------|----------|
| 単一 ZIP の再デプロイ単位 | 1 ハンドラ修正で 3 関数全て更新 | サンプル用途では問題にならず、可読性を優先 |
| Step Functions 完了の非同期確認 | POST は executionArn を即返却し、E2E が polling | 同期化すると Lambda タイムアウトリスクが上がる。floci の SFN 実行時間は数秒で polling 30 秒以内に十分収まる |
| GitLab CI に DinD を要求 | privileged が必要 | サンプル用途として README に明記、shared runner 利用は対象外と注記 |
| local tfstate のみサポート | GitLab managed state は補足のみ | setup.yaml で確定済 |

---

## 4. 制約事項

| 制約 | 影響 | 対応方針 |
|------|------|----------|
| .NET 8 限定 | Lambda プロジェクト | `TargetFramework = net8.0` 固定 |
| API Gateway v1 (REST) 限定 | Terraform / 統合形式 | `aws_api_gateway_*` リソース使用、v2 を一切使わない |
| ZIP パッケージ限定 | ビルド・デプロイ | `dotnet lambda package` を deploy-local.sh / CI で必ず先行実行 |
| local tfstate のみ | CI tf apply 設計 | tfstate を CI artifact 化し、ジョブ内で `terraform destroy` を `after_script` で実行 |
| 実 AWS 不使用 | テスト構成 | AWS 資格情報は `test`/`test` 固定、E2E ジョブで AWS シークレットを参照しない |
| 単一ポート 4566 | endpoint 設定 | provider と AWS SDK の両方で `AWS_ENDPOINT_URL` / `endpoints {}` を使用 |
| Docker socket / DinD 要求 | CI runner 要件 | README に「privileged Docker executor 推奨」と明記 |
| 認証/認可なし | API Gateway | authorizer 未設定、`Authorizer = NONE` |

---

## 5. 前提条件

- [x] 投影プロジェクト `floci-apigateway-csharp` が submodule として登録済（init-work-branch 完了済み）
- [x] 調査ドキュメント `docs/floci-apigateway-csharp/investigation/01〜06` が完了済（investigation.status=completed）
- [x] floci `compatibility-tests/compat-terraform` が参照可能（`submodules/readonly/floci`）
- [ ] GitLab CI runner が privileged Docker executor で構成可能（実装フェーズ前にユーザー側で確認）
- [ ] CI イメージで `dotnet 8 SDK` + `terraform 1.6+` + `docker compose` が利用可能（実装フェーズで確認・README 化）

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-04-25 | 1.0 | 初版作成 | dev-workflow |
