# 受入基準カバレッジレビュー

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | FRONTEND-001 |
| レビューラウンド | 1 |

## 評価サマリー

受入基準（Angular 追加 / CORS / E2E / CI / README / 弊害検証）は概ね計画にカバーされているが、**CI実行可能性**および**配信成果物パス整合性**の観点で受入が成立しない致命的問題が残る。

## 検出された受入カバレッジ問題

### RP-001 (Critical): CI 実行可能性 — check-test-env.sh の責務矛盾

- `web-lint` を含む全 `web-*` ジョブで `scripts/check-test-env.sh` の実行が必須とされているが、同スクリプトが docker / terraform / dotnet まで必須化しているため、`node:20.11-bullseye-slim` 前提の `web-lint` ジョブと矛盾する。
- 計画のままでは CI が成立せず、「CI に web-* ジョブが緑で通る」という受入基準が満たせない。
- **是正**: `check-test-env.sh` をジョブ別プロファイル化（lint / unit / integration / e2e）し、`web-lint` は Node/npm 等の最小チェックに限定。E2E のみ docker/terraform/aws/dotnet 等を要求する。

### RP-002 (Major): 配信成果物パス整合性

- `frontend/dist/frontend/browser/` と `frontend/dist/` でビルド成果物パスが不一致。nginx mount / S3 sync / deploy scripts の整合が崩れる。
- 「nginx で frontend を配信」「S3 へ deploy」の受入が同一パスで通らないリスク。
- **是正**: Angular project 名 / outputPath / browser 出力を一意に固定し、task01 完了条件・task02-03 nginx mount・task07 deploy-frontend.sh・task10 e2e 手順の全記述を同一パスに統一する。

### RP-008 (Major): web-e2e 実行順 / API deployment 保証

- task10 web-e2e 手順に `apply-api-deployment.sh` / `warmup-lambdas.sh` の実行保証がなく、`invoke_url` 取得や API 応答が flaky になる。E2E 受入の安定性が担保されない。
- **是正**:
  - `deploy-local.sh` がそれらを内包するか明記する。
  - `web-e2e` script に `apply-api-deployment.sh` と `warmup-lambdas.sh` を `deploy-local.sh` 後に組み込む。
  - `build-frontend.sh` は `invoke_url` 取得失敗時に fail-fast とする。

### RP-014 (Minor): fail-fast 検証順の整合

- task12 の `AWS_ENDPOINT_URL` 空検証が、`WEB_BASE_URL` 未設定で先に落ちる可能性。受入検証スクリプト自体の信頼性を損なう。
- **是正**: `WEB_BASE_URL=http://localhost:8080 AWS_ENDPOINT_URL= scripts/web-e2e.sh` で検証するよう修正。

### RP-015 (Minor): README 検証強度

- README 見出し検証が `grep -F` のみで、階層・順序を担保しない可能性。「README に Frontend セクションが追加される」受入が形骸化する恐れ。
- **是正**: 既存見出し baseline と新規見出しの位置・順序チェックを `verify-readme-sections.sh` に追加。

### RP-016 (Minor): dry-run revert 対象 SHA 特定

- task12 の dry-run revert 対象 SHA 特定方法が未定義。弊害検証手順が再現性を欠く。
- **是正**: `git log --grep` 等で task02-01 コミットを特定する手順を追加する。

### RP-017 (Minor): ESLint config 形式の根拠不明

- task01 が Angular 18 環境で legacy `.eslintrc.json` を採用しているが、根拠が不明。CI lint の前提整合に影響する。
- **是正**: `eslint.config.js` flat config 採用へ変更、または legacy 採用理由を明記。**推奨は flat config**。

## カバレッジサマリー

- 受入基準: 概ねカバー済み。ただし RP-001 (Critical) により CI 受入が成立しない状態。RP-001 / RP-002 / RP-008 の是正が受入合格の必須条件。
