# 01. 実装方針

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | viewer-container-local |
| タスク名 | container |
| 作成日 | 2026-03-21 |
| 調査結果参照 | [investigation/](../investigation/) |

---

## 1. 方針サマリー

copilot-session-viewer を単一コンテナで自己完結動作させるため、以下のハイブリッドアプローチを採用する。

- **viewer リポジトリ側**に `Dockerfile` + `compose.yaml` + エントリポイントスクリプトを新規作成
- **dev-process の既存パターン**（tini + start-tmux.sh + cplt）を参考に、viewer 専用のコンテナ起動フローを構築
- **ローカル（非コンテナ）動作を維持**しつつ、コンテナ内でも同じロジックで動作するように設計

---

## 2. アプローチ比較

### 案A: dev-process コンテナに viewer を統合

- dev-process の既存 Dockerfile に Next.js ビルドを追加
- **不採用理由**: dev-process と viewer の責務が混在する。viewer 側の独立開発が困難

### 案B: viewer 側に新規 Dockerfile を作成（採用）

- copilot-session-viewer リポジトリに Dockerfile + compose.yaml を作成
- dev-process のパターン（tini, start-tmux.sh, cplt）を参考に viewer 専用スクリプトを構築
- **採用理由**: 
  - 責務が明確に分離される
  - viewer 側だけで完結してビルド・テスト可能
  - 将来の拡張（マルチコンテナ化等）にも柔軟

### 案C: devcontainer.json ベース

- VS Code devcontainer として構築
- **不採用理由**: ヘッドレスサーバーとして独立稼働する要件に合わない

---

## 3. 技術選定

### 3.1 ベースイメージ

| 項目 | 選定 | 理由 |
|------|------|------|
| ベースイメージ | `node:22-bookworm` | Next.js 16 + React 19 の LTS サポート。Debian ベースで tmux ビルド・Playwright 依存を含めやすい |
| PID 1 マネージャ | `tini` | ゾンビプロセス回収。dev-process で実績あり |
| tmux | ソースビルド 3.6a | dev-process と同一バージョン |

### 3.2 マルチステージビルド

```
Stage 1: deps       -- npm ci (依存関係インストール)
Stage 2: builder    -- next build (standalone ビルド)
Stage 3: runner     -- tini + tmux + standalone + エントリポイント
```

**理由**: ビルドツールチェーン（TypeScript, webpack 等）を最終イメージに含めない。イメージサイズ削減。

### 3.3 コンテナ内ツール

| ツール | 必須/任意 | 用途 |
|--------|----------|------|
| tmux | 必須 | Copilot CLI セッション管理 |
| tini | 必須 | PID 1 マネージャ |
| ps (procps) | 必須 | プロセス検出 (terminal.ts) |
| git | 推奨 | セッション情報取得 |
| curl | 推奨 | ヘルスチェック |
| Copilot CLI | 必須 | セッション実行環境（ユーザーがインストール） |

### 3.4 テストフレームワーク

| 種別 | フレームワーク | 理由 |
|------|--------------|------|
| Unit / Integration | Vitest | TypeScript native、高速、ESM 互換 |
| E2E | Playwright | コンテナ内ヘッドレス実行可能。dev-process で実績あり |

---

## 4. ファイル変更一覧

### 新規ファイル

| ファイル | 目的 |
|----------|------|
| `Dockerfile` | マルチステージビルド定義 |
| `compose.yaml` | コンテナ起動設定（ボリューム、環境変数、ポート） |
| `.dockerignore` | ビルドコンテキストから不要ファイルを除外 |
| `scripts/start-viewer.sh` | コンテナエントリポイント（tmux + Next.js 起動） |
| `scripts/cplt` | Copilot CLI ラッパー（dev-process 版を viewer 用に調整） |
| `.env.example` | 環境変数テンプレート |
| `vitest.config.ts` | Vitest 設定 |
| `playwright.config.ts` | Playwright 設定 |
| `src/lib/__tests__/terminal.test.ts` | terminal.ts 単体テスト |
| `src/lib/__tests__/sessions.test.ts` | sessions.ts 単体テスト |
| `e2e/container-startup.spec.ts` | コンテナ起動 E2E テスト |

### 修正ファイル

| ファイル | 変更内容 |
|----------|----------|
| `next.config.ts` | `output: "standalone"` 追加 |
| `src/lib/terminal.ts` | `DISABLE_DOCKER_DETECTION` 環境変数フラグ追加 |
| `package.json` | Vitest / Playwright / テストスクリプト追加 |
| `tsconfig.json` | テスト用 path exclude 追加（必要に応じて） |

### 削除ファイル

なし（既存機能を維持）

---

## 5. 設計原則

### 5.1 ローカル・コンテナ両対応

- **同一コードベース**がローカル（`npm run dev`）でもコンテナ内でも動作する
- Docker 検出の無効化は**環境変数フラグ**で切り替え（コード分岐ではない）
- `$HOME/.copilot` パスは `process.env.HOME` 依存のため、自然にコンテナ分離される

### 5.2 dev-process パターンの流用

| パターン | dev-process | viewer（新規） |
|----------|------------|----------------|
| PID 1 | tini | tini（同一） |
| エントリポイント | start-tmux.sh | start-viewer.sh（カスタム） |
| Copilot CLI ラッパー | cplt | cplt（微調整） |
| tmux 構成 | 3ウィンドウ (editor/copilot/bash) | 3ウィンドウ (viewer/copilot/bash) |
| キープアライブ | while true; wait; sleep 60 | 同一パターン |

### 5.3 段階的テスト導入

1. **Phase 1**: lib モジュール（sessions.ts, terminal.ts）の Vitest 単体テスト
2. **Phase 2**: API route の Integration テスト
3. **Phase 3**: Playwright E2E テスト（コンテナ起動→viewer起動→認証→セッション確認）

---

## 6. リスク軽減策

| リスク | 対策 |
|--------|------|
| tmux 予期せぬ終了 | tini (PID 1) + start-viewer.sh のキープアライブループ |
| better-sqlite3 ビルド失敗 | Dockerfile に build-essential + python3 含める |
| Playwright イメージサイズ増加 | マルチステージビルドで開発ステージに分離 |
| Next.js 16 + Vitest 互換性 | lib モジュールから段階的に導入 |

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-03-21 | 1.0 | 初版作成 | Copilot |
