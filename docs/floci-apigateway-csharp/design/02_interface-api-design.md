# インターフェース/API 設計

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | floci-apigateway-csharp-001 |
| タスク名 | API Gateway + Lambda(.NET) + Step Functions サンプルアプリと CI/CD 基盤の構築 |
| 作成日 | 2026-04-25 |

---

## 1. 公開API/エンドポイント（Todo API）

### 1.1 新規エンドポイント

| メソッド | パス | 概要 | 認証 | API Gateway 統合 |
|----------|------|------|------|------------------|
| `POST` | `/todos` | Todo 作成（Step Functions 起動） | なし（NONE） | AWS_PROXY → `api-handler` Lambda |
| `GET`  | `/todos/{id}` | Todo 取得 | なし（NONE） | AWS_PROXY → `api-handler` Lambda |

> **floci 固有**: 上記の実 invoke URL は
> `http://floci:4566/restapis/{rest_api_id}/{stage}/_user_request_/todos`
> 形式となる。Terraform output `invoke_url` で完全 URL を生成し、E2E に環境変数で渡す。

### 1.2 修正エンドポイント

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

> **設計判断**: POST は **Step Functions 起動の executionArn を即返却**し、SUCCEEDED 確認は呼び出し側が `DescribeExecution` で行う方式（investigation 06 のリスク「コールドスタートタイムアウト」軽減策）。
> Persist 完了前に GET を叩くと 404 が返る可能性があるため、E2E は SFN の `SUCCEEDED` を待ってから GET を実行する。

#### エラーレスポンス

| ステータス | 発生条件 | ボディ例 |
|------------|----------|----------|
| 400 Bad Request | JSON パース失敗 / `title` 未指定 / `title` 長さ違反 / `description` 長さ違反 | `{ "error": "title is required" }` |
| 500 Internal Server Error | `StartExecution` 失敗、未捕捉例外 | `{ "error": "internal" }` |

> **注意**: ValidateTodo は Step Functions 内で実行されるため、**API ハンドラ側でも事前に同等の同期バリデーションを行う**（即時 400 を返すため）。バリデータ実装は `Validation/TodoValidator.cs` に集約し、API/SFN の両方から再利用する。

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
public sealed class Function
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

### 3.4 AWS クライアント生成

```csharp
internal static class AwsClientFactory
{
    public static IAmazonDynamoDB Dynamo();
    public static IAmazonStepFunctions StepFunctions();
}
```

`AWS_ENDPOINT_URL` 環境変数が設定されていれば `ClientConfig.ServiceURL` に代入し floci に向ける。
未設定（実 AWS 想定外だが理論上の本番運用時）はデフォルトエンドポイントを使う。

---

## 4. インターフェース定義（DTO）

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

public sealed record ValidateTodoInput(CreateTodoRequest Todo);

public sealed record ValidateTodoOutput(
    Todo Todo,
    bool Valid,
    IReadOnlyList<string> Errors);

public sealed record PersistTodoOutput(string TodoId, bool Persisted);
```

> JSON シリアライズは `System.Text.Json` 既定（`camelCase` ポリシーを `JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase` で適用）。`TodoStatus` は文字列 `"pending"` / `"done"` で出力（`JsonStringEnumConverter` + `CamelCase`）。

---

## 5. Step Functions ASL 定義

```jsonc
{
  "Comment": "Todo 作成フロー",
  "StartAt": "ValidateTodo",
  "States": {
    "ValidateTodo": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:us-east-1:000000000000:function:validate-todo",
      "Next": "CheckValid"
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
      "Resource": "arn:aws:lambda:us-east-1:000000000000:function:persist-todo",
      "End": true
    },
    "Failed": { "Type": "Fail", "Error": "ValidationFailed" }
  }
}
```

Terraform 内では `aws_sfn_state_machine.todo` の `definition` に上記を `jsonencode()` で埋め込む。
Resource ARN の Lambda 関数名（`validate-todo` / `persist-todo`）は Terraform variable 化する。

---

## 6. Terraform 主要リソース I/F（infra/main.tf 抜粋）

| リソース | 役割 | 主要属性 |
|----------|------|----------|
| `aws_dynamodb_table.todos` | Todos テーブル | `name = "Todos"`, `hash_key = "id"`, `billing_mode = "PAY_PER_REQUEST"` |
| `aws_iam_role.lambda_exec` | Lambda 実行ロール | `assume_role_policy` (lambda) |
| `aws_iam_role.sfn_exec` | SFN 実行ロール | `assume_role_policy` (states) |
| `aws_lambda_function.api_handler` | POST/GET ハンドラ | `runtime = "dotnet8"`, `handler = "TodoApi.Lambda::TodoApi.Lambda.Function::ApiHandler"`, `filename = "lambda/TodoApi.Lambda.zip"` |
| `aws_lambda_function.validate_todo` | SFN Task | 同 zip, `handler = "...Function::ValidateTodo"` |
| `aws_lambda_function.persist_todo` | SFN Task | 同 zip, `handler = "...Function::PersistTodo"` |
| `aws_sfn_state_machine.todo` | ステートマシン | ASL を `jsonencode` |
| `aws_api_gateway_rest_api.todo` | REST API | — |
| `aws_api_gateway_resource.todos` / `todo_id` | パスリソース | `/todos`, `/todos/{id}` |
| `aws_api_gateway_method.{post_todos,get_todo}` | メソッド | `authorization = "NONE"` |
| `aws_api_gateway_integration.{post_todos,get_todo}` | 統合 | `type = "AWS_PROXY"`, integration_uri = api_handler ARN |
| `aws_lambda_permission.apigw` | 呼び出し許可 | api_handler に対し apigateway.amazonaws.com から |
| `aws_api_gateway_deployment.dev` + `aws_api_gateway_stage.dev` | デプロイ・ステージ | `stage_name = "dev"` |

### 6.1 outputs.tf

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
