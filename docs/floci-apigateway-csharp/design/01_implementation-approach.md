# 実装方針

## 概要

| 項目       | 内容                                                         |
| ---------- | ------------------------------------------------------------ |
| チケットID | FRONTEND-001                                                 |
| タスク名   | floci-apigateway-csharp に Angular フロントエンド追加        |
| 作成日     | 2026-04-29                                                   |
| 対象リポジトリ | floci-apigateway-csharp                                  |
| 設計範囲   | `frontend/`, `compose/`, `infra/`, `src/TodoApi.Lambda`, `scripts/`, `.gitlab-ci.yml`, `README.md` |

---

## 1. 選定したアプローチ

### 1.1 実装方針

既存の .NET 8 Lambda + floci(LocalStack) + Terraform バックエンドに対し、
**`frontend/` 配下に Angular 18 LTS の SPA を新規追加**し、
**ブラウザから既存 floci API Gateway invoke_url を直接 HTTP 呼び出し**する。
配信は **nginx sidecar による静的ファイル配信のみ** とし、
**API のリバースプロキシは行わない**。
ブラウザ直呼びとなるため、API Gateway / Lambda 側に **CORS 対応** を追加する。

floci の S3 を「フロント成果物の配置先」として有効化し、
ローカル/CI で `aws s3 sync dist/ s3://frontend-bucket/` → nginx 配信、
というローカル CloudFront 相当パイプラインを構築する。
**floci に CloudFront 相当の実装は確認できないため、本タスクでは CloudFront 相当機能を実装しない**（nginx で代替）。

テストは Angular 標準の **Karma + Jasmine** を単体/結合に、
**Playwright** を E2E に採用。GitLab CI の既存 stage（lint/unit/integration/e2e）に
`web-lint / web-unit / web-integration / web-e2e` を追加し、
npm と Playwright browsers をキャッシュする。

### 1.2 技術選定

| 技術/ツール                             | 選定理由                                                                                                   | 備考                                                       |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| Angular 18 LTS                          | ブレスト決定。LTS で長期安定。standalone components が成熟                                                 | `frontend/` 配下に閉じる                                   |
| Node.js 20 LTS                          | Angular 18 の engines (>=18.19 / >=20.11) を満たす LTS                                                     | devcontainer / CI image で固定                             |
| Karma + Jasmine                         | Angular CLI 既定。`ng test` で単体/結合（HttpTestingController）統一可                                     | Jest 移行は本タスク out_of_scope                           |
| @playwright/test 1.45+                  | ブラウザ E2E 標準。`mcr.microsoft.com/playwright` イメージで CI 再現性確保                                 | CI は Chromium 単一に限定（キャッシュ肥大回避）            |
| nginx 1.27-alpine                       | 軽量・SPA fallback (`try_files`) 設定が容易。compose に sidecar として追加                                 | API リバースプロキシは行わない                             |
| floci S3                                | `aws s3 sync` で静的成果物を配置できるエンドポイント                                                       | `compose/docker-compose.yml` の `SERVICES` に `s3` を追加  |
| API Gateway OPTIONS (Terraform)         | CORS preflight に対応。MOCK 統合で軽量に実装                                                               | floci 互換性に懸念ありのため Lambda fallback も併記        |
| `Function.cs` の `JsonHeaders` 拡張     | 既存共通辞書を CORS 対応版に統一更新することで全レスポンスに CORS ヘッダを付与                             | 既存 Unit テストの期待値を TDD で先に更新                  |
| `assets/config.json` ランタイム設定     | terraform output の invoke_url を CI/ローカルで切り替え可能にするため                                      | ビルド時に shell で生成、ブラウザは APP_INITIALIZER で fetch |
| GitLab CI `.node` テンプレート          | 既存 `.dotnet` テンプレートと同形にし、フロント追加の `extends` を最小化                                   | キャッシュキーは `frontend/package-lock.json` baseline     |

---

## 2. 代替案の比較

| 案 | 概要                                                                                                  | メリット                                                              | デメリット                                                                 | 採用 |
| -- | ----------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- | -------------------------------------------------------------------------- | ---- |
| 案1 | **Angular + nginx 静的配信 + ブラウザ直呼び（CORS 追加）** ← 本案                                     | nginx 設定が単純（`try_files` のみ）。実環境（CloudFront + API GW）と論理構造が一致 | API Gateway / Lambda 側 CORS 実装と OPTIONS 互換確認が必要                 | ✅   |
| 案2 | Angular + nginx をリバースプロキシ化し API 経由（same-origin）                                        | CORS 不要。ブラウザ側はシンプル                                       | nginx 設定肥大。ブレスト決定（API は nginx 経由しない）に反する            | ❌   |
| 案3 | Angular を `ng serve` で開発しつつ E2E は本格 Web サーバー無し                                        | セットアップ最小                                                      | 「S3+CloudFront 相当配信」の acceptance_criteria を満たせない              | ❌   |
| 案4 | React/Vue 採用                                                                                        | チームの慣れ次第                                                      | ブレスト決定（Angular 18 LTS）に反する。`ng test/lint` 一式の恩恵を失う    | ❌   |

---

## 3. 採用理由

- **ブレスト決定事項を全て満たす**: Angular 18 LTS / nginx 静的配信のみ / API 直呼び / CORS 追加 / Karma+Jasmine + Playwright / GitLab CI の `web-*` ジョブ追加。
- **本番想定構成（S3+CloudFront+API Gateway）と論理一致**: ローカル/CI で同形のため、将来本番デプロイ時の差分が「CloudFront 設定追加と CORS Origin の限定」程度で済む。
- **既存資産の非破壊**: `frontend/` 配下に閉じ、既存 `.NET` ビルド・テスト・CI ジョブには干渉しない。CORS 対応のみ既存 `JsonHeaders` を更新するが、TDD で既存テストを先に拡張するため安全。
- **リスクへの備え**: floci の OPTIONS / S3 / CORS 互換に懸念があるため、本書 §4 と `06_side-effect-verification.md` に **Lambda OPTIONS fallback** と **nginx ボリュームマウント fallback** を予備案として明記する。

---

## 4. リスク軽減策（調査リスクとの対応）

調査 `06_risks-and-constraints.md` で特定されたリスクへの設計上の手当て：

| リスクID | リスク                                              | 設計上の軽減策                                                                                                                                                                                  |
| -------- | --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| R1       | floci の API Gateway OPTIONS / MOCK 互換性          | 一次案として Terraform で OPTIONS + MOCK 統合を実装。実装フェーズで Playwright が CORS 失敗を検知した場合に備え、**Lambda 側で `OPTIONS` を 204 で返す fallback ハンドラ** を `Function.cs` に併設可能な構造で設計（`02_interface-api-design.md` §3）。 |
| R2       | floci S3 の静的ホスティング互換性                   | 配信は nginx に閉じる設計とし、S3 は「ビルド成果物の置き場」用途のみに限定。`compose` に **`./frontend/dist:/usr/share/nginx/html:ro` のボリュームマウント fallback** を併記（`04_process-flow-design.md` §3）。 |
| R3       | CORS preflight 不足                                 | Lambda の全レスポンス + APIGW OPTIONS 統合の **両方** で CORS ヘッダ付与。Playwright E2E に「CORS 成立アサート」テストを必須ケースとして含める（`05_test-plan.md` §2.3 E2E-3）。                |
| R4       | E2E 所要時間増                                      | npm / Playwright / docker layer の 3 系統キャッシュを `.gitlab-ci.yml` に明示。Chromium 単一ブラウザに限定。`web-e2e` のみ `e2e` stage に集約し並列度を抑制                                     |
| R5       | Angular 18 ↔ Node 非整合                            | `frontend/package.json` の `engines` と CI image の Node バージョンを 20 LTS に固定                                                                                                              |
| R6       | Playwright キャッシュ肥大                           | `playwright install --with-deps chromium` のみ実行                                                                                                                                              |
| R7       | `dotnet format --verify-no-changes` 誤検知          | `frontend/**` を `.editorconfig` の `[frontend/**]` セクションで Angular 標準に切替、または `dotnet format` の include を `src/**;tests/**` に限定                                               |
| R8       | `JsonHeaders` 変更による既存 Unit テスト破壊        | TDD で `ApiHandlerRoutingTests` 等の期待値を先に更新するタスクを `plan` 側に明示。CORS ヘッダ追加は単一辞書更新で局所化                                                                          |

---

## 5. 設計上の制約・前提

| 制約                                  | 対応方針                                                                       |
| ------------------------------------- | ------------------------------------------------------------------------------ |
| 実 AWS 接続禁止 (DR-001)              | `assets/config.json` には floci 内 URL のみを書き込む。`AWS_*=test` を維持     |
| nginx は静的配信のみ                  | `nginx.conf` は `try_files $uri /index.html;` のみ。`proxy_pass` は使わない    |
| Angular 18 LTS 固定                   | `package.json` で `^18.0.0` ピン                                               |
| 既存 `.NET` CI ジョブ非破壊           | フロント追加は **新ジョブ追加のみ**。既存ジョブの YAML 変更は最小化            |
| CloudFront 相当機能は実装しない       | floci 未対応のため。本番化は out_of_scope                                      |
| `frontend/` 配下に閉じる              | リポジトリ root に余計なファイルを置かない（`Makefile` 拡張等は最小限）        |

---

## 6. 影響を受ける既存ファイル（修正点まとめ）

| ファイル                                | 修正内容                                                                                       |
| --------------------------------------- | ---------------------------------------------------------------------------------------------- |
| `src/TodoApi.Lambda/Function.cs`        | `JsonHeaders` に `Access-Control-Allow-*` を追加（または専用ヘルパで一元化）                   |
| `infra/main.tf` (or 新規 `frontend.tf`) | `/todos`, `/todos/{id}` に `OPTIONS` メソッド + MOCK 統合 + S3 bucket（フロント配信用）追加    |
| `infra/outputs.tf`                      | `frontend_bucket`, `frontend_url`（nginx ベース URL の組み立てヒント）を追加                   |
| `compose/docker-compose.yml`            | `SERVICES` に `s3` 追加、`nginx` サービス追加（floci-net 参加、port 8080）                     |
| `.gitlab-ci.yml`                        | `.node` テンプレート + `web-lint / web-unit / web-integration / web-e2e` ジョブ追加            |
| `scripts/deploy-local.sh`               | 末尾で（任意）`build-frontend.sh` + `deploy-frontend.sh` を呼ぶか、別スクリプトで完結          |
| `scripts/verify-readme-sections.sh`     | README に追加する Frontend セクションを検証対象に追記                                           |
| `README.md`                             | Frontend セクション（ローカル起動 / テスト / CI 実行手順）を追記                               |

---

## 7. 完了の定義

- 6 設計ドキュメント（本書含む）が `docs/floci-apigateway-csharp/design/` に揃う
- ブレスト決定事項・調査結果のリスク軽減策が全て本設計群に反映されている
- `acceptance_criteria` 全項目に対し、検証手段（単体/結合/E2E）が `05_test-plan.md` で対応付けされている
- 既存 .NET の lint/unit/integration/e2e に対する非破壊性が `06_side-effect-verification.md` に明記されている
