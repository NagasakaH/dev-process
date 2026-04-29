# インターフェース / API 設計

## 概要

| 項目       | 内容                                                  |
| ---------- | ----------------------------------------------------- |
| チケットID | FRONTEND-001                                          |
| タスク名   | floci-apigateway-csharp に Angular フロントエンド追加 |
| 作成日     | 2026-04-29                                            |

本書では、ブラウザ ⇔ floci API Gateway の HTTP I/F、CORS 仕様、Angular 内部 I/F、ランタイム設定 I/F、shell スクリプト I/F を定義する。

---

## 1. 公開 HTTP API（floci API Gateway）

### 1.1 エンドポイント一覧

| メソッド | パス          | 状態        | 説明                                  |
| -------- | ------------- | ----------- | ------------------------------------- |
| POST     | `/todos`      | 既存・変更なし | Todo 作成                             |
| GET      | `/todos/{id}` | 既存・変更なし | Todo 取得                             |
| OPTIONS  | `/todos`      | **新規追加** | CORS preflight                        |
| OPTIONS  | `/todos/{id}` | **新規追加** | CORS preflight                        |

invoke_url 構造（既存）:

```
{var.endpoint}/restapis/{rest_api_id}/dev/_user_request_
```

### 1.2 リクエスト / レスポンス（既存スキーマ・無変更）

#### POST /todos

```http
POST /todos HTTP/1.1
Origin: http://localhost:8080
Content-Type: application/json; charset=utf-8

{ "title": "buy milk" }
```

レスポンス（成功）:

```http
HTTP/1.1 201 Created
Content-Type: application/json; charset=utf-8
Access-Control-Allow-Origin: *
Access-Control-Expose-Headers: Content-Type

{ "id": "...", "title": "buy milk", ... }
```

#### GET /todos/{id}

成功 200、未発見 404 `{ "error": "..." }`、不正パラメータ 400 `{ "errors": [...] }`、サーバ例外 500 `{ "error": "internal error" }`。
**全レスポンスに CORS ヘッダ（後述 §2）を付与する**。

### 1.3 OPTIONS（CORS preflight）

```http
HTTP/1.1 204 No Content
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type
Access-Control-Max-Age: 600
```

ボディ無し。

---

## 2. CORS 仕様（追加点）

### 2.1 ヘッダ仕様

| ヘッダ                          | 値                       | 適用範囲                              | 設定箇所                                              |
| ------------------------------- | ------------------------ | ------------------------------------- | ----------------------------------------------------- |
| `Access-Control-Allow-Origin`   | `*`                      | 全レスポンス（成功 / エラー / OPTIONS） | Lambda `JsonHeaders` + APIGW OPTIONS 統合レスポンス   |
| `Access-Control-Allow-Methods`  | `GET, POST, OPTIONS`     | OPTIONS preflight                     | APIGW OPTIONS 統合レスポンス                          |
| `Access-Control-Allow-Headers`  | `Content-Type`           | OPTIONS preflight                     | APIGW OPTIONS 統合レスポンス                          |
| `Access-Control-Max-Age`        | `600`                    | OPTIONS preflight                     | APIGW OPTIONS 統合レスポンス                          |
| `Access-Control-Expose-Headers` | `Content-Type` (任意)    | 全レスポンス                          | Lambda `JsonHeaders`                                  |

> 認証スコープ外のため `*` を採用。本番化時は限定 Origin に変更（out_of_scope）。

### 2.2 実装方針

- **Lambda 側**: `Function.cs` の `JsonHeaders` 共通辞書に CORS ヘッダを追加。`BadRequest` / `NotFound` / 200 / 201 / 500 全レスポンスで自動的に付与される。
- **API Gateway 側**: Terraform で `/todos`, `/todos/{id}` に `aws_api_gateway_method`（OPTIONS, MOCK integration）と `aws_api_gateway_method_response` / `aws_api_gateway_integration_response` を追加。

### 2.3 R1 fallback: Lambda OPTIONS 受け案

floci の APIGW OPTIONS+MOCK が動かない場合、Terraform の OPTIONS メソッドを `aws_api_gateway_integration` で **AWS_PROXY (Lambda)** に切替え、`Function.cs` 側で:

```csharp
if (req.HttpMethod == "OPTIONS")
{
    return new APIGatewayProxyResponse
    {
        StatusCode = 204,
        Headers = CorsPreflightHeaders, // Allow-Origin/Methods/Headers/Max-Age
    };
}
```

を `ApiHandler` 冒頭で処理する fallback を併記する（実装は実装フェーズで切替判断）。

---

## 3. Angular 内部インターフェース

### 3.1 サービス / コンポーネント I/F

```typescript
// frontend/src/app/services/config.service.ts
export interface AppConfig {
  apiBaseUrl: string;
}
@Injectable({ providedIn: 'root' })
export class ConfigService {
  private cfg!: AppConfig;
  load(): Promise<void>;          // APP_INITIALIZER で呼ぶ
  get apiBaseUrl(): string;
}

// frontend/src/app/services/todo-api.service.ts
@Injectable({ providedIn: 'root' })
export class TodoApiService {
  create(req: TodoCreateRequest): Observable<Todo>;     // POST /todos
  get(id: string): Observable<Todo>;                    // GET /todos/{id}
}

// frontend/src/app/models/todo.ts
export interface Todo { id: string; title: string; status?: string; created_at?: string; }
export interface TodoCreateRequest { title: string; }
export interface ApiErrorResponse { errors?: string[]; error?: string; }
```

### 3.2 コンポーネント

| コンポーネント         | 責務                                       | 子要素                          |
| ---------------------- | ------------------------------------------ | ------------------------------- |
| `AppComponent`         | ルート。RouterOutlet 不使用（最小構成）    | `TodoComponent` を直接配置      |
| `TodoComponent`        | フォーム送信 + 結果表示 + エラー表示       | `[formGroup]`, `*ngIf` でエラー |

### 3.3 エラーハンドリング方式

- `TodoApiService` は `HttpErrorResponse` を `catchError` で `ApiErrorResponse` 形式に整形して再 throw。
- `TodoComponent` で 4xx → `errors[0]` を表示、5xx → "サーバエラーが発生しました" を表示。
- ネットワーク失敗 / CORS 失敗（`status === 0`）→ "API に接続できませんでした" を表示し、`console.error` でログ。

### 3.4 起動シーケンス（DI / Bootstrap）

```typescript
// main.ts
bootstrapApplication(AppComponent, {
  providers: [
    provideHttpClient(),
    {
      provide: APP_INITIALIZER,
      multi: true,
      deps: [ConfigService],
      useFactory: (cfg: ConfigService) => () => cfg.load(),
    },
  ],
});
```

---

## 4. ランタイム設定 I/F

### 4.1 `frontend/src/assets/config.json`

```json
{ "apiBaseUrl": "http://localhost:4566/restapis/<rest_api_id>/dev/_user_request_" }
```

| フィールド   | 型     | 必須 | 用途                                  | 制約                              |
| ------------ | ------ | ---- | ------------------------------------- | --------------------------------- |
| `apiBaseUrl` | string | ✅   | floci API Gateway invoke_url          | 末尾スラッシュ無し。HTTP/HTTPS のみ |

### 4.2 生成 I/F（shell）

`scripts/build-frontend.sh` が以下の手順で生成：

```bash
INVOKE_URL=$(terraform -chdir=infra output -raw invoke_url)
cat > frontend/src/assets/config.json <<EOF
{ "apiBaseUrl": "${INVOKE_URL}" }
EOF
( cd frontend && npm ci && npm run build -- --configuration=production )
```

> `apiBaseUrl` が空の場合 `ConfigService.load()` は reject し、UI に「設定読み込みエラー」を表示する（CI で fail-fast）。

---

## 5. shell スクリプト I/F

| スクリプト                       | 入力                                                   | 出力                                          | 説明                                                          |
| -------------------------------- | ------------------------------------------------------ | --------------------------------------------- | ------------------------------------------------------------- |
| `scripts/build-frontend.sh`      | env: `AWS_ENDPOINT_URL`, `AWS_*`                       | `frontend/dist/` 配下の成果物                 | invoke_url を `assets/config.json` に注入し `ng build`        |
| `scripts/deploy-frontend.sh`     | env 同上、引数: `BUCKET=frontend-bucket`               | floci S3 上のオブジェクト                     | `aws s3 sync frontend/dist/ s3://$BUCKET/`                    |
| `scripts/web-e2e.sh`             | env 同上                                               | `frontend/test-results/` (junit) + Playwright HTML | 上記 2 本 + nginx up + `npx playwright test` を 1 コマンド化  |
| `scripts/verify-readme-sections.sh` (更新) | -                                            | exit 0/1                                      | README に Frontend セクションが存在するか検証                 |

すべて `set -euo pipefail` を使い、`AWS_ENDPOINT_URL` 未設定時は exit 1。

---

## 6. nginx 設定 I/F

`compose/nginx/default.conf`（新規）:

```nginx
server {
  listen 8080;
  root /usr/share/nginx/html;
  location / {
    try_files $uri /index.html;
  }
}
```

> `proxy_pass` 等の API リバースプロキシ設定は **行わない**（決定事項）。

`compose/docker-compose.yml` に追加するサービス例:

```yaml
nginx:
  image: nginx:1.27-alpine
  ports: ["8080:8080"]
  networks: [floci-net]
  volumes:
    - ./compose/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    - ./frontend/dist:/usr/share/nginx/html:ro   # ※ S3 fallback 時のみ
```

---

## 7. GitLab CI ジョブ I/F

| ジョブ            | stage         | image                                          | キャッシュ                                                | 主要コマンド                                                                                                                                  |
| ----------------- | ------------- | ---------------------------------------------- | --------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `web-lint`        | `lint`        | `node:20-alpine`                               | `frontend/node_modules`, `~/.npm`                         | `cd frontend && npm ci && npm run lint`                                                                                                       |
| `web-unit`        | `unit`        | `node:20` (Chromium 同梱の `mcr.../playwright` でも可) | 同上                                                      | `cd frontend && npm ci && npm test -- --watch=false --browsers=ChromeHeadlessCI --reporters=junit`                                            |
| `web-integration` | `integration` | 同上                                           | 同上                                                      | `cd frontend && npm ci && npm run test:integration`（HttpTestingController spec を別パターンで実行）                                          |
| `web-e2e`         | `e2e`         | `mcr.microsoft.com/playwright:v1.45.x-jammy`   | `frontend/node_modules`, `~/.npm`, `~/.cache/ms-playwright` | DinD で `docker compose up -d floci nginx` → `scripts/deploy-local.sh` → `scripts/build-frontend.sh` → `scripts/deploy-frontend.sh` → `scripts/web-e2e.sh` |

`artifacts:reports:junit` を全ジョブで設定し、既存 .NET ジョブと同形にする。

---

## 8. 変更点サマリー（API I/F）

| 項目                          | 修正前               | 修正後                                                  | 理由                              |
| ----------------------------- | -------------------- | ------------------------------------------------------- | --------------------------------- |
| `/todos`, `/todos/{id}` メソッド | POST/GET             | POST/GET + **OPTIONS**                                  | CORS preflight 対応               |
| Lambda レスポンスヘッダ       | `Content-Type` のみ  | `Content-Type` + `Access-Control-Allow-Origin: *` ほか | ブラウザからの直接呼び出し許可    |
| Lambda OPTIONS ハンドラ       | 無し                 | （fallback として）OPTIONS → 204 + CORS                | floci OPTIONS 互換非対応時の予備 |
| Angular 公開 I/F              | 無し                 | `TodoApiService.create/get`, `ConfigService.load`      | 新規追加                          |
| ランタイム設定                | 無し                 | `assets/config.json` (`apiBaseUrl`)                    | invoke_url の環境差吸収           |
