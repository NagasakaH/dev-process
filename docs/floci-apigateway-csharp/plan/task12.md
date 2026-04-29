# タスク: task12 - 弊害検証・リグレッション (.NET全テスト再実行 / curl OPTIONS / `dotnet format` / パフォーマンス / CI 全 stage グリーン確認)

## タスク情報

| 項目           | 値                                          |
| -------------- | ------------------------------------------- |
| タスク識別子   | task12                                      |
| 前提条件       | task06, task08, task09, task10, task11      |
| 並列実行可否   | 不可                                        |
| 推定所要時間   | 1.0h                                        |
| 優先度         | 高                                          |

## 作業環境

- 作業ディレクトリ: `/tmp/FRONTEND-001-task12/`
- ブランチ: `FRONTEND-001-task12`

## 設計参照

- [design/06_side-effect-verification.md](../design/06_side-effect-verification.md) §2 全項目, §3 検証順序

## 目的

`06_side-effect-verification.md` §2 に列挙された **既存機能の回帰** と **CORS / OPTIONS / S3 / nginx / CI / README 検証** をすべて実行し、結果を `result-task12.md` に集約する。実装変更は行わない (検証のみ)。

## 実行ステップ

### Step 1: 機能リグレッション検証 (§2.1)
1. `dotnet format --verify-no-changes` → exit 0
2. `dotnet test tests/TodoApi.UnitTests` → 全件 pass (CORS 期待値更新後)
3. floci + s3 起動状態で `dotnet test tests/TodoApi.IntegrationTests` → 全件 pass (task09 で追加した OPTIONS ケース含む)
4. `dotnet test tests/TodoApi.E2ETests` → 全件 pass (CORS ヘッダ追加後の APIGW で)
5. `POST /todos` 応答スキーマが既存と差分なし (追加ヘッダのみ) を `curl -i` で確認
6. `GET /todos/{id}` 同上
7. Step Functions / DDB の挙動が変わらないことを既存 IntegrationTests で確認

### Step 2: CORS / OPTIONS 検証 (§2.2)
8. `curl -i -X OPTIONS <invoke_url>/todos` → 204 + Allow-Origin/Methods/Headers/Max-Age
9. `curl -i -X OPTIONS <invoke_url>/todos/<id>` → 同上
10. `curl -i -X POST <invoke_url>/todos -d '{"title":"x"}'` → 201 + `Access-Control-Allow-Origin: *`
11. `curl -i -X GET <invoke_url>/todos/<id>` → 200 + 同上
12. 4xx / 5xx 応答にも CORS ヘッダ
13. `terraform show` で OPTIONS が AWS_PROXY 統合になっており MOCK 統合や `aws_api_gateway_method_response.response_parameters` の CORS 宣言が無いことを確認

### Step 3: パフォーマンス検証 (§2.3)
14. GitLab CI `web-e2e` ジョブ duration ≤ 15 分
15. `ng build --stats-json` → 初回 bundle ≤ 1MB (gzip)
16. `playwright.config.ts` の `workers: 1` 確認

### Step 4: セキュリティ検証 (§2.4)
17. `frontend/src/assets/config.json` (生成後) に floci 内 URL のみ含まれること
18. `AWS_ENDPOINT_URL=` 空で `web-e2e.sh` → exit 1 (実 AWS 到達防止)
19. `[innerHTML]` 不使用を `git grep '\[innerHTML\]' frontend/` で確認 (XSS)

### Step 5: 互換性 / インフラ検証 (§2.5, §2.6)
20. Chromium で E2E 全 pass (Playwright)
21. floci `floci/floci:latest` + Terraform 1.6.6 + Node 20 LTS / Angular 18 LTS の前提が `engines` / image tag で固定
22. README 既存セクション順序が無変更 (`git diff README.md` で確認)
23. `docker compose down -v` でボリューム残留無し

### Step 6: テスト環境準備 (§2.7)
24. `scripts/check-test-env.sh` → exit 0 (全 readiness OK)

### Step 7: CI 全 stage グリーン確認 (§3 H)
25. GitLab MR の pipeline で 既存 `.dotnet` (lint/unit/integration/e2e) + 新 `web-*` (lint/unit/integration/e2e) の **全ジョブ** が green であること

### Step 8: README 検証 (§3 I)
26. `bash scripts/verify-readme-sections.sh` → exit 0

### Step 9: ロールバック dry-run (§4)
27. `git revert --no-commit <task02-01 commit>` をローカル dry-run で実施し、CORS 変更のみ revert 可能なことを確認 (実際には revert を残さない)

## 成果物

- `docs/floci-apigateway-csharp/plan/result-task12.md`
  - §2 の各項目の pass/fail 結果テーブル
  - 実行ログ抜粋 / curl 出力 / CI pipeline URL
  - パフォーマンス計測値
  - 既存テストとの差分サマリー

## 完了条件

- [ ] `06_side-effect-verification.md` §2 の全項目 pass
- [ ] §3 検証順序のすべてのチェックが完了
- [ ] §4 ロールバック手順が dry-run で再現可能と確認
- [ ] acceptance_criteria 全 7 項目に対応するテストが実通過 (§5 対応表)
- [ ] result-task12.md 作成

## コミット

```bash
git add -A
git commit -m "refs FRONTEND-001 task12 弊害検証・リグレッション結果を集約

- 06_side-effect-verification.md §2 全項目を pass で確認
- .NET lint/unit/integration/e2e + 新 web-* (lint/unit/integration/e2e) を全 green で確認
- curl で OPTIONS 204+CORS / POST/GET の CORS 透過を確認
- ロールバック dry-run でフロント追加とインフラ追加が独立 revert 可能なことを確認"
```

## 注意事項

- 本タスクは **検証のみ**。コード変更が必要な場合は前のタスクへ差し戻し
- ロールバック dry-run の revert は最終的にコミットに含めない
