# コードレビュー修正結果 — Round 01

**チケット**: WEB-DESIGN-001
**対象リポジトリ**: web-design
**日付**: 2026-02-27

## 対応結果サマリ

- **修正 (fixed)**: 9件 (Major 4件 + Minor 5件)
- **反論 (disputed)**: 0件

## Major 指摘 (4件)

| ID      | 重大度 | 対応 | 説明                                                                               |
| ------- | ------ | ---- | ---------------------------------------------------------------------------------- |
| MCR-001 | Major  | 修正 | docker.sock chmod 666 → chmod 660 + dockerグループ追加                              |
| MCR-002 | Major  | 修正 | execInContainer コマンドインジェクション → execFileSync + containerNameバリデーション |
| MCR-003 | Major  | 修正 | DinD/DooDテスト同一 → 各モード固有の検証追加 + DOCKER_MODEスキップ制御              |
| MCR-004 | Major  | 修正 | tsbuildinfo コミット → .gitignore追加 + git rm --cached                              |

## Minor 指摘 (5件)

| ID      | 重大度 | 対応 | 説明                                                                    |
| ------- | ------ | ---- | ----------------------------------------------------------------------- |
| MCR-005 | Minor  | 修正 | MSW init エラーハンドリング → .catch() + フォールバック描画             |
| MCR-006 | Minor  | 修正 | .editorconfig 新規作成                                                  |
| MCR-007 | Minor  | 修正 | .prettierignore 新規作成                                                |
| MCR-008 | Minor  | 修正 | waitForTimeout → waitForFunction(SW controller check)                   |
| MCR-009 | Minor  | 修正 | root element non-null assertion → 明示的nullチェック + エラーメッセージ |

## 修正詳細

### MCR-001: docker.sock chmod 666 (セキュリティ)

**ファイル**: `.devcontainer/scripts/start-code-server.sh`

- `chmod 666 /var/run/docker.sock` を `chmod 660` に変更
- docker.sock の GID を取得し、docker グループを作成
- vscode ユーザーを docker グループに追加

### MCR-002: execInContainer コマンドインジェクション (セキュリティ)

**ファイル**: `e2e/helpers/container.ts`

- `execSync` テンプレートリテラル → `execFileSync('docker', [...])` に変更
- `containerName` のバリデーション（英数字・ハイフン・アンダースコア・ドットのみ）を追加

### MCR-003: DinD/DooD テスト同一 (テスト品質)

**ファイル**: `e2e/docker-mode.spec.ts`

- DinDテスト: コンテナ内 dockerd の独立性を `docker info` で確認
- DooDテスト: `mount | grep docker.sock` でホストソケットマウント確認、ホスト共有確認
- `DOCKER_MODE` 環境変数によるスキップ制御を追加

### MCR-004: tsbuildinfo コミット (Git作法)

**ファイル**: `.gitignore`

- `*.tsbuildinfo` パターンを追加
- `git rm --cached tsconfig.app.tsbuildinfo tsconfig.node.tsbuildinfo` で追跡解除

### MCR-005: MSW init エラーハンドリング

**ファイル**: `src/main.tsx`

- `enableMocking().then().catch()` パターンに変更
- エラー時もフォールバック描画を実行

### MCR-006: .editorconfig 新規作成

標準的な設定: indent_style=space, indent_size=2, end_of_line=lf, charset=utf-8

### MCR-007: .prettierignore 新規作成

node_modules/, dist/, package-lock.json, public/mockServiceWorker.js, *.tsbuildinfo

### MCR-008: msw.spec.ts waitForTimeout

**ファイル**: `e2e/msw.spec.ts`

- `page.waitForTimeout(2000)` → `page.waitForFunction(() => navigator.serviceWorker.controller !== null, { timeout: 10_000 })`

### MCR-009: root element non-null assertion

**ファイル**: `src/main.tsx`

- `document.getElementById('root')!` → 変数に取得後 null チェック + エラーメッセージ

## 検証結果

- **ビルド (`npm run build`)**: ✅ 成功
- **リント (`npm run lint`)**: ✅ エラーなし
- **型チェック (`npx tsc --noEmit`)**: ✅ エラーなし

## 次のステップ

code-review スキルで再レビューを実施してください。
