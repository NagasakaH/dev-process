# 検証結果

## 検証情報
- プロジェクト: floci-apigateway-csharp (FRONTEND-001)
- ブランチ: feature/FRONTEND-001
- 検証日時: 2026-04-29T15:55+00:00
- 実行者: dev-workflow / verification skill
- 対象サブモジュール: submodules/editable/floci-apigateway-csharp
- テスト戦略スコープ: unit / integration / e2e

## 環境
- Node.js: v20.20.2 (nvm 経由 — `package.json#engines.node="^20.11.0"` 準拠。devcontainer 既定の v24.14.0 では engines 非適合)
- npm: 10.8.2
- Chrome (Karma `ChromeHeadlessCI`): Playwright 同梱の `~/.cache/ms-playwright/chromium-1208/chrome-linux64/chrome` を `CHROME_BIN` で利用
- Docker: 28.5.2 / Compose v2.40.3 / floci/floci:latest
- .NET SDK: 8.0 系
- terraform / aws CLI: 利用可能

## フロントエンド検証

### Lint (`npm run lint`)
- **ステータス**: ✅ PASS
- **詳細**: `All files pass linting.` (ng lint / @angular-eslint)

### 型チェック (`npx tsc --noEmit -p tsconfig.json`)
- **ステータス**: ✅ PASS
- **詳細**: 型エラーなし。

### ビルド (`npm run build` = `ng build --configuration=production`)
- **ステータス**: ✅ PASS
- **詳細**: dist 生成成功。Initial total 215.36 kB / 60.72 kB transfer。`frontend/dist/index.html` 生成確認。

### 単体テスト (`npm run test:unit`)
- **コマンド**: `CHROME_BIN=… ng test --watch=false --code-coverage --browsers=ChromeHeadlessCI`
- **テスト結果**: ✅ 17 / 17 SUCCESS
- **カバレッジ閾値 (Karma `coverageReporter.check.global` = statements:80 / branches:70 / functions:90 / lines:80)**
  - **ステータス**: ❌ FAIL（閾値未達）
  - Statements: 69.33% (52/75) — 閾値 80%
  - Branches:   37.14% (13/35) — 閾値 70%
  - Functions:  69.23% (18/26) — 閾値 90%
  - Lines:      69.49% (41/59) — 閾値 80%
  - karma-coverage がエラー出力するも karma の終了コードが 0 で返るため CI では別途ガードが必要（後述「未解決事項」）。

### 結合テスト (`npm run test:integration`)
- **コマンド**: `CHROME_BIN=… ng run frontend:test-integration --watch=false --code-coverage --browsers=ChromeHeadlessCI`
- **テスト結果**: ✅ 6 / 6 SUCCESS
- **カバレッジ閾値**: ❌ FAIL
  - Statements: 61.64% / Branches: 25.71% / Functions: 61.53% / Lines: 62.06%

### 検証中に確認・適用した補正

verification 実施中に以下 2 件の **Angular CLI 18 / Karma 設定起因の構成不整合**
が発見され、テストを実走させるため最小限の修正を適用しコミットしている
（実装内容を変更するものではない）。

1. **`frontend/angular.json`**: `architect.test.options` / `architect.test-integration.options` に
   `include` / `exclude` を追加。
   - 既存の `tsconfig.spec.json#exclude` は TS コンパイル対象だけを除外する一方、
     Angular の karma builder は `find-tests-plugin` が
     `**/*.spec.ts` を独自に走査するため `*.integration.spec.ts` を unit ジョブが
     ロードしようとし `Found 1 load error` で karma がテストを実行する前に死んでいた。
     `options.exclude` を併用して unit と integration を完全分離。
2. **`frontend/package.json`**: `test:unit` / `test:integration` に `--code-coverage` を付与。
   - 付与しないと Angular CLI 18 はカバレッジ計装を行わず `Coverage summary: Statements: Unknown% (0/0)` で
     karma-coverage の閾値チェックが「0/0 で常時 PASS」になるため、閾値 (80/70/90/80)
     が事実上無効化されていた。これは `karma.conf.js` のコメント
     「暫定低閾値運用は禁止。最初から最終閾値 ... を強制する」の意図に反するため修正。

これらにより閾値が初めて実測され、未達 (上記 ❌) が表面化している。

## バックエンド (.NET) 検証

### ビルド (`dotnet build floci-apigateway-csharp.sln -c Release`)
- **ステータス**: ✅ PASS
- **詳細**: 0 Warning(s) / 0 Error(s)。

### .NET 単体テスト (`dotnet test tests/TodoApi.UnitTests -c Release --no-build`)
- **ステータス**: ✅ PASS
- **詳細**: Passed: 34 / Failed: 0 / Skipped: 0。

### .NET 結合テスト (`dotnet test tests/TodoApi.IntegrationTests -c Release --no-build`)
- **ステータス**: ⚠️ PARTIAL
- **詳細**: Passed: 2 / Failed: 0 / Skipped: 9。`AWS_ENDPOINT_URL` 等のローカル AWS 接続が必要な
  ケースは Skip 条件 (`Skip = "AWS endpoint not available"` 系) にヒットしている可能性が高い。
  **このスキップが意図的な仕様なのか、verification 側で env を注入して全件回すべきなのかは
  acceptance_criteria 「既存 .NET 側の lint/unit/integration/e2e ジョブが引き続き成功すること」の
  「成功 = Skip でも成功扱い」かどうかに依存する。code-review 段階での確認推奨。**

## E2E テスト (Playwright + floci + nginx)

### スコープ
brainstorming `test_strategy.e2e` 通り、`scripts/web-e2e.sh` を唯一のエントリポイントとし、
`floci 起動 → terraform apply → API invoke_url 取得 → frontend build → S3 配置 → nginx 配信 →
Playwright 実行` を一気通貫で行うことを E2E 完了条件としている。

### 実行結果
- **ステータス**: ❌ BLOCKED（Playwright 自体は未到達）
- **到達ステップ**:
  - ✅ `scripts/check-test-env.sh e2e` 通過 (node/npm/npx/docker/aws/terraform/dotnet/Playwright cache すべて検出)
  - ✅ floci コンテナ起動 (`http://floci:4566/_localstack/health` から services running 応答取得)
  - ✅ Lambda zip パッケージ (`dotnet lambda package` 成功)
  - ✅ `terraform apply` 全 24 リソース作成完了
    - 出力: `invoke_url=http://floci:4566/restapis/7a39271daa/dev/_user_request_`、
      `frontend_bucket=frontend-bucket`、`stage_name=dev`
  - ❌ `scripts/warmup-lambdas.sh` で `api-handler` Lambda が 120 秒タイムアウト → 全 E2E 連鎖停止

### 詳細ブロッカー

#### B1: nginx サイドカーが devcontainer 内 docker-out-of-docker 環境で起動不可
- **症状**: `compose/docker-compose.yml` の nginx サービスが
  `default.conf` (host file) の bind mount で
  `OCI runtime ... not a directory: Are you trying to mount a directory onto a file (or vice-versa)?`
  を返す。
- **原因**: dev container は親 docker daemon の socket を mount して docker コマンドを実行しており、
  `/workspaces/...` パスは daemon ホスト名前空間と完全一致しない / もしくは file→file bind mount が
  この runtime で拒否される。`alpine` イメージで同パスのディレクトリ bind は成功するため、
  挙動はファイル単位 bind mount に限定される。
- **影響**: WEB_BASE_URL=http://localhost:8080 を構成できない。仮に Playwright を起動しても baseURL に
  到達できず E2E は実行できない。
- **対応案 (実装側で要対応)**: a) compose の volume を「ディレクトリ単位 bind」に変える、
  b) nginx 設定を image ビルド時に焼き込む、
  c) e2e 用 compose override を `compose/docker-compose.e2e.yml` として用意し
  ローカル/CI で読み替える。

#### B2: `api-handler` Lambda が floci 上で起動失敗
- **症状**: `scripts/warmup-lambdas.sh` の `lambda invoke` が 120s タイムアウト。
  floci ログに以下:
  ```
  [lambda:api-handler] LambdaValidationException: Could not find the specified handler assembly
    with the file name 'TodoApi.Lambda, Culture=neutral, PublicKeyToken=null'.
  [lambda:api-handler] RuntimeApiClientException: Could not deserialize the response body.
                       Status: 202 Response: (empty)
  ```
- **確認事項**:
  - `infra/lambda/TodoApi.Lambda.zip` の root に `TodoApi.Lambda.dll` が存在することを `unzip -l` で確認済み。
  - `infra/main.tf` の handler は `TodoApi.Lambda::TodoApi.Lambda.Function::ApiHandler`（規約通り）。
  - floci dotnet8 runtime image (`public.ecr.aws/lambda/dotnet:8`) は pull 済み。
  - Lambda コンテナは spawn されるが、floci の Runtime API が空 body の 202 を返し、
    .NET ランタイムが handler 仕様を取得できずに即落ちる挙動が再現する。
- **原因の切り分け**: brainstorming で要求されている
  「実 AWS に到達せず、AWS_ENDPOINT_URL 未設定時は安全に失敗する」という API 側設計と、
  floci 1.5.9 free edition との dotnet8 runtime ハンドラ解決互換性の問題に見える。
  実装段階 (Step 7) で `warmup-lambdas` を含む E2E 連鎖の通し動作確認が行われていなかった
  可能性が高い。
- **対応案 (実装側で要対応)**: a) `apply-state-machine.sh` 後・warmup 前に handler 設定を
  `aws lambda update-function-configuration` で再適用、
  b) floci のバージョン/設定 (`LAMBDA_RUNTIME_ENVIRONMENT_TIMEOUT` 引き上げ等) を見直し、
  c) Lambda のパッケージング戦略を `dotnet publish` 直配置などへ変更、
  d) brainstorming 上の e2e 仕様変更（API mock を伴う代替）はユーザー承認必須。

### 試行した代替策
- floci-net への dev container 接続: 成功（`http://floci:4566` 経由で health 取得可）
- compose を再起動して nginx だけリトライ: 同じ mount エラーで失敗
- 個別ステップ手動実行で warmup 直前まで前進: B2 に到達

### 結論
B1 / B2 の両方が「実装内のスクリプト/構成」に起因しており、
verification の責務範囲（既存テスト/ビルド/リントの実行確認）を超えるため
**E2E は BLOCKED として記録**。`ask_user` 不可指示のため戦略変更は行わず、
acceptance_criteria 上 E2E に紐づく項目を `BLOCKED` のまま据え置く。

> ⚠️ ワークフロー規約上、E2E が必須スコープに含まれているため、
> verification.status は `completed` ではなく `failed` として記録する。
> 実装段階に戻して B1/B2 を解消する必要がある。

## 受け入れ基準 照合結果

| # | 基準 | 検証方法 | 結果 | 根拠 |
|---|------|----------|------|------|
| AC1 | ローカルで Angular フロントエンドを起動し、floci 上の API を叩いて Todo を作成・取得できること | E2E (Playwright) | ❌ BLOCKED | B1 (nginx 起動不可) / B2 (Lambda init 失敗) |
| AC2 | ローカルで S3 + CloudFront 相当の配信構成を起動し、フロントエンド経由の Todo 作成・取得ができること | E2E (Playwright) | ❌ BLOCKED | B1 |
| AC3 | Angular の単体テスト（component/service）がローカルと CI で実行され、全て通過すること | unit | ⚠️ PARTIAL PASS | テスト 17/17 通過。ローカル実行確認済。CI 実行は未確認。**ただしカバレッジ閾値未達 (statements 69.33% < 80% 等)** |
| AC4 | Angular の結合テスト（HttpClient/API 接続境界など）がローカルと CI で実行され、全て通過すること | integration | ⚠️ PARTIAL PASS | テスト 6/6 通過。**カバレッジ閾値未達** |
| AC5 | Playwright E2E が floci + terraform apply 済み API と S3 + CloudFront 相当フロントエンドに対してローカルと CI で実行され、全て通過すること | e2e | ❌ BLOCKED | B1 / B2 により Playwright 未到達 |
| AC6 | 既存 .NET 側の lint/unit/integration/e2e ジョブが引き続き成功すること | dotnet build/test | ⚠️ PARTIAL PASS | build OK, unit 34/34 OK, integration 2 passed/9 skipped (env 起因の skip)。.NET 側 e2e は AWS env 必要のため未確認 |
| AC7 | README または同等のドキュメントにローカル起動、テスト、CI 実行方法が記載されていること | doc check | ⚠️ NOT_VERIFIED | 既存 `verify-readme-content.sh` / `verify-readme-sections.sh` が存在するが本 verification では未起動 |

## 総合結果

- **判定**: ❌ **失敗あり (verification.status = failed)**
- **要約**:
  - ✅ Lint / typecheck / build / .NET build はすべて通過。
  - ✅ フロントエンド unit (17) / integration (6) / .NET unit (34) のテスト本体は全件 PASS。
  - ❌ フロントエンドのカバレッジ閾値 (80/70/90/80) を unit / integration ともに未達。
  - ❌ E2E は B1 (nginx mount) / B2 (Lambda 起動失敗) で Playwright まで到達できず実行不能。
  - ⚠️ AC3〜AC7 は前述の通り部分通過 / BLOCKED / 未検証が混在。

## 未解決事項 / 実装に戻すべき項目

1. **(High)** AC5 / B2: floci 上で `api-handler` Lambda が起動できない問題。
   warmup と E2E 全体を通せる構成にする。
2. **(High)** AC1 / AC2 / B1: docker-out-of-docker 環境向けの nginx サイドカー
   起動方法（ディレクトリ bind / イメージ焼き込み / e2e override compose 等）。
3. **(High)** AC3 / AC4: フロントエンドのカバレッジ閾値 (80/70/90/80) を満たす追加テスト実装。
4. **(Medium)** karma の閾値違反時に exit code 0 で抜ける挙動を CI が拾えるよう、
   `npm test` ラッパー / CI スクリプト側で coverage-summary を grep する後段ガードを追加。
5. **(Medium)** `tests/TodoApi.IntegrationTests` の Skip 9 件が意図的か確認し、必要なら
   verification 環境で env を注入して全件走らせる。
6. **(Low)** AC7: `verify-readme-content.sh` / `verify-readme-sections.sh` を verification チェイン
   に組み込む。

## 添付ログ
- `deploy-local.log` — terraform apply 連鎖（途中で nginx mount エラー含む）
- `e2e-run.log` — `web-e2e.sh` 1 回目の試行ログ（floci 未起動状態での fail-fast）
