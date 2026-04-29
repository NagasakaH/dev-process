# code-review-fix Round 1 対応結果

## 概要

- 対象: `docs/floci-apigateway-csharp/code-review/round-01-summary.md`
- 修正コミット: `025f207` (`refs FRONTEND-001 gitlab-ci-local検証でCI定義を修正`)
- 結果: Critical / Major / Minor 指摘はすべて修正または技術的理由で反論済み。再 code-review 待ち。

## 指摘対応一覧

| ID | 判定 | 対応内容 |
|----|------|----------|
| CR-001 | fixed | verification failed の主因だった floci OPTIONS preflight 依存を排除。Angular POST を CORS simple request 化し、`web-e2e.sh` / Playwright 6/6 PASS を確認 |
| CR-002 | fixed | E2E-6 の `test.skip` を撤廃し、`WEB_BASE_URL` 未設定時の fail-fast を shell 実行で検証 |
| CR-003 | fixed | E2E-1 で作成 Todo の id / title / status 一致を検証。非同期永続化に合わせて GET 確認を poll 化 |
| CR-004 | fixed | Frontend 型を Backend に合わせ、`TodoStatus = pending | done`、POST 応答を `{ id, executionArn }` 専用型へ変更 |
| CR-005 | fixed | preflight 診断スクリプトの暗黙 skip を廃止し、明示 `ALLOW_SKIP_PREFLIGHT=1` のみ許容 |
| CR-006 | fixed | Karma JUnit 出力を GitLab artifact path (`frontend/test-results/junit-*.xml`) に整合 |
| CR-007 | fixed | no-op `DISABLE_CUSTOM_CORS_APIGATEWAY` env を削除し、floci 制約はコメントのみで記録 |
| CR-008 | fixed | `web-e2e.sh` の IAM Role ARN 取得を `terraform output -raw sfn_exec_role_arn` に変更 |
| CR-009 | fixed | Lambda OPTIONS を `/todos` / `/todos/{id}` のみに限定し、未知 route は 404 |
| CR-010 | fixed | GET `/todos/foo/bar` や `PathParameters.id` に `/` を含む異常入力を 404 |
| CR-011 | fixed | `main.ts` の `innerHTML` を `createElement` / `textContent` に置換 |
| CR-012 | fixed | coverage 閾値検査を `coverage-summary.json` + `JSON.parse` に変更 |
| CR-013 | fixed | SkipIfNoFloci の skip 理由に missing env を明記 |
| CR-014 | fixed | `frontend_url` を `var.frontend_base_url` 化し CI/ローカル差異を切替可能に変更 |
| CR-015 | disputed | GitLab `web-e2e` の追加ツール導入は既存 runner 制約上必要。Playwright image は既に採用済みで、dotnet/terraform/awscli は E2E deploy に必須 |
| CR-016 | fixed | `ALLOWED_ORIGIN` env で CORS origin を上書き可能化。未設定時は既定 `*` を維持 |

## 検証結果

- Frontend unit: 32/32 PASS
- Frontend integration: 17/17 PASS
- Frontend lint/typecheck/build: PASS
- .NET build/unit/integration: PASS
- Infra plan assertion: PASS
- `scripts/web-e2e.sh`: Playwright 6/6 PASS
- `gitlab-ci-local --privileged`: backend `e2e` PASS、`format web-lint unit web-unit integration web-integration web-e2e` PASS
- GitLab pipeline 2489878063: 8/8 jobs success
