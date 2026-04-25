# floci

> 最終更新: 2026-04-25
> パス: `submodules/readonly/floci`（参照専用 / read-only）

## 概要

Floci は Quarkus（Java 25）ベースの **ローカル AWS エミュレータ**。`docker compose up` だけで起動し、AWS の実 wire プロトコル（Query / JSON 1.1 / REST JSON / REST XML）を再現する。LocalStack Community 版の代替を狙った OSS（MIT）であり、本リポジトリでは API Gateway + Lambda + Step Functions の動作検証先として利用する。

- ポート: `4566`
- ライセンス: MIT
- 配布: Docker イメージ `floci/floci:latest`（native）/ `floci/floci:latest-jvm`
- 公式バージョン（pom.xml）: `1.5.7`

---

## 優先度A（必須情報）

### 1. プロジェクト構成

```
submodules/readonly/floci/
├── src/                       # Quarkus アプリ本体（Java 25）
│   ├── main/                  # Controller / Service / Model（services/<svc>/ 配下）
│   └── test/                  # JUnit 5 + RestAssured
├── compatibility-tests/       # AWS SDK / CLI / Terraform / CDK 互換テスト
│   ├── sdk-test-java/
│   ├── sdk-test-python/
│   ├── sdk-test-node/
│   ├── sdk-test-go/
│   ├── sdk-test-rust/
│   ├── sdk-test-awscli/
│   ├── compat-terraform/
│   ├── compat-opentofu/
│   ├── compat-cdk/
│   └── lib/
├── docker/                    # Docker 補助資材
├── docs/                      # mkdocs サイト（getting-started / configuration / services）
├── Dockerfile(.jvm-package|.native|.native-package)
├── docker-compose.yml
├── pom.xml                    # Maven ビルド定義
├── mvnw / mvnw.cmd            # Maven Wrapper
├── run-docker-tests.sh
├── README.md / AGENT.md / CONTRIBUTING.md / CHANGELOG.md / SECURITY.md
└── LICENSE                    # MIT
```

**主要ファイル:**
- `pom.xml` — Quarkus 3.32.3 + AWS SDK BOM 2.42.33 を取り込む親 POM
- `src/main/java/io/github/hectorvent/floci/` — エミュレータ実装本体（`config`, `core.common`, `core.storage`, `lifecycle`, `services.<service>`）
- `AGENT.md` — エージェント向け運用ルール（プロトコル準拠・Storage ルール・サービス追加手順）
- `docker-compose.yml` — ローカル起動サンプル

### 2. 外部公開インターフェース/API

Floci は **AWS の wire プロトコル互換のエンドポイント**（`http://localhost:4566`）を公開する。AWS SDK / CLI から `endpoint-url` / `endpointOverride` で差し向けて利用する。

| プロトコル | 対象サービス | リクエスト | レスポンス | 実装 |
|---|---|---|---|---|
| Query | SQS, SNS, IAM, STS, RDS, ElastiCache, CloudFormation, CloudWatch Metrics | form-encoded POST + `Action` | XML | `AwsQueryController` |
| JSON 1.1 | SSM, EventBridge, CloudWatch Logs, Kinesis, KMS, Cognito, Secrets Manager, ACM | POST + `X-Amz-Target` | JSON | `AwsJson11Controller` |
| REST JSON | Lambda, **API Gateway**, SES V2 | REST パス | JSON | JAX-RS |
| REST XML | S3 | REST パス | XML | JAX-RS |
| TCP（生プロトコル） | ElastiCache, RDS | raw protocol | native | プロキシ |

主要サポートサービス（抜粋）: SSM / SQS / SNS / S3 / DynamoDB(+Streams) / Lambda / API Gateway REST / API Gateway v2 (HTTP) / IAM / STS / Cognito / KMS / Kinesis / Secrets Manager / **Step Functions** / CloudFormation / EventBridge / EventBridge Scheduler / CloudWatch Logs & Metrics / ElastiCache / RDS / MSK / Athena / Glue / Firehose / OpenSearch / ECS / EKS / EC2 / ECR / ACM / SES。

### 3. テスト実行方法

```bash
# 全テスト
./mvnw test

# 個別テストクラス
./mvnw test -Dtest=SsmIntegrationTest

# 個別メソッド
./mvnw test -Dtest=SsmIntegrationTest#putParameter
```

- 単体: `*ServiceTest.java`
- 統合: `*IntegrationTest.java`（JUnit 5 + RestAssured、必要に応じて順序付き）
- 互換性検証: `compatibility-tests/`（AWS SDK / CLI / Terraform / OpenTofu / CDK ベース）。Docker からの実行は `./run-docker-tests.sh`。

### 4. ビルド実行方法

```bash
# 開発モード（ホットリロード）
./mvnw quarkus:dev

# 本番ビルド
./mvnw clean package

# テストスキップ
./mvnw clean package -DskipTests
```

- Native イメージは `Dockerfile.native` / `Dockerfile.native-package`（推奨配布形態、起動約24ms）
- JVM イメージは `Dockerfile.jvm-package`
- Maven Wrapper（`./mvnw`）を使用すること。Maven のローカル導入は不要。

### 5. 依存関係

#### 本番依存（pom.xml の主要 BOM / ライブラリ）
- Quarkus Platform BOM `${quarkus.platform.version}`（既定 3.32.3）
- `quarkus-rest-jackson`, `quarkus-config-yaml`, `quarkus-vertx`
- AWS SDK for Java BOM `2.42.33`
- Vert.x `vertx-mail-client`
- Apache James `apache-mime4j-dom 0.8.11`
- Jackson: `jackson-databind`, `jackson-datatype-jsr310`, `jackson-dataformat-cbor`, `jackson-dataformat-yaml`

#### 開発依存
- JUnit 5 / RestAssured（Quarkus 標準テスト依存に含まれる）
- Docker（Lambda / RDS / ElastiCache / MSK / OpenSearch / ECS / EKS / ECR の実行用）

### 6. 技術スタック

| カテゴリ | 技術 |
|---|---|
| 言語 | Java 25 |
| フレームワーク | Quarkus 3.32.3（JAX-RS / Vert.x） |
| ビルドツール | Maven（Maven Wrapper `./mvnw`） |
| テストフレームワーク | JUnit 5 + RestAssured（+ AWS SDK ベースの互換性テスト） |
| ランタイム配布 | GraalVM ネイティブイメージ / JVM イメージ（Docker） |
| 永続化 | 独自 `StorageBackend`（`memory` / `persistent` / `hybrid` / `wal`） |
| プロトコル | AWS Query / JSON 1.1 / REST JSON / REST XML / 生 TCP |

---

## 優先度B（オプション情報）

### 7. 利用方法/Getting Started

```yaml
# docker-compose.yml
services:
  floci:
    image: floci/floci:latest
    ports:
      - "4566:4566"
    volumes:
      - ./data:/app/data
```

```bash
docker compose up
# もしくは:
docker run -d --name floci \
  -p 4566:4566 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e FLOCI_DEFAULT_REGION=us-east-1 \
  -e FLOCI_SERVICES_LAMBDA_DOCKER_NETWORK=bridge \
  -u root \
  floci/floci:latest

export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

aws s3 mb s3://my-bucket
aws sqs create-queue --queue-name my-queue
aws dynamodb list-tables
```

Lambda / RDS / ElastiCache 等のコンテナ駆動サービスを使う場合は Docker ソケット (`/var/run/docker.sock`) のマウントが必須。

### 8. 環境変数/設定

| 変数名 | 説明 | デフォルト値 |
|---|---|---|
| `FLOCI_PORT` | Floci API のポート | `4566` |
| `FLOCI_DEFAULT_REGION` | デフォルト AWS リージョン | `us-east-1` |
| `FLOCI_DEFAULT_ACCOUNT_ID` | デフォルト AWS アカウント ID | `000000000000` |
| `FLOCI_BASE_URL` | 返却 URL（例: SQS QueueUrl）のベース | `http://localhost:4566` |
| `FLOCI_HOSTNAME` | Compose 内など別コンテナから参照する際のホスト名 | *(unset)* |
| `FLOCI_STORAGE_MODE` | 永続化モード `memory` / `persistent` / `hybrid` / `wal` | `memory` |
| `FLOCI_STORAGE_PERSISTENT_PATH` | 永続化ディレクトリ | `./data` |
| `FLOCI_ECR_BASE_URI` | Lambda 実行用 ECR ベース URI | `public.ecr.aws` |
| `FLOCI_SERVICES_LAMBDA_DOCKER_NETWORK` | Lambda コンテナ接続ネットワーク | （任意） |
| `FLOCI_SERVICES_<SVC>_DEFAULT_IMAGE` | ElastiCache/RDS/MSK/OpenSearch/EKS/ECR 既定イメージの上書き | サービス毎の既定値 |

全設定リファレンス: <https://floci.io/floci/configuration/application-yml/>

### 9. 他submoduleとの連携

- **`submodules/editable/floci-apigateway-csharp`**: 本リポジトリで開発する API Gateway + .NET 8 Lambda + Step Functions 参照実装の検証基盤として、Floci の API Gateway / Lambda / Step Functions エンドポイントを使う想定。AWS SDK の `endpointOverride` を `http://localhost:4566`（または compose 内 `http://floci:4566`）に向けて結合する。

### 10. 既知の制約・制限事項

- 本ディレクトリは **read-only サブモジュール**。ローカルでの修正・コミットは行わない。
- Lambda / RDS / ElastiCache / MSK / OpenSearch / ECS / EKS / ECR は **実 Docker コンテナ起動**を伴うため、Docker ソケットへのアクセスが必須。
- マルチコンテナ構成では `FLOCI_HOSTNAME` を設定しないと SQS 等の返却 URL が他コンテナから解決できない。
- `application.yml` がランタイム既定値の真の出典。`EmulatorConfig` のフォールバック既定と差異がある場合 YAML 側を信頼する（AGENT.md 参照）。
- LocalStack の完全互換ではなく、AWS の実 wire プロトコルへの忠実性を優先する設計。

### 11. バージョニング・互換性

- 現行 `pom.xml` バージョン: `1.5.7`
- イメージタグ: `latest`（native, 推奨）/ `latest-jvm` / `x.y.z` / `x.y.z-jvm`
- 安定リリースはリリースブランチ + タグ起点の publishing workflow で発行される（`main` への merge は即リリースを意味しない）。

### 14. ライセンス情報

MIT License（`LICENSE` ファイル参照）。
