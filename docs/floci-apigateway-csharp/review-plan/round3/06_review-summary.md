# レビューサマリー（round 3）

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | FRONTEND-001 |
| タスク名 | floci-apigateway-csharp に Angular フロントエンド追加（テスト・CI 含む） |
| レビューラウンド | 3 |
| 総合判定 | ⚠️ **条件付き承認 (conditional)** |
| タスク計画参照 | [../../plan/](../../plan/) |
| 設計結果参照 | [../../design/](../../design/) |
| 前ラウンドサマリー | [../round2/06_review-summary.md](../round2/06_review-summary.md) |

## 総合判定

**⚠️ 条件付き承認 (conditional)**

round 2 の RP2-001〜RP2-006 は計画／設計ドキュメントに反映され resolved。RP2-007 は design/02 側では resolved だが design/05 のコードブロックに不整合が残ったため、round 3 で新規 ID **RP3-001** として再指摘した。さらに CI 手順記述の整合性に関する Minor 指摘 **RP3-002** を新規検出。Major 1 件 + Minor 1 件のため conditional とし、修正後 round 4 で再確認する。

## round 2 指摘の解決状況

| ID | 重大度 | 概要 | round 3 状況 | 備考 |
|----|--------|------|--------------|------|
| RP2-001 | 🟠 Major | check-test-env e2e プロファイルと CI 提供ツールの不整合 | ✅ resolved | task07/task10 の e2e プロファイル・before_script に terraform 1.6.6 / dotnet-sdk-8.0 導入が反映済み |
| RP2-002 | 🟡 Minor | web-e2e フロー二重化 | ✅ resolved | task07/task10/design02 で web-e2e.sh を唯一エントリポイント化 |
| RP2-003 | 🟡 Minor | task02-02 RED が task09 OPTIONS IntegrationTest に依存 | ✅ resolved | RED が tests/infra/test-frontend-plan.sh のみに集約 |
| RP2-004 | 🟡 Minor | task05 GREEN 判定 / coverage の曖昧性 | ✅ resolved | task05 を karma config + npm scripts 構成検証に限定し、unit 実行は後続統合ゲートへ移譲 |
| RP2-005 | 🟡 Minor | terraform plan-json jq クエリ堅牢性 | ✅ resolved | `.change.resource.addr` 統一・期待件数 / 未マッチ件数の明示出力を反映 |
| RP2-006 | 🟡 Minor | E2E-5 設計-計画整合性（page.route() 統一） | ✅ resolved | design/05 で page.route() 方針へ統一、停止方式は却下案として記載 |
| RP2-007 | 🟡 Minor | web-e2e順序の設計-計画整合性 | ⚠️ partial | design/02 のフロー記述は更新済み。ただし design/05 §2.3 のコードブロックに旧手順が残るため、**RP3-001** として再指摘 |

> 註: RP2-007 そのものは design/02 で resolved とし、design/05 に残る不整合は新規 ID **RP3-001** として独立トラッキングする（指摘範囲・対象ファイルが異なるため）。

## round 3 指摘事項一覧

| ID | 重大度 | カテゴリ | 指摘内容 | 対応方針 | 関連ファイル | 対応状況 |
|----|--------|----------|----------|----------|--------------|----------|
| RP3-001 | 🟠 Major | 設計-計画整合性 / web-e2e実行順 | design/05_test-plan.md §2.3 の E2E 実行手順が、wait-floci-healthy/deploy-local/apply-api-deployment/warmup/build/deploy を個別実行した後に web-e2e.sh を呼ぶ構成になっている。一方 task07/design02/task10 では web-e2e.sh が同処理を内部実行する唯一エントリポイントであり、design05 の手順は二重実行と解釈分岐を招く。 | design05 §2.3 を `docker compose up -d floci nginx` → `bash scripts/web-e2e.sh` → `docker compose down -v` の3行のみへ修正し、wait/deploy/apply/warmup/build/deploy は web-e2e.sh の内部処理として別表/コメントに移す。 | docs/floci-apigateway-csharp/design/05_test-plan.md | ⬜ 未対応 |
| RP3-002 | 🟡 Minor | CI手順記述の整合性 / check-test-env重複 | task10 は web-e2e script を check-test-env + compose up + web-e2e.sh の3行とする一方、design02 は compose up + web-e2e.sh の2行。さらに before_script と web-e2e.sh 内部でも check-test-env が呼ばれる可能性があり、手順が揺れている。 | check-test-env の呼び出し位置を before_script のみに固定し、script は compose up + web-e2e.sh の2行に統一する。web-e2e.sh 内部での check-test-env はローカル実行保証用に残すなら意図を明記、またはCIでは SKIP_ENV_CHECK=1 等で二重チェックを避ける設計を記載。 | docs/floci-apigateway-csharp/plan/task10.md, docs/floci-apigateway-csharp/design/02_interface-api-design.md, docs/floci-apigateway-csharp/plan/task07.md | ⬜ 未対応 |

### 重大度別集計（round 3 新規）

| 重大度 | 件数 |
|--------|------|
| 🔴 Critical | 0 |
| 🟠 Major | 1 |
| 🟡 Minor | 1 |
| 🔵 Info | 0 |
| **合計** | **2** |

## 判定理由

RP2 の大半は解消済みだが、`web-e2e.sh` を唯一エントリポイントにする方針が design/05 と task07 / task10 / design/02 間でまだ不一致。さらに check-test-env 呼び出し位置にも揺れがあり、CI 手順が二通りに解釈され得る。ゼロトレランス方針により Major / Minor を修正後、round 4 で再確認する。

## 次のステップ

- ⚠️ **条件付き承認**: plan / design スキルで全 2 件（RP3-001, RP3-002）の指摘をタスク計画／設計ドキュメントに反映し、round 4 として再レビューを実施する。
