# タスク: task06 - 結合テスト IT-1〜IT-6 (`HttpTestingController`)

## タスク情報

| 項目           | 値                       |
| -------------- | ------------------------ |
| タスク識別子   | task06                   |
| 前提条件       | task04, task05           |
| 並列実行可否   | 可（task08 と並列）      |
| 推定所要時間   | 1.0h                     |
| 優先度         | 高                       |

## 作業環境

- 作業ディレクトリ: `/tmp/FRONTEND-001-task06/`
- ブランチ: `FRONTEND-001-task06`

## 設計参照

- [design/05_test-plan.md](../design/05_test-plan.md) §1.3, §2.2 (IT-1〜IT-6)

## 目的

`*.integration.spec.ts` 命名で結合テストを追加し、`HttpTestingController` で 1 件のリクエストを 1 回だけ flush することを検証する。

## 実装ステップ (TDD)

### RED
1. `frontend/src/app/todo/todo.flow.integration.spec.ts` (新規) に下記を実装 (FAIL):
   - **IT-1**: フォーム入力 → 送信で `POST <apiBaseUrl>/todos` が 1 回発行され 201 flush 後 DOM に結果反映
   - **IT-2**: `ConfigService.load()` 後の `apiBaseUrl` がリクエスト URL に反映される
   - **IT-3**: 400 `{errors:['title is required']}` flush → DOM に該当文言
   - **IT-4**: 500 flush → "サーバエラーが発生しました"
   - **IT-5**: `error(new ProgressEvent('error'))` flush → "API に接続できませんでした"
   - **IT-6**: `/assets/config.json` を 404 flush → アプリ全体が「設定読み込みエラー」状態
2. `npm run test:integration` で **FAIL**

### GREEN
3. 既存実装 (task03-*, task04) で IT-1〜IT-5 が pass
4. IT-6 については `main.ts` の `bootstrapApplication(...).catch(...)` フォールバック表示が必要 → 既に task04 で実装済み。テスト容易性のため `ConfigService.load` の reject を `BehaviorSubject<'config-error'>` 経由でも公開できるようにし、`AppComponent` 側でも捕捉表示を追加 (必要に応じて)
5. `npm run test:integration` で **GREEN**

### REFACTOR
6. テストヘルパ `setupTodoFlow()` を抽出
7. coverage 閾値 (statements:80 / lines:80 / branches:70 / functions:90) を満たすことを `coverage/integration/text-summary` で確認

## 対象ファイル

| ファイル                                                          | 操作 |
| ----------------------------------------------------------------- | ---- |
| `frontend/src/app/todo/todo.flow.integration.spec.ts`             | 新規 |
| `frontend/src/app/services/config.bootstrap.integration.spec.ts`  | 新規 (IT-6) |

## 完了条件

- [ ] IT-1〜IT-6 がすべて pass
- [ ] `karma.integration.conf.js` の coverage 閾値を満たす
- [ ] result.md 作成

## コミット

```bash
git add -A
git commit -m "refs FRONTEND-001 task06 Angular 結合テスト IT-1〜IT-6 を追加

- HttpTestingController で TodoComponent ↔ TodoApiService ↔ HTTP 境界を検証
- 4xx/5xx/network/ConfigError パスの DOM 反映を検証
- *.integration.spec.ts 命名で test-integration target に分離 (RD-005)"
```
