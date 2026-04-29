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

| メソッド | パス          | 状態        | 統合タイプ      | 説明                                  |
| -------- | ------------- | ----------- | --------------- | ------------------------------------- |
| POST     | `/todos`      | 既存・変更なし | AWS_PROXY (Lambda) | Todo 作成                             |
| GET      | `/todos/{id}` | 既存・変更なし | AWS_PROXY (Lambda) | Todo 取得                             |
| OPTIONS  | `/todos`      | **新規追加** | **AWS_PROXY (Lambda)** | CORS preflight（Lambda が 204 を返す） |
| OPTIONS  | `/todos/{id}` | **新規追加** | **AWS_PROXY (Lambda)** | CORS preflight（Lambda が 204 を返す） |

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

成功ステータスは **204 No Content に統一** する（200 は採用しない）。

```http
HTTP/1.1 204 No Content
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type
Access-Control-Max-Age: 600
```

ボディ無し。Lambda 側 `ApiHandler` が `req.HttpMethod == "OPTIONS"` を判定して返す（後述 §2.3）。

---

## 2. CORS 仕様（追加点）

### 2.1 ヘッダ仕様

| ヘッダ                          | 値                       | 適用範囲                              | 設定箇所                                              |
| ------------------------------- | ------------------------ | ------------------------------------- | ----------------------------------------------------- |
| `Access-Control-Allow-Origin`   | `*`                      | 全レスポンス（成功 / エラー / OPTIONS） | Lambda `JsonHeaders`（POST/GET/OPTIONS 全て）         |
| `Access-Control-Allow-Methods`  | `GET, POST, OPTIONS`     | OPTIONS preflight                     | Lambda OPTIONS ハンドラ（preflight 専用ヘッダ）       |
| `Access-Control-Allow-Headers`  | `Content-Type`           | OPTIONS preflight                     | Lambda OPTIONS ハンドラ                               |
| `Access-Control-Max-Age`        | `600`                    | OPTIONS preflight                     | Lambda OPTIONS ハンドラ                               |
| `Access-Control-Expose-Headers` | `Content-Type` (任意)    | 全レスポンス                          | Lambda `JsonHeaders`                                  |

> 認証スコープ外のため `*` を採用。本番化時は限定 Origin に変更（out_of_scope）。

### 2.2 実装方針

- **Lambda 側（標準・唯一の経路）**: `Function.cs` の `JsonHeaders` 共通辞書に CORS ヘッダを追加。`BadRequest` / `NotFound` / 200 / 201 / 500 の全 POST/GET レスポンスで自動的に付与される。
- **API Gateway 側**: Terraform で `/todos`, `/todos/{id}` に `aws_api_gateway_method`（`OPTIONS`, authorization=`NONE`）と `aws_api_gateway_integration`（`type = "AWS_PROXY"` で Lambda へ統合）を追加。**MOCK 統合は採用しない**（floci 互換性の不確実性を回避）。

### 2.3 Lambda OPTIONS ハンドラ（標準）

`ApiHandler` 冒頭で OPTIONS をハンドルし、`204 No Content` + CORS preflight ヘッダを返す。これが本タスクの **唯一の OPTIONS 実装** であり、fallback ではない。

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

### 2.4 API Gateway での CORS ヘッダ透過方針（RD-011 解消）

POST / GET / OPTIONS いずれも `aws_api_gateway_integration.type = "AWS_PROXY"` を使用するため、**Lambda が返したレスポンスヘッダはそのまま透過** される。したがって `aws_api_gateway_method_response.response_parameters` での `Access-Control-Allow-*` ヘッダ宣言は **不要**（依拠経路: AWS_PROXY 透過）。`AWS_PROXY` 透過に依拠する旨を Terraform の該当リソースのコメントに明記する。本タスクでは APIGW MOCK / HTTP_PROXY 統合への切替は行わない（却下案、本書 §2.2 / `01_implementation-approach.md` §2 参照）。

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
export interface Todo {
  id: string;
  title: string;
  description?: string;
  status: 'open' | 'in_progress' | 'done';
  createdAt: string;   // ISO8601 文字列（Lambda JsonOpts: CamelCase）
  updatedAt: string;   // ISO8601 文字列
}
export interface TodoCreateRequest { title: string; description?: string; }
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
| `scripts/build-frontend.sh`      | env: `AWS_ENDPOINT_URL` (必須), `AWS_*` (test 値必須)  | `frontend/dist/` 配下の成果物                 | invoke_url を `assets/config.json` に注入し `ng build` |
| `scripts/deploy-frontend.sh`     | env 同上、引数: `BUCKET=frontend-bucket`               | floci S3 上のオブジェクト                     | `aws s3 sync frontend/dist/ s3://$BUCKET/`                    |
| `scripts/web-e2e.sh`             | env: `WEB_BASE_URL` (必須), `AWS_ENDPOINT_URL` (必須) | `frontend/test-results/` (junit) + Playwright HTML | 上記 2 本 + nginx up + `npx playwright test` を 1 コマンド化  |
| `scripts/verify-readme-sections.sh` (更新) | -                                            | exit 0/1                                      | README に Frontend セクションが存在するか検証                 |

すべて `set -euo pipefail` を使い、必須 env（`AWS_ENDPOINT_URL` / `WEB_BASE_URL` / `API_BASE_URL`）が **未設定** または **空文字** の場合は **`echo "[FATAL] env XXX is required" >&2; exit 1` で fail-fast** する（RD-002 解消、skip 運用は廃止）。

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
    - ./frontend/dist:/usr/share/nginx/html:ro   # 正規経路: build 成果物を host volume mount で配信
```

> nginx の document root は **常に `./frontend/dist` を host volume mount** する（RD-001 正規経路）。S3 sync は配置検証のため別途実行するが、nginx origin にはしない。

---

## 7. GitLab CI ジョブ I/F

すべて Node / Chromium / Playwright のバージョンを **固定タグ** で利用し、CI 再現性を保証する（RD-003 / RD-007 解消）。

| ジョブ            | stage         | image                                                | キャッシュ                                                | 主要コマンド                                                                                                                                  |
| ----------------- | ------------- | ---------------------------------------------------- | --------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `web-lint`        | `lint`        | `node:20.11-bullseye-slim`                           | `frontend/node_modules`, `~/.npm`                         | `apt-get install -y --no-install-recommends git ca-certificates`（必要時） → `cd frontend && npm ci && npm run lint`                          |
| `web-unit`        | `unit`        | `mcr.microsoft.com/playwright:v1.45.3-jammy`         | `frontend/node_modules`, `~/.npm`                         | `cd frontend && npm ci && npm run test:unit -- --watch=false --browsers=ChromeHeadlessCI --reporters=junit,coverage`                          |
| `web-integration` | `integration` | `mcr.microsoft.com/playwright:v1.45.3-jammy`         | 同上                                                      | `cd frontend && npm ci && npm run test:integration -- --watch=false --browsers=ChromeHeadlessCI --reporters=junit,coverage`                   |
| `web-e2e`         | `e2e`         | `mcr.microsoft.com/playwright:v1.45.3-jammy`         | `frontend/node_modules`, `~/.npm`, `~/.cache/ms-playwright` | DinD service。**before_script** で `bash scripts/check-test-env.sh e2e`、**script** は `docker compose up -d floci nginx` → `bash scripts/web-e2e.sh` の **2 行のみ**（`SKIP_ENV_CHECK=1` を export し `web-e2e.sh` 内部の重複チェックを回避 / RP3-002）。`web-e2e.sh` 内で `wait-floci-healthy.sh` → `deploy-local.sh` → `apply-api-deployment.sh` → `warmup-lambdas.sh` → `build-frontend.sh` → `deploy-frontend.sh` → `npx playwright test` の順に内部実行 / RP-008 / RP2-002 / RP2-007 |

> `mcr.microsoft.com/playwright:v1.45.3-jammy` は **Chromium / Firefox / WebKit と必要な OS パッケージ（fonts, libnss3 等）が同梱** されているため、`web-unit` / `web-integration` / `web-e2e` すべてで Karma の `ChromeHeadlessCI` および Playwright が追加インストール無しに動作する。`web-lint` は ESLint / Prettier しか実行しないため軽量な `node:20.11-bullseye-slim` を使用する。

### 7.1 web-e2e の DinD 設定（RD-004 解消）

`web-e2e` ジョブは GitLab Runner の Docker-in-Docker (DinD) を必須とする。`.gitlab-ci.yml` には以下を必ず明記する。

```yaml
web-e2e:
  stage: e2e
  image: mcr.microsoft.com/playwright:v1.45.3-jammy
  services:
    - name: docker:25.0.3-dind
      alias: docker
      command: ["--tls=false"]
  variables:
    DOCKER_HOST: "tcp://docker:2375"
    DOCKER_TLS_CERTDIR: ""        # TLS を無効化（CI のみ。実 AWS は使わない前提）
    FF_NETWORK_PER_BUILD: "true"  # service コンテナと job コンテナを同一 user-defined network に配置
    WEB_BASE_URL: "http://docker:8080"   # nginx は DinD 上で 8080 公開、job からは alias `docker` で到達
    AWS_ENDPOINT_URL: "http://docker:4566"
    AWS_ACCESS_KEY_ID: "test"
    AWS_SECRET_ACCESS_KEY: "test"
    AWS_DEFAULT_REGION: "us-east-1"
    SKIP_ENV_CHECK: "1"           # RP3-002: before_script で check-test-env.sh e2e 済みのため web-e2e.sh 内部の重複チェックを抑止
  before_script:
    - apt-get update && apt-get install -y --no-install-recommends docker.io docker-compose-plugin awscli unzip curl gnupg ca-certificates
    # RP2-001: Terraform 1.6.6 を固定インストール（check-test-env.sh e2e が要求）
    - curl -fsSL -o /tmp/tf.zip https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
    - unzip -o /tmp/tf.zip -d /usr/local/bin && terraform -version | head -1 | grep -q '1.6.6'
    # RP2-001: .NET SDK 8.0 を固定インストール（check-test-env.sh e2e が要求）
    - curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -o /tmp/ms.deb
    - dpkg -i /tmp/ms.deb && apt-get update && apt-get install -y --no-install-recommends dotnet-sdk-8.0
    - dotnet --list-sdks | grep -q '^8\.'
    - docker info   # DinD 接続確認（失敗時 fail-fast）
    - bash scripts/check-test-env.sh e2e   # node/docker/aws/terraform/dotnet readiness を fail-fast 検証
  script:
    # RP2-002 / RP3-002: web-e2e.sh が唯一のエントリポイント。compose up と web-e2e.sh の 2 行のみ。
    # check-test-env.sh は before_script 側で 1 回だけ呼ぶ。SKIP_ENV_CHECK=1 で web-e2e.sh 内部の重複呼び出しを回避。
    - docker compose -f compose/docker-compose.yml up -d floci nginx
    - bash scripts/web-e2e.sh
    # web-e2e.sh は内部で wait-floci-healthy.sh → deploy-local.sh → apply-api-deployment.sh
    #   → warmup-lambdas.sh → build-frontend.sh → deploy-frontend.sh → npx playwright test
    #   の順に実行する（RP-008 / RP2-007）。CI 側からこれらを直接呼ばないこと（二重実行禁止）。
  after_script:
    - docker compose -f compose/docker-compose.yml down -v || true
  artifacts:
    when: always
    paths: [frontend/test-results/, frontend/playwright-report/]
    reports:
      junit: frontend/test-results/junit.xml
```

ポイント:

- `docker:25.0.3-dind` を service として起動し、`alias: docker` で job コンテナから `tcp://docker:2375` 到達を保証する。
- `DOCKER_TLS_CERTDIR: ""` で TLS を無効化（DinD 側 `--tls=false` と一致させる）。
- `FF_NETWORK_PER_BUILD: "true"` を有効化し、`docker compose` が起動する `floci-net` と service コンテナが **同一 user-defined network** に乗ることを保証する。これにより job コンテナから nginx の `docker:8080` / floci の `docker:4566` が解決可能になる。
- nginx の `8080` は `compose/docker-compose.yml` で `ports: ["8080:8080"]` 公開済み。Playwright は `WEB_BASE_URL=http://docker:8080` で起動し、ジョブ内から DinD 越しに到達する。
- 必須 env (`WEB_BASE_URL`, `AWS_ENDPOINT_URL`) が空の場合 `scripts/web-e2e.sh` が exit 1（RD-002）。
- **(RP2-001)** Playwright image には terraform / dotnet が同梱されないため、`before_script` で **Terraform 1.6.6 と .NET SDK 8.0 を固定インストール**する。これにより `check-test-env.sh e2e` プロファイル（node/docker/aws/terraform/dotnet を要求）が CI 上で成立する。
- **(RP2-002 / RP2-007 / RP3-002)** `script:` は `compose up` と `web-e2e.sh` の **2 行のみ**。`check-test-env.sh` は `before_script` でだけ呼び、`script` 内部の `SKIP_ENV_CHECK=1` で `web-e2e.sh` 内部の重複チェックを抑止する（CI では 1 回のみ readiness 検査を行う）。`wait-floci-healthy.sh` / `deploy-local.sh` / `apply-api-deployment.sh` / `warmup-lambdas.sh` / `build-frontend.sh` / `deploy-frontend.sh` は **`web-e2e.sh` 内部に集約**して二重実行を排除する（task07 / task10 と同順序）。

`artifacts:reports:junit` を全ジョブで設定し、既存 .NET ジョブと同形にする。

---

## 8. 変更点サマリー（API I/F）

| 項目                          | 修正前               | 修正後                                                  | 理由                              |
| ----------------------------- | -------------------- | ------------------------------------------------------- | --------------------------------- |
| `/todos`, `/todos/{id}` メソッド | POST/GET             | POST/GET + **OPTIONS**                                  | CORS preflight 対応               |
| Lambda レスポンスヘッダ       | `Content-Type` のみ  | `Content-Type` + `Access-Control-Allow-Origin: *` ほか | ブラウザからの直接呼び出し許可    |
| Lambda OPTIONS ハンドラ       | 無し                 | （標準）OPTIONS → 204 + CORS（AWS_PROXY 統合）         | floci 互換性確保 / MOCK 不採用     |
| Angular 公開 I/F              | 無し                 | `TodoApiService.create/get`, `ConfigService.load`      | 新規追加                          |
| ランタイム設定                | 無し                 | `assets/config.json` (`apiBaseUrl`)                    | invoke_url の環境差吸収           |
