# レビュー統合サマリー - Round 1

## レビュー情報
- リポジトリ: floci-apigateway-csharp（FRONTEND-001 実装一式）
- ブランチ: feature/FRONTEND-001
- HEAD: 68d9995 `refs FRONTEND-001 create_mr_pr (Code) ブロック記録`
- レビュー方式: dual-model (Claude Opus 4.7 + GPT-5.5) → Opus 4.7 統合
- レビュー日時: 2026-04-29
- MR/PR: **未作成**（create-mr-pr が verification failed のためブロックされ未発行）

## 前提状況
- verification: **failed**（Round 4 で AC1/AC5/E2E 未達、TC-08 未達）
- implement: in_progress（Round 4 修正後の検証で未充足項目が残置）
- create-mr-pr (Codeモード): **blocked**（verification failed のため発行不可）
- 本ラウンドはローカルブランチ差分に対するレビューであり、MR/PR ディスクリプション由来の要求項目抽出はスキップ

## 総合判定
- **判定**: ❌ 差し戻し（revision_required）
- **指摘合計**: Critical 3件 / Major 9件 / Minor 4件 / Info 1件
- **主因**:
  - AC5 / E2E（E2E-1〜E2E-6）が CI/実環境で全通過しておらず、テスト戦略上の必須ゲート未達
  - Lambda OPTIONS 分岐とパスパラメータ取り扱いに仕様外動作の余地
  - Frontend 側のセキュリティ（innerHTML）/ 型整合 / カバレッジ閾値検査の脆さ

## チェックリスト結果（9カテゴリ）

| # | カテゴリ | 結果 | 主な指摘 |
|---|---------|------|---------|
| TC-01 | 設計準拠性 | ✅ pass | — |
| TC-02 | 静的解析 | ✅ pass | — |
| TC-03 | 言語別BP | ❌ fail | CR-009/CR-010/CR-011 |
| TC-04 | セキュリティ | ❌ fail | CR-011/CR-016 |
| TC-05 | テスト・CI | ❌ fail | CR-001/CR-002/CR-003/CR-005/CR-006/CR-008/CR-012/CR-013 |
| TC-06 | パフォーマンス | ❓ unknown | 計測未実施 |
| TC-07 | ドキュメント | ❓ unknown | レビュー対象外 |
| TC-08 | Git作法 | ❌ fail | package-lock 等は別コミット推奨（Info） |
| TC-09 | MR要求項目 | ✅ pass(N/A) | MR/PR 未発行のため対象外 |

## 指摘事項（統合・全件 修正必須）

### 🔴 Critical
- **CR-001** verification failed / create_mr_pr failed
  - カテゴリ: テスト・CI
  - 説明: AC1 / AC5 / E2E が未達、TC-08 未達。verification round4 と create-mr-pr blocked report が根拠。
  - 修正提案: floci の OPTIONS 制約を解消するか、合意済みの代替検証環境で AC を実証する。証跡を verification に追記。
- **CR-002** E2E-6 が `test.skip` で実行されておらず AC5 未達
  - カテゴリ: テスト・CI
  - 説明: AC5 は E2E-1〜E2E-6 全通過が条件だが、E2E-6 が skip されている。WEB_BASE_URL 未設定時の fail-fast を実テスト/CI で検証し、skip を撤廃する必要あり。
  - 修正提案: skip を解除し、必須前提未充足時はテスト失敗とする。CI で実行すること。
- **CR-003** E2E-1 が作成 Todo の title 一致を検証していない
  - カテゴリ: テスト・CI
  - 説明: ID 表示のみ確認しているため Acceptance Criteria の検証として不足。
  - 修正提案: 作成 Todo の title・status の一致をアサートに加える。

### 🟠 Major
- **CR-004** Frontend `TodoStatus` / POST 型が実 Backend と不一致の可能性
  - 修正提案: status は `pending`/`done`、POST 応答は `{id, executionArn}` に揃える。型定義とテストを更新。
- **CR-005** CORS HTTP preflight RED テストが invoke_url 未取得時 `exit 0` で skip
  - 修正提案: 必須前提未充足時はテスト失敗、もしくは明示的な手動 skip オプションのみに限定。CI のゲートとして機能させる。
- **CR-007** `compose/docker-compose.yml` に no-op env `DISABLE_CUSTOM_CORS_APIGATEWAY` が残置
  - 修正提案: 削除、または利用箇所を明確化。
- **CR-008** `scripts/web-e2e.sh` の `terraform state show` + awk 抽出が脆い
  - 修正提案: `terraform output -json` 等の machine-readable 出力に変更し、jq でパースする。
- **CR-009** Lambda OPTIONS 分岐が任意 resource に 204 + CORS を返しうる
  - 修正提案: 対象 resource を `/todos`, `/todos/{id}` に限定。未知の OPTIONS は 404 を返す。
- **CR-010** Lambda `GET /todos/foo/bar` が id `foo/bar` として通り得る
  - 修正提案: resource / id segment の検証を厳格化（スラッシュ禁止・形式バリデーション）。
- **CR-011** `frontend/src/main.ts` の `innerHTML` 使用
  - カテゴリ: セキュリティ
  - 修正提案: `createElement` / `textContent` を用いた DOM 構築に置き換え、XSS リスクを排除。
- **CR-012** `frontend/scripts/check-coverage-threshold.js` が XML 正規表現でカバレッジを抽出している
  - 修正提案: `json-summary` 等の構造化形式を使用し、JSON.parse でフィールドを取得。

### 🟡 Minor
- **CR-006** GitLab `web-unit` / `web-integration` JUnit report path と Karma 出力先の不一致の可能性
  - 修正提案: 出力先パスを揃え、CI 上で artifact の存在を確認する。
- **CR-013** `SkipIfNoFlociTheory` の skip 理由 / 件数のトレース性が低い
  - 修正提案: skip 理由・件数のログ化、または verification 手順に明記。
- **CR-014** `infra/outputs.tf` の `frontend_url` が `localhost:8080` ハードコード
  - 修正提案: CI とのギャップをコメント化、または変数化して環境ごとに切替可能にする。
- **CR-015** GitLab `web-e2e` CI のツール install が重い
  - 修正提案: 事前ビルドイメージ（Playwright 同梱イメージ等）の利用を検討。

### 🔵 Info
- **CR-016** CORS `*` の将来リスク
  - 修正提案: `ALLOWED_ORIGIN` env 等で制御可能にし、本番では明示オリジンに絞れる構造を持たせる。
- 補足: 実 AWS 環境での CORS contract GREEN 証跡が必要。`package-lock.json` 系の更新は次回の別コミット推奨。

## MR/PR 結果書き込み
- **未実施**: MR/PR 未発行（create_mr_pr が blocked、verification failed のため）。
- 対応方針: verification を再度通過させ create-mr-pr を実行した後に、本サマリーをコメント投稿し、description チェックリストを更新する。Draft 解除は全 Minor 以上の指摘解消後に行う。

## 生成されたファイル
- docs/floci-apigateway-csharp/code-review/round-01-summary.md
