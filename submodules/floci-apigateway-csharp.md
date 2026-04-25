# floci-apigateway-csharp

> 最終更新: 2026-04-25
> パス: `submodules/editable/floci-apigateway-csharp`（編集対象 / editable）

## 概要

`floci-apigateway-csharp` は **AWS API Gateway + .NET 8 Lambda + Step Functions** の参照実装サンプル。`floci`（ローカル AWS エミュレータ）上で API Gateway / Lambda / Step Functions の動作検証を CI まで含めて完結させることを目的とした、本リポジトリ管理下の編集対象サブモジュール。

> ⚠️ 本サブモジュールは初期化直後で実装はまだ存在せず、現状リポジトリ直下に `README.md` のみが含まれる「スケルトン」状態である。詳細仕様は今後の brainstorming / design / implement ステップで肉付けされる。

---

## 優先度A（必須情報）

### 1. プロジェクト構成

```
submodules/editable/floci-apigateway-csharp/
├── README.md     # サブモジュール概要（スケルトン）
└── .git          # サブモジュールの Git メタデータ
```

**主要ファイル:**
- `README.md` — 目的説明のみの最小ドキュメント。今後 .NET 8 ソリューション・Lambda プロジェクト・Step Functions 定義・テスト資材が追加される予定。

### 2. 外部公開インターフェース/API

現時点ではコード未実装のため公開 API は無し。想定される公開面（design ステップ以降で確定）:

- **API Gateway REST/HTTP API** によるエンドポイント（Floci の `http://localhost:4566` 経由で公開）
- **Step Functions ステートマシン**（API Gateway → Lambda → Step Functions のフロー）
- **.NET 8 Lambda 関数**（`dotnet8` ランタイム）

### 3. テスト実行方法

未確定（まだテストコードが存在しない）。`floci` 側の互換性テストの流儀（AWS SDK ベースの統合テスト）を踏襲する想定。設計後にこの節を更新する。

### 4. ビルド実行方法

未確定。.NET 8 + Lambda 採用方針より、想定されるコマンドは以下：

```bash
# 想定（実装後に確定）
dotnet build
dotnet test
dotnet lambda package    # Amazon.Lambda.Tools 利用時
```

### 5. 依存関係

#### 本番依存
未確定。想定: `Amazon.Lambda.Core`, `Amazon.Lambda.APIGatewayEvents`, `Amazon.Lambda.Serialization.SystemTextJson`, AWS SDK for .NET（`AWSSDK.StepFunctions` 等）。

#### 開発依存
未確定。想定: `xUnit` または `NUnit`、`Amazon.Lambda.TestUtilities`、`Amazon.Lambda.Tools`（`dotnet tool`）。

### 6. 技術スタック

| カテゴリ | 技術 |
|---|---|
| 言語 | C# / .NET 8 |
| フレームワーク | AWS Lambda for .NET（`dotnet8` ランタイム） |
| ビルドツール | dotnet CLI（`dotnet build` / `dotnet lambda package` 想定） |
| テストフレームワーク | 未確定（xUnit を想定） |
| 連携基盤 | API Gateway（REST/HTTP API） + Step Functions |
| 検証用ローカル基盤 | [`floci`](./floci.md)（`http://localhost:4566`） |

---

## 優先度B（オプション情報）

### 9. 他submoduleとの連携

- **`submodules/readonly/floci`**: 本サブモジュールの主要な検証ターゲット。API Gateway / Lambda（`dotnet8` ランタイム） / Step Functions の各エンドポイントを Floci 上で起動し、ローカル環境および CI 上で結合テストを実行する。AWS SDK for .NET のクライアントは `ServiceURL = "http://localhost:4566"`（Compose 内では `http://floci:4566`）を設定して接続する。

### 10. 既知の制約・制限事項

- リポジトリは初期化直後でコード未実装。詳細仕様・受け入れ基準は brainstorming → design ステップで定義する。
- Floci の Lambda は実 Docker コンテナ（`public.ecr.aws/lambda/dotnet:8`）で実行されるため、検証環境には Docker ソケットへのアクセスが必要。
