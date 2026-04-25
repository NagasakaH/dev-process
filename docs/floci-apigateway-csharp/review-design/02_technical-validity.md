# 技術的妥当性レビュー

## 1. アーキテクチャ選定

| 評価項目 | 判定 | コメント |
|----------|------|----------|
| 要件に対して適切なパターンか | ⚠️ | API GW REST v1 + Lambda(.NET 8) + SFN + DynamoDB はサンプル目的に適切。ただし **DR-002**: POST→SFN(StartExecution) と id 返却の責務が API/SFN 間で矛盾しており論理整合性が破綻。 |
| 既存アーキテクチャとの整合性 | ⚠️ | floci 互換 provider 設定（**DR-006**）と FLOCI_HOSTNAME の扱い（**DR-016**）が曖昧。投資調査結果との整合性も部分的。 |
| スケーラビリティの考慮 | ✅ | サンプル範囲では問題なし。 |
| 拡張性の考慮 | 🔵 | Update/Delete/List の拡張余地（**DR-003**）が示されておらず、設計意図が読み取りにくい。 |

## 2. 技術選定

| 技術 | 選定理由 | 妥当性 | 代替案の検討 |
|------|----------|--------|-------------|
| API Gateway REST v1 | APIGatewayProxyRequest 利用しやすい | ✅ | HTTP API 比較言及あり。 |
| .NET 8 Lambda（ZIP） | dotnet lambda package との親和性 | ✅ | コンテナ Lambda は将来拡張。 |
| Step Functions Standard | サンプルでフロー検証目的 | ⚠️ | **DR-005**: Retry 記述と ASL 例が不整合。 |
| DynamoDB | floci で AWS SDK 検証しやすい | ✅ | RDB 系は対象外で妥当。 |
| Terraform AWS provider | floci 接続前提 | ⚠️ | **DR-006**: endpoints/skip_*/s3_use_path_style 等の具体 HCL 不足。 |
| docker compose で floci 起動 | CI 内完結 | ⚠️ | **DR-008**: image/ports/volumes/healthcheck 未定義。 |

## 3. セキュリティ／責務境界

| 評価項目 | 判定 | コメント |
|----------|------|----------|
| 認証・認可の考慮 | ✅ | サンプル要件のためスコープ外明記済み。 |
| 入力値検証 | ⚠️ | **DR-013**: description 空文字の正規化が未定義。**DR-002**: id 検証/生成責務が二重化のリスク。 |
| 最小権限原則 | ❌ | **DR-009**: Lambda/SFN の DynamoDB/StepFunctions/Lambda Invoke の必要 Action/Resource が未定義。 |
| 実 AWS 接続防止 | ❌ | **DR-001（Critical）**: AWS_ENDPOINT_URL 未設定時にデフォルト AWS へ接続し得る。fail-fast 設計が必要。 |

## 4. 整合性チェック

- **DR-002（Critical）**: POST /todos の id 生成は api-handler に統一すべきだが、ValidateTodo 側で生成する記述があり DTO・シーケンス・IT 期待値が分裂している。
- **DR-005（Major）**: PersistTodo の Retry を前提とする記述と ASL 定義例（Retry 節なし）の不整合。
- **DR-010（Major）**: Lambda timeout=30s 表記と Terraform 表（role/memory_size/environment/source_code_hash）の不整合・欠落。
- **DR-011（Major）**: aws_api_gateway_deployment.dev に triggers/depends_on/lifecycle create_before_destroy が無く、Method/Integration 変更時の再デプロイが失敗するリスク。

## 5. 総評

技術スタック選定自体は妥当だが、**Critical な AC7 違反（DR-001）と論理矛盾（DR-002）が存在**し、Major レベルでも Terraform/IAM/Lambda/API GW deployment の具体性が複数欠けている。実装計画策定前に必ず修正が必要。
