# ワークフロー: init-work-branch

> ⚠️ **必須**: このステップは `init-work-branch` スキルの `skill` ツール経由での呼び出しが必須です。
> スキルを使わない手動実行は禁止されています。

setup.yaml を読み込み、作業ブランチとサブモジュール・設計ドキュメントを初期化する。

## 前提条件
- setup.yaml が存在すること

## コンテキスト取得

```bash
# setup.yaml から情報取得
TICKET_ID=$(yq '.ticket_id' setup.yaml)
TASK_NAME=$(yq '.task_name' setup.yaml)
TARGET_REPOS=$(yq '.target_repositories[].name' setup.yaml)
BASE_BRANCH=$(yq '.target_repositories[0].base_branch // "main"' setup.yaml)
```

## 実行手順

1. **init-work-branch スキル** を実行
   - setup.yaml の内容をスキルに渡す
   - ブランチ作成、サブモジュール追加、設計ドキュメント生成

## 完了後の状態管理

このステップでは project.yaml はまだ存在しない（brainstorming で生成される）。
setup.yaml が正しく読み込めることだけ確認する。
