# ELSA-001 - Elsa Workflow システム機能拡張（Activity DLL読み込み・JSON管理・MassTransit連携・E2Eテスト整備）

<!-- 
================================================================================
このドキュメントは setup.yaml を Single Source of Truth (SSOT) として参照します。
基本情報は setup.yaml の description フィールドから動的に埋め込まれます。
================================================================================
-->

## 基本情報

| 項目 | 内容 |
|------|------|
| チケットID | ELSA-001 |
| タスク名 | Elsa Workflow システム機能拡張（Activity DLL読み込み・JSON管理・MassTransit連携・E2Eテスト整備） |
| 作成日 | 2026-02-20 |
| 作成者 | Hiroaki |
| ステータス | 🔵 初期化 |

---

## 概要

<!-- setup.yaml の description.overview から埋め込み -->
NagasakaH/elsa リポジトリのプロトタイプ実装（tmpブランチ）を参考に、
masterブランチから新規featureブランチを作成し、以下の機能を正式に実装・テスト基盤を整備する：
- Activity DLL の動的読み込み機構
- サンプル Activity DLL プロジェクト
- Elsa Studio の JSON 読み込みを使ったワークフロー管理（Elsa Studio GUI で編集可能）
- MassTransit を使った任意のワークフローの実行・停止
- 包括的なテスト基盤（単体・結合・E2E）

---

## 目的

<!-- setup.yaml の description.purpose から埋め込み -->
現在 tmp ブランチにプロトタイプ状態で存在する実装を、正式なブランチで整理・統合し、
プロダクション品質のコードとテスト基盤を構築する。
特にテスト周りを充実させ、DLL ロードからワークフロー実行まで一貫した品質保証を実現する。

---

## 背景

<!-- setup.yaml の description.background から埋め込み -->
- tmp ブランチに Activity DLL ロード（Activities.Loader）、MassTransit 連携、
  JSON ワークフローカタログ管理等のお試し実装が存在する
- master ブランチは基本的な構成のみ（カスタム Activity 直書き、SQLite、テストなし）
- compose.yml に PostgreSQL + RabbitMQ の Docker 構成が定義済み
- Elsa 3.4.x ベース、.NET 8 ターゲット

---

## 要件

### 機能要件

<!-- setup.yaml の description.requirements.functional から埋め込み -->
- Activity DLL 動的読み込み機構（外部フォルダからDLLをスキャンしアクティビティを自動登録）
- サンプル Activity DLL プロジェクト（テンプレートとして利用可能）
- ワークフロー JSON の起動時読み込み・カタログ管理（WorkflowCatalog）
- Elsa Studio GUI でのワークフロー JSON 編集・保存対応
- 要求（テンプレート等）からワークフロー JSON を生成する仕組み
- MassTransit を使ったワークフローの実行（StartWorkflowCommand）
- MassTransit を使ったワークフローの停止
- ワークフローステータスのイベント発行（WorkflowStatusEvent）

### 非機能要件

<!-- setup.yaml の description.requirements.non_functional から埋め込み -->
- テストカバレッジの充実（単体・結合・E2E の3層）
- 外部DLLのロード安全性（不正DLLのエラーハンドリング）
- ワークフロー JSON のバリデーション（スキーマ準拠チェック）
- Docker Compose ベースの開発環境で完結する構成

---

## スコープ

### 対象範囲

<!-- setup.yaml の description.scope から埋め込み -->
- Activity DLL 動的読み込み機構の実装とテスト
- サンプル Activity DLL テンプレートの作成
- ワークフロー JSON カタログ管理の実装とテスト
- Elsa Studio 連携（GUI編集対応）
- ワークフロー JSON 生成機構
- MassTransit 連携（ワークフロー実行・停止）の実装とテスト
- Playwright CLI による E2E テスト整備
- PostgreSQL + RabbitMQ を使った結合テスト環境

### 対象外

<!-- setup.yaml の description.out_of_scope から埋め込み -->
- 本番環境へのデプロイ
- ユーザー認証・権限管理の本格実装（暫定ハードコーディングのまま）
- RPC Service の新規追加

---

## 受け入れ条件

<!-- setup.yaml の description.acceptance_criteria から埋め込み -->
- Activity DLL を外部フォルダから動的にロードでき、単体テストで検証済み
- ロードしたアクティビティが Elsa Studio のアクティビティ一覧に表示される（結合テスト検証済み）
- ワークフロー JSON をカタログから読み込み、Elsa に登録できる
- Elsa Studio GUI でワークフロー JSON の編集・保存ができる
- 要求からワークフロー JSON を生成する仕組みが動作する
- MassTransit 経由でワークフローの実行・停止ができる
- MassTransit Consumer の単体・結合テストが通過する
- ワークフロー JSON バリデーション（不正JSONのエラーハンドリング含む）テスト通過
- ワークフローライフサイクル（作成→公開→実行→完了→停止）のAPI E2Eテスト通過
- Playwright CLI でのE2Eテスト（Studio上でのワークフロー編集・操作確認）通過

---

## 補足情報

<!-- setup.yaml の description.notes から埋め込み -->
- tmp ブランチの実装を参考にしつつ、新規ブランチで整理して実装する
- Elsa 3.4.x / .NET 8 ベースで実装
- テスト実行環境は Docker Compose（PostgreSQL + RabbitMQ）を前提とする
- Playwright CLI は E2E テストに使用し、Elsa Studio の GUI 操作をテスト可能にする

---

## 1. 調査結果

<!-- investigation スキルが更新 -->

### 1.1 現状分析

<!-- 調査結果は investigation/ を参照 -->

### 1.2 関連コード・ファイル

| ファイル | 役割 | 備考 |
|----------|------|------|
| | | |

### 1.3 参考情報

<!-- 詳細: investigation/ -->

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
| 2026-02-20 | 1.0 | 初版作成 | Hiroaki |
