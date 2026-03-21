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

### 案C: devcontainer.json ベースイメージ + アプリ層 Dockerfile（採用に変更）

- `.devcontainer/devcontainer.json` + features でベースイメージ `copilot-session-viewer:base` をビルド
- その上にアプリ層 `Dockerfile` で Next.js standalone ビルド成果物 + エントリポイントを追加
- **採用に変更した理由**:
  - dev-process で `nagasakah/dev-process:base` + `.devcontainer/Dockerfile` の2層構成が実績あり
  - devcontainer features で Node.js, tmux, git, Copilot CLI, Playwright 依存等を宣言的にインストール可能
  - ベースイメージの構成が devcontainer.json に集約され、メンテナンス性が向上
  - ヘッドレスサーバーとしての独立稼働は、アプリ層 Dockerfile の ENTRYPOINT で実現可能
- **補足**: VS Code devcontainer としては使用しない。devcontainer CLI (`devcontainer build`) でイメージビルドのみ利用

> **決定変更の経緯**: 当初は案B（viewer 側に新規 Dockerfile を単一作成）を採用していたが、
> dev-process の devcontainer ベースイメージパターンを流用する方針に変更。
> これにより、ベースイメージの構成を devcontainer.json で宣言的に管理できる利点が得られる。

---

## 3. 技術選定

### 3.1 2層イメージ構成

| レイヤー | 構成 | 役割 |
|----------|------|------|
| **Layer 1: ベースイメージ** | `.devcontainer/devcontainer.json` + features | OS + ランタイム + ツール群（Node.js, tmux, tini, git, Copilot CLI 等） |
| **Layer 2: アプリ層** | `Dockerfile` (`FROM copilot-session-viewer:base`) | Next.js standalone ビルド成果物 + start-viewer.sh + cplt |

#### dev-process との比較

| 項目 | dev-process | copilot-session-viewer |
|------|------------|------------------------|
| ベースイメージ | `nagasakah/dev-process:base` | `copilot-session-viewer:base` |
| devcontainer.json | `.devcontainer/devcontainer.json` | `.devcontainer/devcontainer.json`（viewer 専用） |
| アプリ層 Dockerfile | `.devcontainer/Dockerfile`（tini, tmux 3.6a, cplt, start-tmux.sh） | `Dockerfile`（Next.js standalone, start-viewer.sh, cplt） |
| ベースOS | `mcr.microsoft.com/devcontainers/dotnet:8.0` | `mcr.microsoft.com/devcontainers/javascript-node:22` |

### 3.2 ベースイメージ（Layer 1）

| 項目 | 選定 | 理由 |
|------|------|------|
| ベースイメージ | `mcr.microsoft.com/devcontainers/javascript-node:22` | Node.js 22 プリインストール。devcontainer features と互換 |
| PID 1 マネージャ | `tini` | ゾンビプロセス回収。アプリ層 Dockerfile でインストール |
| tmux | devcontainer feature (`tmux-apt-get`) + ソースビルド 3.6a | dev-process と同一バージョン |
| Copilot CLI | `ghcr.io/devcontainers/features/copilot-cli:1` | devcontainer feature で宣言的インストール |

### 3.3 アプリ層ビルド（Layer 2）

```
FROM copilot-session-viewer:base

# マルチステージ的に Next.js をビルドするか、
# ホストでビルド済み成果物を COPY するかは実装時に決定。
# 以下は COPY パターン:

WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1

COPY .next/standalone/ ./
COPY .next/static ./.next/static
COPY public ./public
COPY scripts/start-viewer.sh /usr/local/bin/start-viewer
COPY scripts/cplt /usr/local/bin/cplt
RUN chmod +x /usr/local/bin/start-viewer /usr/local/bin/cplt

EXPOSE 3000
USER node

ENTRYPOINT ["tini", "--"]
CMD ["start-viewer"]
```

**理由**: ベースイメージに含まれないアプリ固有のファイル（Next.js ビルド成果物、エントリポイント）のみを追加。ベースイメージの再ビルド頻度を最小化。`WORKDIR /app` によりアプリケーションパスを統一し、`USER node` で非 root 実行を保証。

### 3.4 コンテナ内ツール

| ツール | 必須/任意 | 用途 |
|--------|----------|------|
| tmux | 必須 | Copilot CLI セッション管理 |
| tini | 必須 | PID 1 マネージャ |
| ps (procps) | 必須 | プロセス検出 (terminal.ts) |
| git | 推奨 | セッション情報取得 |
| curl | 推奨 | ヘルスチェック |
| Copilot CLI | 必須 | セッション実行環境（ユーザーがインストール） |

### 3.6 .dockerignore

ビルドコンテキストから不要ファイルを除外し、イメージサイズ削減とセキュリティを確保する。

```
# Secrets
.env
.env.*
!.env.example

# Dependencies (standalone build に含まれる)
node_modules

# Version control
.git
.gitignore

# Test / Development
e2e/
docs/
.devcontainer/
tests/

# Documentation
*.md
LICENSE

# Editor / IDE
.vscode/
.idea/

# Build intermediates (standalone 以外)
.next/cache/
```

### 3.7 dev-process ツールセット比較表

機能要件「Include a dev-process devcontainer-equivalent development toolset」への対応を明確化するため、dev-process ベースイメージと viewer ベースイメージのツール比較を示す。

| ツール | dev-process | viewer | viewer での判断理由 |
|--------|:-----------:|:------:|---------------------|
| Node.js 22 | ✅ (feature) | ✅ (ベースイメージ) | Next.js 実行に必須 |
| tmux 3.6a | ✅ (ソースビルド) | ✅ (ソースビルド) | Copilot CLI セッション管理に必須 |
| tini | ✅ | ✅ | PID 1 ゾンビ回収に必須 |
| git | ✅ (feature) | ✅ (feature) | セッション情報取得に推奨 |
| GitHub CLI (gh) | ✅ (feature) | ✅ (feature) | 認証・API アクセスに推奨 |
| Copilot CLI | ✅ (feature) | ✅ (feature) | セッション実行環境に必須 |
| ripgrep | ✅ | ✅ (feature) | Copilot CLI が使用 |
| curl | ✅ | ✅ (ベースイメージ) | ヘルスチェックに推奨 |
| ps (procps) | ✅ | ✅ (ベースイメージ) | プロセス検出 (terminal.ts) に必須 |
| Playwright deps | ❌ | ✅ (feature) | E2E テスト実行に推奨 |
| .NET SDK | ✅ (ベースイメージ) | ❌ | viewer では不要 |
| Python 3 | ✅ | ❌ | viewer では不要（better-sqlite3 ビルド時は検討） |
| Docker CLI | ✅ | ❌ | コンテナ内では Docker 検出無効のため不要 |

> **方針**: dev-process のコア開発ツール（tmux, tini, git, gh, Copilot CLI, ripgrep）を全て含め、
> .NET / Python 等の viewer に不要な言語ランタイムは除外。Playwright 依存は E2E テスト用に追加。

### 3.8 テストフレームワーク

| 種別 | フレームワーク | 理由 |
|------|--------------|------|
| Unit / Integration | Vitest | TypeScript native、高速、ESM 互換 |
| E2E | Playwright | コンテナ内ヘッドレス実行可能。dev-process で実績あり |

---

## 4. ファイル変更一覧

### 新規ファイル

| ファイル | 目的 |
|----------|------|
| `.devcontainer/devcontainer.json` | ベースイメージ定義（features で Node.js, tmux, git, Copilot CLI 等をインストール） |
| `Dockerfile` | アプリ層（`FROM copilot-session-viewer:base` + Next.js standalone + エントリポイント） |
| `compose.yaml` | コンテナ起動設定（ベースイメージビルド + アプリ層ビルド、ボリューム、環境変数、ポート） |
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
| ベースイメージ構成 | `devcontainer.json` + features → `nagasakah/dev-process:base` | `devcontainer.json` + features → `copilot-session-viewer:base` |
| アプリ層 | `.devcontainer/Dockerfile` (tini, tmux 3.6a, start-tmux.sh, cplt) | `Dockerfile` (tini, tmux 3.6a, Next.js standalone, start-viewer.sh, cplt) |
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
| better-sqlite3 ビルド失敗 | ベースイメージに build-essential + python3 を含める（devcontainer feature で対応） |
| Playwright イメージサイズ増加 | ベースイメージに Playwright deps を含めつつ、E2E テスト用とプロダクション用で分離を検討 |
| Next.js 16 + Vitest 互換性 | lib モジュールから段階的に導入 |
| devcontainer build の複雑化 | compose.yaml でベースイメージビルドを自動化 |

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-03-21 | 1.0 | 初版作成 | Copilot |
| 2026-03-21 | 1.1 | devcontainer ベースイメージ + アプリ層の2層構成に変更。案C を採用に変更 | Copilot |
| 2026-03-21 | 1.2 | MRD-003: WORKDIR /app、パス統一。MRD-010: EXPOSE/ENV/USER 追加。MRD-011: .dockerignore 内容追加。MRD-012: ツール比較表追加 | Copilot |
