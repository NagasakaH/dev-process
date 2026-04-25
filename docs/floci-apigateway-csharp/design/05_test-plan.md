# テスト計画

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | floci-apigateway-csharp-001 |
| タスク名 | API Gateway + Lambda(.NET) + Step Functions サンプルアプリと CI/CD 基盤の構築 |
| 作成日 | 2026-04-25 |

> **テスト戦略の根拠**: `project.yaml` の `brainstorming.test_strategy` を参照。
> scope = `unit` + `integration` + `e2e` を**全て本設計のスコープに含める**。

---

## 1. テスト方針

### 1.1 テストスコープ

| 範囲 | 対象 | 除外 |
|------|------|------|
| 単体テスト (xUnit) | `TodoValidator`、`TodoMapper`、`Todo` シリアライズ、`AwsClientFactory` の endpoint 解決ロジック | floci に依存する全コード |
| 結合テスト (xUnit + `Amazon.Lambda.TestUtilities`) | `Function::ApiHandler` / `Function::ValidateTodo` / `Function::PersistTodo` の各ハンドラを `TestLambdaContext` で直接呼び、floci の DynamoDB / Step Functions と連携 | API Gateway 経路、Terraform apply |
| E2E テスト (xUnit + `HttpClient`) | GitLab CI 上で `docker compose up floci` + `terraform apply` 後、API Gateway invoke URL に対して POST/GET を実行し、Step Functions `DescribeExecution` で SUCCEEDED を確認 | 実 AWS、認証/認可フロー（NONE 固定） |

> **戦略との整合**: `test_strategy.unit.framework=xUnit` / `integration.framework=xUnit + Amazon.Lambda.TestUtilities` / `e2e.method=GitLab CI で docker compose により floci を起動し、Terraform apply 後に API Gateway のエンドポイントを HttpClient/xUnit で呼び出す` を完全に踏襲。

### 1.2 テストカバレッジ目標

サンプル用途のため**機能網羅**を最優先とし、行カバレッジは目安。

| 項目 | 目標値 | 備考 |
|------|--------|------|
| 行カバレッジ（src） | 70% 以上 | `coverlet.collector` で算出（CI artifact） |
| 主要ロジック分岐 (TodoValidator) | 100% | 全 invalid ケースを UT で網羅 |
| 受入基準カバレッジ | 100% | AC1〜AC7 を §6 で対応 |

---

## 2. 新規テストケース

### 2.1 単体テスト（`tests/TodoApi.UnitTests`）

| No | テスト対象 | テスト内容 | 期待結果 | 優先度 |
|----|------------|------------|----------|--------|
| UT-1 | `TodoValidator.Validate` | `title` が空文字 | `Valid=false`, errors に "title" を含む | 高 |
| UT-2 | `TodoValidator.Validate` | `title` 長さ 121 文字 | `Valid=false`, errors に "title" 長さ違反 | 高 |
| UT-3 | `TodoValidator.Validate` | `description` 1025 文字 | `Valid=false`, errors に "description" | 中 |
| UT-4 | `TodoValidator.Validate` | 正常系（title=1文字 / description=null） | `Valid=true`, errors 空 | 高 |
| UT-5 | `TodoMapper.ToAttributeMap` | 全属性ありの `Todo` | DynamoDB attribute map に id/title/description/status/created_at/updated_at が S 型で含まれる | 高 |
| UT-6 | `TodoMapper.ToAttributeMap` | `Description=null` | `description` 属性が出力に含まれない | 中 |
| UT-7 | `TodoMapper.FromAttributeMap` | 全属性ありのマップ | 正しい `Todo` レコード（status enum、UTC DateTime） | 高 |
| UT-8 | `Todo` JSON シリアライズ | 既定 `JsonOpts` で serialize | `status` が `"pending"` 文字列、`createdAt` が camelCase | 中 |
| UT-9 | `AwsClientFactory.Dynamo` | `AWS_ENDPOINT_URL` 設定時 | `AmazonDynamoDBConfig.ServiceURL` が同値 | 中 |
| UT-10 | `AwsClientFactory.Dynamo` | `AWS_ENDPOINT_URL` 未設定時 | `ServiceURL` が null（既定） | 低 |

### 2.2 結合テスト（`tests/TodoApi.IntegrationTests`）

> 前提: テストフィクスチャ `FlociFixture` が `compose/docker-compose.yml` の floci に対し、テーブル `Todos` をテスト前に `terraform apply -target=aws_dynamodb_table.todos` または `aws dynamodb create-table` で作成。Step Functions / Lambda はテストでは使わず、`StateMachineArn` はダミー文字列を渡し、`StartExecution` 実行時にエラーが想定される箇所のみ別途モック化する。

| No | テスト対象 | テスト内容 | 期待結果 | 優先度 |
|----|------------|------------|----------|--------|
| IT-1 | `Function::ApiHandler` (POST) | バリデーション NG: `title=""` | StatusCode=400、Body.error に "title" | 高 |
| IT-2 | `Function::ApiHandler` (GET) | 存在しない id を指定 | StatusCode=404、Body.error="not found" | 高 |
| IT-3 | `Function::PersistTodo` | 有効な `ValidateTodoOutput` を渡す | DynamoDB に PutItem され、`PersistTodoOutput.Persisted=true` | 高 |
| IT-4 | `Function::ApiHandler` (GET) | IT-3 でPutした id を指定 | 200 + 当該 Todo を返す | 高 |
| IT-5 | `Function::ValidateTodo` | 有効な `CreateTodoRequest` | `Valid=true`、`Todo.Id` が新規 UUID | 高 |
| IT-6 | `Function::ValidateTodo` | 無効な `CreateTodoRequest` | `Valid=false`、`Errors` に項目を含む | 中 |
| IT-7 | `Function::ApiHandler` (POST) | StepFunctions モック化（IAmazonStepFunctions のテストダブル）、有効入力 | 201 + Body に `executionArn` 含む | 中 |

`Amazon.Lambda.TestUtilities.TestLambdaContext` を使い、`Function` のテスト用コンストラクタ（`internal Function(repo, sfn, stateMachineArn)`）でリポジトリは実 floci 接続、SFN クライアントはテストごとにモック切替。

### 2.3 E2E テスト（`tests/TodoApi.E2ETests`、CI のみ実行）

前提: GitLab CI `e2e` ジョブ内で以下を順に実行（`scripts/e2e.sh` でも同等を再現可能）。

```
1. compose up -d floci      # docker:dind サービス上
2. (curl http://floci:4566/_localstack/health, ない場合は ping → ヘルスチェック)
3. dotnet lambda package    # src/TodoApi.Lambda → infra/lambda/TodoApi.Lambda.zip
4. cd infra && terraform init && terraform fmt -check && terraform validate
5. terraform apply -auto-approve -var endpoint=http://floci:4566
6. export API_BASE_URL=$(terraform output -raw invoke_url)
   export STATE_MACHINE_ARN=$(terraform output -raw state_machine_arn)
7. dotnet test tests/TodoApi.E2ETests --filter Category=E2E
8. (after_script) terraform destroy -auto-approve
```

| No | テストシナリオ | 手順 | 期待結果 | 優先度 |
|----|----------------|------|----------|--------|
| E2E-PRE-1 | Terraform apply が成功する | 上記 1〜5 | apply 成功、`invoke_url` 出力 | 高 |
| E2E-1 | POST → SFN SUCCEEDED → GET の正常フロー | (1) `POST {API_BASE_URL}/todos` body=`{title:"e2e-1"}` → 201、id/executionArn 取得<br/>(2) `DescribeExecution(executionArn)` を 1 秒間隔最大 30 秒 polling<br/>(3) status=SUCCEEDED を確認<br/>(4) `GET {API_BASE_URL}/todos/{id}` → 200 + 一致する Todo | 全段階で期待通りのレスポンス | 高 |
| E2E-2 | バリデーションエラーで 400 が返る | `POST {API_BASE_URL}/todos` body=`{title:""}` | 400、Body.error に "title" | 高 |
| E2E-3 | 存在しない ID の GET で 404 | `GET {API_BASE_URL}/todos/00000000-0000-0000-0000-000000000000` | 404、Body.error="not found" | 中 |
| E2E-4 | warmup invoke によるコールドスタート緩和（任意） | E2E-1 直前に POST を1回投げる | 後続 POST のレスポンス時間が低下（観察のみ、合否判定なし） | 低 |

### 2.4 E2Eテスト実現性チェックリスト

> ⚠️ **必須**: E2E がスコープ内のため、設計フェーズ中に確認する。

| # | チェック項目 | 確認結果 | 備考 |
|---|-------------|----------|------|
| 1 | Docker / Docker Compose が利用可能か | ☑ 利用可（前提） | GitLab CI runner に privileged Docker executor + DinD を要求、README に明記 |
| 2 | 必要なコンテナイメージがプル可能か | ☑ 可能 | `floci/floci:latest`、`mcr.microsoft.com/dotnet/sdk:8.0`、`hashicorp/terraform:1.6` を CI registry mirror から取得想定 |
| 3 | ネットワーク権限（ポート開放・外部通信） | ☑ 確保済 | 全通信はジョブ内 docker network。外部到達は image pull のみ |
| 4 | 外部サービス（DB, API 等）へのアクセス | ☑ 不要 | floci 内で DynamoDB / SFN / API GW を完結 |
| 5 | E2E テストフレームワーク・ツール | ☑ 済 | xUnit + `HttpClient`（NuGet）。追加ツール不要 |
| 6 | テストデータ・シードデータ準備 | ☑ 可能 | テストごとに POST で生成、destroy で破棄 |
| 7 | CI/CD 環境での E2E 実行 | ⚠ 要確認 | 実装前に GitLab Runner が `privileged` 化されているか確認。privileged 不可なら shell executor + 直 docker compose にフォールバック（README に両方記載） |

> **注**: #7 のみ実装前にユーザー確認が必要。privileged 不可の場合は CI 設計を `shell executor + docker compose` 直叩きに変更する代替手順を README で提示する（acceptance_criteria 達成は両方式で可能）。本設計時点では「環境準備中だが両方式の代替手順が確立されているため、設計続行可能」と判断。

---

## 3. 既存テスト修正

### 3.1 修正が必要なテスト

新規リポジトリのため対象なし。

### 3.2 削除が必要なテスト

新規リポジトリのため対象なし。

---

## 4. テストデータ設計

### 4.1 テストデータ一覧

| データ名 | 用途 | 形式 | 備考 |
|----------|------|------|------|
| `validTodo` | UT-4, IT-3, IT-5, E2E-1 | `{ "title": "buy milk", "description": "2L" }` | 正常系の最小データ |
| `emptyTitleTodo` | UT-1, IT-1, E2E-2 | `{ "title": "" }` | バリデーション NG |
| `longTitleTodo` | UT-2 | `{ "title": "a" x 121 }` | 長さ違反 |
| `unknownId` | IT-2, E2E-3 | `00000000-0000-0000-0000-000000000000` | 存在しない id |

### 4.2 テストフィクスチャ

```csharp
public sealed class FlociFixture : IAsyncLifetime
{
    public string Endpoint { get; } =
        Environment.GetEnvironmentVariable("AWS_ENDPOINT_URL") ?? "http://localhost:4566";

    public IAmazonDynamoDB Dynamo { get; private set; } = default!;

    public async Task InitializeAsync()
    {
        Environment.SetEnvironmentVariable("AWS_ACCESS_KEY_ID", "test");
        Environment.SetEnvironmentVariable("AWS_SECRET_ACCESS_KEY", "test");
        Environment.SetEnvironmentVariable("AWS_DEFAULT_REGION", "us-east-1");
        Dynamo = AwsClientFactory.Dynamo();
        await EnsureTodosTableAsync();
    }
    // ...
}
```

---

## 5. モック/スタブ設計

### 5.1 モック対象

| 対象 | モック方法 | 用途 |
|------|------------|------|
| `IAmazonStepFunctions` | NSubstitute or 手書きフェイク（IT-7 のみ） | 結合テストで API ハンドラのレスポンス検証時、SFN を実行せず `executionArn` を返す |
| `ITodoRepository` | 手書きフェイク（UT 用） | API ハンドラの単体ロジックを floci なしで検証する場合（オプション、優先度低） |

### 5.2 スタブ定義

```csharp
internal sealed class FakeStepFunctions : IAmazonStepFunctions
{
    public Task<StartExecutionResponse> StartExecutionAsync(
        StartExecutionRequest request, CancellationToken ct = default) =>
        Task.FromResult(new StartExecutionResponse {
            ExecutionArn = "arn:aws:states:us-east-1:000000000000:execution:fake:" + Guid.NewGuid(),
            StartDate = DateTime.UtcNow
        });
    // 他メソッドは NotImplementedException
}
```

> E2E では floci 実体を使うためモックは不要。

---

## 6. 受入基準（AC）対応表（再掲・詳細版）

| AC# | 内容 | 検証手段 | 主要テストID |
|-----|------|----------|--------------|
| AC1 | .NET 8 Lambda 実装が含まれる | 単体 + 結合 | UT-1〜UT-10、IT-1〜IT-7 |
| AC2 | Terraform で API GW / Lambda / SFN を floci にデプロイできる | E2E 前段 | E2E-PRE-1（apply 成功） |
| AC3 | GitLab CI で xUnit 単体テスト実行 | 単体（CI `unit` ジョブ） | UT-* 全件 |
| AC4 | GitLab CI で Lambda ハンドラレベルテスト実行 | 結合（CI `integration` ジョブ） | IT-* 全件 |
| AC5 | GitLab CI で floci 経由 API GW E2E 実行 | E2E（CI `e2e` ジョブ） | E2E-1, E2E-2, E2E-3 |
| AC6 | README にセットアップ等記載 | 実装フェーズで担保（テストでは目視レビュー） | （README レビュー） |
| AC7 | 実 AWS 不使用、floci のみで完結 | E2E + 弊害検証 | E2E-1〜3 + 06_side-effect §5.3 |

---

## 7. テスト環境

### 7.1 環境要件

| 項目 | 要件 | 備考 |
|------|------|------|
| .NET SDK | 8.0 | unit/integration/e2e 共通 |
| Docker / Docker Compose | 24+ / v2 | integration/e2e で必要 |
| floci image | `floci/floci:latest` | `compose/docker-compose.yml` で固定可 |
| Terraform | 1.6+ | e2e で必要 |
| Amazon.Lambda.Tools | 最新 | `dotnet tool install -g` を CI で実行 |
| 環境変数 | `AWS_ENDPOINT_URL`, `AWS_DEFAULT_REGION=us-east-1`, `AWS_ACCESS_KEY_ID=test`, `AWS_SECRET_ACCESS_KEY=test`, `FLOCI_HOSTNAME=floci` (CI のみ) | integration/e2e |

### 7.2 セットアップ手順

```bash
# ローカル
docker compose -f compose/docker-compose.yml up -d
dotnet test tests/TodoApi.UnitTests
AWS_ENDPOINT_URL=http://localhost:4566 dotnet test tests/TodoApi.IntegrationTests
./scripts/deploy-local.sh   # build → package → tf apply
./scripts/e2e.sh            # E2E 実行
```

---

## 8. 実行計画

### 8.1 テスト実行順序

1. 単体テスト（floci 不要、最速）
2. 結合テスト（floci 起動済み、apply 不要）
3. E2E テスト（floci + terraform apply 後）

### 8.2 CI/CD 連携

| パイプライン | トリガー | 実行ジョブ | 想定実行時間 |
|--------------|----------|-----------|--------------|
| MR / push | プッシュ | `unit` → `integration` → `e2e` を順次 | 〜10 分（コールドスタート含む） |

ジョブごとに `dotnet format --verify-no-changes`（unit 前段）と `terraform fmt -check && terraform validate`（e2e 前段）を実行（setup.yaml の品質チェック要件）。

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-04-25 | 1.0 | 初版作成 | dev-workflow |
