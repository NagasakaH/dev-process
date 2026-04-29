# タスク: task05 - Karma unit/integration 分離 + tsconfig.spec.* + angular.json target + npm scripts + coverage 閾値

## タスク情報

| 項目           | 値                                          |
| -------------- | ------------------------------------------- |
| タスク識別子   | task05                                      |
| 前提条件       | task01                                      |
| 並列実行可否   | 可（task02-01〜task02-04 と並列）           |
| 推定所要時間   | 0.75h                                       |
| 優先度         | 高                                          |

## 作業環境

- 作業ディレクトリ: `/tmp/FRONTEND-001-task05/`
- ブランチ: `FRONTEND-001-task05`

## 設計参照

- [design/05_test-plan.md](../design/05_test-plan.md) §1.3, §1.4

## 目的

`*.spec.ts` (unit) と `*.integration.spec.ts` (integration) を、karma config / tsconfig.spec / angular.json target / npm scripts レベルで分離する。`coverageReporter.check.global` で **最初から最終閾値** (statements:80 / branches:70 / functions:90 / lines:80) を強制し、未達時 CI fail させる (RD-005 / RD-008 / RP-006)。**暫定的な低閾値運用は禁止**。

> **(RP2-004) 本タスクの GREEN 判定スコープ**: 本タスクは **karma config / tsconfig.spec / angular.json target / npm scripts の構成検証のみ** で GREEN 判定する。`__demo__` 一時 spec は削除済み前提なので coverage 0% で `npm run test:unit` を実行すると閾値で必ず fail するため、**実 `npm run test:unit` / `npm run test:integration` の coverage 閾値ゲートは本タスクの GREEN 条件にしない**。実行は task06 (結合テスト追加) 完了後の **後続統合ゲート（task06 完了後の Group 5 / G5 verification、および task10 の `web-unit` / `web-integration` ジョブ）** で初めて要求する。本タスク内では `ng config -g` / `ng test --help` / 設定ファイルの存在・内容検証 (`grep` / `node -e "require('./karma.conf.js')"` 相当) で構成の妥当性のみを確認する。

## 実装ステップ (TDD: RED-GREEN-REFACTOR)

### RED
1. `frontend/src/app/__demo__/sample.spec.ts` (一時) と `frontend/src/app/__demo__/sample.integration.spec.ts` (一時) を作成 (ダミー `expect(true).toBe(true)`)。**本タスク完了時に削除する一時ファイルである**ことを明示するため、ファイル冒頭に `// TEMPORARY: removed before task05 completion (RP-018)` コメントを必ず付ける
2. `cd frontend && npm run test:unit` がまだ未設定で失敗 / `npm run test:integration` も失敗することを確認

### GREEN
3. `frontend/karma.conf.js` を新規作成 (or `ng test` 既定をベース):
   - `files` glob で `**/*.integration.spec.ts` を **exclude**
   - `coverageReporter.check.global = { statements:80, branches:70, functions:90, lines:80 }`
   - `reporters: ['progress', 'kjhtml', 'junit', 'coverage']`, `karma-junit-reporter` 設定
4. `frontend/karma.integration.conf.js` を新規作成:
   - `files` glob を `**/*.integration.spec.ts` に絞る
   - 同等の coverage 閾値・junit/cobertura レポータ
5. `frontend/tsconfig.spec.json` (include: `**/*.spec.ts`, exclude: `**/*.integration.spec.ts`)
6. `frontend/tsconfig.spec.integration.json` (include: `**/*.integration.spec.ts`)
7. `frontend/angular.json`:
   - `architect.test` を `karma.conf.js` / `tsconfig.spec.json` に対応
   - `architect.test-integration` を新設し `karma.integration.conf.js` / `tsconfig.spec.integration.json` を参照
8. `frontend/package.json` `scripts`:
   ```json
   {
     "lint": "ng lint",
     "test:unit": "ng test --watch=false --browsers=ChromeHeadlessCI",
     "test:integration": "ng run frontend:test-integration --watch=false --browsers=ChromeHeadlessCI",
     "build": "ng build --configuration=production",
     "e2e": "playwright test"
   }
   ```
9. `karma-jasmine` / `karma-chrome-launcher` / `karma-junit-reporter` / `karma-coverage` / `jasmine-core` を devDependency に追加
10. `__demo__/*.spec.ts` を **本タスク内で必ず削除** する。**(RP2-004)** 削除後は **karma config / tsconfig.spec / angular.json target / npm scripts の構成検証のみ** で GREEN 判定する（実 `npm run test:unit` / `npm run test:integration` の coverage 閾値ゲートは task06 完了後の後続統合ゲートで実施）。本タスク内の構成検証手段:
    - `node -e "const c=require('./frontend/karma.conf.js'); c({set:o=>console.log(JSON.stringify(o.coverageReporter.check.global))})"` 相当で global 閾値が `statements:80 / branches:70 / functions:90 / lines:80` であることを確認
    - `jq -e '.projects.frontend.architect.test.builder' frontend/angular.json` および `architect["test-integration"]` の存在を確認
    - `jq -e '.scripts["test:unit"], .scripts["test:integration"], .scripts.lint, .scripts.build, .scripts.e2e' frontend/package.json` がすべて非 null
    - `tsconfig.spec.json` の include/exclude が `**/*.integration.spec.ts` を排他に分離している
    - `ng test --help` (or `ng run frontend:test --help`) の exit 0 のみを許容
    > `ng test --dry-run` 相当を「正式な GREEN 手段」として扱わない（RP2-004）。閾値の一時引き下げ・暫定運用は引き続き禁止 (RP-006)。

### REFACTOR
11. `__demo__` ディレクトリが消えていることを `test ! -d frontend/src/app/__demo__` で検証 (RP-018)
12. `ChromeHeadlessCI` の launcher 定義を `karma.conf.js` 共通モジュール化
13. coverage 出力先 `coverage/unit/` / `coverage/integration/` を分離

## 対象ファイル

| ファイル                                       | 操作 |
| ---------------------------------------------- | ---- |
| `frontend/karma.conf.js`                       | 新規 |
| `frontend/karma.integration.conf.js`           | 新規 |
| `frontend/tsconfig.spec.json`                  | 新規 |
| `frontend/tsconfig.spec.integration.json`      | 新規 |
| `frontend/angular.json`                        | 修正 |
| `frontend/package.json`                        | 修正 |

## 完了条件

- [ ] **(RP2-004)** karma config の `coverageReporter.check.global` が statements:80 / branches:70 / functions:90 / lines:80 で設定されていることを `node -e` で検証 (構成検証のみ)
- [ ] **(RP2-004)** `frontend/angular.json` に `architect.test` と `architect.test-integration` が存在し、それぞれ `karma.conf.js` / `karma.integration.conf.js` を参照
- [ ] **(RP2-004)** `frontend/package.json` の `scripts` に `lint` / `test:unit` / `test:integration` / `build` / `e2e` がすべて定義
- [ ] **(RP2-004)** `tsconfig.spec.json` が `**/*.integration.spec.ts` を `exclude` し、`tsconfig.spec.integration.json` が `**/*.integration.spec.ts` のみ `include` する
- [ ] coverage 閾値設定が **最初から最終値** (statements:80 / branches:70 / functions:90 / lines:80) で両 karma config に存在 (RP-006、暫定低閾値禁止)
- [ ] `*.spec.ts` と `*.integration.spec.ts` が確実に分離される
- [ ] `test ! -d frontend/src/app/__demo__` が真（`__demo__` ディレクトリが存在しない、RP-018）
- [ ] **(RP2-004)** 実 `npm run test:unit` / `npm run test:integration` の coverage 閾値ゲート判定は **後続統合ゲート (task06 完了後の G5 verification および task10 の `web-unit` / `web-integration` ジョブ)** で実施することを result.md に明記し、本タスクでは構成検証のみで完了
- [ ] result.md 作成

## コミット

```bash
git add -A
git commit -m "refs FRONTEND-001 task05 Karma unit/integration 分離+カバレッジ閾値強制

- karma.conf.js / karma.integration.conf.js を新設
- tsconfig.spec.json / tsconfig.spec.integration.json を分離
- angular.json に test / test-integration target を定義
- npm scripts: test:unit / test:integration を追加
- coverageReporter.check.global で閾値強制 (RD-005 / RD-008)"
```

## 注意事項

- `ChromeHeadlessCI` は `mcr.microsoft.com/playwright:v1.45.3-jammy` 同梱 Chromium で動作する想定
