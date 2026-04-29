# レビューサマリー

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | FRONTEND-001 |
| タスク名 | floci-apigateway-csharp に Angular フロントエンド追加（テスト・CI 含む） |
| レビューラウンド | 1 |
| 総合判定 | ❌ **差し戻し (rejected)** |
| タスク計画参照 | [../plan/](../plan/) |
| 設計結果参照 | [../design/](../design/) |

## 総合判定

**❌ 差し戻し (rejected)**

計画は網羅性が高いが、`web-lint` と `check-test-env` の責務衝突により CI が成立しない Critical 指摘がある。さらに成果物パス整合性、依存関係正本、E2E 前提、coverage 運用、5xx 再現方式、API deployment / warmup、infra RED 強度など Major が複数残るため **rejected**。Critical / Major / Minor の全指摘を計画へ反映し、再レビューが必要。

## 指摘事項一覧

| ID | 重大度 | カテゴリ | 指摘内容 | 対応方針 | 対応状況 |
|----|--------|----------|----------|----------|----------|
| RP-001 | 🔴 Critical | CI実行可能性 / check-test-env責務 | `web-lint` を含む全 `web-*` ジョブで `scripts/check-test-env.sh` 実行必須だが、同スクリプトが docker/terraform/dotnet まで必須化しており `node:20.11-bullseye-slim` 前提の `web-lint` と矛盾する。計画のままでは CI が成立しない。 | `check-test-env.sh` をジョブ別プロファイル化（lint/unit/integration/e2e）し、`web-lint` は Node/npm 等の最小チェックに限定。E2E のみ docker/terraform/aws/dotnet 等を要求する。 | ⬜ 未対応 |
| RP-002 | 🟠 Major | 配信成果物パス整合性 | ビルド成果物パスが `frontend/dist/frontend/browser/` と `frontend/dist/` で不一致。nginx mount / S3 sync / deploy scripts の整合が崩れる。 | Angular project 名 / outputPath / browser 出力を一意に固定し、task01 完了条件、task02-03 nginx mount、task07 deploy-frontend.sh、task10 e2e 手順の全記述を同一パスに統一する。 | ⬜ 未対応 |
| RP-003 | 🟠 Major | 依存関係の正確性 / 正本不一致 | `task-list` と `parent-agent-prompt` で依存関係が不一致。task02-01/02/03 の task01 依存有無など実行順の解釈が割れる。 | `task-list` を依存関係の正本と定義し、`parent-agent-prompt` と各 `taskXX` の前提条件を同期。矛盾検知チェックリストを追加する。 | ⬜ 未対応 |
| RP-004 | 🟠 Major | E2E前提漏れ / CORS依存 | task08 の前提に task02-01（Lambda CORS/OPTIONS）が含まれておらず、E2E-3 CORS 成立の前提が保証されない。 | task08 前提条件へ task02-01 を追加し、依存グラフ・並列グループを更新する。 | ⬜ 未対応 |
| RP-005 | 🟠 Major | APP_INITIALIZER責務境界 | task03-01 のタイトル/目的に APP_INITIALIZER 登録があるが、実装ステップ・対象ファイル・完了条件には登録手順がなく、実際は task04 main.ts 側で扱われる。責務境界が矛盾。 | task03-01 は ConfigService 実装のみへ寄せ、APP_INITIALIZER 登録は task04 に一本化する（または逆方向に統合）。 | ⬜ 未対応 |
| RP-006 | 🟠 Major | coverage閾値運用 | task05 で一時的に低い coverage 閾値を許容しており、本番閾値へ戻すタスク・検証が明示されていない。 | 暫定閾値運用を禁止し、最初から最終閾値（80/70/90/80）を設定。task12 に grep 等で閾値を検証する手順を追加する。 | ⬜ 未対応 |
| RP-007 | 🟠 Major | E2E 5xx 再現性 | task08 の E2E-5 で floci Lambda を `docker compose stop` して 5xx 再現とあるが、動的 Lambda コンテナ / on-demand 実行では確実性がない。 | 確実な再現手段に置換する。推奨: Playwright `page.route()` で API 応答を 500 に書き換え、UI エラー表示を検証する。実 API 障害再現は別タスク/将来案に分離。 | ⬜ 未対応 |
| RP-008 | 🟠 Major | web-e2e 実行順 / API deployment | task10 web-e2e 手順に `apply-api-deployment.sh` / `warmup-lambdas.sh` の保証がなく、`invoke_url` 取得や API 応答が flaky になる。 | `deploy-local.sh` が内包するか明記し、`web-e2e` script に `apply-api-deployment.sh` と `warmup-lambdas.sh` を `deploy-local.sh` 後に組み込む。`build-frontend.sh` は `invoke_url` 取得失敗時 fail-fast。 | ⬜ 未対応 |
| RP-009 | 🟠 Major | task07 暗黙依存 | task07 は frontend build と dist path に依存するが前提に task01 がない。cherry-pick 順で単独失敗しうる。 | task07 の前提条件に task01 を追加し、依存グラフ・並列グループを更新する。 | ⬜ 未対応 |
| RP-010 | 🟠 Major | インフラTDD RED強度 | task02-02 の RED が `terraform validate` で always-pass に近く、失敗テストになっていない。 | `terraform plan -json + jq` 等で S3 / OPTIONS / `AWS_PROXY` / response headers の未定義を assertion する RED スクリプトを追加するか、OPTIONS IntegrationTest を task02-02 の RED 完了条件へ紐付ける。 | ⬜ 未対応 |
| RP-011 | 🟡 Minor | wait-floci script責務 | task07 注記で `wait-floci-healthy.sh` が曖昧だが、task10 は明確に呼び出す。 | task07 対象ファイル・完了条件に `scripts/wait-floci-healthy.sh` 新規追加を明記。未起動時 timeout exit 1 の RED も含める。 | ⬜ 未対応 |
| RP-012 | 🟡 Minor | UIエラー表示責務 | task06 が AppComponent 側の本体コード修正余地を残しており、テストタスクに実装責務が漏れている。 | config-error 表示の実装責務を task04 に移し、task06 はテスト追加のみとする。 | ⬜ 未対応 |
| RP-013 | 🟡 Minor | 見積もりバッファ | 見積もりにバッファがなく、task02-02 / task08 / task12 が過少。 | 20〜30% のバッファを明記し、該当タスクを増やす。 | ⬜ 未対応 |
| RP-014 | 🟡 Minor | fail-fast 検証順 | task12 の `AWS_ENDPOINT_URL` 空検証が `WEB_BASE_URL` 未設定で先に落ちる可能性。 | `WEB_BASE_URL=http://localhost:8080 AWS_ENDPOINT_URL= scripts/web-e2e.sh` で検証するよう修正。 | ⬜ 未対応 |
| RP-015 | 🟡 Minor | README検証強度 | README 見出し検証が `grep -F` だけで階層・順序を担保しない可能性。 | 既存見出し baseline と新規見出し位置・順序チェックを追加。 | ⬜ 未対応 |
| RP-016 | 🟡 Minor | コミットSHA特定 | task12 の dry-run revert 対象 SHA 特定方法が未定義。 | `git log --grep` 等で task02-01 コミットを特定する手順を追加。 | ⬜ 未対応 |
| RP-017 | 🟡 Minor | ESLint config形式 | task01 が Angular 18 で legacy `.eslintrc.json` を採用しており根拠不明。 | `eslint.config.js` flat config 採用へ変更、または legacy 採用理由を明記。推奨は flat config。 | ⬜ 未対応 |
| RP-018 | 🟡 Minor | demo spec削除保証 | task05 の `__demo__` 削除が後続統合で漏れる可能性。 | 完了条件に `test ! -d frontend/src/app/__demo__` を追加し、親エージェント検証ゲートにも含める。 | ⬜ 未対応 |

### 重大度別集計

| 重大度 | 件数 |
|--------|------|
| 🔴 Critical | 1 |
| 🟠 Major | 9 |
| 🟡 Minor | 8 |
| 🔵 Info | 0 |
| **合計** | **18** |

## 改善提案（優先度順）

1. **RP-001 (Critical)**: `check-test-env.sh` をジョブ別プロファイル化し、CI 成立を最優先で回復する。
2. **RP-002 / RP-008 / RP-009**: 配信成果物パス・E2E 実行順・暗黙依存を統一して、E2E 受入の再現性を担保する。
3. **RP-003 / RP-004**: 依存関係の正本を `task-list.md` に定め、parent-agent-prompt / 各 task との同期を強制する。
4. **RP-005 / RP-012**: 責務境界（APP_INITIALIZER / UIエラー表示）を再整理し、実装/テストの混在を解消する。
5. **RP-006 / RP-010 / RP-007**: TDD RED の実効性と coverage 閾値運用を最終形に統一し、暫定運用を排除する。
6. **RP-013〜RP-018**: バッファ・検証順・README 検証強度・SHA 特定・ESLint config・demo spec 削除保証を是正し、計画の堅牢性を上げる。

## 次のステップ

- ❌ **差し戻し**: plan スキルで全 18 件の指摘をタスク計画に反映し、round 2 として再レビューを実施する。
