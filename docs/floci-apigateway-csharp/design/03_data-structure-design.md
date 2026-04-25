# データ構造設計

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | floci-apigateway-csharp-001 |
| タスク名 | API Gateway + Lambda(.NET) + Step Functions サンプルアプリと CI/CD 基盤の構築 |
| 作成日 | 2026-04-25 |

---

## 1. エンティティ/モデル設計

### 1.1 ER図（DynamoDB シングルテーブル）

```mermaid
erDiagram
    TODOS {
        string id PK "UUID v4 (HASH key)"
        string title "1〜120文字、必須"
        string description "任意、最大1024文字"
        string status "pending|done"
        string created_at "ISO 8601 UTC"
        string updated_at "ISO 8601 UTC"
    }
```

### 1.2 エンティティ定義

| エンティティ名 | 説明 | テーブル名 |
|----------------|------|------------|
| Todo | Todo ドメインモデル（API/SFN/Repository で共通） | `Todos` |

---

## 2. スキーマ変更

### 2.1 新規テーブル（Terraform）

```hcl
resource "aws_dynamodb_table" "todos" {
  name         = "Todos"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
```

| 属性 | DynamoDB 型 | 必須 | 説明 |
|------|------------|------|------|
| `id` | S | ✅ | UUID v4。PartitionKey |
| `title` | S | ✅ | 1〜120 文字 |
| `description` | S | — | 任意、最大 1024 文字。**空文字 / 空白のみは null と等価**として扱い、属性自体を出力しない（DR-013 対応、UT-11 で確認） |
| `status` | S | ✅ | `pending` / `done` |
| `created_at` | S | ✅ | ISO 8601 UTC（例 `2026-04-25T10:00:00Z`） |
| `updated_at` | S | ✅ | 同上 |

**GSI / TTL / Streams**: 未使用（サンプル簡素化、setup.yaml の non_functional 要件遵守）。

### 2.2 既存テーブル変更

新規リポジトリのため対象なし。

---

## 3. 型定義（C#）

### 3.1 新規型定義

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

// DR-002: api-handler が id・タイムスタンプ・status を確定した完全な Todo を渡す
public sealed record ValidateTodoInput(Todo Todo);

public sealed record ValidateTodoOutput(
    Todo Todo,
    bool Valid,
    IReadOnlyList<string> Errors);

public sealed record PersistTodoOutput(string TodoId, bool Persisted);
```

JSON 設定（共通）:

```csharp
internal static class JsonOpts
{
    public static readonly JsonSerializerOptions Default = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        Converters = { new JsonStringEnumConverter(JsonNamingPolicy.CamelCase) }
    };
}
```

### 3.2 マッピング（DynamoDB ⇄ C#）

`Repositories/TodoMapper.cs` に集約。

| C# プロパティ | DynamoDB 属性名 | 型 | 備考 |
|---------------|-----------------|----|------|
| `Id` | `id` | S | — |
| `Title` | `title` | S | — |
| `Description` | `description` | S | `null` or 空白のみ → **属性自体を出力しない**（`TodoMapper` で正規化、DR-013） |
| `Status` | `status` | S | `Pending` → `"pending"` / `Done` → `"done"` |
| `CreatedAt` | `created_at` | S | `ToUniversalTime().ToString("O")` |
| `UpdatedAt` | `updated_at` | S | 同上 |

```csharp
public static Dictionary<string, AttributeValue> ToAttributeMap(Todo t);
public static Todo FromAttributeMap(Dictionary<string, AttributeValue> map);
```

### 3.3 既存型の変更

新規作成のため対象なし。

---

## 4. データフロー

### 4.1 POST /todos のデータフロー（DR-002 対応：id 採番は api-handler に統一）

```mermaid
flowchart LR
    C[Client] -->|JSON CreateTodoRequest| AGW[API Gateway]
    AGW -->|APIGatewayProxyRequest| H[ApiHandler]
    H -->|sync TodoValidator.Validate + description 正規化| H
    H -->|Guid.NewGuid + DateTime.UtcNow で Todo を確定| H
    H -->|StartExecution input=ValidateTodoInput Todo含む| SFN[Step Functions]
    SFN -->|ValidateTodoInput Todo| V[ValidateTodoHandler]
    V -->|ValidateTodoOutput Todo+Valid 検証のみ id不変| SFN
    SFN -->|ValidateTodoOutput| P[PersistTodoHandler]
    P -->|PutItem AttributeMap id=Todo.Id| DDB[(DynamoDB Todos)]
    P -->|PersistTodoOutput| SFN
    H -->|APIGatewayProxyResponse 201 Todo+executionArn| AGW
    AGW --> C
```

> **id の流れ（DR-002）**: api-handler で `Guid.NewGuid()` 採番 → SFN input の `Todo.Id` → ValidateTodo 入出力で不変 → PersistTodo の `PutItem.id` → 同 id を POST レスポンス・GET key に使用。

### 4.2 GET /todos/{id} のデータフロー

```mermaid
flowchart LR
    C[Client] -->|GET| AGW[API Gateway]
    AGW -->|APIGatewayProxyRequest pathParams.id| H[ApiHandler]
    H -->|GetItemRequest key.id| DDB[(DynamoDB Todos)]
    DDB -->|GetItemResponse| H
    H -->|TodoMapper.FromAttributeMap| H
    H -->|200 Todo / 404| AGW
    AGW --> C
```

---

## 5. マイグレーション計画

### 5.1 マイグレーションステップ

| ステップ | 内容 | ロールバック方法 | 実行順序 |
|----------|------|------------------|----------|
| 1 | `terraform apply` で `aws_dynamodb_table.todos` 作成 | `terraform destroy` | 初回 1 回のみ |
| 2 | 既存データなし（サンプル新規） | — | — |

### 5.2 データ移行

新規構築のため対象なし。

---

## 6. インデックス設計

| テーブル | カラム | インデックス種別 | 目的 |
|----------|--------|------------------|------|
| `Todos` | `id` | PRIMARY (HASH) | 単一アイテム取得 |

GSI/LSI は未使用（サンプル要件に含まれないため）。

---

## 7. アイテムサンプル

```jsonc
{
  "id":          { "S": "f1c8f7a8-1d3a-4cf9-8f88-3b9a3a0b9af1" },
  "title":       { "S": "Buy milk" },
  "description": { "S": "2L organic" },
  "status":      { "S": "pending" },
  "created_at":  { "S": "2026-04-25T10:00:00Z" },
  "updated_at":  { "S": "2026-04-25T10:00:00Z" }
}
```

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-04-25 | 1.0 | 初版作成 | dev-workflow |
| 2026-04-25 | 1.1 | review-design round1 反映: description の空白正規化を明記（DR-013）、DTO を `ValidateTodoInput(Todo)` に変更（DR-002）、§4.1 データフロー図を id 採番が api-handler である旨に更新（DR-002） | dev-workflow |
