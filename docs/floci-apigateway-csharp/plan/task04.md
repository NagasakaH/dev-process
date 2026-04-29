# タスク: task04 - `TodoComponent` + `AppComponent` + `main.ts` bootstrap (DI / APP_INITIALIZER)

## タスク情報

| 項目           | 値                                |
| -------------- | --------------------------------- |
| タスク識別子   | task04                            |
| 前提条件       | task03-01, task03-02              |
| 並列実行可否   | 可（task07 / task09 と並列）      |
| 推定所要時間   | 1.0h                              |
| 優先度         | 高                                |

## 作業環境

- 作業ディレクトリ: `/tmp/FRONTEND-001-task04/`
- ブランチ: `FRONTEND-001-task04`

## 設計参照

- [design/02_interface-api-design.md](../design/02_interface-api-design.md) §3.2〜§3.4
- [design/04_process-flow-design.md](../design/04_process-flow-design.md) §5
- [design/05_test-plan.md](../design/05_test-plan.md) UT-8〜UT-10

## 目的

`TodoComponent` (フォーム + 取得フォーム + 結果表示 + エラー表示) と `AppComponent` (ルート、`TodoComponent` を直接配置) を実装。`main.ts` で `bootstrapApplication` + `provideHttpClient()` + `APP_INITIALIZER (ConfigService.load)` を登録し、`bootstrapApplication(...).catch(...)` で「設定読み込みエラー」フォールバック DOM を描画する。

> **責務境界 (RP-005 / RP-012)**: `APP_INITIALIZER` 登録、`main.ts` の bootstrap catch フォールバック、AppComponent の config-error 表示用ロジック (例: `BehaviorSubject<'config-error'>` 購読 / DOM 表示) は **すべて本タスク (task04)** が担当する。task06 (結合テスト) は本タスクで実装された UI を **検証するだけ** とし、AppComponent / main.ts のコード修正は行わない。

## 実装ステップ (TDD)

### RED
1. `frontend/src/app/todo/todo.component.spec.ts` を新規 (FAIL):
   - **UT-8**: `TodoApiService.create` を spy で 400 `{errors:['title is required']}` 返却 → DOM に "title is required" が表示
   - **UT-9**: 500 `{error:'internal'}` → "サーバエラーが発生しました" が表示
   - **UT-10**: `status===0` → "API に接続できませんでした" が表示
2. `frontend/src/app/app.component.spec.ts` (FAIL): `<app-todo>` がレンダリングされる

### GREEN
3. `frontend/src/app/todo/todo.component.{ts,html,css}`:
   - `ReactiveFormsModule` で title 入力 (required), description 任意
   - 送信ボタン → `TodoApiService.create()` を購読
   - 状態管理: `Loading | Ready | Submitting | ApiError4xx | ApiError5xx | NetworkError | ConfigError` (`04_process-flow-design.md` §5)
   - 取得フォームに id 入力 → `TodoApiService.get()`
4. `frontend/src/app/app.component.{ts,html}`: standalone, `<app-todo />` のみ
5. `frontend/src/main.ts`:
   ```typescript
   bootstrapApplication(AppComponent, {
     providers: [
       provideHttpClient(),
       { provide: APP_INITIALIZER, multi: true, deps:[ConfigService],
         useFactory: (cfg: ConfigService) => () => cfg.load() },
     ],
   }).catch(err => {
     document.body.innerHTML = '<div class="config-error">設定読み込みエラー</div>';
     console.error(err);
   });
   ```
6. `npm run test:unit` GREEN

### REFACTOR
7. テンプレートを Angular 標準 control flow (`@if`) で記述
8. `XSS 対策`: `[innerHTML]` を使用しない (Angular 既定エスケープに依拠)
9. `npm run build` がエラー無く完走

## 対象ファイル

| ファイル                                          | 操作 |
| ------------------------------------------------- | ---- |
| `frontend/src/app/todo/todo.component.{ts,html,css,spec.ts}` | 新規 |
| `frontend/src/app/app.component.{ts,html,css,spec.ts}`        | 新規 |
| `frontend/src/main.ts`                            | 修正 |

## 完了条件

- [ ] UT-8 / UT-9 / UT-10 が pass
- [ ] `npm run build` が成功
- [ ] `[innerHTML]` 不使用、Angular 標準エスケープのみ
- [ ] `APP_INITIALIZER` 登録および `bootstrapApplication(...).catch(...)` の config-error フォールバックが本タスクで実装される (RP-005 / RP-012)
- [ ] AppComponent 側の config-error 購読 / 表示ロジックが本タスクで完結する (task06 はテスト追加のみ)
- [ ] result.md 作成

## コミット

```bash
git add -A
git commit -m "refs FRONTEND-001 task04 TodoComponent と bootstrap を実装

- TodoComponent: title/description フォーム + 取得フォーム + エラー表示
- AppComponent: standalone ルートで TodoComponent を直接配置
- main.ts: APP_INITIALIZER で ConfigService.load() を起動時実行
- UT-8/9/10 (4xx/5xx/network) を pass"
```
