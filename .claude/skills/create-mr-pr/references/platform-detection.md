# プラットフォーム検出

## 検出手順

```bash
REMOTE_URL=$(git remote get-url origin)

if echo "$REMOTE_URL" | grep -q "github.com"; then
  PLATFORM="github"
elif echo "$REMOTE_URL" | grep -q "gitlab"; then
  PLATFORM="gitlab"
else
  echo "未対応プラットフォーム: $REMOTE_URL"
  exit 1
fi
```

## Draft MR/PR作成コマンド

### GitHub

```bash
gh pr create \
  --draft \
  --base "$BASE_BRANCH" \
  --title "$TITLE" \
  --body "$BODY"
```

### GitLab

```bash
# gitlab-apiスキルを使用
# POST /projects/:id/merge_requests
# パラメータ:
#   source_branch: 現在のブランチ
#   target_branch: ベースブランチ
#   title: "Draft: $TITLE"
#   description: $BODY
```

> GitLabではタイトルに `Draft: ` プレフィックスを付けることでdraft状態になる。

## Draft解除コマンド

### GitHub

```bash
gh pr ready "$PR_NUMBER"
```

### GitLab

```bash
# PUT /projects/:id/merge_requests/:mr_iid
# パラメータ:
#   title: "Draft: " プレフィックスを除去したタイトル
```

## MR/PR URL取得

### GitHub

```bash
gh pr view --json url -q '.url'
```

### GitLab

```bash
# GET /projects/:id/merge_requests?source_branch=$BRANCH&state=opened
# → web_url フィールド
```
