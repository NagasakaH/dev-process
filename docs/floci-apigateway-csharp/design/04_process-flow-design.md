# 処理フロー設計

## 概要

| 項目       | 内容                                                  |
| ---------- | ----------------------------------------------------- |
| チケットID | FRONTEND-001                                          |
| タスク名   | floci-apigateway-csharp に Angular フロントエンド追加 |
| 作成日     | 2026-04-29                                            |

本書では「Todo 作成/取得のユーザフロー」「ローカル/CI E2E パイプライン」「エラー / 非常時フロー」を、**修正前後を対比**する形で示す。

---

## 1. ユーザフロー: Todo 作成

### 1.1 修正前シーケンス（フロントエンド無し）

```mermaid
sequenceDiagram
    autonumber
    participant CLI as curl / E2ETests (.NET)
    participant G as floci API Gateway :4566
    participant L as TodoApi.Lambda
    participant D as DynamoDB

    Note over CLI,D: 【修正前】CLI / .NET E2E のみが API を叩ける

    CLI->>G: POST /todos { "title": "milk" }
    G->>L: invoke ApiHandler
    L->>D: PutItem
    D-->>L: ok
    L-->>G: 201 + Todo (Content-Type のみ)
    G-->>CLI: 201
```

### 1.2 修正後シーケンス（ブラウザ → API Gateway 直呼び）

```mermaid
sequenceDiagram
    autonumber
    participant U as User (Browser)
    participant N as nginx :8080 (静的配信)
    participant A as Angular SPA
    participant G as floci API Gateway :4566
    participant L as TodoApi.Lambda
    participant D as DynamoDB

    Note over U,D: 【修正後】ブラウザから直接 invoke_url を呼ぶ + CORS 必須

    U->>N: GET /
    N-->>U: index.html + bundles
    U->>A: ページ表示
    A->>N: GET /assets/config.json
    N-->>A: { apiBaseUrl: "<invoke_url>" }
    Note over A,G: Origin (http://localhost:8080) ≠ API Origin → CORS 必須

    U->>A: title 入力 → 送信
    A->>G: OPTIONS /todos<br/>Origin: http://localhost:8080
    G-->>A: 204 + Access-Control-Allow-Origin: *<br/>Allow-Methods/Headers/Max-Age
    A->>G: POST /todos { "title": "milk" }
    G->>L: invoke ApiHandler
    L->>D: PutItem
    D-->>L: ok
    L-->>G: 201 + Todo + CORS ヘッダ
    G-->>A: 201 + Todo
    A-->>U: 作成 Todo を表示
```

### 1.3 変更点サマリー（ユーザフロー）

| 項目              | 修正前               | 修正後                                          | 理由                          |
| ----------------- | -------------------- | ----------------------------------------------- | ----------------------------- |
| 呼び出し主体      | CLI / .NET E2E       | ブラウザ (Angular SPA)                          | UI 層追加                     |
| 配信レイヤー      | 無し                 | nginx 静的配信 (CloudFront 相当)                | UI のホスティング             |
| CORS preflight    | 無し                 | OPTIONS /todos, /todos/{id} を発行              | クロスオリジン HTTP のため    |
| Lambda 応答ヘッダ | Content-Type のみ    | + Access-Control-Allow-Origin 等                | ブラウザ受理                  |
| invoke_url 解決   | env / .NET 設定      | runtime fetch `assets/config.json`              | CI / ローカルで動的化         |

---

## 2. ユーザフロー: Todo 取得（GET /todos/{id}）

### 2.1 修正後シーケンス

```mermaid
sequenceDiagram
    autonumber
    participant U as User (Browser)
    participant A as Angular SPA
    participant G as API Gateway
    participant L as Lambda
    participant D as DynamoDB

    U->>A: ID 入力 → 取得
    A->>G: OPTIONS /todos/{id}（初回 / cache miss 時）
    G-->>A: 204 + CORS
    A->>G: GET /todos/{id}
    G->>L: invoke
    L->>D: GetItem
    alt 見つかった
      D-->>L: Item
      L-->>G: 200 + Todo + CORS
      G-->>A: 200
      A-->>U: 表示
    else 見つからない
      D-->>L: null
      L-->>G: 404 { error: "..." } + CORS
      G-->>A: 404
      A-->>U: "Todo が見つかりません" を表示
    end
```

> POST 時に取得した preflight キャッシュ（`Access-Control-Max-Age: 600`）が GET にも適用されるため、UI 操作中は OPTIONS が頻発しない。

---

## 3. デプロイ / E2E パイプライン

### 3.1 修正前パイプライン

```mermaid
sequenceDiagram
    autonumber
    participant Dev as Dev/CI
    participant DC as docker compose
    participant FL as floci
    participant TF as terraform
    participant ETN as .NET E2ETests

    Dev->>DC: up -d (floci のみ)
    DC->>FL: start
    Dev->>TF: lambda package + apply
    TF->>FL: APIGW/Lambda/SFN/DDB 作成
    Dev->>TF: output -raw invoke_url
    TF-->>Dev: invoke_url
    Dev->>ETN: dotnet test (E2E) — API_BASE_URL 経由
```

### 3.2 修正後パイプライン（フロント追加）

```mermaid
sequenceDiagram
    autonumber
    participant Dev as Dev/CI runner
    participant DC as docker compose
    participant FL as floci :4566 (S3 含む)
    participant TF as terraform
    participant NG as Angular CLI
    participant S3 as floci S3
    participant NX as nginx :8080
    participant ETN as .NET E2ETests
    participant PW as Playwright

    Dev->>DC: up -d (floci + nginx)
    DC->>FL: start (services + s3)
    DC->>NX: start (待機: dist 未配置でも起動可)
    Dev->>FL: healthcheck OK
    Dev->>TF: lambda package + apply (APIGW + OPTIONS + S3 bucket 作成)
    Dev->>TF: output -raw invoke_url
    TF-->>Dev: invoke_url

    Note over Dev,NG: フロント側
    Dev->>NG: build-frontend.sh<br/>(invoke_url を assets/config.json に注入 → ng build)
    NG-->>Dev: frontend/dist/
    Dev->>S3: deploy-frontend.sh (aws s3 sync dist/ s3://frontend-bucket/)
    Note over Dev,S3: S3 sync は配置検証用。ブラウザ origin にはしない（RD-001 正規経路）
    Dev->>NX: 同じ frontend/dist を host volume mount で配信（compose 起動時にマウント済み）

    Note over Dev,ETN: 既存 .NET E2E は非破壊で並走可能
    Dev->>ETN: dotnet test (既存 E2E)

    Note over Dev,PW: フロント E2E
    Dev->>PW: scripts/web-e2e.sh → npx playwright test
    PW->>NX: GET / (UI 表示確認)
    PW->>FL: ブラウザコンテキストで OPTIONS + POST/GET /todos
    PW-->>Dev: junit + HTML レポート
    Dev->>DC: down -v (after_script)
```

### 3.3 配信経路の一意性（RD-001 解消）

配信経路は **ng build → frontend/dist → (S3 sync 検証) + nginx host volume mount → ブラウザ** の **唯一経路** に固定する。S3 互換不足時の nginx 撤去 / S3 直接配信などの fallback 分岐は本タスクでは設けない。

```mermaid
flowchart LR
    NG[ng build] --> DIST[frontend/dist/]
    DIST -->|aws s3 sync (配置検証)| S3[(floci S3: frontend-bucket)]
    DIST -->|host volume mount<br/>:ro| NX[nginx :8080]
    NX -->|GET /| BR[Browser]
```

---

## 4. エラーフロー

### 4.1 CORS preflight 失敗

```mermaid
sequenceDiagram
    participant A as Angular
    participant G as API Gateway
    A->>G: OPTIONS /todos
    G-->>A: 4xx / CORS ヘッダ欠落
    Note over A: ブラウザが「CORS error」と判定
    A-->>A: HttpClient: status=0
    A-->>U: "API に接続できませんでした" を表示
    A-->>console: console.error(err)
```

CI（Playwright）では `E2E-3 CORS 成立アサート` で fail-fast する（`05_test-plan.md` §2.3 参照）。

### 4.2 サーバ 5xx

```mermaid
sequenceDiagram
    A->>G: POST /todos
    G->>L: invoke
    L-->>G: 500 { error: "internal error" } + CORS
    G-->>A: 500
    A-->>U: "サーバエラーが発生しました" 表示
```

### 4.3 設定ロード失敗

```mermaid
sequenceDiagram
    participant A as Angular
    participant N as nginx
    A->>N: GET /assets/config.json
    N-->>A: 404
    Note over A: APP_INITIALIZER reject
    A-->>U: 「設定読み込みエラー」全画面表示
```

`apiBaseUrl` が空・スキーム不正でも同様に reject（fail-fast）。

### 4.4 必須 env 未設定（fail-fast 統一、RD-002 解消）

`AWS_ENDPOINT_URL` / `WEB_BASE_URL` / `API_BASE_URL` が未設定または空文字の場合、shell スクリプトと Playwright `globalSetup` の **両方で fail-fast** する。skip 運用は廃止する。

```mermaid
flowchart LR
    SH[scripts/*.sh] -->|env 未設定/空| EXIT1[echo FATAL >&2; exit 1]
    GS[playwright globalSetup] -->|baseURL/AWS_ENDPOINT_URL 未設定/空| THROW[throw new Error<br/>→ Playwright run abort]
    NG[ng build] -->|config.json apiBaseUrl 空| FAIL2[ConfigService.load reject<br/>→ ビルドは成功するがアプリ起動時に fail-fast]
```

判定ルール:

| 経路                          | 判定                                                  | 失敗時の挙動                          |
| ----------------------------- | ----------------------------------------------------- | ------------------------------------- |
| `scripts/build-frontend.sh`   | `: "${AWS_ENDPOINT_URL:?env required}"` 等で参照      | `set -u` + `${VAR:?}` で exit 1       |
| `scripts/web-e2e.sh`          | `WEB_BASE_URL` / `AWS_ENDPOINT_URL` 必須              | exit 1                                |
| `playwright.config.ts` `globalSetup` | `if (!process.env.WEB_BASE_URL) throw new Error(...)` | Playwright run abort（skip しない）   |
| `playwright.config.ts` `use.baseURL` | `process.env.WEB_BASE_URL` を直接参照（fallback 値を持たない） | 未設定なら globalSetup で abort       |

これにより実 AWS への到達と「skip による品質ゲートのバイパス」を構造的に防ぐ（DR-001）。

---

## 5. 状態遷移（Angular UI）

```mermaid
stateDiagram-v2
    [*] --> Loading
    Loading --> Ready: config.json 取得成功
    Loading --> ConfigError: 取得失敗 / 不正
    Ready --> Submitting: 送信ボタン
    Submitting --> Ready: 201 表示
    Submitting --> ApiError4xx: 4xx (errors[0] 表示)
    Submitting --> ApiError5xx: 5xx (固定文言)
    Submitting --> NetworkError: status=0 (CORS / ネット)
    ApiError4xx --> Ready: 入力修正
    ApiError5xx --> Ready: 再試行
    NetworkError --> Ready: 再試行
    ConfigError --> [*]
```

---

## 6. 非同期処理 / 並列性

- Angular `HttpClient` は Observable ベース。`take(1)` または `firstValueFrom` で完了を待つ。
- Playwright のテストは `playwright.config.ts` の `workers: 1` で逐次実行（CI リソース節約 + floci 競合回避）。
- 既存 Step Functions（ValidateTodo → PersistTodo）は本タスクで変更なし。

---

## 7. 変更点サマリー（処理フロー全体）

| フェーズ           | 修正前                      | 修正後                                                              |
| ------------------ | --------------------------- | ------------------------------------------------------------------- |
| ユーザ操作         | CLI                         | Browser (Angular SPA via nginx)                                     |
| Preflight          | 無し                        | OPTIONS /todos, /todos/{id}                                         |
| 設定解決           | env / .NET 設定             | runtime `assets/config.json`                                        |
| デプロイ           | terraform apply             | + ng build + aws s3 sync + nginx 反映                               |
| E2E                | .NET xUnit (1 系統)         | .NET xUnit (既存) + Playwright (新規・並走可)                        |
| エラー UI          | 無し                        | UI 上に 4xx/5xx/CORS/設定ロード失敗を分けて表示                     |
| ロールバック       | feature ブランチ破棄        | + `frontend/`, compose/nginx, infra OPTIONS+S3, web-* ジョブ revert |
