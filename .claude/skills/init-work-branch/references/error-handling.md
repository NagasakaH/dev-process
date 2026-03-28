# エラーハンドリング

init-work-branch スキルのエラーハンドリングと注意事項。

## 必須入力不足

```
エラー: 必須入力が不足しています
不足項目: {missing_fields}

ticket_id, task_name, target_repositories を指定してください。
```

## サブモジュール追加失敗

```
警告: サブモジュールの追加に失敗しました
リポジトリ: {repository_url}
原因: {error_message}

処理を続行しますか？ [y/N]
```

## 注意事項

- 既存のfeatureブランチがある場合は確認を求める
- サブモジュールが既に存在する場合はスキップして処理を続行
- git設定（user.name, user.email）が必要
- description が文字列で渡された場合は overview として処理
- **Worktree安全確認**: `/tmp/` 配下にworktreeを作成する場合、`.gitignore` に `/tmp/` パターンが含まれていることを確認し、worktreeディレクトリがリポジトリにコミットされないようにする
