# 実装可能性レビュー

## 1. 設計の詳細度

| 評価項目 | 判定 | コメント |
|----------|------|----------|
| 実装に必要な情報が十分か | ❌ | Terraform（**DR-006**）、IAM（**DR-009**）、Lambda 属性（**DR-010**）、API GW deployment（**DR-011**）、CI（**DR-007**）、docker-compose（**DR-008**）、補助スクリプト（**DR-014**）の具体度がいずれも不足。実装者が判断に迷う領域が広範。 |
| 曖昧な記述がないか | ❌ | **DR-002**: id 生成責務が API/SFN 間で曖昧。**DR-016**: var.endpoint と FLOCI_HOSTNAME の役割分担が曖昧。 |
| インターフェース定義の明確さ | ⚠️ | POST /todos のレスポンス DTO と SFN 入出力 DTO の整合（**DR-002**）が崩れている。 |
| データ構造定義の明確さ | ⚠️ | Todo.description の正規化（**DR-013**）が未定義で、UT/IT の期待値が一意に決まらない。 |

## 2. 制約との整合性

| 制約 | 整合性 | コメント |
|------|--------|----------|
| 実 AWS を使わない（AC7） | ❌ | **DR-001（Critical）**。fail-fast 化が必須。 |
| floci のみでデプロイ・テスト完結 | ⚠️ | **DR-008/DR-012/DR-016**: docker-compose 完成度、Runner privileged 前提、エンドポイント役割分担。 |
| GitLab CI で完結 | ⚠️ | **DR-007**: パイプライン定義スケルトンが必要。 |
| Terraform local tfstate 基本 | ⚠️ | tfstate 取扱い・後始末の明示が不足（**DR-007** と関連）。 |

## 3. 必要な追加情報（修正必須）

設計を実装可能にするため、以下を設計内に反映すること（再設計時の必須項目）：

1. **AWS_ENDPOINT_URL fail-fast**: 起動時必須環境変数として未設定なら例外で停止。`AmazonDynamoDBConfig.ServiceURL` と `AmazonStepFunctionsConfig.ServiceURL` の双方に明示適用。Lambda と Terraform provider の双方で実 AWS フォールバックを禁止。
2. **id 生成統一**: api-handler が `Guid.NewGuid().ToString()` で生成し、SFN 入力 DTO にも `id` を含める。ValidateTodo は受け取った Todo の検証のみに役割を限定。05_test-plan.md の IT 期待値も整合させる。
3. **Terraform provider 完全 HCL 例**: `aws ~> 6.0`、`endpoints { apigateway/lambda/dynamodb/stepfunctions/iam/sts = var.endpoint }`、`skip_credentials_validation = true`、`skip_metadata_api_check = true`、`skip_requesting_account_id = true`、`s3_use_path_style = true`。
4. **.gitlab-ci.yml スケルトン**: stages（lint/unit/integration/e2e）、image、services、variables、scripts、artifacts、after_script、DinD（または privileged Runner）方針、E2E は同一ジョブ内で `compose up → terraform apply → tests → terraform destroy → compose down` を完結。
5. **docker-compose.yml**: 公式 floci image、`4566:4566`、`FLOCI_HOSTNAME=floci`、`/var/run/docker.sock` マウント、`healthcheck`（curl で 4566 確認）。
6. **IAM 最小権限**: Lambda 実行ロール（DynamoDB GetItem/PutItem、StepFunctions StartExecution/DescribeExecution）、SFN 実行ロール（Lambda InvokeFunction）。`aws_iam_role_policy` で Resource を ARN 限定。
7. **Lambda 必須属性**: `role`、`memory_size = 512`、`timeout = 30`、`environment.variables = { AWS_ENDPOINT_URL, STATE_MACHINE_ARN, TABLE_NAME, AWS_DEFAULT_REGION }`、`source_code_hash = filebase64sha256(zip)`。
8. **API GW deployment**: `triggers = { redeploy = sha1(jsonencode([resources, methods, integrations])) }`、`depends_on = [...]`、`lifecycle { create_before_destroy = true }`。
9. **scripts/deploy-local.sh / scripts/e2e.sh**: package → terraform init/apply → tests → destroy の擬似コードを設計に追加し、CI と一致させる。
10. **Integration fixture**: xUnit fixture が AWSSDK.DynamoDBv2 `CreateTableAsync` を冪等実行する方式に固定（Terraform への依存を排除）。
11. **description 正規化**: `string.IsNullOrWhiteSpace(description) ? null : description.Trim()` を I/F 設計と DTO に明記し、対応 UT を追加。
12. **var.endpoint と FLOCI_HOSTNAME の役割分担表**: 「terraform output invoke_url は var.endpoint（host から floci を指す URL）」「floci 内部からの解決は FLOCI_HOSTNAME=floci」を明記し、CI 上で localhost が混入しない検証観点を追加。
13. **CRUD 範囲決定**: POST/GET 完結＋作成フロー検証へ再定義し、Update/Delete/List はスコープ外として OOS に追記、または設計拡張する。
14. **README 章構成（設計時固定）**: Overview/Prerequisites/Local Setup/floci Deploy/CI/Test/Debug/Troubleshooting/Known issues とレビュー観点を 05_test-plan.md と独立節で固定。

## 4. 結論

設計は方針レベルでは描けているが、**サンプル参照実装として必要な「具体 HCL/YAML/コード片」がほぼ全領域で欠落**しており、現状のままでは実装者が作業を開始できない。差し戻しが妥当。
