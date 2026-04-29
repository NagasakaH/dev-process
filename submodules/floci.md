# floci

> 最終更新: 2025-04-25

## 概要

[Floci](https://github.com/floci-io/floci) は無料・オープンソース（MIT）の **ローカル AWS エミュレータ**。`docker compose up` だけで起動でき、AWS SDK / AWS CLI を AWS のワイヤープロトコルレベルで受け付ける。LocalStack Community Edition の代替として位置づけられ、認証トークン不要・機能ゲートなしで 35+ AWS サービスを提供する。
本 dev-process リポジトリでは `submodules/readonly/floci/` に配置されており、**読み取り専用**の参照実装として扱う（コード改修は行わない）。

主な特徴: ネイティブイメージで起動 ~24 ms / アイドルメモリ ~13 MiB / Docker イメージ ~90 MB。LocalStack Community 比で大幅に軽量。

---

## 優先度A（必須情報）

### 1. プロジェクト構成

```
floci/
├── README.md                 # ユーザー向け概要・利用方法
├── AGENT.md                  # AI エージェント向けの開発ルール
├── CONTRIBUTING.md / CODE_OF_CONDUCT.md / SECURITY.md / LICENSE
├── CHANGELOG.md              # release 履歴 (semantic-release 由来)
├── pom.xml                   # Maven プロジェクト定義 (Quarkus)
├── mvnw / mvnw.cmd / .mvn/   # Maven Wrapper
├── Dockerfile                # ネイティブイメージ用
├── Dockerfile.jvm-package    # JVM パッケージ用
├── Dockerfile.native / Dockerfile.native-package
├── docker-compose.yml        # ローカル起動例
├── docker/                   # 補助 Docker 資材
├── docs/                     # MkDocs ドキュメントソース
│   ├── index.md
│   ├── getting-started/
│   ├── configuration/
│   ├── services/
│   ├── contributing.md
│   ├── assets/
│   └── requirements.txt      # MkDocs 依存
├── mkdocs.yml                # ドキュメントサイト設定
├── compatibility-tests/      # 多言語 SDK 互換テスト群 (1850+)
├── run-docker-tests.sh
├── .gitlab-ci.yml は無し / .github/  # GitHub Actions ワークフロー
├── .releaserc.json           # semantic-release 設定
├── .coderabbit.yaml          # CodeRabbit (AI レビュー) 設定
└── src/
    ├── main/
    │   ├── java/io/github/hectorvent/floci/
    │   │   ├── config/        # EmulatorConfig
    │   │   ├── core/common/   # AwsJson11Controller, AwsQueryController, AwsException, ...
    │   │   ├── core/storage/  # StorageBackend, StorageFactory (memory/persistent/hybrid/wal)
    │   │   ├── lifecycle/     # EmulatorLifecycle
    │   │   └── services/<svc>/ # 各 AWS サービス実装 (acm, apigateway, apigatewayv2,
    │   │                        appconfig, athena, bedrockruntime, cloudformation,
    │   │                        cloudwatch, cognito, dynamodb, ec2, ecr, ecs, eks,
    │   │                        elasticache, eventbridge, firehose, glue, iam, kinesis,
    │   │                        kms, lambda, msk, opensearch, pipes, rds,
    │   │                        resourcegroupstagging, s3, scheduler, secretsmanager,
    │   │                        ses, sns, sqs, ssm, stepfunctions)
    │   └── resources/
    │       ├── application.yml         # Quarkus 設定 (本番)
    │       ├── application.yml.bak
    │       ├── default_banner.txt
    │       ├── certs/
    │       ├── META-INF/
    │       └── org/
    └── test/                  # JUnit 5 + RestAssured によるテスト
```

**主要ファイル / 主要コンポーネント:**

- `core/common/AwsJson11Controller`、`AwsQueryController` — AWS Wire Protocol（JSON 1.1 / Query）共通ハンドラ。
- `core/common/AwsException` + `AwsExceptionMapper` — AWS 互換のエラーレスポンス生成。
- `core/storage/StorageBackend` + `StorageFactory` — `memory` / `persistent` / `hybrid` / `wal` モードの抽象化。
- `config/EmulatorConfig` — `floci.*` 設定の Quarkus バインディング。
- `lifecycle/EmulatorLifecycle` — 永続化ロード/フラッシュ等のライフサイクル管理。
- `services/<svc>/{*Controller, *Service, model/}` — サービス毎の標準パターン（コントローラ薄め、サービスにビジネスロジック、`model/` にドメイン）。
- `application.yml` — 起動時の有効サービス・ストレージモード等を確定する **唯一の真実の源**。

### 2. 外部公開インターフェース/API

- **エンドポイント**: 単一 HTTP エンドポイント `http://localhost:4566` で全 AWS サービスを受ける（ポートは `FLOCI_PORT` で変更可、デフォルト 4566）。
- **認証**: AWS SigV4 互換（資格情報は何でも可、`test`/`test` 推奨）。`region` も任意。
- **対応プロトコル / 主なサービス**（`AGENT.md` より）:

  | プロトコル | サービス | 実装 |
  |---|---|---|
  | Query (form-encoded POST + `Action`) → XML | SQS, SNS, IAM, STS, RDS, ElastiCache, CloudFormation, CloudWatch Metrics | `AwsQueryController` |
  | JSON 1.1 (POST + `X-Amz-Target`) | SSM, EventBridge, CloudWatch Logs, Kinesis, KMS, Cognito, Secrets Manager, ACM | `AwsJson11Controller` |
  | REST JSON | Lambda, API Gateway, SES v2 | JAX-RS |
  | REST XML | S3 | JAX-RS |
  | TCP (raw) | ElastiCache, RDS | ネイティブプロキシ |

- **対応 AWS サービス（35+）**: SSM, SQS, SNS, S3, DynamoDB, DynamoDB Streams, Lambda, API Gateway REST, API Gateway v2 (HTTP), IAM, STS, Cognito, KMS, Kinesis, Secrets Manager, Step Functions, CloudFormation, EventBridge, EventBridge Scheduler, CloudWatch Logs, CloudWatch Metrics, ElastiCache, RDS (PostgreSQL/MySQL/MariaDB), MSK, Athena (DuckDB sidecar), Glue Data Catalog, Data Firehose, ECS, EC2, ACM, ECR, SES, SES v2, OpenSearch, AppConfig / AppConfigData, Bedrock Runtime (stub), EKS。
- **Docker 連携が必要なサービス**: Lambda, ElastiCache, RDS, MSK, ECS, EKS, OpenSearch, ECR（Docker socket のマウントが必須）。
- **Container 制御**: Lambda は `public.ecr.aws/lambda/<runtime>` を自動解決（java/python/nodejs/ruby/dotnet/go/provided.al2023 等）。`Image` パッケージタイプは `ImageUri` をそのまま使用し、ECR URI は floci のローカル ECR にリライトされる。
- **SDK 互換性検証**: 1,850+ の自動テスト（Java SDK v2, JS SDK v3, boto3, Go SDK v2, AWS CLI v2, Rust SDK, Terraform, OpenTofu, AWS CDK）。

### 3. テスト実行方法

Maven Wrapper を使用（Java 25 / Quarkus 3.32〜3.34）:

```bash
./mvnw test                              # 全テスト実行 (JUnit 5 + RestAssured)
./mvnw test -Dtest=SsmIntegrationTest    # 特定クラス
./mvnw test -Dtest=SsmIntegrationTest#putParameter  # 特定メソッド
```

- **テストフレームワーク**: JUnit 5、RestAssured、Jackson、Quarkus Test。
- **命名規約**: 単体テスト `*ServiceTest.java`、結合テスト `*IntegrationTest.java`。
- **互換テストスイート**: `compatibility-tests/`（言語別に Java/Node/Python/Go/AWS CLI/Rust、IaC 別に Terraform/OpenTofu/CDK）。`run-docker-tests.sh` で Docker 経由実行可能。
- 詳細な互換テストモジュール:

  | モジュール | 言語/ツール | テスト数 |
  |---|---|---|
  | `sdk-test-java` | Java 17 + AWS SDK v2 | 889 |
  | `sdk-test-node` | Node.js + AWS SDK v3 | 360 |
  | `sdk-test-python` | Python 3 + boto3 | 264 |
  | `sdk-test-go` | Go + AWS SDK v2 | 136 |
  | `sdk-test-awscli` | AWS CLI v2 | 145 |
  | `sdk-test-rust` | Rust AWS SDK | 86 |
  | `compat-terraform` | Terraform v1.10+ | 14 |
  | `compat-opentofu` | OpenTofu v1.9+ | 14 |
  | `compat-cdk` | AWS CDK v2+ | 17 |

### 4. ビルド実行方法

```bash
./mvnw quarkus:dev                  # 開発モード (live reload)
./mvnw clean package                # JVM パッケージ
./mvnw clean package -DskipTests    # テスト省略
```

- ネイティブイメージ生成: `Dockerfile.native` / `Dockerfile.native-package` を使用。
- Docker イメージタグ:
  - `latest` — ネイティブイメージ（サブ秒起動・推奨）
  - `latest-jvm` — JVM イメージ
  - `x.y.z` / `x.y.z-jvm` — ピン留めリリース
- 公式 Docker イメージは **`floci/floci`**（旧 `hectorvent/floci` は 2026/3 以降更新なし）。

### 5. 依存関係

主要な技術依存（`pom.xml`）:

| カテゴリ | 内容 |
|---|---|
| BOM | `io.quarkus.platform:quarkus-bom` 3.34.3、`software.amazon.awssdk:bom` 2.42.33 |
| Quarkus 拡張 | `quarkus-rest-jackson`、`quarkus-config-yaml`、`quarkus-vertx` |
| HTTP / メール | `io.vertx:vertx-mail-client`、`org.apache.james:apache-mime4j-dom` 0.8.11 |
| JSON | `jackson-databind`、`jackson-datatype-jsr310`、`jackson-dataformat-cbor`、`jackson-dataformat-yaml` |
| スケジューリング | `com.cronutils:cron-utils` |
| AWS SDK | `software.amazon.awssdk:*`（BOM 経由） |

Docker ベースの実行時依存（floci がコンテナを起動する対象）:

| サービス | デフォルトイメージ |
|---|---|
| Lambda | `public.ecr.aws/lambda/<runtime>:<version>` |
| ElastiCache | `valkey/valkey:8` |
| RDS PostgreSQL | `postgres:16-alpine` |
| RDS MySQL | `mysql:8.0` |
| RDS MariaDB | `mariadb:11` |
| MSK | `redpandadata/redpanda:latest` |
| OpenSearch | `opensearchproject/opensearch:2` |
| EKS | `rancher/k3s:latest` |
| ECR | `registry:2` |

### 6. 技術スタック

| カテゴリ | 技術 |
|---|---|
| 言語 | Java 25（`maven.compiler.release=25`） |
| フレームワーク | Quarkus 3.34.3（README/AGENT 上は 3.32 系記載あり）、JAX-RS、Vert.x |
| ビルドツール | Maven 3.x（`./mvnw` ラッパー同梱）、GraalVM Native Image |
| コンテナ | Docker / Docker Compose（複数 Dockerfile：JVM / native / package） |
| テストフレームワーク | JUnit 5、RestAssured、Quarkus Test |
| シリアライゼーション | Jackson（databind、jsr310、cbor、yaml）、`XmlBuilder` / `XmlParser`（独自） |
| AWS SDK | aws-sdk-java v2 (2.42.33) |
| ストレージモード | `memory` / `persistent` / `hybrid`（既定）/ `wal` |
| ロギング | JBoss Logging |
| リリース | semantic-release（`.releaserc.json`） |
| ライセンス | MIT |

---

## 優先度B（オプション情報）

### 7. 利用方法/Getting Started

最小起動例（`docker-compose.yml`）:

```yaml
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
```

直接起動（Docker ソケット必須サービス利用時）:

```bash
docker run -d --name floci \
  -p 4566:4566 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e FLOCI_DEFAULT_REGION=us-east-1 \
  -e FLOCI_SERVICES_LAMBDA_DOCKER_NETWORK=bridge \
  -u root \
  floci/floci:latest
```

AWS SDK / CLI 設定:

```bash
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
aws s3 mb s3://my-bucket
```

### 8. 環境変数/設定

`FLOCI_*` プレフィックスでの環境変数オーバーライドに対応（一部抜粋）:

| 変数名 | 説明 | デフォルト値 |
|---|---|---|
| `FLOCI_PORT` | API ポート | `4566` |
| `FLOCI_DEFAULT_REGION` | 既定リージョン | `us-east-1` |
| `FLOCI_DEFAULT_ACCOUNT_ID` | 既定アカウント ID | `000000000000` |
| `FLOCI_BASE_URL` | サービス URL のベース（SQS QueueUrl 等） | `http://localhost:4566` |
| `FLOCI_HOSTNAME` | Compose 内で利用するホスト名（マルチコンテナ時必須） | 未設定 |
| `FLOCI_STORAGE_MODE` | ストレージモード `memory` / `persistent` / `hybrid` / `wal` | `memory`（README 表）※既定の振る舞いは `hybrid` 説明あり：起動後の挙動を確認すること |
| `FLOCI_STORAGE_PERSISTENT_PATH` | 永続化ディレクトリ | `./data` |
| `FLOCI_ECR_BASE_URI` | Lambda 用 ECR ベース URI | `public.ecr.aws` |
| `FLOCI_SERVICES_ELASTICACHE_DEFAULT_IMAGE` | ElastiCache 既定イメージ | `valkey/valkey:8` |
| `FLOCI_SERVICES_RDS_DEFAULT_POSTGRES_IMAGE` | RDS PostgreSQL 既定イメージ | `postgres:16-alpine` |
| `FLOCI_SERVICES_RDS_DEFAULT_MYSQL_IMAGE` | RDS MySQL 既定イメージ | `mysql:8.0` |
| `FLOCI_SERVICES_RDS_DEFAULT_MARIADB_IMAGE` | RDS MariaDB 既定イメージ | `mariadb:11` |
| `FLOCI_SERVICES_MSK_DEFAULT_IMAGE` | MSK 既定イメージ | `redpandadata/redpanda:latest` |
| `FLOCI_SERVICES_OPENSEARCH_DEFAULT_IMAGE` | OpenSearch 既定イメージ | `opensearchproject/opensearch:2` |
| `FLOCI_SERVICES_EKS_DEFAULT_IMAGE` | EKS 既定イメージ | `rancher/k3s:latest` |
| `FLOCI_SERVICES_ECR_REGISTRY_IMAGE` | ECR レジストリ実装 | `registry:2` |
| `FLOCI_SERVICES_LAMBDA_DOCKER_NETWORK` | Lambda コンテナの参加ネットワーク | 環境依存 |

設定ファイル: `src/main/resources/application.yml`（本番）、テスト用 `application.yml`（`src/test/resources` 等）。`floci.*` 名前空間配下、`EmulatorConfig` でバインド。

### 9. 他submoduleとの連携

- 本 dev-process リポジトリ内では **`submodules/editable/floci-apigateway-csharp`**（同 `submodules/floci-apigateway-csharp.md` 参照）が利用対象 AWS エミュレータとして floci を想定している。当該プロジェクトの compose は `localstack/localstack:latest` を直接参照しているが、互換性の参照仕様としては本 floci のドキュメントが正となる。

### 10. 既知の制約・制限事項

- **Docker socket 必須サービス**: Lambda / ElastiCache / RDS / MSK / ECS / EKS / OpenSearch / ECR を使う場合は `/var/run/docker.sock` のマウントが必須。
- **Bedrock Runtime はスタブ**: Converse / InvokeModel はダミー応答、ストリーミングは 501。
- **マルチコンテナ Compose**: `FLOCI_HOSTNAME` を設定しないと SQS QueueUrl 等が `http://localhost:4566/...` を返し、別コンテナから解決できない。
- **AWS 互換維持の絶対要件**（AGENT.md）:
  - カスタムエンドポイント形状を作らない
  - 利便性のためにリクエスト/レスポンスフォーマットを変えない
  - StorageFactory をバイパスしない
  - ストレージ・設定・サービス追加時は `EmulatorConfig` / `application.yml`（main + test）/ `StorageFactory` / docs / tests を一括更新する
- **MIT ライセンス**だが、Docker イメージ移行（旧 `hectorvent/floci` → `floci/floci`）以降、旧リポジトリは更新されない。

### 11. バージョニング・互換性

- semantic-release によるリリース運用（`.releaserc.json`）。
- `main` ブランチへの merge は安定リリースを意味しない。リリース系列はリリースブランチ + タグで定義され、タグが publish ワークフローを起動する（AGENT.md「Release Awareness」）。
- イメージタグポリシーは README §Image Tags 参照（`latest` がネイティブ推奨）。

### 12. コントリビューションガイド

- 詳細は `CONTRIBUTING.md` / `CODE_OF_CONDUCT.md`。
- コミットは Conventional Commits（`feat:` / `fix:` / `perf:` / `docs:` / `chore:`）。
- **AI ツール由来の `Co-Authored-By` トレーラーは付与しない**（AGENT.md「Pull Request Guidelines」明記）。
- セキュリティ報告: `SECURITY.md`。
- AI コードレビューは CodeRabbit (`.coderabbit.yaml`) を利用。

### 14. ライセンス情報

MIT License（`LICENSE`）。
