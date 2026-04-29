# タスク: task07 - scripts: `build-frontend.sh` / `deploy-frontend.sh` / `web-e2e.sh` / `check-test-env.sh`

## タスク情報

| 項目           | 値                                          |
| -------------- | ------------------------------------------- |
| タスク識別子   | task07                                      |
| 前提条件       | task01, task02-02, task02-03                |
| 並列実行可否   | 可（task04 / task09 と並列）                |
| 推定所要時間   | 1.25h（20〜30% バッファ込み、RP-013）       |
| 優先度         | 高                                          |

> **依存追記 (RP-009)**: `build-frontend.sh` / `deploy-frontend.sh` は Angular の `frontend/dist/` 構造に依存するため task01 を前提に追加。cherry-pick 時は task01 が先に統合済みであることを必須とする。

## 作業環境

- 作業ディレクトリ: `/tmp/FRONTEND-001-task07/`
- ブランチ: `FRONTEND-001-task07`

## 設計参照

- [design/02_interface-api-design.md](../design/02_interface-api-design.md) §4.2, §5
- [design/04_process-flow-design.md](../design/04_process-flow-design.md) §3, §4.4
- [design/05_test-plan.md](../design/05_test-plan.md) §1.5, §2.3 E2E 実行手順
- [design/06_side-effect-verification.md](../design/06_side-effect-verification.md) §2.7

## 目的

shell スクリプト 5 本を新設し、ローカル / CI で再利用可能にする。必須 env 未設定時は **fail-fast** (`exit 1`) を統一する (RD-002)。`check-test-env.sh` は **ジョブ別プロファイル** (lint / unit / integration / e2e) に分割し、`web-lint` 等の Node 単独ジョブが docker / terraform / aws / dotnet を要求しない構造とする (RP-001)。`wait-floci-healthy.sh` を新規追加し未起動時 timeout で fail-fast する (RP-011)。

## 実装ステップ (TDD)

### RED
1. `tests/scripts/test-build-frontend.bats` (または bash test) を作成し:
   - `AWS_ENDPOINT_URL=` 空文字状態で `scripts/build-frontend.sh` を起動 → exit 1
   - `terraform output -raw invoke_url` を空文字 stub で返す状態で `scripts/build-frontend.sh` → exit 1（`invoke_url` 空時の fail-fast 検証、RP-008 / RP-002）
   - `WEB_BASE_URL=http://localhost:8080 AWS_ENDPOINT_URL=` で `scripts/web-e2e.sh` を起動 → exit 1（先に WEB_BASE_URL を満たし AWS_ENDPOINT_URL の未設定検証であることを保証、RP-014 と整合）
   - `scripts/check-test-env.sh lint` で `command -v node` を擬似的に外す → exit 1
   - `scripts/check-test-env.sh e2e` で docker / terraform / aws / dotnet いずれか不在で exit 1
   - `scripts/check-test-env.sh lint` 時に **docker / terraform / aws / dotnet を要求しない**ことを `bash -x` トレースで確認（RP-001）
   - **(RP3-002)** `SKIP_ENV_CHECK=1 WEB_BASE_URL=... AWS_ENDPOINT_URL=...` で `scripts/web-e2e.sh` を起動 → 内部の `check-test-env.sh e2e` が呼ばれない（`bash -x` トレース or stub で観測）。未設定時は呼ばれることも併せて確認
   - `scripts/wait-floci-healthy.sh` を timeout=1 で起動し floci 未起動の状態で exit 1（RP-011）
2. テスト実行で **FAIL**

### GREEN
3. **`scripts/build-frontend.sh`** (新規) — Angular outputPath 統一 `frontend/dist/` (RP-002):
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   : "${AWS_ENDPOINT_URL:?env required}"
   : "${AWS_ACCESS_KEY_ID:?env required}"
   : "${AWS_SECRET_ACCESS_KEY:?env required}"
   : "${AWS_DEFAULT_REGION:?env required}"
   INVOKE_URL=$(terraform -chdir=infra output -raw invoke_url || true)
   if [[ -z "${INVOKE_URL}" ]]; then
     echo "[FATAL] invoke_url empty (terraform output not initialized?)" >&2
     exit 1
   fi
   mkdir -p frontend/src/assets
   cat > frontend/src/assets/config.json <<EOF
   { "apiBaseUrl": "${INVOKE_URL}" }
   EOF
   ( cd frontend && npm ci && npm run build )
   # 配信成果物パスは frontend/dist/ に固定 (Angular outputPath {base:"dist", browser:""})
   test -f frontend/dist/index.html || { echo "[FATAL] frontend/dist/index.html missing" >&2; exit 1; }
   ```
4. **`scripts/deploy-frontend.sh`** (新規) — 成果物パスは task01 で固定した `frontend/dist/` を使用 (RP-002):
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   : "${AWS_ENDPOINT_URL:?env required}"
   BUCKET="${BUCKET:-frontend-bucket}"
   test -d frontend/dist || { echo "[FATAL] frontend/dist not built" >&2; exit 1; }
   aws --endpoint-url "$AWS_ENDPOINT_URL" s3 sync frontend/dist/ "s3://${BUCKET}/" --delete
   ```
   > Angular 18 の application builder の `outputPath` を `{ base: "dist", browser: "" }` に設定し `frontend/dist/index.html` を直接出力する形を task01 で固定する (RP-002)。task02-03 nginx mount / task07 deploy-frontend.sh / task08 e2e baseURL / task10 CI artifacts もすべて `frontend/dist/` 直下を前提とする。
5. **`scripts/web-e2e.sh`** (新規) — `deploy-local.sh` 後に `apply-api-deployment.sh` と `warmup-lambdas.sh` を必ず挟む (RP-008)。CI からの二重チェック回避のため、`SKIP_ENV_CHECK=1` が set されている場合は内部の `check-test-env.sh e2e` をスキップする (RP3-002):
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   : "${WEB_BASE_URL:?env required}"
   : "${AWS_ENDPOINT_URL:?env required}"
   # RP3-002: CI では before_script で check-test-env.sh e2e 済みのため SKIP_ENV_CHECK=1 で重複回避。
   #          ローカル実行ではデフォルト未設定のままにし、本スクリプトが readiness 担保する唯一エントリポイントとなる。
   if [[ "${SKIP_ENV_CHECK:-0}" != "1" ]]; then
     bash scripts/check-test-env.sh e2e
   fi
   bash scripts/wait-floci-healthy.sh
   bash scripts/deploy-local.sh
   bash scripts/apply-api-deployment.sh   # RP-008: invoke_url を確定させる
   bash scripts/warmup-lambdas.sh         # RP-008: 初回コールドスタート由来の flaky を排除
   bash scripts/build-frontend.sh
   bash scripts/deploy-frontend.sh
   ( cd frontend && npx playwright test --reporter=junit,html )
   ```
6. **`scripts/check-test-env.sh`** (新規) — **ジョブ別プロファイル** (RP-001) `lint` / `unit` / `integration` / `e2e`。引数未指定時は後方互換で `e2e` 相当のフルチェック:
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   PROFILE="${1:-e2e}"

   require_node() {
     command -v node >/dev/null || { echo "[FATAL] node missing" >&2; exit 1; }
     node -v | grep -qE '^v20\.11\.' || { echo "[FATAL] node 20.11.x required" >&2; exit 1; }
     command -v npm >/dev/null || { echo "[FATAL] npm missing" >&2; exit 1; }
   }
   require_browser() {
     command -v npx >/dev/null || { echo "[FATAL] npx missing" >&2; exit 1; }
     # ChromeHeadlessCI は Playwright image 同梱想定。明示確認は warning 扱い
     [[ -d "${HOME}/.cache/ms-playwright" ]] || echo "[WARN] playwright browsers cache missing" >&2
   }
   require_docker() {
     command -v docker >/dev/null || { echo "[FATAL] docker missing" >&2; exit 1; }
     docker compose version >/dev/null || { echo "[FATAL] docker compose missing" >&2; exit 1; }
   }
   require_aws_terraform_dotnet() {
     command -v aws >/dev/null || { echo "[FATAL] aws missing" >&2; exit 1; }
     command -v terraform >/dev/null || { echo "[FATAL] terraform missing" >&2; exit 1; }
     terraform -version | head -1 | grep -q '1.6.6' || echo "[WARN] terraform != 1.6.6" >&2
     command -v dotnet >/dev/null || { echo "[FATAL] dotnet missing" >&2; exit 1; }
   }

   case "$PROFILE" in
     lint)        require_node ;;                                    # node/npm のみ (RP-001)
     unit)        require_node; require_browser ;;                   # + Chromium
     integration) require_node; require_browser ;;
     e2e)         require_node; require_browser; require_docker; require_aws_terraform_dotnet ;;
     *) echo "[FATAL] unknown profile: $PROFILE" >&2; exit 1 ;;
   esac
   echo "[OK] test env ready ($PROFILE)"
   ```
7. **`scripts/wait-floci-healthy.sh`** (新規・RP-011):
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:4566}"
   TIMEOUT="${WAIT_TIMEOUT:-60}"
   for i in $(seq 1 "$TIMEOUT"); do
     if curl -sf "${ENDPOINT}/_localstack/health" >/dev/null 2>&1; then
       echo "[OK] floci healthy after ${i}s"; exit 0
     fi
     sleep 1
   done
   echo "[FATAL] floci did not become healthy in ${TIMEOUT}s" >&2
   exit 1
   ```
8. すべてのスクリプトに `chmod +x` 相当 (`git update-index --chmod=+x`)
9. テスト実行で **GREEN**

### REFACTOR
10. 共通 fail-fast パターン (`: "${VAR:?...}"`) のコメントで設計参照 (RD-002) を明記
11. `check-test-env.sh` のプロファイル分岐をコメントで RP-001 解消理由を明記
12. `wait-floci-healthy.sh` の TIMEOUT を env で上書き可能にしておく

## 対象ファイル

| ファイル                          | 操作 |
| --------------------------------- | ---- |
| `scripts/build-frontend.sh`        | 新規 |
| `scripts/deploy-frontend.sh`       | 新規 |
| `scripts/web-e2e.sh`               | 新規 |
| `scripts/check-test-env.sh`        | 新規 |
| `scripts/wait-floci-healthy.sh`    | 新規 (RP-011) |

## 完了条件

- [ ] 全スクリプトが必須 env 未設定で exit 1 (smoke 検証)
- [ ] `bash -n` で syntax error 無し
- [ ] `chmod +x` 相当が git 上で反映
- [ ] `scripts/check-test-env.sh lint` が docker / terraform / aws / dotnet を要求せず exit 0 (RP-001)
- [ ] `scripts/check-test-env.sh e2e` が docker / terraform / aws / dotnet 不在で exit 1
- [ ] `WEB_BASE_URL=http://localhost:8080 AWS_ENDPOINT_URL= scripts/web-e2e.sh` が AWS_ENDPOINT_URL 未設定起因で exit 1 (RP-014 と整合)
- [ ] **(RP3-002)** `SKIP_ENV_CHECK=1` を export した状態で `scripts/web-e2e.sh` を起動すると内部の `check-test-env.sh e2e` 呼び出しが **スキップ** されること（CI 二重チェック回避方針が反映されていることを `bash -x` トレース等で確認）。未設定時は従来どおり `check-test-env.sh e2e` を呼ぶこと。
- [ ] `scripts/wait-floci-healthy.sh` が timeout 後 exit 1 (RP-011)
- [ ] `frontend/dist/` 直下に `index.html` が出力されることを `build-frontend.sh` 末尾で検証 (RP-002)
- [ ] result.md 作成

## コミット

```bash
git add -A
git commit -m "refs FRONTEND-001 task07 frontend 関連 shell スクリプトを追加

- build-frontend.sh: invoke_url を assets/config.json に注入し ng build
- deploy-frontend.sh: aws s3 sync で floci S3 に配置 (配置検証専用、RD-001)
- web-e2e.sh: Playwright を junit/html で実行
- check-test-env.sh: 05_test-plan §1.5 の readiness を fail-fast 検証 (RD-002 / RD-012)"
```
