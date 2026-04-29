# FRONTEND-001 Round 4 検証レポート

- 対象: `submodules/editable/floci-apigateway-csharp`
- ブランチ: `feature/FRONTEND-001`
- 実行日時 (UTC): 2026-04-29T17:04Z – 17:24Z
- 前回 (Round 3) からの変更点: NEW-1 (floci 1.5.9 OPTIONS 制約) 調査 + HTTP REDテスト + ドキュメント追加。
  Lambda/IaC は設計 (RD-006 / RD-011) 通りで本番 AWS 想定では正常動作する見込み。

## 結果サマリー

| 項目 | 結果 |
| --- | --- |
| Frontend lint | ✅ PASS |
| Frontend typecheck (`tsc --noEmit`) | ✅ PASS |
| Frontend build (`ng build --configuration=production`) | ✅ PASS (Initial 215.36 kB) |
| Frontend unit (Karma + cov ガード) | ✅ 32/32 PASS, 100/94.28/100/100 |
| Frontend integration (Karma + cov ガード) | ✅ 17/17 PASS, 98.63/80/100/98.27 |
| .NET build (sln) | ✅ 0 warning / 0 error |
| .NET unit | ✅ 34/34 PASS |
| .NET integration (floci 起動下) | ✅ 12/12 PASS (`SkipIfNoFloci` を全て満たして実行) |
| Terraform infra plan assertion | ✅ PASS (7/7 expected resources, AWS_PROXY 統合確認) |
| CORS preflight HTTP REDテスト (NEW-1) | ❌ 既知 RED (floci 1.5.9 制約。本番 AWS では GREEN 想定) |
| README verify (`verify-readme-content.sh` + `verify-readme-sections.sh`) | ✅ PASS |
| Compose config (`docker compose config`) | ✅ PASS |
| nginx Dockerfile build | ✅ PASS |
| Playwright E2E (`scripts/web-e2e.sh`) | ❌ 3 passed / 2 failed / 1 skipped (NEW-1 起因) |

## 受け入れ基準照合

| AC | 検証手段 | 結果 | 根拠 |
| --- | --- | --- | --- |
| AC1 ローカル Angular + floci API で Todo CRUD | e2e (E2E-1) | FAIL | E2E-1 fail (NEW-1: OPTIONS preflight が floci で 200 + Allow のみ → ブラウザが POST を中止) |
| AC2 S3 + CloudFront 相当配信から CRUD | e2e (E2E-2) | PASS | E2E-2 pass (nginx 配信から index.html と Angular 起動を確認) |
| AC3 Angular unit がローカル/CI 通過 | unit + threshold | PASS | 32/32 + 100/94.28/100/100、`check-coverage-threshold.js` で閾値ガード済 |
| AC4 Angular integration がローカル/CI 通過 | integration + threshold | PASS | 17/17 + 98.63/80/100/98.27 |
| AC5 Playwright E2E ローカル/CI 通過 | e2e | PARTIAL_PASS | 3 passed (E2E-2/4/5) / 2 failed (E2E-1/3) / 1 skipped (E2E-6, design 通り)。E2E-1/3 のみ NEW-1 起因 |
| AC6 .NET 既存 lint/unit/integration/e2e 維持 | dotnet | PASS | build 0 warn / unit 34/34 / integration 12/12 (floci 起動下) / TodoApi.E2ETests は build 成功 |
| AC7 README にローカル/テスト/CI 手順 | doc | PASS | verify-readme-content.sh / verify-readme-sections.sh いずれも OK |

## NEW-1 (floci 1.5.9 OPTIONS 制約) — 既知 RED

- 観測: `OPTIONS /todos`、`OPTIONS /todos/{id}` で `HTTP/1.1 200 OK` + `Allow: HEAD, DELETE, POST, GET, OPTIONS, PUT, PATCH` のみが返り、
  `Access-Control-Allow-Origin` 等が無いため、ブラウザがプリフライトを失敗扱いにし `POST /todos` を発射しない。
- 原因: floci 1.5.9 `ApiGatewayUserRequestController` に `@OPTIONS` ハンドラが無く、Quarkus / RESTEasy 既定の自動 OPTIONS 応答が AWS_PROXY 統合より先にマッチする。
  - <https://github.com/floci-io/floci/blob/main/src/main/java/io/github/hectorvent/floci/services/apigateway/ApiGatewayUserRequestController.java>
- 設計準拠は Round 4 implement (NEW-1 修正) で確認済み:
  - `infra/frontend.tf` に `OPTIONS /todos`・`OPTIONS /todos/{id}` の `AWS_PROXY` 統合 + Lambda permission 既存。
  - `src/TodoApi.Lambda/Function.cs` で OPTIONS は `204 + Access-Control-*`。
  - `tests/TodoApi.IntegrationTests/CorsOptionsTests.cs` (5 件) PASS。
  - `tests/infra/test-frontend-plan.sh` で 7/7 期待リソース + `AWS_PROXY` 統合 + RD-011 違反 (MOCK / response_parameters CORS) 不在を assert 済み。
- 追加: `tests/infra/test-cors-preflight-http.sh` を RED テストとして同梱。floci 修正版で自動 GREEN になる前提。
- 設計上の回避策 (nginx で API proxy / MOCK 統合 / gateway responses による CORS 宣言) は RD-001 / RD-006 / RD-011 で禁止のため、ローカル E2E では NEW-1 を解消できない。

## 環境メモ / 既知の運用上の落とし穴

- `tests/infra/test-frontend-plan.sh` は `terraform plan` の `planned_change` を assert するため、ローカル `infra/terraform.tfstate` が残った状態では FAIL する。
  Round 4 検証では state を一時退避 → テスト実行 → state 復旧で対応 (今回も同手順で PASS 確認)。
- `scripts/web-e2e.sh` 内の `apply-state-machine.sh` は `floci` がまだ生きていて state machine が残っている場合 `UpdateStateMachine` 未対応で 254。
  検証時は事前に `aws stepfunctions delete-state-machine` で削除してから web-e2e.sh を実行した。本番 AWS では発生しないが、ローカル運用ノウハウとして記録。

## E2E 内訳 (Playwright)

| ID | テスト名 | 結果 | 備考 |
| --- | --- | --- | --- |
| E2E-1 | title 作成 → GET 同一 title | FAIL | NEW-1: preflight 200/Allow のみで POST 不発射 |
| E2E-2 | `/foo/bar` 直接遷移で Angular ルータが index.html | PASS | nginx + Angular SPA fallback 確認 |
| E2E-3 | console.error 無し / OPTIONS=204 / POST=201 | FAIL | NEW-1: OPTIONS=200 観測 |
| E2E-4 | title 空送信で `errors[0]` UI 表示 | PASS | |
| E2E-5 | POST 500 モックで "サーバエラー" UI 表示 | PASS | |
| E2E-6 | `WEB_BASE_URL` 未設定で web-e2e.sh が exit 1 (shell 検証) | SKIP | 設計通り (design fixture skip) |

## 判定

- 非 E2E: 全 PASS。Round 3 比で .NET integration が SkipIfNoFloci=満たすケースで 12/12 全実行。
- E2E: NEW-1 (floci 1.5.9 OPTIONS 制約) の影響で E2E-1 / E2E-3 のみ FAIL。本実装 (IaC + Lambda + 契約テスト) は設計通りで、本番 AWS 想定では GREEN になる見込み。
- 総合: **Round 2 (4 fail) → Round 4 (2 fail) と段階的改善**。残 2 件は upstream floci 修正待ち。

→ ローカル E2E が NEW-1 で RED のため、`verification.status = failed`、ブロッカーは upstream 待ち。
   契約テスト群 (`tests/infra/test-cors-preflight-http.sh`、`CorsOptionsTests.cs`、`test-frontend-plan.sh`) で本番 AWS での合格性は担保。

## 成果物

- `docs/floci-apigateway-csharp/verification/round4/verification-report.md` (本ファイル)
- `docs/floci-apigateway-csharp/verification/round4/implement-fix-report.md`
- 各種ログ:
  - `frontend-typecheck.log` / `frontend-build.log` / `frontend-unit.log` / `frontend-integration.log`
  - `dotnet-build.log` / `dotnet-unit.log` / `dotnet-integration.log`
  - `infra-frontend-plan.log` / `infra-cors-preflight-http.log`
  - `verify-readme-content.log` / `verify-readme-sections.log`
  - `compose-config.log` / `nginx-build.log`
  - `e2e-run.log` (Playwright JUnit XML 含む)
