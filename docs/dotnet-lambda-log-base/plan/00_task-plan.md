# タスク計画

## タスク一覧

| No | タスク | 依存 | 並列可否 |
|---|---|---|---|
| T1 | README.md 更新（Mermaid図 + 課金情報） | なし | 可 |
| T2 | docs/logging-library/requirements.md 作成 | なし | 可 |
| T3 | docs/logging-library/basic-design.md 作成 | T2 | 順次 |
| T4 | docs/logging-library/detailed-design.md 作成 | T3 | 順次 |

## 実行戦略

- T1 は独立タスク
- T2-T4 は順次実行（内容の一貫性確保のため）
- T1 と T2 は並列実行可能

## タスク詳細

### T1: README.md 更新

対象: `submodules/dotnet-lambda-log-base/README.md`

追加内容:
1. Terraform インフラ構成の Mermaid 図（graph LR/TD）
2. AWS 課金要素テーブル（サービス・課金モデル・無料枠・コスト目安）
3. docs/logging-library/ へのリンク

### T2: requirements.md 作成

対象: `submodules/dotnet-lambda-log-base/docs/logging-library/requirements.md`

内容:
- 背景と課題（Lambda 標準ログの制限）
- 機能要件（構造化ログ、ログ振り分け、S3配信）
- 非機能要件（パフォーマンス、スレッドセーフティ）
- 受け入れ条件
- E2Eテスト項目と結果（13テスト）

### T3: basic-design.md 作成

対象: `submodules/dotnet-lambda-log-base/docs/logging-library/basic-design.md`

内容:
- アーキテクチャ概要（コンポーネント図）
- ILogger/ILoggerProvider パターンの採用理由
- ログ振り分けフロー（Information → all-logs, Error → both）
- DI 構成
- 単体テスト概要（28テスト、6クラス）

### T4: detailed-design.md 作成

対象: `submodules/dotnet-lambda-log-base/docs/logging-library/detailed-design.md`

内容:
- クラス図（Mermaid）
- 各クラスの責務・公開API
- 処理フロー（シーケンス図: ログ書き込み、FlushAsync）
- PutLogEvents バッチ分割ロジック
- エラーハンドリング
- 単体テスト詳細（28テスト全項目）
