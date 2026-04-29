# タスク: task07 - scripts: `build-frontend.sh` / `deploy-frontend.sh` / `web-e2e.sh` / `check-test-env.sh`

## タスク情報

| 項目           | 値                                |
| -------------- | --------------------------------- |
| タスク識別子   | task07                            |
| 前提条件       | task02-02, task02-03              |
| 並列実行可否   | 可（task04 / task09 と並列）      |
| 推定所要時間   | 1.0h                              |
| 優先度         | 高                                |

## 作業環境

- 作業ディレクトリ: `/tmp/FRONTEND-001-task07/`
- ブランチ: `FRONTEND-001-task07`

## 設計参照

- [design/02_interface-api-design.md](../design/02_interface-api-design.md) §4.2, §5
- [design/04_process-flow-design.md](../design/04_process-flow-design.md) §3, §4.4
- [design/05_test-plan.md](../design/05_test-plan.md) §1.5, §2.3 E2E 実行手順
- [design/06_side-effect-verification.md](../design/06_side-effect-verification.md) §2.7

## 目的

shell スクリプト 4 本を新設し、ローカル / CI で再利用可能にする。必須 env 未設定時は **fail-fast** (`exit 1`) を統一する (RD-002)。

## 実装ステップ (TDD)

### RED
1. `tests/scripts/test-build-frontend.bats` (または bash test) を作成し:
   - `AWS_ENDPOINT_URL=` 空文字状態で `scripts/build-frontend.sh` を起動 → exit 1
   - `WEB_BASE_URL=` 未設定で `scripts/web-e2e.sh` を起動 → exit 1
   - `scripts/check-test-env.sh` で node 不在を擬似 → exit 1
2. テスト実行で **FAIL**

### GREEN
3. **`scripts/build-frontend.sh`** (新規):
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   : "${AWS_ENDPOINT_URL:?env required}"
   : "${AWS_ACCESS_KEY_ID:?env required}"
   : "${AWS_SECRET_ACCESS_KEY:?env required}"
   : "${AWS_DEFAULT_REGION:?env required}"
   INVOKE_URL=$(terraform -chdir=infra output -raw invoke_url)
   [[ -z "$INVOKE_URL" ]] && { echo "[FATAL] invoke_url empty" >&2; exit 1; }
   cat > frontend/src/assets/config.json <<EOF
   { "apiBaseUrl": "${INVOKE_URL}" }
   EOF
   ( cd frontend && npm ci && npm run build )
   ```
4. **`scripts/deploy-frontend.sh`** (新規):
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   : "${AWS_ENDPOINT_URL:?env required}"
   BUCKET="${BUCKET:-frontend-bucket}"
   aws --endpoint-url "$AWS_ENDPOINT_URL" s3 sync frontend/dist/frontend/browser/ "s3://${BUCKET}/" --delete
   ```
   > Angular 18 の出力ディレクトリ構造に合わせる (`frontend/dist/<project>/browser/`)。実出力は task01 で確定させる。
5. **`scripts/web-e2e.sh`** (新規):
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   : "${WEB_BASE_URL:?env required}"
   : "${AWS_ENDPOINT_URL:?env required}"
   ( cd frontend && npx playwright test --reporter=junit,html )
   ```
6. **`scripts/check-test-env.sh`** (新規) — `05_test-plan.md` §1.5 の readiness を全て検証:
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   command -v node >/dev/null || { echo "[FATAL] node missing" >&2; exit 1; }
   node -v | grep -qE '^v20\.11\.' || { echo "[FATAL] node 20.11.x required" >&2; exit 1; }
   command -v npm >/dev/null || exit 1
   command -v docker >/dev/null || exit 1
   docker compose version >/dev/null || exit 1
   command -v aws >/dev/null || exit 1
   command -v terraform >/dev/null || exit 1
   terraform -version | head -1 | grep -q '1.6.6' || true   # warn
   command -v dotnet >/dev/null || exit 1
   echo "[OK] test env ready"
   ```
7. すべてのスクリプトに `chmod +x` 相当 (`git update-index --chmod=+x`)
8. テスト実行で **GREEN**

### REFACTOR
9. 共通 fail-fast パターン (`: "${VAR:?...}"`) のコメントで設計参照 (RD-002) を明記
10. `wait-floci-healthy.sh` が既存にあれば再利用、無ければ task07 で簡易版を追加

## 対象ファイル

| ファイル                          | 操作 |
| --------------------------------- | ---- |
| `scripts/build-frontend.sh`        | 新規 |
| `scripts/deploy-frontend.sh`       | 新規 |
| `scripts/web-e2e.sh`               | 新規 |
| `scripts/check-test-env.sh`        | 新規 |

## 完了条件

- [ ] 全スクリプトが必須 env 未設定で exit 1 (smoke 検証)
- [ ] `bash -n` で syntax error 無し
- [ ] `chmod +x` 相当が git 上で反映
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
