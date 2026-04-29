# タスク: task11 - `README.md` Frontend セクション追記 + `scripts/verify-readme-sections.sh` 更新

## タスク情報

| 項目           | 値                       |
| -------------- | ------------------------ |
| タスク識別子   | task11                   |
| 前提条件       | task07, task10           |
| 並列実行可否   | 不可                     |
| 推定所要時間   | 0.5h                     |
| 優先度         | 中                       |

## 作業環境

- 作業ディレクトリ: `/tmp/FRONTEND-001-task11/`
- ブランチ: `FRONTEND-001-task11`

## 設計参照

- [design/05_test-plan.md](../design/05_test-plan.md) §1.6 (検証対象見出し一覧)
- [design/06_side-effect-verification.md](../design/06_side-effect-verification.md) §2.5

## 目的

`README.md` に Frontend セクション (6 見出し) を追記し、`scripts/verify-readme-sections.sh` の検証対象を `05_test-plan.md` §1.6 の表に合わせて拡張する (RD-010)。

## 実装ステップ (TDD)

### RED
1. `scripts/verify-readme-sections.sh` を実行 → README に `## Frontend` 等が無いため exit 1 を確認 (RED)
2. `verify-readme-sections.sh` を更新後 README が未追記の状態で exit 1 を維持

### GREEN
3. `scripts/verify-readme-sections.sh`:
   - 既存の検証対象見出し (例: `## ローカル起動`, `## テスト`, `## CI`) を保持
   - 新規必須見出し 6 件を追加 (`## Frontend`, `### Frontend ローカル起動`, `### Frontend ローカルテスト`, `### Frontend E2E テスト`, `### Frontend CI 実行手順`, `### Frontend 環境変数 (WEB_BASE_URL / AWS_ENDPOINT_URL / API_BASE_URL)`)
   - 検証ロジックは `grep -F -q` で完全一致、欠落時 `exit 1`
4. `README.md` に下記 6 見出しを追記:
   - `## Frontend` 概要
   - `### Frontend ローカル起動` (`scripts/deploy-local.sh` → `scripts/build-frontend.sh` → `scripts/deploy-frontend.sh` → `docker compose up -d nginx` → http://localhost:8080)
   - `### Frontend ローカルテスト` (`cd frontend && npm run test:unit`, `npm run test:integration`)
   - `### Frontend E2E テスト` (`scripts/web-e2e.sh` の手順、必須 env 一覧)
   - `### Frontend CI 実行手順` (web-lint / web-unit / web-integration / web-e2e の概要、DinD 必須)
   - `### Frontend 環境変数 (WEB_BASE_URL / AWS_ENDPOINT_URL / API_BASE_URL)` (各 env の用途と未設定時の fail-fast 挙動)
5. `bash scripts/verify-readme-sections.sh` で **GREEN**

### REFACTOR
6. README 内のリンクを設計ドキュメントへ追加 (`docs/floci-apigateway-csharp/design/`)
7. 既存セクション順序を変更しない (`06_side-effect-verification.md` §2.5)

## 対象ファイル

| ファイル                                | 操作 |
| --------------------------------------- | ---- |
| `README.md`                             | 修正 |
| `scripts/verify-readme-sections.sh`     | 修正 |

## 完了条件

- [ ] `bash scripts/verify-readme-sections.sh` が exit 0
- [ ] 既存セクションの順序が変わっていない
- [ ] `## Frontend` 配下 6 見出しが全て存在
- [ ] result.md 作成

## コミット

```bash
git add -A
git commit -m "refs FRONTEND-001 task11 README に Frontend セクション 6 件を追加 + verify script 拡張

- README.md に ## Frontend / ローカル起動 / ローカルテスト / E2E テスト / CI 実行手順 / 環境変数 を追記
- scripts/verify-readme-sections.sh: 必須見出し 6 件を grep -F で機械検証 (RD-010)
- 既存セクション順序は無変更 (回帰防止)"
```
