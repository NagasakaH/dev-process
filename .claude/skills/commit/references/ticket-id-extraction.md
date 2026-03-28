# チケットID抽出の詳細

## ブランチ名からチケットIDを抽出

以下のパターンからチケットIDを抽出してください：

| ブランチパターン         | 抽出対象            |
| ------------------------ | ------------------- |
| `feature/{チケットID}-*` | `{チケットID}` 部分 |
| `issue/{チケットID}-*`   | `{チケットID}` 部分 |
| `bugfix/{チケットID}-*`  | `{チケットID}` 部分 |
| `hotfix/{チケットID}-*`  | `{チケットID}` 部分 |
| `fix/{チケットID}-*`     | `{チケットID}` 部分 |

## チケットIDの例

- GitHub/GitLab Issue: `123`, `456`
- Jira: `PROJ-123`, `ABC-456`
- Redmine: `#123`, `123`

## リポジトリ情報の取得方法

GitHub/GitLabのリポジトリ情報は以下のコマンドで取得できます：

```bash
git remote get-url origin
```

出力例からowner/repoを抽出：

- `https://github.com/owner/repo.git` → owner: `owner`, repo: `repo`
- `git@github.com:owner/repo.git` → owner: `owner`, repo: `repo`
