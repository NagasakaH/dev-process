# レビューサマリー（round 1）

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | floci-apigateway-csharp-001 |
| タスク名 | API Gateway + Lambda(.NET) + Step Functions サンプルアプリと CI/CD 基盤の構築 |
| レビュー日 | 2026-04-25 |
| レビュー者 | review-design スキル |
| ラウンド | 1 |
| 設計結果参照 | [design/](../design/) |
| 調査結果参照 | [investigation/](../investigation/) |

---

## 総合判定: ❌ 差し戻し（rejected）

Critical 指摘が 2 件、Major が 9 件、Minor が 5 件。AC7（実 AWS 不使用）を直接破る Critical 違反と、API/SFN 間の id 生成責務の論理矛盾が存在し、実装計画フェーズに進む前に設計修正が必須。

## 指摘件数サマリー

- 🔴 Critical: 2 件（DR-001, DR-002）
- 🟠 Major: 9 件（DR-003〜DR-011）
- 🟡 Minor: 5 件（DR-012〜DR-016）
- 🔵 Info: 0 件

合計: **16 件**（全件 status=open）。Minor 含め **全件修正必須**。

## 指摘事項一覧

| No | 重大度 | カテゴリ | 指摘内容 | 関連ファイル | 対応方針 | 状態 |
|----|--------|----------|----------|--------------|----------|------|
| DR-001 | 🔴 Critical | AC7/実AWS不使用整合性 | AWS_ENDPOINT_URL 未設定時にデフォルト AWS エンドポイントへ接続し得る設計があり、floci 完結要件に違反する。 | 02_interface-api-design.md | 未設定は起動エラーにし、実 AWS 向きフォールバックを禁止。Lambda/Terraform provider の双方で fail-fast 化。 | ⬜ 未対応 |
| DR-002 | 🔴 Critical | 設計の論理矛盾/API-SFN間のID生成責務 | POST /todos は StartExecution 直後に id を返すが、id 生成が ValidateTodo Lambda 側に見える記述と矛盾しており、E2E POST→GET 前提が崩れる。 | 02_interface-api-design.md / 03_data-structure-design.md / 04_process-flow-design.md / 05_test-plan.md | id 生成は api-handler に統一、ValidateTodo は検証のみ。DTO/シーケンス/IT 期待値を統一する。 | ⬜ 未対応 |
| DR-003 | 🟠 Major | 要件カバレッジ/CRUD範囲 | 「CRUD を中心」要件に対し POST/GET のみで Update/Delete/List の扱いと除外根拠が不足。 | setup.yaml / docs/floci-apigateway-csharp/design/ | API 範囲を POST/GET + 作成フロー検証に再定義し、Update/Delete/List はスコープ外明記または設計追加。 | ⬜ 未対応 |
| DR-004 | 🟠 Major | README要件/AC6 | README 要件が実装段階での担保のみで、設計時点での章構成・必須記載項目・検証方法が未定義。 | 05_test-plan.md | Overview/Prerequisites/Local Setup/floci Deploy/CI/Test/Debug/Troubleshooting/Known issues とレビュー観点を設計に固定。 | ⬜ 未対応 |
| DR-005 | 🟠 Major | 技術的妥当性/ASL Retry整合性 | PersistTodo の Retry を前提にした記述と ASL 定義例（Retry 節なし）が矛盾。 | 02_interface-api-design.md / 04_process-flow-design.md | ASL に Retry を明記、または Retry を将来拡張へ降格して全設計を統一。 | ⬜ 未対応 |
| DR-006 | 🟠 Major | Terraform provider設定 | provider.tf の具体的 HCL（endpoints/skip_*/s3_use_path_style 等）が不足し、実 AWS 問い合わせ抑止証跡が弱い。 | 01_implementation-approach.md / 02_interface-api-design.md | aws ~> 6.0 と必要 endpoints を var.endpoint に向ける完全 HCL 例を追加。 | ⬜ 未対応 |
| DR-007 | 🟠 Major | GitLab CI具体定義 | .gitlab-ci.yml の stages/jobs/image/services/variables/scripts/artifacts/after_script/DinD/tfstate 方針が未定義。 | 01_implementation-approach.md / 04_process-flow-design.md / 05_test-plan.md | CI YAML スケルトンを設計に追加し、E2E は同一ジョブ内で floci 起動→package→apply→tests→destroy が完結する方針を固定。 | ⬜ 未対応 |
| DR-008 | 🟠 Major | docker-compose具体定義 | compose/docker-compose.yml の image/ports/environment/FLOCI_HOSTNAME/volumes/healthcheck が未定義。 | 01_implementation-approach.md / 05_test-plan.md | floci 公式 image、4566 公開、FLOCI_HOSTNAME=floci、docker socket、healthcheck を含む YAML 例を追加。 | ⬜ 未対応 |
| DR-009 | 🟠 Major | IAMポリシー | Lambda/SFN に必要な DynamoDB / StepFunctions / Lambda Invoke の最小権限ポリシーが未定義。 | 02_interface-api-design.md | aws_iam_role_policy / aws_iam_policy で必要 Action/Resource を具体化。 | ⬜ 未対応 |
| DR-010 | 🟠 Major | Lambda設定属性 | role/memory_size/timeout/environment/source_code_hash が不足し、設計内 timeout=30s と Terraform 表が不整合。 | 02_interface-api-design.md | role、memory_size、timeout=30、AWS_ENDPOINT_URL、STATE_MACHINE_ARN、TABLE_NAME、AWS_DEFAULT_REGION、source_code_hash を追加。 | ⬜ 未対応 |
| DR-011 | 🟠 Major | API Gateway deployment | Method/Integration 変更時の再デプロイトリガーと create_before_destroy が未定義。 | 02_interface-api-design.md | aws_api_gateway_deployment.dev に triggers、depends_on、lifecycle create_before_destroy を明記。 | ⬜ 未対応 |
| DR-012 | 🟡 Minor | CI前提/Runner | GitLab Runner privileged 前提が未確定のままで AC5 実現性にリスク。 | 05_test-plan.md / 06_side-effect-verification.md | privileged Docker executor を推奨前提として明記、不可時は shell executor + docker compose の代替手順で同等 AC を満たす方針を固定。 | ⬜ 未対応 |
| DR-013 | 🟡 Minor | description正規化 | description 空文字の扱いが未定義。 | 02_interface-api-design.md / 03_data-structure-design.md | `string.IsNullOrWhiteSpace ? null : description.Trim()` 等の正規化を明記し UT を追加。 | ⬜ 未対応 |
| DR-014 | 🟡 Minor | 補助スクリプト | scripts/deploy-local.sh / scripts/e2e.sh の内容が未定義。 | 01_implementation-approach.md / 05_test-plan.md | package→terraform init/apply→test→destroy の擬似コードを追加し CI 手順と一致させる。 | ⬜ 未対応 |
| DR-015 | 🟡 Minor | Integration fixture | Integration テストの DynamoDB テーブルセットアップ方法が Terraform / AWS CLI 二択で未確定。 | 05_test-plan.md | xUnit fixture が AWSSDK.DynamoDBv2 CreateTableAsync を冪等実行する方式に固定。 | ⬜ 未対応 |
| DR-016 | 🟡 Minor | API Gateway invoke URL/FLOCI_HOSTNAME | var.endpoint と FLOCI_HOSTNAME の役割分担が不明確で、CI で localhost 混入リスクの検証観点が不足。 | 02_interface-api-design.md / 06_side-effect-verification.md | 役割分担表を追加し、output invoke_url=var.endpoint、内部解決=FLOCI_HOSTNAME を明記。CI に混入検出 assertion を追加。 | ⬜ 未対応 |

## 判定理由

- AC 対応表は存在するが、**AC7（実 AWS 不使用）を破る可能性**（DR-001）が設計上残存しており、設計レベルで担保できていない。
- **API / Step Functions 間の id 生成責務の矛盾**（DR-002）により、I/F・データ構造・処理フロー・テスト計画間の整合性が破綻している。
- Terraform（DR-006/009/010/011）、CI（DR-007）、docker-compose（DR-008）、補助スクリプト（DR-014）など、サンプル参照実装として必須となる「具体的構成片」が広範に欠落しており、実装計画フェーズに進める状態にない。

以上より、Critical 指摘の存在を理由に **総合判定は ❌ 差し戻し（rejected）** とする。

## 改善提案（再設計の優先順）

1. AC7 の fail-fast 化（DR-001）を最優先で設計に反映する。
2. id 生成責務を api-handler に統一（DR-002）し、I/F・DTO・シーケンス・IT/E2E 期待値を整合させる。
3. CRUD 範囲（DR-003）を POST/GET + 作成フロー検証へ確定し、Update/Delete/List の扱いを設計内に明記する。
4. Terraform / IAM / Lambda / API GW deployment / .gitlab-ci.yml / docker-compose の **具体 HCL/YAML スケルトン** を設計に組み込む（DR-006〜DR-011）。
5. README 章構成（DR-004）と補助スクリプト（DR-014）を設計時点で確定させ、テスト計画と齟齬がないようにする。
6. Minor 指摘（DR-012〜DR-016）も **全件修正必須**。Runner 前提・description 正規化・fixture 方式・エンドポイント役割分担を確定する。

## 次のステップ

- ❌ 差し戻し: design スキルで再設計を実施 → round 2 で再レビュー。
- 再レビュー時は全 16 件の指摘について `status: resolved` または明示的な `deferred`（ユーザー承認必須）を付与すること。
