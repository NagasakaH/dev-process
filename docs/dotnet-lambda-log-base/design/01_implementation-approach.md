# 実装方針

## アプローチ

ドキュメント作成タスクのため、dotnet-lambda-log-base リポジトリ内のファイルのみを変更する。

### 変更対象

| ファイル | 操作 | 内容 |
|---|---|---|
| `README.md` | 更新 | Terraform構成Mermaid図・AWS課金要素情報を追加 |
| `docs/logging-library/requirements.md` | 新規 | ログライブラリの要件定義 |
| `docs/logging-library/basic-design.md` | 新規 | ログライブラリの基本設計 |
| `docs/logging-library/detailed-design.md` | 新規 | ログライブラリの詳細設計 |

### README.md 更新方針

既存 README の構成を維持しつつ、以下のセクションを追加・更新:

1. **Terraform インフラ構成図** — 「アーキテクチャ」セクションに Mermaid 図を追加
2. **AWS 課金要素** — 新規セクションとして追加（各サービスの課金モデル・無料枠・コスト目安）
3. **E2E テスト情報** — 既存セクションの情報を最新化

### ログライブラリドキュメント方針

3階層構造で、上位ドキュメントから下位ドキュメントへ自然に読み進められる構成:

- **requirements.md**: What（何を実現するか）— 課題・要件・受け入れ条件
- **basic-design.md**: How（どう実現するか）— アーキテクチャ・コンポーネント構成
- **detailed-design.md**: Implementation（実装詳細）— クラス定義・API・処理フロー

各ドキュメントに関連するテスト項目と結果を記載する。
