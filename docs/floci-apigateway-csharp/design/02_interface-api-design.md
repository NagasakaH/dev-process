# インターフェース/API 設計

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | floci-apigateway-csharp-001 |
| タスク名 | API Gateway + Lambda(.NET) + Step Functions サンプルアプリと CI/CD 基盤の構築 |
| 作成日 | 2026-04-25 |

---

## 1. 公開API/エンドポイント（Todo API）

### 1.1 新規エンドポイント（本サンプルのスコープ）

| メソッド | パス | 概要 | 認証 | API Gateway 統合 |
|----------|------|------|------|------------------|
| `POST` | `/todos` | Todo 作成（api-handler が id を採番→Step Functions 起動） | なし（NONE） | AWS_PROXY → `api-handler` Lambda |
| `GET`  | `/todos/{id}` | Todo 取得 | なし（NONE） | AWS_PROXY → `api-handler` Lambda |

> **floci 固有**: 上記の実 invoke URL は
> `http://floci:4566/restapis/{rest_api_id}/{stage}/_user_request_/todos`
> 形式となる。Terraform output `invoke_url` で完全 URL を生成し、E2E に環境変数で渡す。

### 1.2 スコープ外（将来拡張）

本サンプルは「**POST/GET + 作成フロー（API Gateway → Lambda → Step Functions → DynamoDB）の検証**」に範囲を限定する。
以下は **out_of_scope** としてスコープ外とし、README の「Future Work」セクションに明記する（DR-003 対応）。

| メソッド | パス | スコープ外理由 | 想定対応 |
|----------|------|----------------|----------|
| `PATCH`/`PUT` | `/todos/{id}` | サンプル簡素化（SFN フロー検証目的に対し追加価値が少ない） | 将来拡張: `aws_dynamodb` UpdateItem + `Updated` ステート追加 |
| `DELETE` | `/todos/{id}` | 同上 | 将来拡張: DeleteItem |
| `GET` | `/todos` (List) | GSI/ページング設計が必要でサンプル簡素化を阻害 | 将来拡張: GSI `created_at` + Query |

> **要件との整合**: setup.yaml `requirements.functional` の「CRUD を中心」は、本サンプルでは **Create/Read（POST/GET）+ Step Functions 経由の作成フロー検証** をもって「中心」を達成し、Update/Delete/List は将来拡張として README に明記することで合意する（DR-003 対応）。

### 1.3 修正エンドポイント

| メソッド | パス | 変更内容 | 後方互換 |
|----------|------|----------|----------|
| — | — | 新規作成のため対象なし | — |

---

## 2. リクエスト/レスポンス定義

### 2.1 POST /todos

#### リクエスト

```jsonc
// Content-Type: application/json
{
  "title": "Buy milk",          // 必須、1〜120文字
  "description": "2L organic"   // 任意、最大1024文字
}
```

```csharp
public sealed record CreateTodoRequest(string Title, string? Description);
```

#### 正常レスポンス（201 Created）

```jsonc
{
  "id":           "f1c8f7a8-1d3a-4cf9-8f88-3b9a3a0b9af1",
  "title":        "Buy milk",
  "description":  "2L organic",
  "status":       "pending",
  "createdAt":    "2026-04-25T10:00:00Z",
  "updatedAt":    "2026-04-25T10:00:00Z",
  "executionArn": "arn:aws:states:us-east-1:000000000000:execution:todo-state-machine:..."
}
```

> **設計判断（DR-002 対応）**: `id` は **api-handler が `Guid.NewGuid()` で採番**し、
> `createdAt`/`updatedAt`/`status="pending"` も api-handler が確定させた後で `StartExecution` の `input` に
> `Todo`（id 含む）を渡す。**ValidateTodo Lambda は検証のみ**を担当し id を生成しない。
> これにより POST レスポンスで返した `id` と DynamoDB に格納される `id` が必ず一致し、E2E の POST → polling → GET が成立する（DR-002）。
> POST は **Step Functions 起動の executionArn を即返却**し、SUCCEEDED 確認は呼び出し側が `DescribeExecution` で行う（コールドスタートタイムアウト軽減策、investigation 06）。
> Persist 完了前に GET を叩くと 404 が返る可能性があるため、E2E は SFN の `SUCCEEDED` を待ってから GET を実行する。

#### エラーレスポンス

| ステータス | 発生条件 | ボディ例 |
|------------|----------|----------|
| 400 Bad Request | JSON パース失敗 / `title` 未指定 / `title` 長さ違反 / `description` 長さ違反 | `{ "error": "title is required" }` |
| 500 Internal Server Error | `StartExecution` 失敗、未捕捉例外 | `{ "error": "internal" }` |

> **注意**: ValidateTodo は Step Functions 内で「検証のみ」を担当し、**id 採番は行わない**（DR-002）。API ハンドラ側でも事前に同等の同期バリデーションを行う（即時 400 を返すため）。バリデータ実装は `Validation/TodoValidator.cs` に集約し、API/SFN の両方から再利用する。
>
> **description 正規化（DR-013 対応）**: API ハンドラと ValidateTodo の双方で `description` は `string.IsNullOrWhiteSpace(s) ? null : s.Trim()` で正規化する。空文字・空白のみは `null` と等価とし、DynamoDB 属性も欠損させる。UT-11 で確認する。

### 2.2 GET /todos/{id}

#### リクエスト

- パスパラメータ: `id`（UUID 文字列）
- ボディ: なし

#### 正常レスポンス（200 OK）

```jsonc
{
  "id":          "f1c8f7a8-1d3a-4cf9-8f88-3b9a3a0b9af1",
  "title":       "Buy milk",
  "description": "2L organic",
  "status":      "pending",
  "createdAt":   "2026-04-25T10:00:00Z",
  "updatedAt":   "2026-04-25T10:00:00Z"
}
```

#### エラーレスポンス

| ステータス | 発生条件 | ボディ例 |
|------------|----------|----------|
| 404 Not Found | DynamoDB に該当 `id` のアイテムなし | `{ "error": "not found" }` |
| 500 Internal Server Error | DynamoDB 例外、未捕捉例外 | `{ "error": "internal" }` |

---

## 3. 関数シグネチャ（C# Lambda ハンドラ）

### 3.1 API ハンドラ（Function::ApiHandler）

```csharp
public sealed partial class Function
{
    private readonly ITodoRepository _repo;
    private readonly IAmazonStepFunctions _sfn;
    private readonly string _stateMachineArn;

    // 本番用：パラメータレス
    public Function() : this(
        new TodoRepository(AwsClientFactory.Dynamo()),
        AwsClientFactory.StepFunctions(),
        Environment.GetEnvironmentVariable("STATE_MACHINE_ARN") ?? "")
    { }

    // テスト用
    internal Function(ITodoRepository repo, IAmazonStepFunctions sfn, string stateMachineArn)
    {
        _repo = repo;
        _sfn = sfn;
        _stateMachineArn = stateMachineArn;
    }

    public async Task<APIGatewayProxyResponse> ApiHandler(
        APIGatewayProxyRequest request,
        ILambdaContext context);
}
```

### 3.2 Step Functions ハンドラ

```csharp
public sealed partial class Function
{
    public Task<ValidateTodoOutput> ValidateTodo(
        ValidateTodoInput input,
        ILambdaContext context);

    public Task<PersistTodoOutput> PersistTodo(
        ValidateTodoOutput input,
        ILambdaContext context);
}
```

### 3.3 リポジトリ / バリデータ

```csharp
public interface ITodoRepository
{
    Task PutAsync(Todo todo, CancellationToken ct = default);
    Task<Todo?> GetByIdAsync(string id, CancellationToken ct = default);
}

public static class TodoValidator
{
    public static (bool Valid, IReadOnlyList<string> Errors) Validate(CreateTodoRequest req);
}
```

### 3.4 AWS クライアント生成（fail-fast、DR-001 対応）

```csharp
internal static class AwsClientFactory
{
    public static IAmazonDynamoDB Dynamo();
    public static IAmazonStepFunctions StepFunctions();
}
```

**`AWS_ENDPOINT_URL` は必須**とし、未設定なら `InvalidOperationException("AWS_ENDPOINT_URL is required (floci-only deployment)")` をスローして起動失敗させる（DR-001）。
これにより実 AWS への意図せぬフォールバックを **設計レベルで禁止**する。実装疑似コード:

```csharp
internal static class AwsClientFactory
{
    private static string RequireEndpoint() =>
        Environment.GetEnvironmentVariable("AWS_ENDPOINT_URL")
            ?? throw new InvalidOperationException(
                "AWS_ENDPOINT_URL is required (floci-only deployment; falling back to real AWS is forbidden)");

    public static IAmazonDynamoDB Dynamo()
    {
        var cfg = new AmazonDynamoDBConfig { ServiceURL = RequireEndpoint() };
        return new AmazonDynamoDBClient(cfg);
    }

    public static IAmazonStepFunctions StepFunctions()
    {
        var cfg = new AmazonStepFunctionsConfig { ServiceURL = RequireEndpoint() };
        return new AmazonStepFunctionsClient(cfg);
    }
}
```

> **検証観点**: UT-9（設定時）と **UT-10（未設定時に例外）**の双方を必須化する（05_test-plan §2.1 で UT-10 を更新）。
> Terraform provider 側でも `var.endpoint` を必須変数化（default なし）して同等の fail-fast を担保する（§6.1）。

---

## 4. インターフェース定義（DTO、DR-002 対応）

api-handler が id・タイムスタンプ・初期 status を確定した完全な `Todo` を ValidateTodo / PersistTodo に渡す。
ValidateTodo は **検証結果のみ**を返し（id・属性は不変）、PersistTodo は同じ `Todo` を保存する。

```csharp
namespace TodoApi.Lambda.Models;

public sealed record Todo(
    string Id,
    string Title,
    string? Description,
    TodoStatus Status,
    DateTime CreatedAt,
    DateTime UpdatedAt);

public enum TodoStatus { Pending, Done }

public sealed record CreateTodoRequest(string Title, string? Description);

// api-handler が組み立てた Todo（id 採番済み）を SFN 入力として渡す
public sealed record ValidateTodoInput(Todo Todo);

// 検証結果。Todo は不変で透過、Valid と Errors のみ追加
public sealed record ValidateTodoOutput(
    Todo Todo,
    bool Valid,
    IReadOnlyList<string> Errors);

// PersistTodo の入力は ValidateTodoOutput（Choice で valid==true のみ通過）
public sealed record PersistTodoOutput(string TodoId, bool Persisted);
```

> JSON シリアライズは `System.Text.Json` 既定（`camelCase` ポリシーを `JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase` で適用）。`TodoStatus` は文字列 `"pending"` / `"done"` で出力（`JsonStringEnumConverter` + `CamelCase`）。
>
> **不変条件（DR-002）**: `ValidateTodoInput.Todo.Id` == `ValidateTodoOutput.Todo.Id` == DynamoDB に格納される `id` == POST レスポンスで返却した `id`。IT-3/IT-5/IT-7 と E2E-1 で確認する。

---

## 5. Step Functions ASL 定義（DR-005 対応：Retry/Catch を ASL に明記）

> **INFO-1 対応（round2）**: ASL 内の Lambda ARN は固定文字列ではなく、Terraform 側で `jsonencode` + `aws_lambda_function.*.arn` を用いて動的参照する。これにより AWS アカウント ID／関数名変更時にも ASL を編集不要にする。下記 JSON は **設計表現用のテンプレート**であり、実体は次節の HCL で組み立てる。

設計表現用テンプレート（プレースホルダ `${VALIDATE_TODO_ARN}` / `${PERSIST_TODO_ARN}` を Terraform で差し替え）:

```jsonc
{
  "Comment": "Todo 作成フロー",
  "StartAt": "ValidateTodo",
  "States": {
    "ValidateTodo": {
      "Type": "Task",
      "Resource": "${VALIDATE_TODO_ARN}",
      "Next": "CheckValid",
      "Catch": [
        { "ErrorEquals": ["States.ALL"], "Next": "Failed" }
      ]
    },
    "CheckValid": {
      "Type": "Choice",
      "Choices": [
        { "Variable": "$.valid", "BooleanEquals": true, "Next": "PersistTodo" }
      ],
      "Default": "Failed"
    },
    "PersistTodo": {
      "Type": "Task",
      "Resource": "${PERSIST_TODO_ARN}",
      "Retry": [
        {
          "ErrorEquals": ["States.TaskFailed"],
          "IntervalSeconds": 1,
          "MaxAttempts": 3,
          "BackoffRate": 2.0
        }
      ],
      "Catch": [
        { "ErrorEquals": ["States.ALL"], "Next": "Failed" }
      ],
      "End": true
    },
    "Failed": { "Type": "Fail", "Error": "ValidationFailed" }
  }
}
```

Terraform 側の組み立て例（`infra/main.tf` 抜粋。ARN ハードコード禁止、`aws_lambda_function.*.arn` を直接参照）:

```hcl
resource "aws_sfn_state_machine" "todo" {
  name     = "todo-flow"
  role_arn = aws_iam_role.sfn_exec.arn

  definition = jsonencode({
    Comment = "Todo 作成フロー"
    StartAt = "ValidateTodo"
    States = {
      ValidateTodo = {
        Type     = "Task"
        Resource = aws_lambda_function.validate_todo.arn
        Next     = "CheckValid"
        Catch    = [{ ErrorEquals = ["States.ALL"], Next = "Failed" }]
      }
      CheckValid = {
        Type    = "Choice"
        Choices = [{ Variable = "$.valid", BooleanEquals = true, Next = "PersistTodo" }]
        Default = "Failed"
      }
      PersistTodo = {
        Type     = "Task"
        Resource = aws_lambda_function.persist_todo.arn
        Retry = [{
          ErrorEquals     = ["States.TaskFailed"]
          IntervalSeconds = 1
          MaxAttempts     = 3
          BackoffRate     = 2.0
        }]
        Catch = [{ ErrorEquals = ["States.ALL"], Next = "Failed" }]
        End   = true
      }
      Failed = { Type = "Fail", Error = "ValidationFailed" }
    }
  })
}
```

> **設計の整合（DR-005）**: 04 §3.2 の「`States.TaskFailed` リトライ 3 回」記述は本 ASL の `PersistTodo.Retry` と一致する。`ValidateTodo` はリトライしない（バリデーション結果はリトライしても変わらないため）。

---

## 6. Terraform 主要リソース I/F（infra/main.tf 抜粋）

| リソース | 役割 | 主要属性 |
|----------|------|----------|
| `aws_dynamodb_table.todos` | Todos テーブル | `name = "Todos"`, `hash_key = "id"`, `billing_mode = "PAY_PER_REQUEST"` |
| `aws_iam_role.lambda_exec` | Lambda 実行ロール | `assume_role_policy` (lambda) + 最小権限 inline policy（§6.3） |
| `aws_iam_role.sfn_exec` | SFN 実行ロール | `assume_role_policy` (states) + 最小権限 inline policy（§6.3） |
| `aws_lambda_function.api_handler` | POST/GET ハンドラ | `runtime = "dotnet8"`, `handler = "TodoApi.Lambda::TodoApi.Lambda.Function::ApiHandler"`, `filename = "lambda/TodoApi.Lambda.zip"`, `role`, `memory_size`, `timeout`, `environment`, `source_code_hash`（§6.4） |
| `aws_lambda_function.validate_todo` | SFN Task | 同 zip, `handler = "...Function::ValidateTodo"`、その他属性は §6.4 |
| `aws_lambda_function.persist_todo` | SFN Task | 同 zip, `handler = "...Function::PersistTodo"`、その他属性は §6.4 |
| `aws_sfn_state_machine.todo` | ステートマシン | ASL を `jsonencode` |
| `aws_api_gateway_rest_api.todo` | REST API | — |
| `aws_api_gateway_resource.todos` / `todo_id` | パスリソース | `/todos`, `/todos/{id}` |
| `aws_api_gateway_method.{post_todos,get_todo}` | メソッド | `authorization = "NONE"` |
| `aws_api_gateway_integration.{post_todos,get_todo}` | 統合 | `type = "AWS_PROXY"`, integration_uri = api_handler ARN |
| `aws_lambda_permission.apigw` | 呼び出し許可 | api_handler に対し apigateway.amazonaws.com から |
| `aws_api_gateway_deployment.dev` + `aws_api_gateway_stage.dev` | デプロイ・ステージ | `stage_name = "dev"`、triggers/depends_on/lifecycle は §6.5 |

### 6.1 provider.tf（DR-006 対応：完全 HCL 例）

```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "endpoint" {
  description = "floci endpoint (e.g. http://localhost:4566 / http://floci:4566). Required; no default to fail-fast on real-AWS access."
  type        = string
  # DR-001: default を設けず未指定なら apply 失敗とする
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway     = var.endpoint
    apigatewayv2   = var.endpoint
    dynamodb       = var.endpoint
    iam            = var.endpoint
    lambda         = var.endpoint
    stepfunctions  = var.endpoint
    sts            = var.endpoint
    cloudwatchlogs = var.endpoint
  }
}
```

> **DR-001/DR-006 の設計担保**: `var.endpoint` は default なしの required 変数とし、`-var endpoint=...` または `TF_VAR_endpoint` を指定しない apply は失敗する。`skip_*` フラグと `endpoints { ... }` で実 AWS への問い合わせを抑止する。AWS provider v6 系の `s3_use_path_style` は v5 の `s3_force_path_style` から改名されているため必ず本表記を使う。

### 6.2 outputs.tf

```hcl
output "rest_api_id"        { value = aws_api_gateway_rest_api.todo.id }
output "stage_name"         { value = aws_api_gateway_stage.dev.stage_name }
output "invoke_url" {
  value = "${var.endpoint}/restapis/${aws_api_gateway_rest_api.todo.id}/${aws_api_gateway_stage.dev.stage_name}/_user_request_"
}
output "state_machine_arn"  { value = aws_sfn_state_machine.todo.arn }
output "table_name"         { value = aws_dynamodb_table.todos.name }
```

E2E は `terraform output -raw invoke_url` を読み出して環境変数 `API_BASE_URL` に渡す。

### 6.2.1 var.endpoint と FLOCI_HOSTNAME の役割分担表（DR-016 対応）

| 変数 | 設定主体 | 用途 | 値の例（CI） | 値の例（ローカル） |
|------|----------|------|--------------|--------------------|
| `var.endpoint`（Terraform） | terraform apply 実行コマンド | (a) provider の `endpoints` 設定、(b) `output invoke_url` のホスト部 | `http://floci:4566` | `http://localhost:4566` |
| `AWS_ENDPOINT_URL`（Lambda 環境変数） | `aws_lambda_function.environment.variables` | Lambda 内 AWS SDK が floci に接続する内部解決 | `http://floci:4566` | （ローカルでは Lambda は floci 内で起動するため `http://localhost:4566`） |
| `FLOCI_HOSTNAME`（floci コンテナ環境変数） | `compose/docker-compose.yml` `environment` | floci 自身が API GW invoke URL の host を生成する際の名前 | `floci` | （未設定でも localhost で動作） |

**設計上の制約（DR-016）**:
- CI では `var.endpoint=http://floci:4566` と `FLOCI_HOSTNAME=floci` を**必ずペアで設定**する。
- E2E が読む `API_BASE_URL` は `terraform output -raw invoke_url` の値であり、CI ではホスト部が **`floci` でなければならない**。
- E2E テストの先頭で `Assert.DoesNotContain("localhost", apiBaseUrl)` を CI 環境（`CI=true`）下に限り強制する（06 §1.1 の検証観点に追加）。

### 6.3 IAM 最小権限ポリシー（DR-009 対応）

```hcl
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "todo-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Lambda → DynamoDB（PutItem/GetItem のみ）+ StepFunctions StartExecution + CloudWatch Logs
data "aws_iam_policy_document" "lambda_inline" {
  statement {
    sid       = "DynamoTodos"
    actions   = ["dynamodb:PutItem", "dynamodb:GetItem"]
    resources = [aws_dynamodb_table.todos.arn]
  }
  statement {
    sid       = "StartExecution"
    actions   = ["states:StartExecution", "states:DescribeExecution"]
    resources = [aws_sfn_state_machine.todo.arn, "${replace(aws_sfn_state_machine.todo.arn, "stateMachine", "execution")}:*"]
  }
  statement {
    sid       = "CloudWatchLogs"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_inline" {
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_inline.json
}

# Step Functions → Lambda Invoke（validate-todo / persist-todo のみ）
data "aws_iam_policy_document" "sfn_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sfn_exec" {
  name               = "todo-sfn-exec"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume.json
}

data "aws_iam_policy_document" "sfn_inline" {
  statement {
    sid     = "InvokeLambdas"
    actions = ["lambda:InvokeFunction"]
    resources = [
      aws_lambda_function.validate_todo.arn,
      aws_lambda_function.persist_todo.arn,
    ]
  }
}

resource "aws_iam_role_policy" "sfn_inline" {
  role   = aws_iam_role.sfn_exec.id
  policy = data.aws_iam_policy_document.sfn_inline.json
}
```

> floci では IAM の評価は緩く、ポリシー違反でブロックされない場合があるが、本サンプルは「**実 AWS でも最小権限で動作する HCL の参照実装**」を目的として最小権限を明記する。

### 6.4 Lambda 関数属性（DR-010 対応）

3 関数共通の属性方針:

```hcl
locals {
  lambda_zip      = "${path.module}/lambda/TodoApi.Lambda.zip"
  lambda_zip_hash = filebase64sha256(local.lambda_zip)
  common_env = {
    AWS_ENDPOINT_URL    = var.endpoint
    AWS_DEFAULT_REGION  = "us-east-1"
    TABLE_NAME          = aws_dynamodb_table.todos.name
  }
}

resource "aws_lambda_function" "api_handler" {
  function_name    = "api-handler"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = "dotnet8"
  handler          = "TodoApi.Lambda::TodoApi.Lambda.Function::ApiHandler"
  filename         = local.lambda_zip
  source_code_hash = local.lambda_zip_hash
  memory_size      = 512
  timeout          = 30
  environment {
    variables = merge(local.common_env, {
      STATE_MACHINE_ARN = aws_sfn_state_machine.todo.arn
    })
  }
}

resource "aws_lambda_function" "validate_todo" {
  function_name    = "validate-todo"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = "dotnet8"
  handler          = "TodoApi.Lambda::TodoApi.Lambda.Function::ValidateTodo"
  filename         = local.lambda_zip
  source_code_hash = local.lambda_zip_hash
  memory_size      = 512
  timeout          = 30
  environment { variables = local.common_env }
}

resource "aws_lambda_function" "persist_todo" {
  function_name    = "persist-todo"
  role             = aws_iam_role.lambda_exec.arn
  runtime          = "dotnet8"
  handler          = "TodoApi.Lambda::TodoApi.Lambda.Function::PersistTodo"
  filename         = local.lambda_zip
  source_code_hash = local.lambda_zip_hash
  memory_size      = 512
  timeout          = 30
  environment { variables = local.common_env }
}
```

| 属性 | 値 | 根拠 |
|------|----|------|
| `runtime` | `dotnet8` | setup.yaml |
| `memory_size` | 512 MB | .NET 8 コールドスタート緩和（128MB だと 5s 超過する事例） |
| `timeout` | 30 秒 | API Gateway 統合のハードリミット 29s と整合（04 §4.1） |
| `source_code_hash` | `filebase64sha256(zip)` | zip 変更検知で自動再デプロイ |
| `environment.AWS_ENDPOINT_URL` | `var.endpoint` | DR-001 の fail-fast を満たす |
| `environment.STATE_MACHINE_ARN` | `aws_sfn_state_machine.todo.arn` | api-handler が `StartExecution` で参照 |
| `environment.TABLE_NAME` | `aws_dynamodb_table.todos.name` | リポジトリが PutItem/GetItem で参照 |

### 6.5 API Gateway deployment（DR-011 対応）

```hcl
resource "aws_api_gateway_deployment" "dev" {
  rest_api_id = aws_api_gateway_rest_api.todo.id

  triggers = {
    redeploy = sha1(jsonencode([
      aws_api_gateway_resource.todos.id,
      aws_api_gateway_resource.todo_id.id,
      aws_api_gateway_method.post_todos.id,
      aws_api_gateway_method.get_todo.id,
      aws_api_gateway_integration.post_todos.id,
      aws_api_gateway_integration.get_todo.id,
    ]))
  }

  depends_on = [
    aws_api_gateway_integration.post_todos,
    aws_api_gateway_integration.get_todo,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.todo.id
  deployment_id = aws_api_gateway_deployment.dev.id
  stage_name    = "dev"
}
```

> **設計意図（DR-011）**: Method/Integration を変更したのに stage が更新されない問題を `triggers` で検知し、`create_before_destroy` で **新 deployment 作成 → stage 切替 → 旧 deployment 破棄** の順を保証する。`depends_on` で integration が deployment より先に作成されることを明示する（apply 1 回目の race 防止）。

---

## 7. エラーハンドリング

### 7.1 エラー種別

| エラー種別 | 発生箇所 | 対応 |
|------------|----------|------|
| `ValidationException` (独自) | `TodoValidator` で `Valid=false` + 同期 API パス | 400 + `{ "error": <messages.join(", ")> }` |
| `ResourceNotFoundException` (`AWSSDK.DynamoDBv2`) | `GetItem` 結果の Item が空 | 404 + `{ "error": "not found" }`（ただし `GetItemResponse.Item` 空チェックを優先実装） |
| `JsonException` | リクエストボディ JSON パース失敗 | 400 + `{ "error": "invalid json" }` |
| `AmazonStepFunctionsException` | `StartExecution` 失敗 | 500 + `{ "error": "internal" }` + `Logger.LogError` |
| 未捕捉 `Exception` | その他全般 | 500 + `{ "error": "internal" }` + `Logger.LogError(ex.ToString())` |

### 7.2 共通レスポンスヘルパ

```csharp
private static APIGatewayProxyResponse Json(int status, object body) =>
    new()
    {
        StatusCode = status,
        Headers = new Dictionary<string, string> { ["Content-Type"] = "application/json" },
        Body = JsonSerializer.Serialize(body, JsonOpts)
    };
```

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-04-25 | 1.0 | 初版作成 | dev-workflow |
| 2026-04-25 | 1.1 | review-design round1 反映: §1 スコープ再定義（DR-003）、§2.1 id 採番を api-handler に統一（DR-002）+ description 正規化（DR-013）、§3.4 AwsClientFactory fail-fast 化（DR-001）、§4 DTO を `ValidateTodoInput(Todo)` に変更（DR-002）、§5 ASL に Retry/Catch 追加（DR-005）、§6.1 provider.tf 完全 HCL（DR-006）、§6.2.1 var.endpoint vs FLOCI_HOSTNAME 表（DR-016）、§6.3 IAM 最小権限（DR-009）、§6.4 Lambda 完全属性（DR-010）、§6.5 API GW deployment triggers/lifecycle（DR-011） | dev-workflow |
| 2026-04-25 | 1.2 | review-design round2 反映: §3.1 Function クラス宣言を `public sealed partial class Function` に統一し §3.2 と整合（DR2-003）、§5 ASL の Lambda Resource を Terraform `jsonencode` + `aws_lambda_function.*.arn` 動的参照に変更し ARN ハードコードを撤廃（INFO-1） | dev-workflow |
