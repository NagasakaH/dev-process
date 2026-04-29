# タスク: task01 - Angular 18.2 frontend スキャフォールド

## タスク情報

| 項目           | 値                                |
| -------------- | --------------------------------- |
| タスク識別子   | task01                            |
| 前提条件       | なし                              |
| 並列実行可否   | 不可                              |
| 推定所要時間   | 1.0h                              |
| 優先度         | 高                                |

## 作業環境

- 作業ディレクトリ: `/tmp/FRONTEND-001-task01/`
- ブランチ: `FRONTEND-001-task01`

## 設計参照

- [design/01_implementation-approach.md](../design/01_implementation-approach.md) §1.2
- [design/03_data-structure-design.md](../design/03_data-structure-design.md) §6.2
- [design/05_test-plan.md](../design/05_test-plan.md) §1.3 npm scripts

## 目的

`floci-apigateway-csharp/frontend/` 配下に Angular 18.2 LTS の SPA プロジェクトを新規作成し、後続タスクが利用する基盤（package.json / tsconfig / angular.json / ESLint / engines / npm scripts スケルトン）を整える。

## 実装ステップ

1. `frontend/` ディレクトリを新規作成（リポジトリルート直下）
2. Angular 18.2 LTS の standalone components 構成で scaffold:
   - `frontend/package.json`（`~18.2.0` ピン、`engines.node: "^20.11.0"`、`engines.npm: "^10.0.0"`）
   - `frontend/angular.json`（**project 名は `frontend` で固定**、`projects.frontend.architect.build.options.outputPath = { "base": "dist", "browser": "" }` を設定し成果物を **`frontend/dist/index.html`** 直下に出力する。`projects.frontend.architect.test` のみ仮設定。`test-integration` は task05 で追加）— RP-002 配信成果物パス統一
   - `frontend/tsconfig.json` / `frontend/tsconfig.app.json`
   - `frontend/src/index.html` / `src/main.ts`（最小 bootstrap、`AppComponent` は仮プレースホルダ）
   - `frontend/src/styles.css`
3. ESLint (`@angular-eslint`) を導入し **`frontend/eslint.config.js` (ESLint flat config)** を追加（Angular 18 推奨、RP-017）。legacy `.eslintrc.json` は採用しない
4. npm scripts スケルトン: `lint` / `build` / `test:unit` / `test:integration` / `e2e`（中身は後続タスクで実装、`exit 0` でも可）
5. `frontend/.gitignore` に `node_modules/` `dist/` `coverage/` `playwright-report/` `test-results/` `.angular/` を追加
6. `frontend/README.md` に「scaffold のみ。詳細は task01 以降」と最小記載

## 対象ファイル

| ファイル                              | 操作   |
| ------------------------------------- | ------ |
| `frontend/package.json`                | 新規   |
| `frontend/angular.json`                | 新規   |
| `frontend/tsconfig*.json`              | 新規   |
| `frontend/src/index.html`              | 新規   |
| `frontend/src/main.ts`                 | 新規   |
| `frontend/src/styles.css`              | 新規   |
| `frontend/eslint.config.js`            | 新規 (flat config / RP-017) |
| `frontend/.gitignore`                  | 新規   |
| `frontend/README.md`                   | 新規   |

## テスト方針 (TDD: RED-GREEN-REFACTOR)

### RED
- 失敗テスト: `npm ci && npm run lint && npm run build` がローカル devcontainer で成功することを smoke として検証する。事前に「`ng build` が `Cannot find module @angular/core`」で失敗することを確認。

### GREEN
- 上記依存をインストールし、`npm ci` / `ng build` が exit 0 となるよう scaffold を完成させる。
- `node -v` が `v20.11.x` であること（README に確認手順を記載）。

### REFACTOR
- `package-lock.json` をコミットに含め CI 再現性を担保
- `engines` フィールドの整合確認（`node ^20.11.0`, `npm ^10.0.0`）
- ESLint flat config (`eslint.config.js`) を Angular 18 標準セットに合わせる (RP-017)
- `outputPath` の `{ base: "dist", browser: "" }` 設定により成果物が `frontend/dist/index.html` に出ることを `ng build` 後に確認 (RP-002)

## 完了条件

- [ ] `frontend/package.json` に Angular 18.2 / Node 20.11 LTS ピンが入っている
- [ ] `cd frontend && npm ci && npm run build` がローカルで成功
- [ ] `npm run lint` がローカルで成功（コード未実装でも 0 件）
- [ ] `frontend/.gitignore` が node_modules / dist / coverage 等を除外
- [ ] `eslint.config.js` (flat config) が存在し、`.eslintrc.json` を作成しない (RP-017)
- [ ] `ng build` 後 `test -f frontend/dist/index.html` が真 (RP-002)
- [ ] result.md を `docs/floci-apigateway-csharp/plan/result-task01.md` に作成

## コミット

```bash
git add -A
git commit -m "refs FRONTEND-001 task01 Angular 18.2 frontend scaffold

- frontend/ ディレクトリを新規作成し Angular 18.2 LTS の standalone bootstrap scaffold を追加
- package.json は ~18.2.0 / engines.node ^20.11.0 にピン
- ESLint / tsconfig / angular.json / .gitignore を追加し後続タスクの基盤を整備"
```

## 注意事項

- `frontend/` 配下に閉じる。ルートの既存 .NET / Terraform ファイルは触らない
- `package-lock.json` を必ずコミットし CI 再現性を担保
