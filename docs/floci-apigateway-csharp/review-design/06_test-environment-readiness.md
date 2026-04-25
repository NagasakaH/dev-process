# テスト環境準備状況

## 1. 必要リソース一覧

| # | リソース | 必要性 | 状態 | 備考 |
|---|----------|--------|------|------|
| 1 | .NET 8 SDK | 必須 | ⚠️ 要確認 | dev container には用意されている想定。実装フェーズで `dotnet --version` で要確認。 |
| 2 | Terraform CLI（aws provider ~> 6.0） | 必須 | ⚠️ 要確認 | dev container 同上。`terraform -version` で確認。 |
| 3 | Docker / docker compose | 必須 | ⚠️ 要確認 | floci 起動に必須。Docker daemon の起動可否、CI Runner の privileged 前提（**DR-012**）の確認が必要。 |
| 4 | floci 公式コンテナイメージ | 必須 | ❌ 設計未確定 | **DR-008**: image 名/tag が設計に未明記。投資調査結果と整合させる必要あり。 |
| 5 | xUnit + Amazon.Lambda.TestUtilities | 必須 | ⚠️ 要確認 | 実装時に NuGet 解決可能であること。 |
| 6 | AWSSDK.DynamoDBv2 / AWSSDK.StepFunctions | 必須 | ⚠️ 要確認 | 同上。 |
| 7 | GitLab Runner（privileged 推奨） | 必須 | ❌ 設計未確定 | **DR-012**: 前提が未確定。privileged 推奨と shell executor 代替を設計で固定する必要あり。 |
| 8 | サンプルリポジトリ（floci-apigateway-csharp） | 必須 | ✅ 準備済 | submodules/floci-apigateway-csharp に存在。 |
| 9 | floci 関連リポジトリ参照 | 必須 | ✅ 準備済 | submodules/floci に存在。 |
| 10 | dummy AWS 認証情報（AKID/SECRET=test） | 必須 | ⚠️ 要確認 | AC7 担保のため dummy 値固定で動作する必要あり（**DR-001** と関連）。 |

## 2. 不足リソースへの対応

設計上の不足（DR-008/DR-012）は **設計修正で確定する必要がある** ため、ユーザー追加リソース要求の前に再設計を要する。

実行環境側のランタイム（.NET 8 SDK / Terraform / Docker）は dev container により概ね揃っている前提だが、実装着手時に以下を verify すること：

```bash
dotnet --version    # 8.x 系であること
terraform -version  # >= 1.5
docker version      # daemon 起動済み
docker compose version
```

**結論**: 設計時点で固定すべき要素（floci image 名、Runner 前提）が未確定のため、**テスト環境準備は設計修正後に再評価が必要**。
