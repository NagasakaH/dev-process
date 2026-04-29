# タスク: task10 - `.gitlab-ci.yml` `web-lint` / `web-unit` / `web-integration` / `web-e2e` (DinD 設定込み) 追加

## タスク情報

| 項目           | 値                                |
| -------------- | --------------------------------- |
| タスク識別子   | task10                            |
| 前提条件       | task05, task07, task08            |
| 並列実行可否   | 不可                              |
| 推定所要時間   | 1.0h                              |
| 優先度         | 高                                |

## 作業環境

- 作業ディレクトリ: `/tmp/FRONTEND-001-task10/`
- ブランチ: `FRONTEND-001-task10`

## 設計参照

- [design/02_interface-api-design.md](../design/02_interface-api-design.md) §7, §7.1
- [design/05_test-plan.md](../design/05_test-plan.md) §1.2, §6
- [design/06_side-effect-verification.md](../design/06_side-effect-verification.md) §2.7

## 目的

`.gitlab-ci.yml` に `web-lint` / `web-unit` / `web-integration` / `web-e2e` の 4 ジョブを追加する。既存 `.dotnet` テンプレートと同形の `.node` テンプレートを定義する。`web-e2e` は DinD service (`docker:25.0.3-dind`, `--tls=false`) と `FF_NETWORK_PER_BUILD: "true"` を必ず設定する (RD-004 / RD2-004)。各ジョブ冒頭で `scripts/check-test-env.sh` を実行 (RD-012)。

## 実装ステップ (TDD)

### RED
1. `.gitlab-ci.yml` の現状をベースラインとして取得
2. 仮実行 (`gitlab-ci-lint` 相当) で `web-*` ジョブが未定義であることを確認

### GREEN
3. `.gitlab-ci.yml` に下記を追加 (`02_interface-api-design.md` §7 を厳守):
   - `.node` テンプレート (image: `node:20.11-bullseye-slim`、cache: `frontend/node_modules`, `~/.npm`、key は `frontend/package-lock.json` baseline)
   - `web-lint`: stage `lint` / image `node:20.11-bullseye-slim` / `bash scripts/check-test-env.sh lint` (RP-001 — Node/npm のみ。docker/terraform/aws/dotnet を要求しない) → `cd frontend && npm ci && npm run lint`
   - `web-unit`: stage `unit` / image `mcr.microsoft.com/playwright:v1.45.3-jammy` / `bash scripts/check-test-env.sh unit` → `cd frontend && npm ci && npm run test:unit -- --reporters=junit,coverage` / artifacts `junit:` 設定
   - `web-integration`: stage `integration` / 同 image / `bash scripts/check-test-env.sh integration` → `npm run test:integration -- --reporters=junit,coverage`
   - `web-e2e`: stage `e2e` / 同 image / **DinD service** + `DOCKER_HOST=tcp://docker:2375` / `DOCKER_TLS_CERTDIR=""` / `FF_NETWORK_PER_BUILD: "true"` / `WEB_BASE_URL: "http://docker:8080"` / `AWS_ENDPOINT_URL: "http://docker:4566"` / `AWS_*=test` / before_script で `apt-get install docker.io docker-compose-plugin awscli` + `docker info` + `bash scripts/check-test-env.sh e2e` / script で `docker compose up -d floci nginx` → `bash scripts/wait-floci-healthy.sh` → `bash scripts/deploy-local.sh` → `bash scripts/apply-api-deployment.sh` → `bash scripts/warmup-lambdas.sh` → `bash scripts/build-frontend.sh` → `bash scripts/deploy-frontend.sh` → `bash scripts/web-e2e.sh` (RP-008) / after_script `docker compose down -v || true` / artifacts `frontend/test-results/, frontend/playwright-report/` + `reports.junit`
4. 全 4 ジョブの先頭で `scripts/check-test-env.sh <profile>` を実行（profile は lint/unit/integration/e2e、RP-001）
5. 既存 `.dotnet` ジョブ (`lint`/`unit`/`integration`/`e2e`) の YAML を **変更しない** (新ジョブ追加のみ)
6. ローカル `gitlab-ci-lint` (もしくは `glab ci lint`) で syntax 通過

### REFACTOR
7. キャッシュキーを `frontend/package-lock.json` baseline 統一
8. coverage XML (`cobertura-coverage.xml`) を `artifacts.reports.coverage_report` に登録
9. コメントで RD-002 / RD-003 / RD-004 / RD-007 / RD2-004 解消を明記

## 対象ファイル

| ファイル          | 操作 |
| ----------------- | ---- |
| `.gitlab-ci.yml`  | 修正 |

## 完了条件

- [ ] `gitlab-ci-lint` (or `glab ci lint`) が exit 0
- [ ] `web-lint`/`web-unit`/`web-integration`/`web-e2e` の 4 ジョブが定義
- [ ] 各 web-* ジョブの before_script で **対応プロファイル** (`check-test-env.sh lint|unit|integration|e2e`) が呼ばれている (RP-001)
- [ ] `web-lint` ジョブの image が `node:20.11-bullseye-slim` で、docker/terraform/aws/dotnet をインストールしないこと (RP-001)
- [ ] `web-e2e` の script に `wait-floci-healthy.sh` → `deploy-local.sh` → `apply-api-deployment.sh` → `warmup-lambdas.sh` → `build-frontend.sh` → `deploy-frontend.sh` → `web-e2e.sh` の順序で含まれている (RP-008)
- [ ] DinD `--tls=false` / `DOCKER_HOST=tcp://docker:2375` / `DOCKER_TLS_CERTDIR=""` / `FF_NETWORK_PER_BUILD=true` がすべて設定
- [ ] image tag が `mcr.microsoft.com/playwright:v1.45.3-jammy` / `node:20.11-bullseye-slim` (固定)
- [ ] 既存 `.dotnet` ジョブの YAML 変更が無いこと (`git diff` で確認)
- [ ] result.md 作成

## コミット

```bash
git add -A
git commit -m "refs FRONTEND-001 task10 GitLab CI に web-* ジョブを追加 (DinD 込み)

- .node テンプレートを新設 (node:20.11-bullseye-slim ピン)
- web-lint / web-unit / web-integration / web-e2e を追加
- web-* は mcr.microsoft.com/playwright:v1.45.3-jammy 固定 (RD-003 / RD-007)
- web-e2e は DinD service (--tls=false, 2375) + FF_NETWORK_PER_BUILD=true (RD-004 / RD2-004)
- check-test-env.sh を全ジョブ冒頭で実行 (RD-012)
- 既存 .dotnet ジョブは無変更 (R8)"
```

## 注意事項

- `latest` / `v1.45.x` 等の可変タグを使わない (RD-007)
- 既存 `.dotnet` ジョブ YAML を **絶対に** 変更しない
