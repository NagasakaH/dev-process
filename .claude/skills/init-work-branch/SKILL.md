---
name: init-work-branch
description: 作業ブランチ初期化スキル。チケットID・タスク名・対象リポジトリ情報を入力として、featureブランチ作成、サブモジュール追加、設計ドキュメント生成を行う。「作業ブランチを初期化」「init-work-branch」「開発セットアップ」「featureブランチを作成」などのフレーズで発動。
---

# 作業ブランチ初期化スキル

チケットID・タスク名・対象リポジトリ情報を入力として、開発に必要な環境を自動構築します。

> **設計原則**: `git clone` + `git submodule init && git submodule update` だけで同等の開発環境が再現できること

## 入力情報

### 必須入力
- **ticket_id** - チケットID（ブランチ名・ドキュメント名に使用）
- **task_name** - タスク名
- **target_repositories** - 修正対象リポジトリ（少なくとも1つ）。各リポジトリに `name`, `url`, `base_branch`（デフォルト: main）を含む

### オプション入力
- **description** - タスクの説明（overview, purpose, background, requirements, acceptance_criteria, scope, out_of_scope, notes）
- **related_repositories** - 参照用リポジトリ一覧（読み取り専用のサブモジュール）
- **base_branch** - 親リポジトリの元ブランチ（デフォルト: 現在のブランチ）
- **submodules_dir** - サブモジュール配置ディレクトリ（デフォルト: `submodules`）
- **design_document_dir** - 設計ドキュメント配置ディレクトリ（デフォルト: `docs`）

## 成果物

- `feature/{ticket_id}` ブランチ
- サブモジュール（submodules/配下）
- 設計ドキュメント（docs/{ticket_id}.md）- description から動的に埋め込み

## このスキルの目的

1. **ブランチ管理** - チケットIDに基づいたfeatureブランチを作成
2. **依存リポジトリ管理** - 関連・修正対象リポジトリをサブモジュールとして追加
3. **ドキュメント準備** - 入力された description を基に設計ドキュメントを生成

## 処理フロー

1. **入力のバリデーション** - 必須入力（ticket_id, task_name, target_repositories）を確認
2. **featureブランチ作成** - 現在のブランチから `feature/{ticket_id}` を作成
3. **サブモジュールディレクトリ準備** - submodules/ ディレクトリを作成
4. **関連リポジトリ追加** - related_repositories をサブモジュールとして追加
5. **修正対象リポジトリ追加** - target_repositories をサブモジュールとして追加、内部でfeatureブランチ作成
6. **設計ドキュメント作成** - テンプレートを使用し description から各セクションを動的埋め込み
7. **初期コミット** - 変更をステージング＆コミット
8. **完了レポート** - 初期化結果を表示

> 📖 各ステップの詳細手順・コード例は [references/processing-steps.md](references/processing-steps.md) を参照

## エラーハンドリング・注意事項

- 必須入力不足時はエラーメッセージを表示
- サブモジュール追加失敗時は警告を表示し続行確認
- 既存featureブランチがある場合は確認を求める
- サブモジュールが既に存在する場合はスキップ
- description が文字列の場合は overview として処理
- **Worktree安全確認**: `/tmp/` 配下にworktree作成時は `.gitignore` に `/tmp/` パターンを確認

> 📖 詳細は [references/error-handling.md](references/error-handling.md) を参照

## 典型的なワークフロー

```
[入力受け取り] → [ブランチ作成] → [サブモジュール追加] → [修正対象追加] → [ドキュメント生成] → [初期コミット] → [完了レポート]
```

## 参照ファイル

- 設計ドキュメントテンプレート: [references/design-document-template.md](references/design-document-template.md)
- 詳細処理手順: [references/processing-steps.md](references/processing-steps.md)
- エラーハンドリング: [references/error-handling.md](references/error-handling.md)
