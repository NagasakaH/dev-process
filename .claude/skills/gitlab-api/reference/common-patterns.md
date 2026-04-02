# Common Patterns

## Basic API Operations

```python
from common import GitLabClient

client = GitLabClient()

# URL-encode project paths (namespace/project -> namespace%2Fproject)
pid = client.encode_path("my-group/my-project")

# GET request
projects = client.api("GET", "/projects?per_page=100&page=2")

# POST with JSON body (dict is auto-serialized)
new_project = client.api("POST", "/projects", {"name": "new-project", "visibility": "private"})

# PUT to update
client.api("PUT", "/projects/{}".format(pid), {"description": "Updated"})

# DELETE
client.api("DELETE", "/projects/{}".format(pid))
```

## Error Handling

All API calls check HTTP status codes. On error (HTTP 400+), the response body is printed to stderr and the process exits with code 1.

```python
# Errors are handled automatically by GitLabClient.api()
# For custom error handling, use urllib directly:
from urllib.request import Request, urlopen
from urllib.error import HTTPError

try:
    result = client.api("POST", "/projects", {"name": "test"})
except SystemExit:
    # api() calls sys.exit(1) on error
    pass
```

## File Attachment Workflow

To attach images or files to issues, merge requests, or comments:

1. **Upload the file** to the project using `upload_project_file`
2. **Extract the `markdown` link** from the response
3. **Embed the markdown** in the `description` or note `body`

```python
from common import GitLabClient
from projects import upload_project_file
from issues import create_issue

client = GitLabClient()

# Upload file and get markdown link
upload = upload_project_file(client, "my-group/my-project", "/path/to/image.png")
image_md = upload["markdown"]

# Use in issue description
create_issue(client, "my-group/my-project", "Bug report",
             description="Details:\n\n{}".format(image_md))
```

See [projects.md](projects.md#upload-a-file-to-a-project) for the upload API details.

## JSON 安全性

Python の `json` モジュールによるシリアライズにより、シェル展開の問題は根本的に解消されている:

- マルチラインコンテンツ → `json.dumps()` が安全にエスケープ
- 特殊文字（`$`, `` ` ``, `\` 等） → Python 文字列として安全に処理
- ユーザー入力 → dict に格納し `json.dumps()` で自動シリアライズ

### 推奨パターン

CLI から直接実行、または Python モジュールをインポートして使用:

```python
from common import GitLabClient

client = GitLabClient()

# マルチラインの description も安全
description = """## Steps to reproduce

1. Open the dashboard
2. Click on "Settings"
3. Observe the error

## Expected behavior

Settings page should load without errors.
"""

result = client.api("POST", "/projects/{}/issues".format(
    client.encode_path("my-group/my-project")
), {
    "title": "Bug: Settings page crash",
    "description": description,
    "labels": "bug,priority::high",
})
print(result["web_url"])
```

## API レスポンスの検証

API 呼び出し後は、必ずレスポンスを検証すること。

### ステータスコードチェック

`GitLabClient.api()` はHTTPエラー時に自動的にエラー出力して終了する。追加のチェックは不要。

### 作成後の内容確認（GET で再取得）

```python
from common import GitLabClient
from issues import create_issue, get_issue

client = GitLabClient()

# 作成
created = create_issue(client, "my-group/my-project", "Bug report",
                       description="Details here")
issue_iid = created["iid"]

# 再取得して検証
verified = get_issue(client, "my-group/my-project", issue_iid)
assert verified["title"] == "Bug report"
assert "Details here" in verified["description"]
```

### JSON 構造チェック

```python
result = client.api("POST", "/projects", {"name": "test"})
for field in ["id", "name", "web_url"]:
    assert field in result, "Missing field: {}".format(field)
```