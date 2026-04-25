# 既存パターン調査

## 概要

対象リポジトリは新規のため独自の規約はまだない。本サンプルが従う標準パターンを、関連リポジトリ floci の compat tests と .NET / Terraform / xUnit の一般的な慣行から導出する。

## コーディングスタイル（採用予定）

### .NET 8

- `Nullable` 有効、`ImplicitUsings` 有効（`csproj` で `enable`）
- `dotnet format` を CI に組み込み（setup.yaml で確定済）
- 命名規則は Microsoft 標準

### Terraform

- `terraform fmt` / `terraform validate` を CI に組み込み（setup.yaml で確定済）
- リソース名は `snake_case`（floci compat-terraform 踏襲）
- 変数は `variables.tf`、出力は `outputs.tf` に分離

### 命名規則

| 対象 | 規則 | 例 |
|------|------|-----|
| C# クラス/レコード | PascalCase | `TodoRepository`, `CreateTodoRequest` |
| C# メソッド | PascalCase | `GetByIdAsync` |
| C# private フィールド | `_camelCase` | `_dynamoClient` |
| Terraform リソース | snake_case | `aws_dynamodb_table.todos` |
| Lambda 関数名 | kebab-case | `api-handler`, `validate-todo`, `persist-todo` |
| DynamoDB 属性 | snake_case | `created_at` |

## 実装パターン（提案）

### Lambda ハンドラ（API Gateway proxy 統合）

```csharp
public class Function
{
    private readonly ITodoRepository _repo;
    private readonly IAmazonStepFunctions _sfn;

    public Function() : this(
        new TodoRepository(AwsClientFactory.Dynamo()),
        AwsClientFactory.StepFunctions()) { }

    internal Function(ITodoRepository repo, IAmazonStepFunctions sfn)
    {
        _repo = repo;
        _sfn = sfn;
    }

    public async Task<APIGatewayProxyResponse> FunctionHandler(
        APIGatewayProxyRequest request, ILambdaContext context)
    {
        return (request.HttpMethod, request.Resource) switch
        {
            ("POST", "/todos") => await CreateAsync(request, context),
            ("GET",  "/todos/{id}") => await GetAsync(request, context),
            _ => Json(404, new { message = "not found" })
        };
    }
}
```

### DynamoDB リポジトリ

```csharp
public sealed class TodoRepository : ITodoRepository
{
    private readonly IAmazonDynamoDB _client;
    private const string TableName = "Todos";

    public TodoRepository(IAmazonDynamoDB client) => _client = client;

    public async Task PutAsync(Todo t, CancellationToken ct = default)
    {
        await _client.PutItemAsync(new PutItemRequest
        {
            TableName = TableName,
            Item = TodoMapper.ToAttributeMap(t)
        }, ct);
    }
}
```

### AWS クライアント生成（floci endpoint 対応）

```csharp
internal static class AwsClientFactory
{
    private static readonly string? Endpoint =
        Environment.GetEnvironmentVariable("AWS_ENDPOINT_URL");

    public static IAmazonDynamoDB Dynamo() =>
        new AmazonDynamoDBClient(BuildConfig<AmazonDynamoDBConfig>());

    private static T BuildConfig<T>() where T : ClientConfig, new()
    {
        var cfg = new T();
        if (!string.IsNullOrEmpty(Endpoint)) cfg.ServiceURL = Endpoint;
        return cfg;
    }
}
```

`AWS_ENDPOINT_URL` を読む方式は floci ドキュメント（getting-started/aws-setup.md）の推奨パターン。

## Terraform パターン（floci provider）

```hcl
# infra/provider.tf
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}

variable "endpoint" {
  type    = string
  default = "http://localhost:4566"
}

provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    dynamodb       = var.endpoint
    lambda         = var.endpoint
    iam            = var.endpoint
    sts            = var.endpoint
    apigateway     = var.endpoint
    stepfunctions  = var.endpoint
    s3             = var.endpoint
    cloudwatchlogs = var.endpoint
  }
}
```

出典: `submodules/readonly/floci/compatibility-tests/compat-terraform/provider.tf`

## テストパターン

### 単体テスト（純粋ロジック）

```csharp
public class TodoValidatorTests
{
    [Fact]
    public void Empty_title_is_invalid()
    {
        var r = TodoValidator.Validate(new CreateTodoRequest("", null));
        Assert.False(r.Valid);
        Assert.Contains("title", string.Join(",", r.Errors));
    }
}
```

### 結合テスト（Lambda ハンドラ + floci）

```csharp
public class FunctionHandlerTests : IClassFixture<FlociFixture>
{
    private readonly Function _fn;

    public FunctionHandlerTests(FlociFixture _) =>
        _fn = new Function(); // AWS_ENDPOINT_URL は環境変数で注入

    [Fact]
    public async Task Get_returns_404_for_unknown_id()
    {
        var req = new APIGatewayProxyRequest {
            HttpMethod = "GET",
            Resource   = "/todos/{id}",
            PathParameters = new Dictionary<string,string>{ ["id"] = "missing" }
        };
        var res = await _fn.FunctionHandler(req, new TestLambdaContext());
        Assert.Equal(404, res.StatusCode);
    }
}
```

`Amazon.Lambda.TestUtilities.TestLambdaContext` を利用。

### E2E テスト（API Gateway 経由）

```csharp
public class TodoApiE2ETests : IClassFixture<FlociFixture>
{
    private readonly HttpClient _http;
    private readonly string _baseUrl; // tf output 由来

    [Fact]
    public async Task Post_then_Get_succeeds()
    {
        var post = await _http.PostAsJsonAsync($"{_baseUrl}/todos",
            new { title = "buy milk" });
        post.EnsureSuccessStatusCode();
        var created = await post.Content.ReadFromJsonAsync<Todo>();
        var get = await _http.GetAsync($"{_baseUrl}/todos/{created!.Id}");
        Assert.Equal(HttpStatusCode.OK, get.StatusCode);
    }
}
```

### テストファイル配置

```
tests/
├── TodoApi.UnitTests/             # 純粋ロジック（floci 不要）
├── TodoApi.IntegrationTests/      # Lambda ハンドラ + floci
└── TodoApi.E2ETests/              # API Gateway 経由（CI のみ既定で有効）
```

## エラーハンドリングパターン

```csharp
try { ... }
catch (ValidationException ex) { return Json(400, new { error = ex.Message }); }
catch (ResourceNotFoundException) { return Json(404, new { error = "not found" }); }
catch (Exception ex)
{
    context.Logger.LogError(ex.ToString());
    return Json(500, new { error = "internal" });
}
```

## ロギングパターン

- `ILambdaContext.Logger.LogInformation/LogError` を直接利用（最小依存）
- 構造化が必要であれば `Microsoft.Extensions.Logging` を将来追加

## 備考

- 既存 floci compat-terraform は API Gateway / Lambda / Step Functions リソースを定義していないため、本サンプルが「**floci 上で .NET 8 Lambda + REST API + Step Functions を Terraform で構築する初期参照実装**」となる位置付け。
- DI フレームワークは導入せず、コンストラクタ2系統（パラメータレス本番用 + テスト用）で十分（サンプル簡素性優先）。
