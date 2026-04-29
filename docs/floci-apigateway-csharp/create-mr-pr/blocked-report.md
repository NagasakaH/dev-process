# Step 9 create-mr-pr (Code mode) ブロックレポート

- チケット: FRONTEND-001
- 対象リポジトリ: `submodules/editable/floci-apigateway-csharp` (gitlab: nagasaka-experimental/floci-apigateway-csharp)
- ブランチ: `feature/FRONTEND-001`
- モード: code
- プラットフォーム: gitlab
- 状態: **blocked**（draft MR/PR は未作成）
- 記録日時: 2026-04-29T17:29:39+00:00

## ブロック理由

`create-mr-pr` ワークフロー Code モードの前提条件は `verification.status == completed` であるが、現状は **`failed`**。

主因は **NEW-1**: floci 1.5.9 (`ApiGatewayUserRequestController`) に `@OPTIONS` ハンドラが未定義のため、ローカルの floci-as-API-Gateway 模倣環境では OPTIONS preflight が AWS_PROXY 統合へ到達せず、Quarkus 既定で 200+Allow を返す。これにより Playwright E2E-1 / E2E-3 が fail。

- これは **upstream (floci 1.5.9) 起因のローカルエミュレーション制約**であり、本リポジトリの設計（RD-006 / RD-011）および IaC/Lambda 契約テストは PASS。
- 本番 AWS API Gateway 上では同設計により GREEN となる見込み。
- RED テスト (`scripts/cors-preflight-red.sh` 相当) と証跡は verification セクションに記録済み。

## 検証サマリ（verification より）

| 項目 | 結果 |
|---|---|
| Frontend UT (32/32) + 閾値ガード | PASS |
| Frontend IT (17/17) + 閾値ガード | PASS |
| .NET unit (34/34) | PASS |
| .NET integration (12/12, floci 起動下) | PASS |
| infra plan assertion (7/7) + AWS_PROXY + RD-011 | PASS |
| ng build / dotnet build / docker build / compose config | PASS |
| ng lint / tsc --noEmit | PASS |
| Playwright E2E (6 件) | 3 pass / 2 fail (E2E-1, E2E-3 = NEW-1) / 1 skip (E2E-6 設計通り) |

### Acceptance Criteria 充足状況

- AC1: **FAIL** (E2E-1, NEW-1 起因のみ)
- AC2: PASS (E2E-2)
- AC3: PASS (UT)
- AC4: PASS (IT)
- AC5: **PARTIAL_PASS** (E2E-1/3 のみ NEW-1 起因 fail)
- AC6: PASS (.NET 既存)

## ブロッカー一覧

| ID | 種別 | 内容 | 想定対応 |
|---|---|---|---|
| BLK-1 | upstream | floci 1.5.9 `ApiGatewayUserRequestController` に `@OPTIONS` 未実装 | (a) floci upstream への PR / (b) ローカル前段に OPTIONS を AWS_PROXY 統合と同等に返す patch / (c) E2E-1/3 を本番 AWS 環境で実行する CI ジョブを別途用意 |
| BLK-2 | プロセス | `verification.status == failed` のため `create-mr-pr` Code モードの前提条件未達 | BLK-1 解消 → verification 再実行 → completed 化 |

## 想定 PR 本文ドラフト（送信は保留）

`code-template.md` に従い AI 自動チェック項目に下記根拠を埋め込む予定。verification 完了後に再生成して送信する。

- AI 自動チェック (チェック予定項目と根拠 / 対象外理由の例)
  - `[x]` ビルド成功 — 根拠: `ng build production OK (215.36 kB)` / `dotnet build sln OK (0 warn/0 err)` / `docker build` & `docker compose config` OK
  - `[x]` Lint / 型チェック — 根拠: `ng lint: All files pass linting.` / `tsc --noEmit -p tsconfig.json: no errors.`
  - `[x]` ユニットテスト — 根拠: Angular UT 32/32 + cov 100/94.28/100/100、.NET unit 34/34
  - `[x]` インテグレーションテスト — 根拠: Angular IT 17/17 + cov 98.63/80/100/98.27、.NET integration 12/12 (floci + AWS_ENDPOINT_URL 下)
  - `[ ]` E2E テスト全パス（**対象外: NEW-1 = floci 1.5.9 upstream 制約により OPTIONS preflight が AWS_PROXY 統合に到達しないため、本番 AWS では GREEN 見込みだがローカルでは E2E-1/3 fail。BLK-1 解消後に再評価**）
  - `[x]` IaC plan assertion — 根拠: 7/7 PASS、AWS_PROXY 統合確認、RD-011 違反なし
  - `[x]` 不要ファイル混入なし — 根拠: `git status` / `git diff --stat` 確認、生成物・秘匿情報なし
- AI+人間チェックは未送信のため未記入

## 次に可能な作業

1. **BLK-1 を解消する**: floci upstream に OPTIONS ハンドラを追加するか、ローカル前段で OPTIONS を AWS_PROXY 同等にプロキシ。完了後、verification を再実行して completed 化 → 本ステップを再開。
2. **暫定運用**: AC1/AC5 の E2E-1/3 を本番 AWS 環境（または floci を使わない真の AWS API Gateway）でのみ評価する CI ジョブを追加し、ローカル fail を許容するゲート設計に合意。これも verification の再評価が必要。
3. 上記いずれも採れない場合は、`finishing-branch` で本ブランチを保留扱いとして記録。

本ブロックレポートは verification 完了後に削除または history へ移動する想定。
