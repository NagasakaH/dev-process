# WEB-DESIGN-001 - ウェブデザイン要件定義プロジェクト環境構築

<!-- 
================================================================================
このドキュメントは setup.yaml を Single Source of Truth (SSOT) として参照します。
基本情報は setup.yaml の description フィールドから動的に埋め込まれます。
================================================================================
-->

## 基本情報

| 項目 | 内容 |
|------|------|
| チケットID | WEB-DESIGN-001 |
| タスク名 | ウェブデザイン要件定義プロジェクト環境構築 |
| 作成日 | 2026-02-27 |
| 作成者 | Hiroaki |
| ステータス | 🔵 初期化 |

---

## 概要

<!-- setup.yaml の description.overview から埋め込み -->
dev-processを参考に、ウェブデザインの要件定義を行うためのプロジェクト環境を構築する。
画面デザインや画面の振る舞いを定義・プレビューできる開発環境を確立し、
Reactベースの画面モックを作成してcode-server上でプレビューするワークフローを整備する。

---

## 目的

<!-- setup.yaml の description.purpose から埋め込み -->
ウェブアプリケーションの要件定義フェーズにおいて、画面デザインと画面の振る舞いを
コードベースで定義・検証できる環境を提供する。バックエンドはモックで代替し、
フロントエンドの画面のみに集中して要件を可視化・共有する。

---

## 背景

<!-- setup.yaml の description.background から埋め込み -->
dev-processリポジトリが提供するdevcontainer構成（DooD/DinD切り替え、開発ツール統合）
を参考にしつつ、ウェブデザインに特化した環境を構築する。
tmux起動の代わりにcode-serverを起動し、ブラウザベースのVS Code環境で
React開発とプレビューを行う。

---

## 要件

### 機能要件

<!-- setup.yaml の description.requirements.functional から埋め込み -->
- devcontainerのfeatureとしてcode-serverを追加し、コンテナ起動時にcode-serverを自動起動する（tmuxの代替）
- copilot CLI、git、playwright、prettierをdevcontainerに含める
- dev-processと同様のDooD/DinD起動切り替え機構を実装する
- Reactプロジェクトを初期化し、画面コンポーネントを作成できる環境を整える
- code-server上でReactアプリをプレビュー（ホットリロード対応）する方法を確立する
- 画面のみを作成し、バックエンドはモックで代替する構成にする
- code-serverにReact開発に必要なVS Code拡張機能をプリインストールする
- code-serverにGitHub Copilot拡張機能をプリインストールする

### 非機能要件

<!-- setup.yaml の description.requirements.non_functional から埋め込み -->
- code-serverがブラウザからアクセス可能であること
- Reactアプリのホットリロードがcode-server環境で動作すること
- Playwrightによる画面スクリーンショット・テストが実行可能であること

---

## スコープ

### 対象範囲

<!-- setup.yaml の description.scope から埋め込み -->
- devcontainer環境構築（code-server起動、DooD/DinD切り替え）
- Reactプロジェクト初期設定
- code-server用VS Code拡張機能の設定（React開発用 + Copilot）
- 画面デザイン・モックのプレビュー環境確立
- Playwrightによるスクリーンショット/テスト環境

### 対象外

<!-- setup.yaml の description.out_of_scope から埋め込み -->
- バックエンドAPI実装（モックで代替）
- データベース設計・構築
- 本番デプロイ環境
- CI/CDパイプライン

---

## 受け入れ条件

<!-- setup.yaml の description.acceptance_criteria から埋め込み -->
- devcontainerでcode-serverが起動し、ブラウザからアクセスできる
- Reactプロジェクトが初期化され、code-server上でプレビューできる
- DooD/DinD切り替え機構が動作する
- copilot CLI, git, playwright, prettierが使用可能
- code-serverにReact開発用拡張機能がインストールされている
- code-serverにGitHub Copilot拡張機能がインストールされている
- 画面デザインのモック作成・プレビューのワークフローが確立されている

---

## 補足情報

<!-- setup.yaml の description.notes から埋め込み -->
dev-processリポジトリの以下の構成を参考にする:
- .devcontainer/ の構成（devcontainer.json, Dockerfile, docker-compose）
- scripts/dev-container.sh のDooD/DinD切り替え機構
- tmuxの代わりにcode-serverを起動する構成に変更
Reactのビルドツールは Vite を推奨。
将来的にはdev-processと同様のCopilot向けスキル（.claude/skills/）設定を
web-designリポジトリにも組み込んでいく予定。初回スコープでは環境構築に集中する。

---

## 1. 調査結果

<!-- investigation スキルが更新 -->

### 1.1 現状分析

dev-processのdevcontainer構成（2段階ビルド、DooD/DinD切替、tmux起動）を詳細調査し、
web-designへのcode-server起動環境移植方針を確立した。

主な発見:
- dev-processは2段階ビルド（`devcontainer build` → `Dockerfile`）パターンを採用
- start-tmux.shのUID/GID調整・Docker socketパーミッション修正ロジックはcode-server版でもそのまま必要
- DooD時は `--entrypoint start-code-server` でdocker-init.shをスキップ
- code-serverのdevcontainer featureは公式に存在せず、Dockerfile内でインストールが必要
- GitHub Copilot拡張機能はOpen VSX制約が最大リスク

詳細は [investigation/](./web-design/investigation/) を参照。

### 1.2 関連コード・ファイル

| ファイル | 役割 | 備考 |
|----------|------|------|
| `submodules/dev-process/.devcontainer/devcontainer.json` | devcontainer features定義 | 23個のfeature、web-designでは9個に絞り込み |
| `submodules/dev-process/.devcontainer/Dockerfile` | プリビルドイメージのカスタムレイヤー | tmux → code-server に変更 |
| `submodules/dev-process/.devcontainer/scripts/start-tmux.sh` | コンテナ起動スクリプト | start-code-server.sh のベース |
| `submodules/dev-process/scripts/dev-container.sh` | DooD/DinD切替・コンテナ管理 | ほぼそのまま移植（イメージ名・entrypoint変更） |
| `submodules/dev-process/scripts/build-and-push-devcontainer.sh` | 2段階ビルド+push | イメージ名変更して移植 |

### 1.3 参考情報

- [アーキテクチャ調査](./web-design/investigation/01_architecture.md)
- [データ構造調査](./web-design/investigation/02_data-structure.md)
- [依存関係調査](./web-design/investigation/03_dependencies.md)
- [既存パターン調査](./web-design/investigation/04_existing-patterns.md)
- [統合ポイント調査](./web-design/investigation/05_integration-points.md)
- [リスク・制約分析](./web-design/investigation/06_risks-and-constraints.md)

---

## 2. 設計

<!-- design スキルが更新 -->

### 2.1 設計方針

dev-processリポジトリの2段階ビルドパターンを踏襲し、Node.js LTS + code-server構成に置換する。
tmux起動スクリプトをcode-server起動スクリプトに変更し、DooD/DinD切り替え機構はdev-container.shから移植する。

詳細は [design/01_implementation-approach.md](./web-design/design/01_implementation-approach.md) を参照。

### 2.2 変更箇所

#### 追加ファイル

| ファイル | 目的 |
|----------|------|
| `.devcontainer/devcontainer.json` | devcontainer features・settings定義 (9 features) |
| `.devcontainer/Dockerfile` | code-server・拡張機能追加レイヤー |
| `.devcontainer/scripts/start-code-server.sh` | コンテナ起動スクリプト (tmux代替) |
| `scripts/dev-container.sh` | DooD/DinD切り替え・コンテナ管理 (dev-processから移植) |
| `scripts/build-and-push-devcontainer.sh` | プリビルドイメージ作成 |
| `src/App.tsx` | メインReactコンポーネント |
| `src/main.tsx` | Viteエントリポイント |
| `src/index.css` | Tailwind CSSグローバルスタイル |
| `src/mocks/browser.ts` | MSWブラウザワーカー設定 |
| `src/mocks/handlers.ts` | APIモックハンドラー |
| `e2e/code-server.spec.ts` | code-serverアクセスE2Eテスト |
| `e2e/react-preview.spec.ts` | ReactプレビューE2Eテスト |
| `e2e/extensions.spec.ts` | 拡張機能確認E2Eテスト |
| `e2e/docker-mode.spec.ts` | DooD/DinD動作確認E2Eテスト |
| `vite.config.ts` | Vite設定 (usePolling対応) |
| `package.json` | npm依存定義 |
| `tsconfig.json` | TypeScript設定 |

#### 修正ファイル

| ファイル | 変更内容 |
|----------|----------|
| (なし) | 新規プロジェクトのため修正ファイルなし |

#### 削除ファイル

| ファイル | 理由 |
|----------|------|
| (なし) | 新規プロジェクトのため削除ファイルなし |

### 2.3 インターフェース設計

スクリプトCLIインターフェース: `dev-container.sh up/down/status/shell/logs`、環境変数 `DOCKER_MODE` によるDooD/DinD切替。
ポート: 8080 (code-server)、5173 (Vite dev server)。

詳細は [design/02_interface-api-design.md](./web-design/design/02_interface-api-design.md) を参照。

### 2.4 データ構造

Reactプロジェクト構造 (Vite + TypeScript + Tailwind CSS + MSW)、devcontainer構成ファイル、E2Eテストファイル。

詳細は [design/03_data-structure-design.md](./web-design/design/03_data-structure-design.md) を参照。

---

## 3. 実装計画

<!-- plan スキルが更新 -->

### 3.1 タスク分割

<!-- 詳細: plan/task-list.md -->

| タスク識別子 | タスク名 | 前提条件 | 並列可否 | 推定時間 | ステータス |
|--------------|----------|----------|----------|----------|------------|
| | | | | | ⬜ 未着手 |

### 3.2 依存関係

<!-- 依存関係図は plan スキルで生成 -->

### 3.3 見積もり

| タスク | 見積もり | 実績 |
|--------|----------|------|
| | | |

---

## 4. テスト計画

<!-- design/05_test-plan.md を参照 -->

### 4.1 テスト対象

brainstormingで決定したテスト戦略に基づき、E2Eテストのみを実施する。
Playwrightでdevcontainerビルド→起動後の動作確認を行う。

### 4.2 テストケース

| No | テスト内容 | 期待結果 | 結果 |
|----|------------|----------|------|
| E2E-1 | code-serverアクセス確認 | ブラウザからVS Code UIが表示される | ⬜ |
| E2E-2 | Reactアプリプレビュー確認 | http://localhost:5173 でReactアプリ表示 | ⬜ |
| E2E-3 | 拡張機能インストール確認 | ESLint, Prettier, Tailwind等がインストール済み | ⬜ |
| E2E-4 | 開発ツール動作確認 | node, git, playwright, prettier等が利用可能 | ⬜ |
| E2E-5 | DinDモード動作確認 | コンテナ内でdocker psが成功 | ⬜ |
| E2E-6 | DooDモード動作確認 | ホストDockerが利用可能 | ⬜ |

詳細は [design/05_test-plan.md](./web-design/design/05_test-plan.md) を参照。

### 4.3 テスト環境

Docker Engine 20.10+、Node.js LTS、Playwright 1.50+

---

## 5. 弊害検証

<!-- design/06_side-effect-verification.md を参照 -->

### 5.1 影響範囲

新規プロジェクトのため既存機能への影響なし。dev-processから移植するスクリプトの動作確認が主要な検証対象。

### 5.2 リスク分析

| リスク | 影響度 | 発生可能性 | 対策 |
|--------|--------|------------|------|
| Copilot拡張機能 (Open VSX制約) | 高 | 高 | VSIXインストール試行 + Copilot CLIフォールバック |
| Vite HMR不安定 (bind mount) | 中 | 中 | `usePolling: true` 設定 |
| DooD UID/GID不一致 | 中 | 低 | start-code-server.shでUID/GID調整ロジック移植 |
| code-server拡張機能互換性 | 中 | 中 | 事前にOpen VSX対応を確認 |

詳細は [design/06_side-effect-verification.md](./web-design/design/06_side-effect-verification.md) を参照。

### 5.3 ロールバック計画

gitでファイル切り戻し (5分)、Docker Hubから以前のタグをpull (10分)、code-server不具合時はtmux構成にフォールバック (30分)

---

## 6. レビュー・承認

### 6.1 レビュー履歴

| 日付 | レビュアー | 結果 | コメント |
|------|------------|------|----------|
| | | | |

### 6.2 承認

#### 完了条件

##### 実装レビュー完了
- [ ] コード品質確認
  - [ ] シェルスクリプトのコーディング規約準拠 (shfmt)
  - [ ] TypeScript/React のコーディング規約準拠 (ESLint + Prettier)
  - [ ] Dockerfile ベストプラクティス準拠
- [ ] 設計方針の遵守確認
  - [ ] 設計書との整合性確認
  - [ ] dev-processパターンの正確な移植確認
- [ ] セキュリティレビュー完了
  - [ ] code-server認証設定確認
  - [ ] --privileged使用の妥当性確認
  - [ ] VSIX取得元の確認

##### テスト完了
- [ ] テスト計画に記載のテスト実行完了
  - [ ] E2E-1: code-serverアクセス確認
  - [ ] E2E-2: Reactプレビュー確認
  - [ ] E2E-3: 拡張機能インストール確認
  - [ ] E2E-4: 開発ツール動作確認
  - [ ] E2E-5: DinDモード動作確認
  - [ ] E2E-6: DooDモード動作確認

##### 弊害検証完了
- [ ] Copilot拡張機能のOpen VSX制約確認
- [ ] Vite HMRの動作確認 (usePolling)
- [ ] DooD時のUID/GID調整確認
- [ ] パフォーマンス検証 (ビルド時間、起動時間)

---

## 7. 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-02-27 | 1.0 | 初版作成 | Hiroaki |
| 2026-02-27 | 1.1 | 設計セクション更新（design スキル実行） | Copilot |
