# レビューサマリー（round 2）

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | FRONTEND-001 |
| タスク名 | floci-apigateway-csharp に Angular フロントエンド追加（テスト・CI 含む） |
| レビューラウンド | 2 |
| 総合判定 | ⚠️ **条件付き承認 (conditional)** |
| タスク計画参照 | [../../plan/](../../plan/) |
| 設計結果参照 | [../../design/](../../design/) |
| 前ラウンドサマリー | [../06_review-summary.md](../06_review-summary.md) |

## 総合判定

**⚠️ 条件付き承認 (conditional)**

round 1 の 18 件（RP-001〜RP-018）は計画ドキュメントに反映され resolved。一方で round 2 では下記 7 件の新規指摘が残る。とくに RP2-001 は CI が成立しない Major であり、Minor を含む全件修正後に round 3 で再確認する。

## round 1 指摘の解決状況

RP-001〜RP-018 はすべて round 2 計画更新で **resolved**。詳細は [../06_review-summary.md](../06_review-summary.md) を参照。

## round 2 指摘事項一覧

| ID | 重大度 | カテゴリ | 指摘内容 | 対応方針 | 関連ファイル | 対応状況 |
|----|--------|----------|----------|----------|--------------|----------|
| RP2-001 | 🟠 Major | CI実行可能性 / check-test-env e2e プロファイル整合 | task10 の web-e2e before_script は docker/awscli のみを導入するが、task07 の check-test-env.sh e2e プロファイルは terraform/dotnet も必須としており、Playwright image には含まれないため CI が成立しない。 | task10 before_script に terraform 1.6.6 と dotnet-sdk-8.0 の導入手順を固定して追加するか、e2e プロファイルを分割する。推奨は導入手順を明記し、完了条件にも terraform/dotnet 利用可能確認を追加。 | docs/floci-apigateway-csharp/plan/task07.md, docs/floci-apigateway-csharp/plan/task10.md | ⬜ 未対応 |
| RP2-002 | 🟡 Minor | CI重複実行 / web-e2e フロー二重化 | task10 の web-e2e script が deploy-local/apply-api-deployment/warmup/build/deploy を直接呼んだ後に web-e2e.sh を呼ぶ一方、task07 の web-e2e.sh 自身も同一処理を実行するため二重実行になる。 | web-e2e.sh を唯一のエントリポイントにし、task10 script は check-test-env + compose up + web-e2e.sh のみに簡略化。重複呼び出し禁止を完了条件化。 | docs/floci-apigateway-csharp/plan/task07.md, docs/floci-apigateway-csharp/plan/task10.md | ⬜ 未対応 |
| RP2-003 | 🟡 Minor | TDD RED の cross-task 依存 | task02-02 の RED/完了条件が task09 の OPTIONS IntegrationTest に依存しており、task02-02 単独で検証できない。 | task02-02 の RED は tests/infra/test-frontend-plan.sh のみに集約し、task09 連動は task09 完了条件へ移す。 | docs/floci-apigateway-csharp/plan/task02-02.md, docs/floci-apigateway-csharp/plan/task09.md | ⬜ 未対応 |
| RP2-004 | 🟡 Minor | task05 GREEN 判定 / coverage | task05 は __demo__ spec を作って削除しつつ coverage 最終閾値を強制するため、単独 GREEN 判定が曖昧。ng test --dry-run 相当も正式手段でない。 | task05 の GREEN 判定を明示化する。推奨: task05 内では karma config と npm scripts の構成検証に限定し、実 npm run test:unit は後続統合ゲートで実行する旨を明記。 | docs/floci-apigateway-csharp/plan/task05.md | ⬜ 未対応 |
| RP2-005 | 🟡 Minor | terraform plan-json パース堅牢性 | task02-02 の jq クエリが Terraform 1.6.6 schema とズレた fallback を含み、false negative/可読性低下のリスクがある。 | Terraform 1.6.6 の plan -json schema に合わせ `.change.resource.addr` のみに統一し、期待件数と未マッチ件数を明示出力する。 | docs/floci-apigateway-csharp/plan/task02-02.md | ⬜ 未対応 |
| RP2-006 | 🟡 Minor | 設計-計画整合性 / E2E 5xx | plan は E2E-5 を page.route() 方針に変更したが、design 側に docker compose stop 方式が残っている。 | design 側も page.route() 方針に統一し、停止方式を却下案として明記する。 | docs/floci-apigateway-csharp/design/05_test-plan.md | ⬜ 未対応 |
| RP2-007 | 🟡 Minor | 設計-計画整合性 / web-e2e順序 | plan は deploy-local 後に apply-api-deployment/warmup を必須化したが、design の DinD 手順に未反映。 | design の web-e2e 手順を task07/task10 と同順序に更新する。 | docs/floci-apigateway-csharp/design/02_interface-api-design.md | ⬜ 未対応 |

### 重大度別集計（round 2 新規）

| 重大度 | 件数 |
|--------|------|
| 🔴 Critical | 0 |
| 🟠 Major | 1 |
| 🟡 Minor | 6 |
| 🔵 Info | 0 |
| **合計** | **7** |

## 判定理由

round1 の 18 件は解消されたが、e2e プロファイルと CI 提供ツール不一致の Major、および web-e2e 二重実行、cross-task RED 依存、coverage 判定、jq schema、設計-計画整合の Minor が残る。ゼロトレランス方針により conditional とし、RP2-001〜RP2-007 修正後に round 3 で再確認する。

## 次のステップ

- ⚠️ **条件付き承認**: plan スキルで全 7 件（RP2-001〜RP2-007）の指摘をタスク計画／設計ドキュメントに反映し、round 3 として再レビューを実施する。
