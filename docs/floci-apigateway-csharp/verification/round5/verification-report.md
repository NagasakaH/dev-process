# FRONTEND-001 Round 5 検証レポート

## 検証情報

- プロジェクト: floci-apigateway-csharp
- 対象コミット: `9c0a4c3` (`refs FRONTEND-001 code-review round2 指摘対応`)
- テスト戦略スコープ: unit / integration / E2E
- 検証結果: ✅ 全通過

## 単体・結合テスト実行結果

| 種別 | コマンド | 結果 |
|------|----------|------|
| Frontend unit | `cd frontend && CHROME_BIN=/usr/bin/chromium npm run test:unit` | ✅ 32/32 PASS, coverage 100/94.28/100/100 |
| Frontend integration | `cd frontend && CHROME_BIN=/usr/bin/chromium npm run test:integration` | ✅ 17/17 PASS, coverage 98.64/80/100/98.30 |
| .NET unit | `dotnet test tests/TodoApi.UnitTests -c Release --no-restore` | ✅ 37/37 PASS |
| .NET integration | `AWS_ENDPOINT_URL=http://host.docker.internal:4566 dotnet test tests/TodoApi.IntegrationTests -c Release --no-restore` | ✅ 12/12 PASS |
| Infra plan assertion | `bash tests/infra/test-frontend-plan.sh` | ✅ 7/7 expected resources + AWS_PROXY 統合確認 PASS |
| CORS preflight diagnostic | `bash tests/infra/test-cors-preflight-http.sh` | ✅ diagnostic WARN扱い。floci 1.5.9 の OPTIONS ギャップを検出しつつ通常検証は PASS |

## GitLab CI ローカル検証

`gitlab-ci-local` で CI 定義そのものをローカル検証した。

| 対象 | コマンド | 結果 |
|------|----------|------|
| Backend E2E job | `npx --yes gitlab-ci-local@latest --privileged --pull-policy if-not-present e2e` | ✅ PASS。warmup 3 Lambda OK、`TodoApi.E2ETests` 6/6 PASS |
| 残り CI jobs | `npx --yes gitlab-ci-local@latest --privileged --pull-policy if-not-present --concurrency 1 format web-lint unit web-unit integration web-integration web-e2e` | ✅ PASS。format/web-lint/unit/web-unit/integration/web-integration/web-e2e 全通過 |
| Round 2 web-e2e recheck | `npx --yes gitlab-ci-local@latest --privileged --pull-policy if-not-present web-e2e` | ✅ PASS。Playwright 6/6 PASS、`frontend/test-results/junit.xml` 生成確認 |

補足: このローカル Docker は server architecture が arm64 のため、backend `e2e` job でも `scripts/deploy-local.sh` と同じ Lambda architecture 自動判定を使用するよう CI 定義を修正した。GitLab SaaS Runner では amd64 として動作する。

## GitLab CI 実行結果

- **Pipeline**: https://gitlab.com/nagasaka-experimental/floci-apigateway-csharp/-/pipelines/2489915868
- **対象コミット**: `9c0a4c3`
- **結果**: ✅ success
- **ジョブ**: `format`, `web-lint`, `unit`, `web-unit`, `integration`, `web-integration`, `e2e`, `web-e2e` の8ジョブすべて success

## E2Eテスト実行結果

- **ステータス**: ✅ PASS
- **実行方法**: `WEB_BASE_URL=http://host.docker.internal:8080 AWS_ENDPOINT_URL=http://host.docker.internal:4566 CHROME_BIN=/usr/bin/chromium SKIP_ENV_CHECK=1 bash scripts/web-e2e.sh`
- **対象環境**: floci 1.5.9 + nginx static frontend + Playwright Chromium
- **詳細**: Playwright 6/6 PASS。`web-e2e.sh` の deploy-local / state machine 冪等適用 / API deployment / lambda warmup / frontend build / S3 sync / nginx 配置まで含めて通過。

## ビルド・リント・型チェック

| 項目 | コマンド | 結果 |
|------|----------|------|
| .NET build | `dotnet build floci-apigateway-csharp.sln -c Release --no-restore` | ✅ 0 warning / 0 error |
| Frontend build | `cd frontend && npm run build` | ✅ production build PASS |
| Frontend lint | `cd frontend && npm run lint` | ✅ All files pass linting |
| Frontend typecheck | `cd frontend && npm run typecheck` | ✅ `tsc --noEmit` PASS |

## 受け入れ基準 照合結果

| 基準 | 検証方法 | 結果 |
|------|----------|------|
| AC1 ローカル Angular + floci API で Todo CRUD | E2E-1 | ✅ PASS |
| AC2 S3 + CloudFront 相当配信から CRUD | E2E-2 / S3 sync / nginx static serving | ✅ PASS |
| AC3 Angular unit がローカル/CI 通過 | Frontend unit | ✅ PASS |
| AC4 Angular integration がローカル/CI 通過 | Frontend integration | ✅ PASS |
| AC5 Playwright E2E ローカル/CI 通過 | `scripts/web-e2e.sh` / Playwright E2E-1〜E2E-6 | ✅ PASS |
| AC6 .NET 既存 lint/unit/integration/e2e 維持 | .NET build/unit/integration | ✅ PASS |
| AC7 README にローカル/テスト/CI 手順 | 既存 README verify + 実行コマンド確認 | ✅ PASS |

## 重要な修正点

- floci 1.5.9 が OPTIONS preflight を Lambda へ転送しない制約に対し、ブラウザ CRUD 経路を CORS simple request (`text/plain;charset=UTF-8`) にしてローカル E2E を GREEN 化。
- Lambda 側の OPTIONS / CORS 契約は維持し、`STRICT_PREFLIGHT=1` で実 AWS / floci 修正版の厳密確認が可能。
- `apply-state-machine.sh` を floci の `UpdateStateMachine` 未対応に合わせて delete + create で冪等化。
- `build-frontend.sh` はビルド時のみ `config.json` を注入し、終了後にプレースホルダへ戻す。
- GitLab CI の `web-unit` / `web-integration` で Playwright image 内 Chromium を `CHROME_BIN` に設定。
- GitLab CI の `e2e` / `web-e2e` を `gitlab-ci-local` で再現し、DinD、zip、AWS CLI v1/v2、Terraform version check、Lambda architecture 差分を修正。
- Round 2 指摘対応として、破壊的 AWS 操作を local/floci endpoint のみに制限し、Playwright JUnit artifact を `frontend/test-results/junit.xml` に生成するよう修正。

## 総合結果

✅ **全通過**。Round 4 の E2E 残ブロッカー (E2E-1/E2E-3) は解消済み。
