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

#### 配信パイプラインの正規経路（RD-001 解消）

ローカル / CI 双方で次の **唯一の正規経路** を採る。代替案は本書 §2 で却下する。

1. `ng build` で `frontend/dist/` を生成
2. `aws s3 sync frontend/dist/ s3://frontend-bucket/`（floci S3 への配置。本番 S3 + CloudFront 相当の論理整合と `scripts/deploy-frontend.sh` の経路検証を兼ねる）
3. **同じ `frontend/dist/` を nginx の document root にホストボリュームマウント** (`./frontend/dist:/usr/share/nginx/html:ro`) してブラウザに配信
4. nginx は **静的配信専用**。`/` への `try_files $uri /index.html;` のみ。`proxy_pass` 等の **API リバースプロキシは設けない**

**CloudFront 相当**は nginx の静的配信のみで代替する（floci に CloudFront 互換実装が無いため、本タスクでは CloudFront 機能は実装しない）。
**S3 を nginx origin にする案 / nginx 撤去案 / S3 静的ホスティング URL 直接利用案は本タスクでは却下** する（floci S3 静的ホスティング互換が不確実、かつブレスト決定『nginx 静的配信』に反するため）。S3 sync は配置検証のために必ず実行するが、ブラウザが取得する成果物は **常に nginx 経由** とする。

テストは Angular 標準の **Karma + Jasmine** を単体/結合に、
**Playwright** を E2E に採用。GitLab CI の既存 stage（lint/unit/integration/e2e）に
`web-lint / web-unit / web-integration / web-e2e` を追加し、
npm と Playwright browsers をキャッシュする。

### 1.2 技術選定

| 技術/ツール                             | 選定理由                                                                                                   | 備考                                                       |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| Angular 18.2.x (LTS)                    | ブレスト決定。LTS で長期安定。standalone components が成熟                                                 | `frontend/package.json` で `~18.2.0` ピン                  |
| Node.js 20.11.x (LTS)                   | Angular 18 の engines (>=18.19 / >=20.11) を満たす LTS。`engines.node` を `^20.11.0` に固定               | devcontainer / CI image で `node:20.11-bullseye-slim` 固定 |
| Karma 6.4.x + Jasmine 5.x               | Angular CLI 既定。`ng test` で unit / integration（HttpTestingController）を別 karma config で実行         | Jest 移行は本タスク out_of_scope                           |
| @playwright/test 1.45.3                 | ブラウザ E2E 標準。`mcr.microsoft.com/playwright:v1.45.3-jammy` 固定タグで CI 再現性確保                  | CI は Chromium 単一に限定（キャッシュ肥大回避）            |
| nginx 1.27-alpine                       | 軽量・SPA fallback (`try_files`) 設定が容易。compose に sidecar として追加                                 | API リバースプロキシは行わない                             |
| floci S3                                | `aws s3 sync` で静的成果物を配置できるエンドポイント                                                       | `compose/docker-compose.yml` の `SERVICES` に `s3` を追加  |
| API Gateway OPTIONS (Terraform, AWS_PROXY → Lambda) | CORS preflight に対応。**floci の APIGW MOCK 統合互換性が不確実**なため、本設計では Lambda OPTIONS を **標準** とし、成功ステータスを **204 No Content** に統一 | MOCK 統合は本タスクでは採用しない                           |
| `Function.cs` の `JsonHeaders` 拡張     | 既存共通辞書を CORS 対応版に統一更新することで全レスポンスに CORS ヘッダを付与                             | 既存 Unit テストの期待値を TDD で先に更新                  |
| `assets/config.json` ランタイム設定     | terraform output の invoke_url を CI/ローカルで切り替え可能にするため                                      | ビルド時に shell で生成、ブラウザは APP_INITIALIZER で fetch |
| GitLab CI `.node` テンプレート          | 既存 `.dotnet` テンプレートと同形にし、フロント追加の `extends` を最小化                                   | キャッシュキーは `frontend/package-lock.json` baseline     |

---

## 2. 代替案の比較

| 案 | 概要                                                                                                  | メリット                                                              | デメリット                                                                 | 採用 |
| -- | ----------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- | -------------------------------------------------------------------------- | ---- |
| 案1 | **Angular + nginx 静的配信（host volume mount）+ floci S3 sync + ブラウザ直呼び（CORS 追加）** ← 本案 | nginx 設定が単純（`try_files` のみ）。実環境（CloudFront + API GW）と論理構造が一致。S3 配置経路も検証可 | API Gateway / Lambda 側 CORS 実装と OPTIONS 互換確認が必要                 | ✅   |
| 案2 | Angular + nginx をリバースプロキシ化し API 経由（same-origin）                                        | CORS 不要。ブラウザ側はシンプル                                       | nginx 設定肥大。ブレスト決定（API は nginx 経由しない）に反する            | ❌   |
| 案3 | Angular を `ng serve` で開発しつつ E2E は本格 Web サーバー無し                                        | セットアップ最小                                                      | 「S3+CloudFront 相当配信」の acceptance_criteria を満たせない              | ❌   |
| 案4 | React/Vue 採用                                                                                        | チームの慣れ次第                                                      | ブレスト決定（Angular 18 LTS）に反する。`ng test/lint` 一式の恩恵を失う    | ❌   |
| 案5 | nginx を撤去し floci S3 静的ホスティング URL を直接利用                                                | コンテナ 1 個削減                                                     | floci S3 の静的ホスティング互換性が不確実。ブレスト決定『nginx 静的配信』に反する。**却下** | ❌   |
| 案6 | nginx を撤去し S3 オブジェクトを別経路で配信                                                          | -                                                                     | ブレスト決定に反するため検討対象外。**却下**                               | ❌   |

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
| R1       | floci の API Gateway OPTIONS / MOCK 互換性          | **MOCK 統合は採用せず、Lambda OPTIONS（AWS_PROXY 統合）を標準化** する。`Function.cs` の `ApiHandler` 冒頭で `req.HttpMethod == "OPTIONS"` のとき `204 No Content + CORS preflight ヘッダ` を返す（`02_interface-api-design.md` §2.3）。Terraform は `/todos`, `/todos/{id}` の OPTIONS を AWS_PROXY → Lambda で 1 経路に統一。 |
| R2       | floci S3 の静的ホスティング互換性                   | 配信は **nginx host volume mount による静的配信に一意化**。S3 は「ビルド成果物の配置検証先」として `aws s3 sync` のみ実行し、ブラウザ origin にしない（`04_process-flow-design.md` §3）。fallback / 代替経路は設けない。 |
| R3       | CORS preflight 不足                                 | Lambda の全レスポンス（POST/GET/OPTIONS）で `JsonHeaders` 経由で CORS ヘッダを付与。AWS_PROXY 統合の **レスポンスヘッダ透過** に依拠する（`02_interface-api-design.md` §2.4）。Playwright E2E に「CORS 成立アサート」テストを必須ケースとして含める（`05_test-plan.md` §2.3 E2E-3）。 |
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
