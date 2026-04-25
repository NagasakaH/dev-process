# 要件カバレッジレビュー

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | floci-apigateway-csharp-001 |
| タスク名 | API Gateway + Lambda(.NET) + Step Functions サンプルアプリと CI/CD 基盤の構築 |
| レビュー日 | 2026-04-25 |
| レビュー者 | review-design スキル（round 1） |
| 設計結果参照 | [design/](../design/) |
| 調査結果参照 | [investigation/](../investigation/) |

---

## 1. 機能要件の対応

| No | 機能要件 | 設計での対応箇所 | カバー状況 | 備考 |
|----|----------|------------------|------------|------|
| FR-1 | Todo API のサンプル（CRUD 中心、Step Functions は簡易フロー） | 02_interface-api-design.md（POST /todos, GET /todos/{id}）／04_process-flow-design.md | ⚠️ 部分カバー | **DR-003**: Update/Delete/List の扱いと除外根拠が未記載。「CRUD 中心」要件に対し POST/GET のみで論拠不足。 |
| FR-2 | .NET 8 Lambda を実装し API Gateway から呼び出せる構成 | 01_implementation-approach.md／02_interface-api-design.md | ✅ カバー | API GW REST v1 + APIGatewayProxyRequest/Response 採用。 |
| FR-3 | Step Functions ステートマシンを Terraform で定義し Lambda と連携 | 02_interface-api-design.md／04_process-flow-design.md | ⚠️ 部分カバー | **DR-005**: Retry 記述と ASL 例が不整合。**DR-002**: id 生成責務が API/SFN 間で矛盾。 |
| FR-4 | Terraform で API Gateway, Lambda, Step Functions, IAM を定義 | 01_implementation-approach.md／02_interface-api-design.md | ⚠️ 部分カバー | **DR-006**: provider HCL 不足。**DR-009**: IAM 最小権限ポリシー未定義。**DR-010**: Lambda 必須属性不足。**DR-011**: API GW deployment trigger/lifecycle 未定義。 |
| FR-5 | GitLab CI で xUnit 単体テストを実行 | 05_test-plan.md | ⚠️ 部分カバー | **DR-007**: .gitlab-ci.yml の stages/jobs 具体定義が不足。 |
| FR-6 | GitLab CI で Lambda ハンドラ/関数レベルのテストを実行 | 05_test-plan.md | ⚠️ 部分カバー | **DR-007** に同じ。**DR-015**: integration fixture のテーブル準備方式が二択で未確定。 |
| FR-7 | GitLab CI で floci を使い API Gateway 経由の E2E を実行 | 05_test-plan.md／06_side-effect-verification.md | ⚠️ 部分カバー | **DR-008**: docker-compose.yml 具体定義不足。**DR-012**: privileged Runner 前提が未確定。 |
| FR-8 | README にローカル実行/CI/Terraform/テスト/デバッグ方法を記載 | 05_test-plan.md（実装フェーズ担保言及） | ❌ 未カバー | **DR-004**: 設計時点で README 章構成・必須記載項目・検証方法が未定義。 |

## 2. 非機能要件の対応

| No | 非機能要件 | 設計での対応箇所 | カバー状況 | 備考 |
|----|------------|------------------|------------|------|
| NFR-1 | 最小構成・サンプルとして読みやすい構成 | 00_design-overview.md／01_implementation-approach.md | ✅ カバー | 2ステート最小フロー、ZIP パッケージ採用。 |
| NFR-2 | 実 AWS 資格情報なしで主要テストを実行可能 | 02_interface-api-design.md／05_test-plan.md | ❌ 未カバー | **DR-001**: AWS_ENDPOINT_URL 未設定時に実 AWS にフォールバックし得る設計。fail-fast 化が必要。 |
| NFR-3 | Terraform state はローカル tfstate 基本、GitLab managed は補足 | 01_implementation-approach.md | ⚠️ 部分カバー | README 補足の具体記載要件（DR-004）と連動して未定義。 |
| NFR-4 | .NET 8 と Terraform の一般的な開発フローに沿う | 01_implementation-approach.md | ✅ カバー | dotnet format、terraform fmt/validate を CI に組み込む方針あり。 |

## 3. 受入基準（AC）の対応

| AC | 受入基準 | 設計での対応 | カバー状況 | 備考 |
|----|----------|--------------|------------|------|
| AC1 | Todo API の .NET 8 Lambda 実装が含まれる | 01_implementation-approach.md / 02_interface-api-design.md | ✅ カバー | |
| AC2 | Terraform で API GW/Lambda/SFN を floci 上にデプロイできる | 02_interface-api-design.md | ⚠️ 部分カバー | DR-006/009/010/011 の具体性不足。 |
| AC3 | GitLab CI で xUnit 単体テストが実行される | 05_test-plan.md | ⚠️ 部分カバー | DR-007。 |
| AC4 | GitLab CI で Lambda ハンドラ/関数レベルテストが実行される | 05_test-plan.md | ⚠️ 部分カバー | DR-007/DR-015。 |
| AC5 | GitLab CI で floci を使った API GW 経由 E2E が実行される | 05_test-plan.md / 06_side-effect-verification.md | ⚠️ 部分カバー | DR-007/DR-008/DR-012。 |
| AC6 | README にセットアップ/ローカル/Terraform/CI/テスト/デバッグが記載 | 05_test-plan.md（実装担保） | ❌ 未カバー | DR-004。 |
| AC7 | 実 AWS を使わず floci のみでデプロイ・テストが完結 | 02_interface-api-design.md / 06_side-effect-verification.md | ❌ 未カバー | **DR-001（Critical）**: 設計上 fail-fast が保証されない。**DR-016**: var.endpoint と FLOCI_HOSTNAME の役割分担が曖昧。 |

## 4. カバレッジサマリー

- 機能要件カバレッジ: 1/8 完全カバー、6/8 部分カバー、1/8 未カバー
- 非機能要件カバレッジ: 2/4 完全カバー、1/4 部分カバー、1/4 未カバー
- 受入基準カバレッジ: 1/7 完全カバー、4/7 部分カバー、2/7 未カバー（うち AC7 は Critical 違反）

**結論**: AC 対応表自体は存在するが、AC7（実 AWS 不使用）を破る Critical 違反、AC6（README 設計時定義）の未カバーが致命的。CRUD 範囲（FR-1）の論拠も不足しており、要件カバレッジは差し戻しレベル。
