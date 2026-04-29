# タスク: task09 - .NET `TodoApi.IntegrationTests` に `OPTIONS` 204+CORS ケース追加

## タスク情報

| 項目           | 値                                |
| -------------- | --------------------------------- |
| タスク識別子   | task09                            |
| 前提条件       | task02-01, task02-02              |
| 並列実行可否   | 可（task04 / task07 と並列）      |
| 推定所要時間   | 0.5h                              |
| 優先度         | 中                                |

## 作業環境

- 作業ディレクトリ: `/tmp/FRONTEND-001-task09/`
- ブランチ: `FRONTEND-001-task09`

## 設計参照

- [design/05_test-plan.md](../design/05_test-plan.md) §3
- [design/06_side-effect-verification.md](../design/06_side-effect-verification.md) §2.2

## 目的

API Gateway 経由で `OPTIONS /todos` / `OPTIONS /todos/{id}` が **204 + 必須 CORS ヘッダ** を返すこと、および POST/GET 応答に CORS ヘッダが含まれることを既存 `TodoApi.IntegrationTests` に追加する。

## 実装ステップ (TDD)

### RED
1. `tests/TodoApi.IntegrationTests/CorsOptionsTests.cs` (新規) を追加:
   - `OPTIONS /todos` → `204`, `Access-Control-Allow-Origin: *`, `Allow-Methods: GET, POST, OPTIONS`, `Allow-Headers: Content-Type`, `Max-Age: 600`
   - `OPTIONS /todos/{id}` → 同上
   - `POST /todos` 成功時に `Access-Control-Allow-Origin: *` を含む
   - `GET /todos/{id}` 成功時に同上
   - 4xx/5xx 応答にも CORS ヘッダが含まれる
2. `dotnet test tests/TodoApi.IntegrationTests` を **FAIL** で確認 (Lambda + Terraform 反映前なら failing)

### GREEN
3. task02-01 (Lambda CORS) + task02-02 (Terraform OPTIONS) が apply 済みの floci に対して `dotnet test` を **GREEN** で確認

### REFACTOR
4. CORS 期待値を `[Theory]` で `/todos` / `/todos/{id}` を共通化

## 対象ファイル

| ファイル                                                | 操作 |
| ------------------------------------------------------- | ---- |
| `tests/TodoApi.IntegrationTests/CorsOptionsTests.cs`    | 新規 |

## 完了条件

- [ ] 上記 5 ケースが pass
- [ ] 既存 IntegrationTests が引き続き pass
- [ ] **(RP2-003)** task02-01 + task02-02 統合前は本タスクの `OPTIONS /todos` ケースが **RED**（exit non-zero）であることを `dotnet test` で確認し、両タスク統合後に **GREEN** になることを cherry-pick 後に検証する。task02-02 側の RED と切り離し、cross-task RED の保証は **task09 側で完結**させる
- [ ] result.md 作成

## コミット

```bash
git add -A
git commit -m "refs FRONTEND-001 task09 .NET IntegrationTests に OPTIONS 204+CORS ケース追加

- /todos, /todos/{id} の OPTIONS が 204 + 必須 CORS ヘッダで応答することを検証
- POST/GET および 4xx/5xx 応答にも Access-Control-Allow-Origin が付与されることを検証"
```
