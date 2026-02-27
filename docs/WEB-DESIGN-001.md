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

<!-- 詳細: design/01_implementation-approach.md -->

### 2.2 変更箇所

#### 追加ファイル

| ファイル | 目的 |
|----------|------|
| | |

#### 修正ファイル

| ファイル | 変更内容 |
|----------|----------|
| | |

#### 削除ファイル

| ファイル | 理由 |
|----------|------|
| | |

### 2.3 インターフェース設計

<!-- 詳細: design/02_interface-api-design.md -->

### 2.4 データ構造

<!-- 詳細: design/03_data-structure-design.md -->

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

### 4.2 テストケース

| No | テスト内容 | 期待結果 | 結果 |
|----|------------|----------|------|
| 1 | | | ⬜ |

### 4.3 テスト環境

---

## 5. 弊害検証

<!-- design/06_side-effect-verification.md を参照 -->

### 5.1 影響範囲

### 5.2 リスク分析

| リスク | 影響度 | 発生可能性 | 対策 |
|--------|--------|------------|------|
| | | | |

### 5.3 ロールバック計画

---

## 6. レビュー・承認

### 6.1 レビュー履歴

| 日付 | レビュアー | 結果 | コメント |
|------|------------|------|----------|
| | | | |

### 6.2 承認

- [ ] 設計レビュー完了
- [ ] 実装レビュー完了
- [ ] テスト完了
- [ ] 弊害検証完了

---

## 7. 変更履歴

| 日付 | バージョン | 変更内容 | 変更者 |
|------|------------|----------|--------|
| 2026-02-27 | 1.0 | 初版作成 | Hiroaki |
