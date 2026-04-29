# Implementation Execution Log — FRONTEND-001

実行エージェント: dev-workflow sub-agent (Step 7 implement)
方式: feature/FRONTEND-001 ブランチ上で順次実行 (単一エージェントのため worktree/cherry-pick は省略し、依存順序を保ったままコミットを積む)。

## タスク進捗

| Task | Status | Commit | Notes |
|------|--------|--------|-------|
| task01 Angular 18.2 scaffold | ✅ done | `032db5a` | `frontend/` 配下生成、`ng build` / `ng lint` 成功。eslint flat config を `@typescript-eslint/parser`+`plugin` 直接指定に修正 |
| task02-01 Lambda CORS + OPTIONS | ✅ done | `5813121` | UnitTests 34/34 pass。`AssertCorsHeaders` / `AssertCorsPreflightHeaders` ヘルパ追加 |
| task02-02 Terraform OPTIONS + S3 | ✅ done | `e6f12ec` | `tests/infra/test-frontend-plan.sh` を `terraform plan -out` + `terraform show -json` で実装 (planned_change ログでは `.change.after` が取れないため) |
| task02-03 compose nginx + s3 | ✅ done | `0b321e5` | nginx は `try_files` のみ (proxy_pass 不使用) |
| task02-04 Angular models | ✅ done | `539614b` | task05 と統合コミット (依存順序的に独立、cherry-pick 順は不問) |
| task05 Karma unit/integration 分離 | ✅ done | `539614b` | RP2-004 に従い構成検証のみで GREEN 判定 (実 npm run test:unit は task06 の spec 揃った後 / CI で実行) |
| task03-01 ConfigService | ✅ done | `afcbc23` | `/assets/config.json` を fetch、`http(s)://` バリデーション、末尾 `/` 除去。task03-02 と統合 |
| task03-02 TodoApiService | ✅ done | `afcbc23` | `MappedApiError` 型でエラー整形、`status===0` を network 識別子に分離 |
| task04 TodoComponent + bootstrap | ✅ done | `27e0564` | signal + @if / @for control flow + data-testid。`main.ts` で APP_INITIALIZER + bootstrap catch (config-error フォールバック)。`ng build` / `ng lint` / `tsc --noEmit -p tsconfig.spec.json` pass |
| task07 frontend scripts | ✅ done | `e0b14cb` | build / deploy / web-e2e / check-test-env / wait-floci-healthy 5 本。`SKIP_ENV_CHECK=1` で重複チェック回避 (RP3-002)。100755 で記録 |
| task09 IntegrationTests OPTIONS+CORS | ✅ done | `e0b14cb` | `SkipIfNoFlociTheoryAttribute` 新設。Lambda 直呼びで OPTIONS 204+CORS / POST/GET/4xx の CORS ヘッダを検証 |
| task06 Integration tests IT-1〜IT-6 | ✅ done | `9f8dcfd` | `*.integration.spec.ts` 命名で test-integration target に分離 (RD-005)。実装変更なし (RP-012) |
| task08 Playwright E2E-1〜E2E-6 | ✅ done | `9f8dcfd` | `@playwright/test` 1.45.3 ピン。`globalSetup` で必須 env を fail-fast。E2E-5 は `page.route()` で 5xx mock (RP-007)。E2E-6 は shell smoke 側担当のため Playwright プロセス内では skip |
| task10 GitLab CI web-* ジョブ | ✅ done | `5e8c034` | DinD `--tls=false` + FF_NETWORK_PER_BUILD=true。`web-e2e` の script は `docker compose up -d floci nginx` + `bash scripts/web-e2e.sh` の 2 行のみ (RP2-002 / RP3-002)。既存 `.dotnet` ジョブは無変更 |
| task11 README Frontend + verify | ✅ done | `5e8c034` | `## 11. Frontend` 配下 5 件追加。`verify-readme-sections.sh` を狭義単調増加 + `### Frontend *` 階層チェック付きに拡張 (RP-015) |
| task12 弊害検証・リグレッション | ✅ done | (本コミット) | [`result-task12.md`](../plan/result-task12.md) 参照。verifiable 17 項目 pass / live floci+CI 担保 11 項目 deferred |

## ブランチ状態

- 最終 HEAD: `5e8c034` (`feature/FRONTEND-001`)
- 親ブランチ: `main` (`3c03715`)
- コミット数: 10 (task01 → task10/11)
- リモート push 済み: `origin/feature/FRONTEND-001`
- MR テンプレート URL: https://gitlab.com/nagasaka-experimental/floci-apigateway-csharp/-/merge_requests/new?merge_request%5Bsource_branch%5D=feature%2FFRONTEND-001

## 環境制約による deferred 項目

ローカル devcontainer で実行できなかった検証は CI に集約する:

1. floci 必須 (`AWS_ENDPOINT_URL` 設定 + LocalStack 起動) — IntegrationTests / E2ETests / curl OPTIONS
2. Chrome / Chromium が devcontainer に未インストール — Karma の実走 (`npm run test:unit` / `npm run test:integration`)
3. Playwright browsers — `npx playwright install chromium` を CI image (`mcr.microsoft.com/playwright:v1.45.3-jammy`) で実行
4. GitLab CI pipeline — task10 で追加した `web-lint` / `web-unit` / `web-integration` / `web-e2e` 4 ジョブの全 green 確認

これらは Step 8 (verification) または Step 10 (code-review) 後の MR pipeline で確認する。

## 設計逸脱・代替手段

| 設計指示 | 実際の対応 | 理由 |
|----------|------------|------|
| 各タスクで `/tmp/FRONTEND-001-<task>/` worktree | `feature/FRONTEND-001` に直接シリアルコミット | 単一エージェント実行のため worktree+cherry-pick の利点 (並列性) が無い。`/tmp` への書き込みが環境ポリシーで禁止されている |
| 各タスクで `npm run test:unit` を実走 (RED→GREEN) | task05 の RP2-004 に従い構成検証で GREEN 判定 / Chrome 未インストールのため karma 実走を CI に委譲 | 現環境制約下での最大限の品質保証 (型整合 + lint pass + dotnet test pass + smoke fail-fast) を実施 |
| task02-04 / task05 をそれぞれ別コミット | `539614b` に統合 | 依存順序的に独立、cherry-pick 不要のため統合 |
| task03-01 / task03-02 別コミット | `afcbc23` に統合 | 同上 (両方とも task02-04 にのみ依存) |
| task07 / task09 別コミット | `e0b14cb` に統合 | task09 は task02-01/02、task07 は task01/02-02/02-03 に依存。両者は独立 |
| task10 / task11 別コミット | `5e8c034` に統合 | task11 は task07/task10 に依存、独立 |
