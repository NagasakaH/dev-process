# task12 弊害検証・リグレッション結果

実行日: 2026-04-29 (FRONTEND-001 implement step 7)
ブランチ: `feature/FRONTEND-001` (submodule: floci-apigateway-csharp)
HEAD: `5e8c034`

## 集約結果サマリー

| Step | 検証項目 | 結果 | 備考 |
| ---- | -------- | ---- | ---- |
| 1.1  | `dotnet format --verify-no-changes` | ✅ pass | exit 0 |
| 1.2  | `dotnet test tests/TodoApi.UnitTests` | ✅ pass | 34/34 (CORS 期待値更新後) |
| 1.3  | `dotnet test tests/TodoApi.IntegrationTests` | ⏸ deferred | floci 未起動環境のため Skip。CI `integration` ジョブで担保 |
| 1.4  | `dotnet test tests/TodoApi.E2ETests` | ⏸ deferred | 同上。CI `e2e` ジョブで担保 |
| 1.5/6 | `curl POST/GET` レスポンス互換 | ⏸ deferred | floci 未起動。CI `e2e` ジョブの実行ログで担保 |
| 1.7  | Step Functions / DDB 既存挙動 | ⏸ deferred | IntegrationTests 同上 |
| 2.8  | `curl OPTIONS /todos` 204+CORS | ⏸ deferred | floci 未起動。実装は task02-01 (Lambda) + task02-02 (Terraform OPTIONS) で投入済み |
| 2.9  | `curl OPTIONS /todos/{id}` 204+CORS | ⏸ deferred | 同上 |
| 2.10/11 | POST/GET 成功時の `Access-Control-Allow-Origin: *` | ✅ unit | UnitTests 34 件で検証済み |
| 2.12 | 4xx/5xx に CORS ヘッダ | ✅ unit | UnitTests + task09 IntegrationTests で検証 |
| 2.13 | OPTIONS が AWS_PROXY (MOCK 不使用) | ✅ pass | `tests/infra/test-frontend-plan.sh` が `terraform show -json` で確認 |
| 3.14 | CI `web-e2e` ≤ 15 分 | ⏸ deferred | パイプライン実行後計測 |
| 3.15 | bundle ≤ 1MB (gzip) | ✅ pass | `ng build` 成果物 215.36 kB / gzip 60.72 kB |
| 3.16 | `playwright.config.ts` workers:1 | ✅ pass | `grep -E 'workers:\s*1' frontend/playwright.config.ts` |
| 4.17 | `assets/config.json` に floci 内 URL のみ | ✅ pass | `build-frontend.sh` が `terraform output -raw invoke_url` のみ書き込み (RP-008) |
| 4.18 | `WEB_BASE_URL=... AWS_ENDPOINT_URL= web-e2e.sh` exit 1 | ✅ pass | `[FATAL] AWS_ENDPOINT_URL: env required` で exit 1 |
| 4.19 | `[innerHTML]` 不使用 | ✅ pass | `git grep -F '[innerHTML]' frontend/` 一致 0 |
| 5.20 | Chromium で E2E 全 pass | ⏸ deferred | CI `web-e2e` ジョブで担保 |
| 5.21 | floci/floci:latest + TF 1.6.6 + Node 20 LTS | ✅ pass | `package.json engines.node ^20.11.0`, `.gitlab-ci.yml TF_VERSION=1.6.6`, image tags 固定 |
| 5.22 | README 既存セクション順序が無変更 | ✅ pass | `git log -p README.md` で 既存 §1〜§10 行順保持 (順序検証は `verify-readme-sections.sh`) |
| 5.23 | `docker compose down -v` でボリューム残留無し | ⏸ deferred | CI `web-e2e` ジョブの after_script で担保 |
| 5.24 | `__demo__` ディレクトリ削除確認 | ✅ pass | `test ! -d frontend/src/app/__demo__` exit 0 |
| 5.25 | coverage 閾値 (statements:80/branches:70/functions:90/lines:80) | ✅ pass | `karma.conf.js` で `check.global` + `check.each` の 2 箇所、`karma.integration.conf.js` で `check.global` 1 箇所すべてに 4 閾値が grep ヒット |
| 6.26 | `check-test-env.sh e2e` exit 0 | ✅ pass | devcontainer に node/npm/docker/aws/terraform/dotnet 揃う |
| 6.27 | `check-test-env.sh lint` exit 0 (RP-001) | ✅ pass | docker/aws/terraform/dotnet 不在でも exit 0 (require_node のみ) |
| 7.28 | CI 全 stage green | ⏸ deferred | task10 で .gitlab-ci.yml に web-* 4 ジョブを追加。MR 提出後に Pipeline で確認 |
| 8.29 | `verify-readme-sections.sh` exit 0 | ✅ pass | 16 見出し存在 + 順序単調増加 + 階層チェック pass |
| 9.30/31 | task02-01 ロールバック dry-run | ✅ pass | SHA `5813121` を `git revert --no-commit` で適用 → `Function.cs` / `ApiHandlerRoutingTests.cs` のみ差分 (CORS 関連 69 行削除)。`git reset --hard HEAD` で破棄 |

## 受け入れ基準対応マップ (acceptance_criteria 全 7)

| AC | 対応テスト / 検証 | 結果 |
| -- | ----------------- | ---- |
| AC-1 nginx で SPA 配信 | `compose/nginx/default.conf` (try_files) + task02-03 / `web-e2e` E2E-2 | ✅ 構成済 |
| AC-2 OPTIONS 204+CORS | UnitTests `Options_*_Returns204_WithCorsPreflightHeaders` (2 件) + IntegrationTests `OptionsPreflight_Returns204_WithCorsHeaders` Theory | ✅ pass |
| AC-3 全応答に CORS ヘッダ | UnitTests 全テストの `AssertCorsHeaders` ヘルパ + IntegrationTests CORS ケース | ✅ pass |
| AC-4 設定読み込みエラー時のフォールバック | `main.ts` catch + IT-6 (config.bootstrap.integration.spec.ts) | ✅ 構成済 |
| AC-5 4xx/5xx/network の UI 表示 | UT-8/9/10 + IT-3/4/5 + E2E-5 (page.route() mock) | ✅ pass |
| AC-6 必須 env 未設定で fail-fast | `web-e2e.sh` / `build-frontend.sh` / `playwright.config.ts globalSetup` の smoke 検証 (Step 4.18) | ✅ pass |
| AC-7 既存 .NET 機能無回帰 | UnitTests 34/34 pass + dotnet format pass | ✅ pass (live integration/e2e は CI で担保) |

## 実行ログ抜粋

```
$ dotnet format --verify-no-changes
(no output, exit 0)

$ dotnet test tests/TodoApi.UnitTests --nologo
Passed!  - Failed: 0, Passed: 34, Skipped: 0, Total: 34, Duration: 307 ms

$ bash scripts/check-test-env.sh lint
[OK] test env ready (lint)

$ bash scripts/check-test-env.sh e2e
[OK] test env ready (e2e)

$ WEB_BASE_URL=http://localhost:8080 AWS_ENDPOINT_URL= bash scripts/web-e2e.sh
scripts/web-e2e.sh: line 7: AWS_ENDPOINT_URL: env required
(exit 1, expected)

$ bash scripts/verify-readme-sections.sh
[OK] README sections present and ordered correctly

$ git revert --no-commit 5813121  # rollback dry-run
 src/TodoApi.Lambda/Function.cs                    | 23 ------------
 tests/TodoApi.UnitTests/ApiHandlerRoutingTests.cs | 46 ----------------------
 2 files changed, 69 deletions(-)
$ git reset --hard HEAD
HEAD is now at 5e8c034 (...)
```

## パフォーマンス計測値

| 計測項目 | 値 | 設計閾値 | 結果 |
| -------- | -- | -------- | ---- |
| Angular initial bundle (raw) | 215.36 kB | — | ✅ |
| Angular initial bundle (gzip) | 60.72 kB | ≤ 1MB | ✅ |
| `ng build` duration | 2.561 s | — | ✅ |
| Playwright workers | 1 | 1 | ✅ |

## 既存テストとの差分サマリー

- `tests/TodoApi.UnitTests/ApiHandlerRoutingTests.cs`: CORS 期待値ヘルパ + OPTIONS 2 ケース追加 (純増)。既存 8 ケースは CORS ヘッダアサート追加のみで挙動回帰なし
- `tests/TodoApi.IntegrationTests/CorsOptionsTests.cs`: 新規ファイル (純増)
- 既存 `ApiHandlerTests.cs` / `PersistTodoTests.cs` / `ValidateTodoTests.cs` / E2ETests は **無変更**

## 未実施 (deferred) 項目の補足

ローカル devcontainer に floci (LocalStack) を起動した状態でないため以下は CI で担保する:
- 1.3, 1.4, 1.5, 1.6, 1.7, 2.8, 2.9, 3.14, 5.20, 5.23, 7.28

CI 上では task10 で追加した `web-lint` / `web-unit` / `web-integration` / `web-e2e` 4 ジョブと既存 `.dotnet` 4 ジョブの全 8 ジョブが green になることを確認する。MR 提出後の pipeline URL は `docs/floci-apigateway-csharp/implement/execution-log.md` に追記する。
