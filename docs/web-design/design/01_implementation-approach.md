# 実装方針

## 概要

| 項目 | 内容 |
|------|------|
| チケットID | WEB-DESIGN-001 |
| タスク名 | ウェブデザイン要件定義プロジェクト環境構築 |
| 作成日 | 2026-02-27 |

---

## 1. 選定したアプローチ

### 1.1 実装方針

dev-processリポジトリの2段階ビルドパターン（devcontainer build → Dockerfile）を踏襲し、Node.js LTS + code-server構成に置換する。tmux起動スクリプトをcode-server起動スクリプトに変更し、DooD/DinD切り替え機構はdev-container.shからほぼそのまま移植する。

**基本方針:**
1. **ベースイメージ**: `mcr.microsoft.com/devcontainers/javascript-node:lts` を使用
2. **2段階ビルド**: devcontainer.json features → Dockerfile でcode-server・拡張機能追加
3. **起動スクリプト**: `start-tmux.sh` のUID/GID調整ロジックを `start-code-server.sh` に移植
4. **DooD/DinD**: `dev-container.sh` をweb-design用にカスタマイズ（イメージ名・entrypoint変更、ポート追加）
5. **React環境**: Vite + React + TypeScript + Tailwind CSS で初期化、MSWでAPIモック
6. **VS Code拡張機能**: Dockerfile内で `code-server --install-extension` によりプリインストール

### 1.2 技術選定

| 技術/ツール | 選定理由 | 備考 |
|-------------|----------|------|
| Node.js LTS (javascript-node:lts) | ベースイメージとしてNode.jsランタイム内蔵 | devcontainer公式イメージ |
| code-server | ブラウザベースVS Code環境、tmuxの代替 | `curl -fsSL https://code-server.dev/install.sh \| sh` でインストール |
| Vite 6.x | 高速ビルド・HMR、React公式推奨 | `@vitejs/plugin-react` でReact対応 |
| React 19.x | UIフレームワーク | 画面モック作成に最適 |
| TypeScript 5.x | 型安全なコード記述 | Vite標準対応 |
| Tailwind CSS 4.x | ユーティリティファーストCSS | `@tailwindcss/vite` プラグインで統合 |
| MSW 2.x | ブラウザ内APIモック | Service Worker方式、バックエンド不要 |
| Playwright | E2Eテスト | devcontainer feature で依存自動インストール |
| Docker-in-Docker 2.x | DinDサポート | devcontainer feature |

---

## 2. 代替案の比較

### 2.1 開発環境方式

| 案 | 概要 | メリット | デメリット | 採用 |
|----|------|----------|------------|------|
| 案1: code-server (Dockerfile内インストール) | Dockerfileで直接インストール | 完全制御可能、拡張機能プリインストール対応 | devcontainer feature非対応のため手動管理 | ✅ |
| 案2: VS Code Remote - Containers | VS Code Desktop + Remote Containers | ネイティブVS Code体験、Marketplace完全対応 | ブラウザベースでない、ローカルVS Code必須 | ❌ |
| 案3: Gitpod/Codespaces | クラウドベース開発環境 | セットアップ不要 | コスト発生、オフライン不可 | ❌ |

### 2.2 GitHub Copilot対応方式

| 案 | 概要 | メリット | デメリット | 採用 |
|----|------|----------|------------|------|
| 案1: VSIX手動インストール + Copilot CLI フォールバック | Dockerfile内でVSIXインストールを試行、失敗時はCopilot CLIで代替 | 段階的対応可能 | VSIXの入手・更新が手動 | ✅ |
| 案2: marketplace.json上書き | code-serverの拡張機能マーケットプレースをMicrosoft Marketplaceに変更 | 全拡張機能が利用可能 | ライセンス上グレー | ❌ |
| 案3: Copilot CLI のみ | ターミナルからCopilot CLIのみ使用 | 確実に動作 | インラインコード補完不可 | ❌ (フォールバックとして採用) |

---

## 3. 採用理由

### 3.1 決定要因

1. **dev-processとの整合性**: 2段階ビルドパターン、DooD/DinD切替機構をそのまま移植でき、運用ノウハウを共有できる
2. **ブラウザベース開発**: code-serverによりVS Code Desktopのインストールなしでブラウザから開発可能。要件定義レビューに最適
3. **React + Vite**: 高速HMRで画面デザイン変更を即座にプレビュー可能。MSWとの組み合わせでバックエンド不要の完全フロントエンド開発環境を実現

### 3.2 トレードオフ

- **Open VSX制約**: code-serverではMicrosoft Marketplace拡張機能を直接利用できないため、GitHub Copilot等はVSIXインストールまたはCLI代替が必要
- **パフォーマンス**: bind mount環境でのファイル監視はinotifyが効かない場合があり、Vite HMRに`usePolling`設定が必要
- **node_modules I/O**: bind mountではnpm install/ビルドが遅くなるが、初回スコープではnamed volume未使用（必要に応じて追加）

---

## 4. 制約事項

| 制約 | 影響 | 対応方針 |
|------|------|----------|
| Platform linux/amd64 のみ | ARM Macではエミュレーション実行 | dev-processと同様、将来マルチアーキテクチャ対応検討 |
| Open VSX Registry制約 | GitHub Copilot拡張がマーケットプレース経由で入手不可 | VSIXインストール試行 + Copilot CLIフォールバック |
| code-server認証なし (`--auth none`) | ローカルネットワーク内からアクセス可能 | ローカル開発専用として文書化 |
| `--privileged` 必須 | DinD/DooD両方でコンテナ特権が必要 | ローカル開発環境のため許容 |
| E2Eテストのみ | 単体テスト・結合テストはスコープ外 | brainstormingで決定済み、将来追加 |

---

## 5. 前提条件

- [x] dev-processリポジトリの構成を調査済み（investigation完了）
- [x] brainstormingで技術選定・テスト戦略を決定済み
- [ ] Docker Engine がホストにインストールされていること
- [ ] Docker Hub (nagasakah/web-design) へのpush権限があること
- [ ] `devcontainer` CLI がインストールされていること（ビルド時のみ）

---

## 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-02-27 | 1.0 | 初版作成 | Copilot |
