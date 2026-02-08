# opentelemetry-issue-1 - トレース用のライブラリが欲しい

<!-- 
================================================================================
このドキュメントは setup.yaml を Single Source of Truth (SSOT) として参照します。
基本情報は setup.yaml の description フィールドから動的に埋め込まれます。
================================================================================
-->

## 基本情報

| 項目 | 内容 |
|------|------|
| チケットID | opentelemetry-issue-1 |
| タスク名 | トレース用のライブラリが欲しい |
| 作成日 | 2026-02-08 |
| 作成者 | Hiroaki |
| ステータス | 🔵 初期化 |

---

## 概要

<!-- setup.yaml の description.overview から埋め込み -->
TracingSampleと横並びで本番運用できるトレース用のライブラリを作成する。
C#で書かれたdotnet 8で動くコンソールアプリに対して、ログをトレースに埋め込むように
置き換え、開始終了をトレースできるようにする。

---

## 目的

<!-- setup.yaml の description.purpose から埋め込み -->
- 本番運用可能なトレース用ライブラリの作成
- OpenTelemetryとJaegerを使用したトレース機能の実現
- 複数スレッド・async/await環境での親子関係トレースの実現

---

## 背景

<!-- setup.yaml の description.background から埋め込み -->
導入予定のアプリは複数スレッドでモジュールを起動し、モジュールの中でasync awaitを
使っている環境。
任意のメソッドで親を設定し、それより後で呼ばれる全てのメソッド（新規タスクや
並列実行するタスクも含む）で親子関係を設定しOpenTelemetryとJaegerでトレースを
行えるようにしたい。
呼び出しメソッドはDIを使っているものもあればstaticなメソッドなども混在している。

---

## 要件

### 機能要件

<!-- setup.yaml の description.requirements.functional から埋め込み -->
- TracingSampleと横並びで本番運用できるトレース用ライブラリの作成
- 保存はJaegerを使用
- C#、dotnet 8で動くコンソールアプリ対応
- ログをトレースに埋め込むように置き換え
- 開始終了をトレースできる機能
- 複数スレッドでモジュールを起動する環境に対応
- モジュール内でasync awaitを使用する環境に対応
- 任意のメソッドで親を設定可能
- 新規タスクや並列実行するタスクでも親子関係を設定可能
- DIを使っているメソッドに対応
- staticなメソッドに対応
- 様々なパターンで親となるActivityを作成可能
- 各メソッドの呼び出しの開始終了を記録

### 非機能要件

<!-- setup.yaml の description.requirements.non_functional から埋め込み -->
- 本番運用可能な品質

---

## スコープ

### 対象範囲

<!-- setup.yaml の description.scope から埋め込み -->
- トレース用ライブラリの作成
- 呼び出しパターンのバリエーション洗い出し
- テストパターンと実装の検討

### 対象外

<!-- setup.yaml の description.out_of_scope から埋め込み -->
（未定義）

---

## 受け入れ条件

<!-- setup.yaml の description.acceptance_criteria から埋め込み -->
- スレッドやasyncなどの呼び出しパターンを網羅した要件が洗い出されていること
- 各パターンに対するテストパターンが定義されていること
- テストパターンに対する実装方針が検討されていること

---

## 補足情報

<!-- setup.yaml の description.notes から埋め込み -->
- 可能な限りいろいろなパターンで親となるActivityを作成できるようにする
- その子要素としていろいろなバリエーションで呼び出される各メソッドの呼び出しの
  開始終了を記録できるライブラリを作成する

---

## 1. 調査結果

<!-- dev-investigation スキルが更新 -->

### 1.1 現状分析

TracingSample.Tracingライブラリは、DispatchProxyを使用したインターフェースベースの自動トレーシング機能を提供。`[Trace]`アトリビュートによるメソッドマーキングとDI拡張メソッド（`AddTracedScoped`等）により、既存コードへの影響を最小限にトレース機能を追加可能。

**現在の対応状況:**
- ✅ async/await環境での親子関係トレース（Activity.Current自動伝播）
- ✅ DI経由サービスのトレース（TracingProxy経由）
- ✅ Task.Runでの新規タスク（ExecutionContext伝播）
- ❌ staticメソッド（DispatchProxy制約により未対応）
- △ 任意の親設定（明示的API要検討）
- △ new Thread等の明示的スレッド作成（手動コンテキスト伝播必要）

詳細は [dev-investigation/](./opentelemtry/dev-investigation/) を参照。

### 1.2 関連コード・ファイル

| ファイル | 役割 | 備考 |
|----------|------|------|
| `TracingSample.Tracing/Attributes/TraceAttribute.cs` | トレースアトリビュート定義 | Name, RecordParameters等のオプション |
| `TracingSample.Tracing/Interceptors/TracingProxy.cs` | プロキシ実装 | async/await対応済み |
| `TracingSample.Tracing/Extensions/ServiceCollectionExtensions.cs` | DI拡張メソッド | Scoped/Transient/Singleton対応 |
| `TracingSample.Console/Program.cs` | 単一スレッドデモ | OpenTelemetry設定例 |
| `TracingSample.MultithreadedWorker/Program.cs` | マルチスレッドデモ | ワーカー単位の手動Activity作成例 |

### 1.3 参考情報

- [アーキテクチャ調査](./opentelemtry/dev-investigation/01_architecture.md)
- [データ構造調査](./opentelemtry/dev-investigation/02_data-structure.md)
- [依存関係調査](./opentelemtry/dev-investigation/03_dependencies.md)
- [既存パターン調査](./opentelemtry/dev-investigation/04_existing-patterns.md)
- [統合ポイント調査](./opentelemtry/dev-investigation/05_integration-points.md)
- [リスク・制約分析](./opentelemtry/dev-investigation/06_risks-and-constraints.md)

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
| staticメソッド非対応 | 高 | 確実 | 手動トレースヘルパー提供 |
| 機密情報漏洩 | 高 | 高 | RecordParameters=false、自動マスク機能 |
| リフレクションオーバーヘッド | 中 | 確実 | 重要メソッドのみトレース |
| Fire-and-Forget親子関係 | 中 | 中 | ドキュメント化、パターン提供 |
| 並列処理コンテキスト | 中 | 中 | ParallelTraceHelper提供 |

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
| 2026-02-08 | 1.0 | 初版作成 | Hiroaki |
| 2026-02-08 | 1.1 | 調査結果セクション更新 | Claude |
