# PR/MR修正結果書き込み手順

code-review-fixの修正結果をMR/PRに書き込む手順。

> [!CAUTION]
> **Shell展開防止（必須）**
> - `--body "$VAR"` や heredoc/echo でのbody構築は **禁止**（shell展開でMarkdownが破壊される）
> - GitHub: 必ず `--body-file` でファイル経由で渡す
> - GitLab: 必ず `create`ツールでPythonスクリプトを作成し、`requests` ライブラリ経由で渡す

## 書き込みタイミング

```
指摘対応完了 → コミット → 1. 完了レポートコメント投稿 → 2. レビュースレッドへ返信 → 3. 書き込み確認
```

## 1. 修正結果コメント投稿

完了レポート（[output-templates.md](output-templates.md) の形式）をMR/PRコメントとして投稿。

### GitHub

```bash
PR_NUMBER=$(gh pr view --json number -q '.number')
# 完了レポートをファイルとして作成（createツールまたはeditツールで作成済み）
gh pr comment "$PR_NUMBER" --body-file "docs/{target}/code-review/fix-report.md"
```

### GitLab

`create`ツールでPythonスクリプトを作成し、`bash`ツールで実行する。

```python
# post_fix_report.py — createツールで作成
import requests, os, sys

gitlab_url = os.environ.get("CI_SERVER_URL", "https://gitlab.com")
token = os.environ["GITLAB_TOKEN"]
project_id = os.environ["CI_PROJECT_ID"]
mr_iid = sys.argv[1]
report_file = sys.argv[2]

with open(report_file, "r") as f:
    report_content = f.read()

response = requests.post(
    f"{gitlab_url}/api/v4/projects/{project_id}/merge_requests/{mr_iid}/notes",
    headers={"PRIVATE-TOKEN": token},
    json={"body": report_content}
)
response.raise_for_status()
print(f"Fix report posted: note_id={response.json()['id']}")
```

```bash
python post_fix_report.py "$MR_IID" "docs/{target}/code-review/fix-report.md"
```

## 2. レビュースレッドへの返信

各指摘に対する修正内容/反論をレビュースレッドに個別返信する。

### 返信フォーマット

修正済みの場合:
```markdown
**対応: 修正済み** ✅
{fixed_description}
コミット: {commit_sha}
```

反論の場合:
```markdown
**対応: 反論** ⚠️
{dispute_reason}
```

### GitHub

`gh api` でレビューコメントに返信する。返信内容はファイル経由で渡す。

```bash
# 返信内容をJSONファイルとして作成（createツールで作成）
# reply-CR-001.json:
#   {"body": "**対応: 修正済み** ✅\nAPIレスポンスを { data, error } 形式に修正\nコミット: abc1234"}

# レビューコメントへの返信（Pull Request Review Comment Reply API）
gh api \
  -X POST \
  "/repos/{owner}/{repo}/pulls/${PR_NUMBER}/comments/${COMMENT_ID}/replies" \
  --input reply-CR-001.json
```

### GitLab

MRディスカッションノートに返信する。`create`ツールでPythonスクリプトを作成し実行。

```python
# reply_to_discussion.py — createツールで作成
import requests, os, sys

gitlab_url = os.environ.get("CI_SERVER_URL", "https://gitlab.com")
token = os.environ["GITLAB_TOKEN"]
project_id = os.environ["CI_PROJECT_ID"]
mr_iid = sys.argv[1]
discussion_id = sys.argv[2]
reply_file = sys.argv[3]

with open(reply_file, "r") as f:
    reply_content = f.read()

response = requests.post(
    f"{gitlab_url}/api/v4/projects/{project_id}/merge_requests/{mr_iid}/discussions/{discussion_id}/notes",
    headers={"PRIVATE-TOKEN": token},
    json={"body": reply_content}
)
response.raise_for_status()
print(f"Reply posted: note_id={response.json()['id']}")
```

```bash
# 各指摘のdiscussion_idに対して返信
python reply_to_discussion.py "$MR_IID" "$DISCUSSION_ID" reply-CR-001.md
```

## 3. 書き込み後の内容確認

書き込み後、APIで内容を再取得し、意図通りに反映されたか確認する。

### GitHub

```bash
# 最新コメントを確認
gh pr view "$PR_NUMBER" --json comments --jq '.comments[-1].body' | head -5

# レビュー返信を確認（特定のコメントIDで取得）
gh api "/repos/{owner}/{repo}/pulls/comments/${COMMENT_ID}" --jq '.body' | head -3
```

### GitLab

```python
# verify_fix_writing.py — createツールで作成
import requests, os, sys

gitlab_url = os.environ.get("CI_SERVER_URL", "https://gitlab.com")
token = os.environ["GITLAB_TOKEN"]
project_id = os.environ["CI_PROJECT_ID"]
mr_iid = sys.argv[1]

# 最新のノート（コメント）を確認
response = requests.get(
    f"{gitlab_url}/api/v4/projects/{project_id}/merge_requests/{mr_iid}/notes",
    headers={"PRIVATE-TOKEN": token},
    params={"sort": "desc", "per_page": 3}
)
response.raise_for_status()
notes = response.json()
for note in notes:
    print(f"--- note_id={note['id']} ---")
    for line in note["body"].split("\n")[:3]:
        print(line)
    print()
```

### 不一致時のリトライ

確認で不一致が検出された場合:
1. 書き込み内容のファイルを再確認
2. API呼び出しを再実行（最大2回リトライ）
3. 2回リトライしても不一致の場合、エラーとして報告
