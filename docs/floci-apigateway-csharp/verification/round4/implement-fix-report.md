# FRONTEND-001 Round 4 implement 修正レポート (NEW-1)

## 対象

Round 3 残ブロッカー **NEW-1**: API Gateway OPTIONS preflight が
204 + CORS ヘッダではなく 200 + `Allow:` のみを返し、E2E-1 / E2E-3 が失敗する。

## 結論

- **本実装 (IaC + Lambda) は設計 (RD-006 / RD-011) 通りで、本番 AWS 環境では正常に動作する見込み**。
- ローカル E2E でのみ発生する根本原因は、OSS の AWS API エミュレータ
  [`floci`](https://github.com/floci-io/floci) **1.5.9** の
  `ApiGatewayUserRequestController` に `@OPTIONS` ハンドラが定義されていない
  ことで、Quarkus / RESTEasy が自動生成する OPTIONS 応答 (200 + `Allow:` ヘッダ)
  が AWS_PROXY 統合より先にマッチしてしまい、Lambda にイベントが転送されない
  ことである。
- `ApiGatewayExecuteController` も同様に `@OPTIONS` 未定義。
- 該当ソース:
  <https://github.com/floci-io/floci/blob/main/src/main/java/io/github/hectorvent/floci/services/apigateway/ApiGatewayUserRequestController.java>
- floci は GraalVM native build のため
  `QUARKUS_HTTP_CORS` 等のランタイム設定では矯正できない。
- 設計上 `nginx での API proxy` `MOCK 統合` `gateway responses による CORS 宣言`
  はいずれも禁止 (RD-001 / RD-006 / RD-011) のため、ローカルで本制約を
  回避する手段は存在しない。

## 確認した観測事実

```bash
$ curl -i -X OPTIONS \
    'http://host.docker.internal:4566/restapis/<id>/dev/_user_request_/todos' \
    -H 'Origin: http://host.docker.internal:8080' \
    -H 'Access-Control-Request-Method: POST' \
    -H 'Access-Control-Request-Headers: Content-Type'

HTTP/1.1 200 OK
Allow: HEAD, DELETE, POST, GET, OPTIONS, PUT, PATCH
x-amz-id-2: ...
content-length: 0
```

- POST / GET は同じ invoke URL で 201 / 200 + `Access-Control-Allow-Origin: *`
  を返し、Lambda 統合自体は正常稼働。
- `aws apigateway get-method --http-method OPTIONS` で OPTIONS リソースが
  AWS_PROXY → Lambda として登録済みであることを確認。

## 設計準拠の根拠

| 項目 | 場所 | 状態 |
| --- | --- | --- |
| OPTIONS /todos AWS_PROXY 統合 | `infra/frontend.tf` | ✅ 既存 |
| OPTIONS /todos/{id} AWS_PROXY 統合 | `infra/frontend.tf` | ✅ 既存 |
| Lambda OPTIONS ハンドラ (204 + CORS) | `src/TodoApi.Lambda/Function.cs` L47–55 / L170–176 | ✅ 既存 |
| 全レスポンスへの `Access-Control-Allow-Origin: *` 付与 | `Function.cs` L162–168 | ✅ 既存 |
| Lambda 契約検証 (xUnit) | `tests/TodoApi.IntegrationTests/CorsOptionsTests.cs` | ✅ 5 件 PASS |
| terraform plan assertion | `tests/infra/test-frontend-plan.sh` | ✅ PASS |

## 追加成果物

1. **`tests/infra/test-cors-preflight-http.sh`** (新規)
   - HTTP レイヤで OPTIONS が 204 + 必須 CORS ヘッダを返すかを assert する
     RED テスト。
   - 現状 floci 1.5.9 では FAIL する想定で、floci 修正版に切り替わると
     自動的に GREEN になる。
2. **`compose/docker-compose.yml`** に NEW-1 制約をコメント化、
   将来の修正版に備え `DISABLE_CUSTOM_CORS_APIGATEWAY=1` を予防的に設定
   (現バージョンでは no-op)。

## 検証ログ

```text
$ AWS_ENDPOINT_URL=http://host.docker.internal:4566 \
    dotnet test tests/TodoApi.IntegrationTests
Passed:    12, Skipped:     0, Total:    12

$ dotnet test tests/TodoApi.UnitTests
Passed:    34, Skipped:     0, Total:    34

$ bash tests/infra/test-frontend-plan.sh
[OK] frontend plan assertions passed

$ bash tests/infra/test-cors-preflight-http.sh
[FAIL] /todos: expected 204, got 200
[FAIL] /todos/abc: expected 204, got 200
[KNOWN] floci 1.5.9 has no @OPTIONS handler in ApiGatewayUserRequestController.
```

## 残課題と推奨対応

1. **floci upstream 起票** (推奨): `floci-io/floci` に
   `[BUG] OPTIONS preflight is not dispatched to AWS_PROXY Lambda integration`
   を起票し、`@OPTIONS` ハンドラ追加を依頼する。
2. **E2E-1 / E2E-3**: floci 修正までローカル E2E では failing 状態のまま。
   本番 AWS では本実装で通る。CI に floci ローカル E2E を含める場合、
   `test-cors-preflight-http.sh` で RED を許容する仕組みが別途必要。
3. **production smoke test**: 本番デプロイ後、実 API Gateway で
   OPTIONS 204 + CORS を確認するスモークを既存運用へ追加することを推奨。
