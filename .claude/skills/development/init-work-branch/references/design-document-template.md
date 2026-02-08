# {{TICKET_ID}} - {{TASK_NAME}}

<!-- 
================================================================================
このドキュメントは setup.yaml を Single Source of Truth (SSOT) として参照します。
基本情報は setup.yaml の description フィールドから動的に埋め込まれます。
================================================================================
-->

## 基本情報

| 項目 | 内容 |
|------|------|
| チケットID | {{TICKET_ID}} |
| タスク名 | {{TASK_NAME}} |
| 作成日 | {{CREATED_DATE}} |
| 作成者 | {{AUTHOR}} |
| ステータス | 🔵 初期化 |

---

## 概要

<!-- setup.yaml の description.overview から埋め込み -->
{{DESCRIPTION_OVERVIEW}}

---

## 目的

<!-- setup.yaml の description.purpose から埋め込み -->
{{DESCRIPTION_PURPOSE}}

---

## 背景

<!-- setup.yaml の description.background から埋め込み -->
{{DESCRIPTION_BACKGROUND}}

---

## 要件

### 機能要件

<!-- setup.yaml の description.requirements.functional から埋め込み -->
{{REQUIREMENTS_FUNCTIONAL}}

### 非機能要件

<!-- setup.yaml の description.requirements.non_functional から埋め込み -->
{{REQUIREMENTS_NON_FUNCTIONAL}}

---

## スコープ

### 対象範囲

<!-- setup.yaml の description.scope から埋め込み -->
{{DESCRIPTION_SCOPE}}

### 対象外

<!-- setup.yaml の description.out_of_scope から埋め込み -->
{{DESCRIPTION_OUT_OF_SCOPE}}

---

## 受け入れ条件

<!-- setup.yaml の description.acceptance_criteria から埋め込み -->
{{ACCEPTANCE_CRITERIA}}

---

## 補足情報

<!-- setup.yaml の description.notes から埋め込み -->
{{DESCRIPTION_NOTES}}

---

## 1. 調査結果

<!-- dev-investigation スキルが更新 -->

### 1.1 現状分析

<!-- 調査結果は dev-investigation/ を参照 -->

### 1.2 関連コード・ファイル

| ファイル | 役割 | 備考 |
|----------|------|------|
| | | |

### 1.3 参考情報

<!-- 詳細: dev-investigation/ -->

---

## 2. 設計

<!-- dev-design スキルが更新 -->

### 2.1 設計方針

<!-- 詳細: dev-design/01_implementation-approach.md -->

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

<!-- 詳細: dev-design/02_interface-api-design.md -->

### 2.4 データ構造

<!-- 詳細: dev-design/03_data-structure-design.md -->

---

## 3. 実装計画

<!-- dev-plan スキルが更新 -->

### 3.1 タスク分割

<!-- 詳細: dev-plan/task-list.md -->

| タスク識別子 | タスク名 | 前提条件 | 並列可否 | 推定時間 | ステータス |
|--------------|----------|----------|----------|----------|------------|
| | | | | | ⬜ 未着手 |

### 3.2 依存関係

<!-- 依存関係図は dev-plan スキルで生成 -->

### 3.3 見積もり

| タスク | 見積もり | 実績 |
|--------|----------|------|
| | | |

---

## 4. テスト計画

<!-- dev-design/05_test-plan.md を参照 -->

### 4.1 テスト対象

### 4.2 テストケース

| No | テスト内容 | 期待結果 | 結果 |
|----|------------|----------|------|
| 1 | | | ⬜ |

### 4.3 テスト環境

---

## 5. 弊害検証

<!-- dev-design/06_side-effect-verification.md を参照 -->

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
| {{CREATED_DATE}} | 1.0 | 初版作成 | {{AUTHOR}} |
