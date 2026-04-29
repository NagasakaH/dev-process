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

`*.spec.ts` (unit) と `*.integration.spec.ts` (integration) を、karma config / tsconfig.spec / angular.json target / npm scripts レベルで分離する。`coverageReporter.check.global` で閾値強制し、未達時 CI fail させる (RD-005 / RD-008)。

## 実装ステップ (TDD: RED-GREEN-REFACTOR)

### RED
1. `frontend/src/app/__demo__/sample.spec.ts` (一時) と `frontend/src/app/__demo__/sample.integration.spec.ts` (一時) を作成 (ダミー `expect(true).toBe(true)`)
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
10. `cd frontend && npm run test:unit` / `npm run test:integration` がダミー spec で **GREEN** (coverage 閾値はダミー spec のみで `0%` のため意図的に低い閾値を一時設定し、後続タスクで実コードと spec が増えた段階で再評価。**ただし最終 PR 時点では §1.4 の閾値を満たすこと**)

### REFACTOR
11. ダミー `__demo__` spec を削除し、後続タスクが追加する `*.spec.ts` を待つ前提とする
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

- [ ] `npm run test:unit` がローカルで成功 (ChromeHeadlessCI)
- [ ] `npm run test:integration` がローカルで成功
- [ ] coverage 閾値設定 (lines:80 / statements:80 / branches:70 / functions:90) が両 karma config に存在
- [ ] `*.spec.ts` と `*.integration.spec.ts` が確実に分離される
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
