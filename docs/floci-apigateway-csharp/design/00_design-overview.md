# 設計概要

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | floci-apigateway-csharp-001 |
| タスク名 | API Gateway + Lambda(.NET) + Step Functions サンプルアプリと CI/CD 基盤の構築 |
| 作成日 | 2026-04-25 |
| 作成者 | dev-workflow |
| 調査結果参照 | [investigation/](../investigation/) |

---

## 1. 目的

`floci-apigateway-csharp` リポジトリにおいて、実 AWS を一切使用せず **floci ローカルエミュレータ** 上で
API Gateway (REST v1) + .NET 8 Lambda (ZIP) + Step Functions + DynamoDB の
最小 Todo API サンプルを構築するための詳細設計を定義する。

成果物として以下を網羅する。

- 実装方針（採用アーキテクチャ・代替案比較・トレードオフ）
- インターフェース/API 設計（HTTP API・Lambda ハンドラ・C# DTO・Step Functions ASL）
- データ構造設計（DynamoDB スキーマ・C# モデル・データフロー）
- 処理フロー設計（POST/GET シーケンス・状態遷移・エラーフロー）
- テスト計画（xUnit 単体 / Lambda 結合 / GitLab CI 上の floci E2E）
- 弊害検証計画（コールドスタート・floci 固有挙動・リスク緩和）

---

## 2. 調査結果サマリー

### 2.1 アーキテクチャ概要

サーバーレス3層（API Gateway → Lambda → DynamoDB）に Step Functions オーケストレーション層を加えた構成。
新規リポジトリのため、`src/TodoApi.Lambda`、`tests/{Unit,Integration,E2E}Tests`、`infra`、`compose`、
`scripts`、`.gitlab-ci.yml` を新規作成する（investigation 01）。

### 2.2 データ構造概要

DynamoDB シングルテーブル `Todos`（PK: `id`、`PAY_PER_REQUEST`、GSI なし）。
DTO は `Todo` / `CreateTodoRequest` / `ValidateTodoInput` / `ValidateTodoOutput` / `PersistTodoOutput`。
Step Functions ASL は `ValidateTodo → Choice → PersistTodo / Fail`（investigation 02）。

### 2.3 依存関係概要

NuGet: `Amazon.Lambda.Core`, `Amazon.Lambda.APIGatewayEvents`, `Amazon.Lambda.Serialization.SystemTextJson`,
`AWSSDK.DynamoDBv2 ~>4`, `AWSSDK.StepFunctions ~>4`、テストは `xunit` + `Amazon.Lambda.TestUtilities`。
Terraform は `hashicorp/aws ~> 6.0`、CLI は `dotnet 8` + `Amazon.Lambda.Tools` + `terraform 1.6+` + `docker compose`
（investigation 03）。

### 2.4 既存パターン概要

- .NET 8: `Nullable`/`ImplicitUsings` 有効、`dotnet format` 強制、Microsoft 命名規則。
- Terraform: `terraform fmt`/`validate`、リソース名 snake_case、`provider.tf`/`variables.tf`/`outputs.tf` 分離。
- DI フレームワーク不採用（コンストラクタ2系統）、`AWS_ENDPOINT_URL` 経由で floci 接続（investigation 04）。

### 2.5 統合ポイント概要

すべての AWS 呼び出しは `http://localhost:4566`（CI 内は `http://floci:4566`）に集約。
API Gateway invoke URL は floci 固有形式 `/restapis/{id}/{stage}/_user_request_/...` を使用し、
Terraform output で完全 URL を E2E に渡す（investigation 05）。

### 2.6 リスク・制約概要

主要リスク: ①Docker socket / DinD、②`FLOCI_HOSTNAME` 漏れによる URL 不到達、
③invoke URL 形式差、④Step Functions polling、⑤.NET 8 Lambda コールドスタート。
各リスクへの軽減策は本設計および §06_side-effect-verification に組み込み済み（investigation 06）。

---

## 3. 設計内容

詳細は以下の各ドキュメントに分割して記述する。

| 区分 | ドキュメント |
|------|--------------|
| 1. 実装方針 | [01_implementation-approach.md](./01_implementation-approach.md) |
| 2. インターフェース/API 設計 | [02_interface-api-design.md](./02_interface-api-design.md) |
| 3. データ構造設計 | [03_data-structure-design.md](./03_data-structure-design.md) |
| 4. 処理フロー設計 | [04_process-flow-design.md](./04_process-flow-design.md) |
| 5. テスト計画 | [05_test-plan.md](./05_test-plan.md) |
| 6. 弊害検証計画 | [06_side-effect-verification.md](./06_side-effect-verification.md) |

---

## 4. 受入基準対応表（Acceptance Criteria Traceability）

`setup.description.acceptance_criteria` と本設計の対応関係。検証手段（単体/結合/E2E）を明示する。

| # | acceptance_criteria | 設計参照 | 検証手段 | 主たるテストID |
|---|--------------------|----------|----------|----------------|
| AC1 | 作成先リポジトリに Todo API サンプルの .NET 8 Lambda 実装が含まれている | 01 §1, 02 §2-§3 | 単体 + 結合 | UT-1〜UT-5, IT-1〜IT-3 |
| AC2 | Terraform で API Gateway、Lambda、Step Functions のサンプル構成を floci 上にデプロイできる | 01 §1.2, 03 §2, 04 §1.2 | E2E（前段の `terraform apply`） | E2E-PRE-1（apply 成功）, E2E-1 |
| AC3 | GitLab CI で xUnit 単体テストが実行される | 05 §1.1, §7.2 | 単体 | UT-* 全件（CI `unit` ジョブ） |
| AC4 | GitLab CI で Lambda ハンドラ/関数レベルのテストが実行される | 05 §1.1, §7.2 | 結合 | IT-* 全件（CI `integration` ジョブ） |
| AC5 | GitLab CI で floci を使った API Gateway 経由の E2E テストが実行される | 05 §1.1, §7.2, 06 §3 | E2E | E2E-1, E2E-2, E2E-3 |
| AC6 | README にセットアップ、ローカル実行、Terraform による floci デプロイ、CI、テスト、デバッグ方法が記載されている | 01 §1.3 | 単体（README 存在チェックは実装タスクで担保） | ドキュメント検証（implement 段階） |
| AC7 | 実 AWS を使わず、floci のみでデプロイとテストが完結する構成になっている | 01 §1.2, 03 §1, 04 §1.2, 06 §1, §5 | E2E + 弊害検証 | E2E-1〜E2E-3（実 AWS 資格不使用）+ 06 §5.3 |

> **検証手段の凡例**
> - **単体**: `tests/TodoApi.UnitTests/`（純粋ロジック、floci 不要）
> - **結合**: `tests/TodoApi.IntegrationTests/`（`Amazon.Lambda.TestUtilities` + floci）
> - **E2E**: `tests/TodoApi.E2ETests/`（GitLab CI で `docker compose up floci` + `terraform apply` 後に `HttpClient` で API Gateway 経由）

---

## 5. 参考資料

- [調査結果ディレクトリ](../investigation/)
- [project.yaml](../../../project.yaml)
- [setup.yaml](../../../setup.yaml)

---

## 完了条件

| カテゴリ | 完了条件 |
|----------|----------|
| 実装レビュー完了 | 全設計ドキュメントが review-design スキルで承認され、未解決の `status: open` 指摘がない |
| テスト完了 | 単体 (UT-*)・結合 (IT-*)・E2E (E2E-*) が GitLab CI で全件成功し、AC1〜AC7 対応テストが PASS |
| 弊害検証完了 | 06_side-effect-verification の §1〜§6 全項目を確認し、リスクマトリクスの「要対応」象限が全て軽減策適用済 |

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-04-25 | 1.0 | 初版作成 | dev-workflow |
