# implement 差し戻し対応レポート (Round 2 → Round 3)

- チケット: FRONTEND-001
- 対象: `submodules/editable/floci-apigateway-csharp`
- 対応元: `docs/floci-apigateway-csharp/verification/round2/verification-report.md`

## 1. Round 2 残ブロッカーへの修正

### R1 — `web-e2e.sh` から `apply-api-deployment.sh` への env 伝搬欠落 → 解消 ✅
- 変更: `scripts/web-e2e.sh`
- `terraform -chdir=infra output -raw rest_api_id|stage_name` から `REST_API_ID` / `STAGE_NAME` を導出し、`ENDPOINT=$AWS_ENDPOINT_URL` と共に export してから `apply-api-deployment.sh` を呼ぶ。
- 証拠: round3 の e2e-run.log で `apply-api-deployment.sh` が即時失敗せず、後続の warmup / build / deploy / playwright まで到達。

### R2 — DOOD 環境で `frontend/dist` bind mount が空ディレクトリ化 → 解消 ✅
- 変更: `compose/docker-compose.yml` から `frontend/dist:/usr/share/nginx/html:ro` bind mount を撤去。
- 変更: `scripts/deploy-frontend.sh` で `aws s3 sync` 後に `docker exec ... rm -rf` + `docker cp frontend/dist/. floci-nginx:/usr/share/nginx/html/` を実行。事前に nginx コンテナ稼働を確認し fail-fast。
- 証拠: `curl http://host.docker.internal:8080/index.html` が `<!doctype html>` を返し、`/assets/config.json` も SPA fallback ではなく実 JSON を返す。E2E-2 (SPA fallback) PASS。

### R3 — `dist/assets/config.json` がビルド成果物に含まれず Angular bootstrap 失敗 → 解消 ✅
- 変更: `frontend/angular.json` の `architect.build.options.assets` / `test.options.assets` / `test-integration.options.assets` を全て `[{ "glob": "**/*", "input": "src/assets", "output": "/assets" }]` に設定。
- 検証: `npm run build` 後、`frontend/dist/assets/config.json` が出力されることを確認。`curl http://host.docker.internal:8080/assets/config.json` で正規 JSON を返す。E2E-4 / E2E-5 PASS により ConfigService bootstrap 経路の復旧を確認。

### 追加修正 — Step Functions state machine 再適用 (R1 と同種の terraform_data 冪等性ギャップ)
- 変更: `scripts/web-e2e.sh` で terraform output / `aws lambda get-function` から `STATE_MACHINE_ARN` / `ROLE_ARN` / `VALIDATE_LAMBDA_ARN` / `PERSIST_LAMBDA_ARN` を取得し `apply-state-machine.sh` を冪等に再実行。
- 理由: `terraform_data.todo_state_machine` はステートが残ると local-exec を再実行しないため、floci 再起動後は state machine 実体が存在しなくなる (Round 3 で R3 解消後に新規顕在化した `StateMachineDoesNotExistException`)。R1 と同じ修正パターン。
- 証拠: floci ログで `Created State Machine: arn:aws:states:us-east-1:000000000000:stateMachine:todo-flow` を確認。`curl POST /todos` が `{"id":"...","executionArn":"..."}` を返し、状態遷移 SUCCEEDED まで完了。

## 2. 検証結果 (round3)

| 種別 | 結果 | 備考 |
|------|------|------|
| `ng lint` | ✅ PASS | All files pass linting |
| `npm run test:unit` | ✅ PASS | 32/32, statements 100% / branches 94.28% / functions 100% / lines 100% (閾値クリア) |
| `npm run test:integration` | ✅ PASS | 17/17, statements 98.63% / branches 80% / functions 100% / lines 98.27% |
| `npm run build` | ✅ PASS | dist/ + dist/assets/config.json 出力確認 |
| `compose/nginx` Docker build | ✅ PASS | floci-frontend-nginx:local |
| `scripts/verify-readme-content.sh` | ✅ PASS | "README content OK" |
| `scripts/verify-readme-sections.sh` | ✅ PASS | "[OK] README sections present and ordered correctly" |
| `docker compose config` | ✅ PASS | bind mount 撤去後も valid |
| `bash -n scripts/{web-e2e,deploy-frontend}.sh` | ✅ PASS | shell syntax OK |
| `scripts/web-e2e.sh` (E2E 全体) | 🟡 PARTIAL | 6 件中 3 PASS / 2 FAIL / 1 SKIP (E2E-6 は仕様 skip) |

### Playwright 詳細 (round3)

| ID | 結果 | 備考 |
|----|------|------|
| E2E-1 | ❌ FAIL | POST /todos の created レスポンス UI 反映が timeout |
| E2E-2 | ✅ PASS | (R3 修正で改善) |
| E2E-3 | ❌ FAIL | OPTIONS preflight が CORS ヘッダなしで browser 拒否 |
| E2E-4 | ✅ PASS | (R3 修正で改善) |
| E2E-5 | ✅ PASS | (R3 修正で改善) |
| E2E-6 | ⏭️ SKIP | 仕様通りの shell 側検証 |

### Round 2 ブロッカー解消状況

| Round 2 ID | 状態 | 根拠 |
|------------|------|------|
| R1 (env 伝搬欠落) | ✅ 解消 | web-e2e.sh が apply-api-deployment.sh を経て後続ステップに到達 |
| R2 (dist bind mount) | ✅ 解消 | docker cp 方式で nginx に dist 配信、curl で確認、E2E-2 PASS |
| R3 (assets/config.json 欠落) | ✅ 解消 | dist/assets/config.json 出力確認、E2E-4/5 PASS |

## 3. 残ブロッカー (Round 3 新規 / Round 2 では R3 配下に隠蔽されていた)

### NEW-1 — API Gateway CORS preflight 未設定
- 症状: `OPTIONS /todos` が `200 OK` (期待 204) を返し、`Access-Control-Allow-Origin/Methods/Headers` レスポンスヘッダが欠落。ブラウザは preflight 失敗として後続 POST を送出しない。
- 根拠: `curl -X OPTIONS ... -H "Origin: http://host.docker.internal:8080"` のレスポンスに CORS ヘッダなし。floci ログにも Lambda invocation 記録なし。
- 影響: E2E-1 (POST→GET フロー) と E2E-3 (OPTIONS=204/POST=201 観測) が timeout。Angular 自体は ConfigService load まで含め正常起動済み。
- 推奨修正 (本 Round スコープ外):
  - `infra/main.tf` で `/todos` および `/todos/{id}` の `OPTIONS` メソッドを追加し、Mock integration で `Access-Control-Allow-{Origin,Methods,Headers}` と 204 を返すよう設定。
  - もしくは Lambda 側で OPTIONS をハンドルし 204 + CORS ヘッダを返す。
- 注: Round 2 verification 時は R3 (Angular bootstrap 失敗) が先に発火し UI 描画自体が起こらなかったため CORS 不備が顕在化していなかった。R1/R2/R3 解消後に新規発見された別カテゴリのブロッカー。

## 4. コミット

- `feat(frontend-001): Round 2 ブロッカー (R1/R2/R3) と state machine 冪等化を修正`
  - scripts/web-e2e.sh: terraform output から env 導出、apply-state-machine.sh / apply-api-deployment.sh を冪等再実行
  - scripts/deploy-frontend.sh: docker cp で dist を nginx へ配信
  - compose/docker-compose.yml: bind mount 撤去
  - frontend/angular.json: assets glob を build/test/test-integration に追加

## 5. 証拠ファイル

- `docs/floci-apigateway-csharp/verification/round3/e2e-run.log` (web-e2e.sh 全実行ログ)
- `docs/floci-apigateway-csharp/verification/round3/implement-fix-report.md` (本ファイル)
