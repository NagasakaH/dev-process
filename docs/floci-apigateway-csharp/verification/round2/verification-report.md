# 検証結果レポート (Round 2)

- チケット: FRONTEND-001
- ブランチ: feature/FRONTEND-001
- 対象サブモジュール: submodules/editable/floci-apigateway-csharp
- 実行日時 (UTC): 2026-04-29T16:11Z 〜 2026-04-29T16:22Z
- 判定: **FAILED** (E2E 6 件中 4 件失敗 / 残ブロッカー 3 件)

## 1. 概要

Round 1 verification (failed) を受けて差し戻された implement (commit `da2ada3`) を対象に再検証を実施した。
非 E2E のすべての検証は通過したが、E2E は新たに発見された **3 件の残ブロッカー (R1〜R3)**
により Playwright テスト 4 件が失敗した。Round 1 の B1 (nginx conf bind mount) と
B2 (Lambda warmup timeout) は解消されたことを確認。

## 2. 検証結果サマリ

| 種別 | 結果 | 備考 |
|------|------|------|
| Frontend lint (`ng lint`) | ✅ PASS | All files pass linting |
| Frontend typecheck (`tsc --noEmit`) | ✅ PASS | exit 0 |
| Frontend build (`npm run build` / production) | ✅ PASS | initial 215.36 kB |
| Frontend unit (`npm run test:unit` + threshold guard) | ✅ PASS | 32/32 PASS, statements 100% / branches 94.28% / functions 100% / lines 100% (閾値 80/70/90/80) |
| Frontend integration (`npm run test:integration` + threshold guard) | ✅ PASS | 17/17 PASS, statements 98.63% / branches 80% / functions 100% / lines 98.27% |
| .NET build (`dotnet build` / 0 warnings) | ✅ PASS | 0 Warning(s) / 0 Error(s) |
| .NET unit (`dotnet test UnitTests`) | ✅ PASS | 34/34 PASS |
| .NET integration (`dotnet test IntegrationTests`) | ✅ PASS (環境依存 9 件 SKIP) | 2 passed / 9 skipped (`SkipIfNoFlociFact` 仕様通り。AWS_ENDPOINT_URL 未設定時の skip。) |
| `scripts/verify-readme-content.sh` | ✅ PASS | "README content OK" |
| `scripts/verify-readme-sections.sh` | ✅ PASS | "[OK] README sections present and ordered correctly" |
| `compose/nginx/Dockerfile` ビルド | ✅ PASS | Round 1 B1 fix が機能。bind mount を撤去しイメージ焼き込みに変更されたことを確認。 |
| `scripts/warmup-lambdas.sh` (リトライ強化) | ✅ PASS | api-handler / validate-todo / persist-todo すべて 1 回目で OK。Round 1 B2 解消を確認。 |
| **`scripts/web-e2e.sh` (E2E エントリ)** | ❌ **FAIL** | 詳細は §3 |

## 3. E2E 詳細 (`scripts/web-e2e.sh`)

### 3.1 実行手順

devcontainer (DOOD) 上で以下を設定して実行:

```bash
export WEB_BASE_URL=http://host.docker.internal:8080
export AWS_ENDPOINT_URL=http://host.docker.internal:4566
export DOCKER_MODE=dood
export AWS_DEFAULT_REGION=us-east-1 AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
bash scripts/web-e2e.sh
```

### 3.2 進捗

| ステップ | 結果 |
|----------|------|
| `check-test-env.sh e2e` | OK |
| `wait-floci-healthy.sh` | OK (8 秒で healthy) |
| `deploy-local.sh` (compose up + dotnet lambda package + terraform apply) | OK (23 resources) |
| `warmup-lambdas.sh` (Round 1 fix) | OK (api-handler/validate-todo/persist-todo すべて attempt 1 で成功) |
| `apply-api-deployment.sh` (web-e2e.sh からの呼び出し) | ❌ FAIL → R1 |
| `build-frontend.sh` / `deploy-frontend.sh` (R1 を手動回避して継続) | OK |
| nginx 経由の SPA 配信 (`http://host.docker.internal:8080/`) | ❌ FAIL → R2 (R3 の派生) |
| `frontend && npx playwright test` | ❌ FAIL (4/6) → R3 が根本原因 |

### 3.3 Playwright 結果 (手動回避後)

```
4 failed
  E2E-1: title を作成し ID を控えて GET で同じ title が表示される
  E2E-2: /foo/bar を直接開いても Angular ルータが index.html を返す
  E2E-3: console.error が出ず OPTIONS=204 / POST=201 が観測される
  E2E-5: POST /todos のレスポンスを 500 にモックすると "サーバエラーが発生しました" が表示される
1 skipped
  E2E-6: WEB_BASE_URL 未設定で web-e2e.sh が exit 1 (shell 側で検証, task07)
1 passed (1.7m)
  E2E-4: title 空送信で errors[0] が UI に表示される (ConfigService load 前 throw 経路)
```

すべての失敗は `getByTestId('title-input')` が timeout で見つからない症状。
`<app-root>` 配下が空のまま (= Angular bootstrap が起動していない)。

## 4. 残ブロッカー (Round 2 新規)

### R1 — `web-e2e.sh` から `apply-api-deployment.sh` を呼ぶ際に必須 env を伝搬していない

- 症状: `scripts/apply-api-deployment.sh: line 4: ENDPOINT: ENDPOINT is required`
- 場所: `scripts/web-e2e.sh:16`
- 原因: `apply-api-deployment.sh` は `ENDPOINT` / `REST_API_ID` / `STAGE_NAME` を必須 env で要求するが、`web-e2e.sh` 側でこれらを `terraform output -raw` から導出して export していない。
- 補足: `deploy-local.sh` 内の `terraform apply` が `terraform_data.todo_api_deployment.local-exec` 経由で同じスクリプトを既に実行済みのため、後段の独立呼び出しは技術的に冗長な再実行である。
- 推奨修正: `web-e2e.sh` で `terraform -chdir=infra output -raw` から `REST_API_ID` / 既定 `STAGE_NAME=dev` / `ENDPOINT=$AWS_ENDPOINT_URL` を導出して export する。または冗長な独立呼び出しを削除する。

### R2 — `compose/docker-compose.yml` の nginx `frontend/dist` bind mount が DOOD 環境で失敗

- 症状: `floci-nginx` 起動後、`/usr/share/nginx/html/` が空ディレクトリのまま (`directory index ... is forbidden` 403)。
- 場所: `compose/docker-compose.yml` の nginx サービス `volumes: - "../frontend/dist:/usr/share/nginx/html:ro"`
- 原因: devcontainer (DOOD) では docker daemon は **ホスト** で動作するため、ホストから見えない `/workspaces/...` パスを bind mount できない (host docker daemon が空ディレクトリを自動生成)。
- 補足: Round 1 fix は **conf ファイル** の bind mount だけを Dockerfile 焼き込みに変更したが、**dist ディレクトリ** の bind mount は残存しており、同じ DOOD 制約が残っている。
- 推奨修正のいずれか:
  - (a) `deploy-frontend.sh` で `aws s3 sync` 後に `docker cp frontend/dist/. floci-nginx:/usr/share/nginx/html/` を行う。
  - (b) nginx サービスを「dist を build 時にイメージへ焼き込む」マルチステージ構成にし、`build-frontend.sh` / `deploy-frontend.sh` の後に `docker compose build nginx && docker compose up -d nginx` を回す。
  - (c) 静的配信を S3+nginx ではなく `aws s3 website` シミュレーションに切り替える (要 RD-001 再確認)。
- 検証: 手動で `docker cp frontend/dist/. floci-nginx:/usr/share/nginx/html/` した後は `curl http://host.docker.internal:8080/index.html` が `<!doctype html><html><app-root>...` を返すことを確認。

### R3 — `frontend/src/assets/config.json` がビルド成果物に含まれず Angular bootstrap が失敗 (E2E 主要因)

- 症状: 手動で nginx に dist を配置後も `<app-root>` 配下が描画されず、E2E のセレクタが timeout。
- 場所: `frontend/angular.json` `architect.build.options.assets: []` (空配列)
- 原因: `scripts/build-frontend.sh` は `frontend/src/assets/config.json` を生成してから `ng build` を実行するが、`angular.json` の `assets` 設定が空配列のため `dist/assets/config.json` が出力されない。実際に `ls frontend/dist/` を確認したところ `index.html / main-*.js / polyfills-*.js / styles-*.css / 3rdpartylicenses.txt` のみで `assets/` ディレクトリが存在しない。`curl /assets/config.json` は SPA fallback の `index.html` を返す。
- 影響: ConfigService.load() が JSON でないレスポンス (HTML) を受け取り起動時に reject。AppComponent bootstrap が失敗し UI 全体が描画されない。E2E-1/2/3/5 すべてがこの症状に該当。
- ConfigService 単体テストは load 失敗パスを検証しているため UT は緑だが、bootstrap 経路の **integration / E2E** がこのギャップを暴いた形。
- 推奨修正: `frontend/angular.json` の `architect.build.options.assets`  と `architect.test.options.assets` / `test-integration.options.assets` に
  ```json
  [{ "glob": "**/*", "input": "src/assets", "output": "/assets" }]
  ```
  を追加する。修正後 `npm run build` で `dist/assets/config.json` が出力されることを確認すること。

### Round 1 ブロッカーの解消状況

| Round 1 | 状態 |
|---------|------|
| B1: nginx **conf** bind mount → Dockerfile 焼き込み | ✅ 解消 (確認済み) |
| B1': nginx **dist** bind mount は未対応 | ❌ R2 として残存 |
| B2: Lambda warmup timeout | ✅ 解消 (warmup attempt 1 で成功) |
| coverage 閾値未達 | ✅ 解消 (UT 32/32 + IT 17/17 で全閾値クリア) |
| coverage CI ガード未実装 | ✅ 解消 (`scripts/check-coverage-threshold.js`) |

## 5. 受け入れ基準照合

| AC | method | 結果 | 根拠 |
|----|--------|------|------|
| AC1 ローカル Angular + floci API で Todo CRUD | e2e | ❌ FAIL | E2E-1 fail (R3) |
| AC2 S3+CloudFront 相当配信から CRUD | e2e | ❌ FAIL | nginx 配信は到達 (R2 を回避すれば) するが Angular が起動しない (R3)。E2E-2 fail |
| AC3 Angular unit がローカル/CI 通過 | unit | ✅ PASS | 32/32 + 100/94.28/100/100、閾値ガード実装 |
| AC4 Angular integration がローカル/CI 通過 | integration | ✅ PASS | 17/17 + 98.63/80/100/98.27、閾値ガード実装 |
| AC5 Playwright E2E ローカル/CI 通過 | e2e | ❌ FAIL | 4/6 fail (R3 主因 / R1 / R2 副因) |
| AC6 .NET 既存 lint/unit/integration/e2e 維持 | dotnet | 🟡 PARTIAL | build 0 warn / unit 34/34 / integration 2 pass + 9 skip (仕様通り) / e2e は web-e2e.sh 配下のため AC5 と連動して未通過 |
| AC7 README にローカル/テスト/CI 手順 | doc | ✅ PASS | verify-readme-{content,sections}.sh 両方 OK |

## 6. 証拠ファイル

- `docs/floci-apigateway-csharp/verification/round2/frontend-unit.log`
- `docs/floci-apigateway-csharp/verification/round2/frontend-integration.log`
- `docs/floci-apigateway-csharp/verification/round2/e2e-run.log` (web-e2e.sh up to R1 失敗)
- `docs/floci-apigateway-csharp/verification/round2/e2e-playwright.log`
- (Round 1) `docs/floci-apigateway-csharp/verification/verification-report.md`

## 7. 次アクション (推奨)

implement への差し戻し対応:

1. R3: `frontend/angular.json` の `assets` 設定を有効化 (3 箇所: build / test / test-integration)。
2. R2: `compose/docker-compose.yml` の nginx を build ベース (dist 焼き込み) に変更、または `deploy-frontend.sh` で `docker cp` を行う。
3. R1: `scripts/web-e2e.sh` で `apply-api-deployment.sh` 呼び出し前に `terraform output` から env を導出 export する (または冗長呼び出しを除去する)。
4. 修正後、`scripts/web-e2e.sh` を再実行し E2E 6/6 (E2E-6 は shell skip のため 5/5 actual) PASS を確認する。
