# レビュー結果 - Round 2 / Group 1: FRONTEND-001 実装一式

## レビュー情報
- リポジトリ: floci-apigateway-csharp
- ベースSHA: `3c0371559487afd98b9665fc9afe894149550dff`
- ヘッドSHA: `9c0a4c388e249ce87e59c90a1fb5bfee71d936f3`
- MR: https://gitlab.com/nagasaka-experimental/floci-apigateway-csharp/-/merge_requests/2
- レビュー日時: 2026-04-29T23:23:58+00:00
- レビュアー: Opus 4.7 + GPT-5.5 → 統合判定

## 意図グループ情報
- グループ名: Angular frontend + local/CI verification
- カテゴリ: mixed
- 対象コミット:
  - `032db5a`〜`9c0a4c3`: Angular frontend、Terraform/nginx/S3、単体・結合・E2E、GitLab CI、Round 1/2 指摘対応

## チェックリスト結果

### 1. 設計準拠性
- [x] DC-01: 設計成果物との整合性 — ✅ OK
- [x] DC-02: API/インターフェース互換性 — ✅ OK

### 2. 静的解析
- [x] SA-01: frontend lint/typecheck — ✅ OK
- [x] SA-02: dotnet format/build — ✅ OK

### 3. 言語別BP
- [x] BP-01: Angular/TypeScript の型整合 — ✅ OK
- [x] BP-02: C# Lambda routing/null safety — ✅ OK
- [x] BP-03: shell script fail-fast/error handling — ✅ OK

### 4. セキュリティ
- [x] SE-01: シークレット混入なし — ✅ OK
- [x] SE-02: DOM XSS 回避 — ✅ OK
- [x] SE-03: 破壊的 AWS 操作の non-local endpoint ガード — ✅ OK（Round 2 fix）

### 5. テスト・CI
- [x] TC-01: Unit / Integration / E2E — ✅ OK
- [x] TC-02: gitlab-ci-local — ✅ OK
- [x] TC-03: GitLab pipeline — ✅ OK
- [x] TC-04: JUnit artifact path — ✅ OK（Round 2 fix）

### 6. パフォーマンス
- [x] PF-01: UI/CI 変更による明確な性能劣化なし — ✅ OK

### 7. ドキュメント
- [x] DOC-01: README frontend/CI/env 説明 — ✅ OK

### 8. Git作法
- [x] GH-01: コミット粒度・不要ファイル除外 — ✅ OK

### 9. MR要求項目
- [x] MR-01: MR description の AI自動チェック根拠 — ✅ OK
- [x] MR-02: Draft MR として作成 — ✅ OK

## 指摘事項

### 🔴 Critical
（なし）

### 🟠 Major
- **CR-017**: Local-only destructive AWS operations are not guarded against non-local endpoints
  - カテゴリ: セキュリティ
  - 出典: GPT-5.5
  - 該当ファイル: `scripts/apply-state-machine.sh`, `scripts/deploy-frontend.sh`
  - 対応: `scripts/local-endpoint.sh` に `assert_local_aws_endpoint` を追加し、`localhost` / `127.0.0.1` / `host.docker.internal` / `docker` / `floci` の `:4566` 以外を拒否。意図的な非ローカル endpoint は `ALLOW_NON_LOCAL_AWS_ENDPOINT=1` の明示 override のみに限定。
  - ステータス: fixed (`9c0a4c3`)

### 🟡 Minor
- **CR-018**: Playwright JUnit artifact path is declared but reporter output file is overridden
  - カテゴリ: テスト・CI
  - 出典: GPT-5.5
  - 該当ファイル: `scripts/web-e2e.sh`, `frontend/playwright.config.ts`, `.gitlab-ci.yml`
  - 対応: `scripts/web-e2e.sh` の `--reporter=junit,html` を削除し、`playwright.config.ts` の `reporter` 設定（`test-results/junit.xml`）を使用。`gitlab-ci-local web-e2e` 後に `frontend/test-results/junit.xml` 生成を確認。
  - ステータス: fixed (`9c0a4c3`)

### 🔵 Info
- `apply-state-machine.sh` の delete+create は floci 1.5.9 の `UpdateStateMachine` 未対応に対するローカル専用回避。Round 2 fix により non-local endpoint では既定拒否される。
- `ALLOWED_ORIGIN` の単一 origin 運用では `Vary: Origin` は不要。将来 multi-origin 化する場合は追加検討。
- `warmup-lambdas.sh` の `persist-todo` warmup は local DynamoDB に `id=warmup` を書くが、E2E は fresh GUID を使うため影響なし。

## 静的解析・検証結果
- `bash -n scripts/local-endpoint.sh scripts/apply-state-machine.sh scripts/deploy-frontend.sh scripts/web-e2e.sh scripts/verify-local-endpoint.sh`: ✅ PASS
- `bash scripts/verify-local-endpoint.sh`: ✅ PASS
- `WEB_BASE_URL=http://localhost:8080 AWS_ENDPOINT_URL=http://localhost:4566 npx playwright test --list`: ✅ 6 tests detected
- `npx --yes gitlab-ci-local@latest --privileged --pull-policy if-not-present web-e2e`: ✅ PASS, Playwright 6/6 PASS, `frontend/test-results/junit.xml` generated
- GitLab pipeline 2489915868: ✅ success, 8/8 jobs success

## グループ判定
- **判定**: ✅ 承認
- **理由**: Round 1 指摘は全て解消または妥当な反論済み。Round 2 の Major/Minor 指摘も `9c0a4c3` で修正され、ローカルCIとGitLab CIの両方で成功したため。
