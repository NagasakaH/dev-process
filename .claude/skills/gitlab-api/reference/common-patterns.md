# Common Patterns

## Basic API Operations

```bash
# URL-encode project paths (namespace/project → namespace%2Fproject)
PROJECT_ID=$(urlencode "my-group/my-project")

# Pagination
gitlab_api GET "/projects?per_page=100&page=2"

# POST with JSON body
gitlab_api POST "/projects" '{"name":"new-project","visibility":"private"}'

# PUT to update
gitlab_api PUT "/projects/$PROJECT_ID" '{"description":"Updated"}'

# DELETE
gitlab_api DELETE "/projects/$PROJECT_ID"
```

## Error Handling

All functions check HTTP status codes. On error, the response body (usually containing `{"message":"..."}`) is printed to stderr.

## File Attachment Workflow

To attach images or files to issues, merge requests, or comments:

1. **Upload the file** to the project using `gitlab_upload_project_file` (calls `POST /projects/:id/uploads`)
2. **Extract the `markdown` link** from the response JSON
3. **Embed the markdown** in the `description` or note `body`

```bash
source scripts/common.sh
source scripts/projects.sh
source scripts/issues.sh

# Upload file and get markdown link
UPLOAD=$(gitlab_upload_project_file "my-group/my-project" "/path/to/image.png")
IMAGE_MD=$(echo "$UPLOAD" | jq -r '.markdown')

# Use in issue description, MR description, or comment body
gitlab_create_issue "my-group/my-project" "Bug report" "Details:\n\n${IMAGE_MD}"
```

See [projects.md](projects.md#upload-a-file-to-a-project) for the upload API details.

## ⚠️ 既存シェル関数の使用制限

`scripts/*.sh` のヘルパー関数は内部で heredoc (`cat <<EOF`) を使用しているレガシー実装である。以下のルールを厳守すること:

- **単純なパラメータのみ**（変数展開・特殊文字・マルチラインを含まない）の場合に限り使用可
- **マルチライン body / description を含む操作には使用禁止** — 必ず `create` ツールで Python/Node.js スクリプトを作成して実行すること
- 既存シェル関数は将来的に Python 実装へ移行予定のレガシーコードである

## Shell展開リスクと安全なパターン

### 危険パターン（使用禁止）

```bash
# ❌ heredoc 内の $変数 がシェル展開される
curl -X POST "$GITLAB_URL/api/v4/projects/$PID/issues" \
  -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  -d @- <<EOF
{"title": "$TITLE", "description": "$DESCRIPTION"}
EOF

# ❌ echo 内でバッククォートや $() が展開される
echo '{"title": "'"$TITLE"'", "description": "'"$DESC"'"}' | curl -d @- ...

# ❌ コマンド置換でファイル内容を注入 — 特殊文字でJSONが壊れる
curl -d "$(cat body.json)" ...

# ❌ Python heredoc を bash 経由で実行 — シェルマーカーが混入
bash -c 'python3 <<PYEOF
import requests
...
PYEOF'
```

### 安全パターン（推奨）

**Python スクリプトを `create` ツールで作成し、`bash` で実行する:**

```python
# create ツールで gitlab_create_issue.py として保存
import json, os, requests

url = f"{os.environ['GITLAB_URL']}/api/v4/projects/{project_id}/issues"
headers = {"PRIVATE-TOKEN": os.environ["GITLAB_TOKEN"]}
data = {"title": title, "description": description}

resp = requests.post(url, headers=headers, json=data)
resp.raise_for_status()
result = resp.json()
print(json.dumps(result, indent=2))
```

```bash
# bash ツールで実行
python3 gitlab_create_issue.py
```

**Node.js の場合:**

```javascript
// create ツールで gitlab_create_issue.mjs として保存
const url = `${process.env.GITLAB_URL}/api/v4/projects/${projectId}/issues`;
const resp = await fetch(url, {
  method: "POST",
  headers: {
    "PRIVATE-TOKEN": process.env.GITLAB_TOKEN,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({ title, description }),
});
const result = await resp.json();
console.log(JSON.stringify(result, null, 2));
```

### 使い分けの判断基準

| ケース | 方法 |
|--------|------|
| 単純な GET / DELETE（ボディなし） | `curl` 直接実行で OK |
| 1行の JSON ボディ（変数展開なし） | `curl` + シングルクォートで OK |
| マルチラインボディ / ユーザー入力を含む | **必ず** Python/Node.js スクリプト |
| Markdown 記法を含む description | **必ず** Python/Node.js スクリプト |

## API レスポンスの検証

API 呼び出し後は、必ずレスポンスを検証すること。

### ステータスコードチェック

```python
resp = requests.post(url, headers=headers, json=data)
if resp.status_code not in (200, 201):
    print(f"Error {resp.status_code}: {resp.text}", file=sys.stderr)
    sys.exit(1)
```

### 作成後の内容確認（GET で再取得）

```python
# 作成
created = requests.post(url, headers=headers, json=data).json()
issue_iid = created["iid"]

# 再取得して検証
verify_url = f"{base_url}/issues/{issue_iid}"
verified = requests.get(verify_url, headers=headers).json()

assert verified["title"] == expected_title
assert expected_text in verified["description"]
```

### JSON 構造チェック

```python
result = resp.json()
# 必須フィールドの存在確認
for field in ["id", "iid", "title", "web_url"]:
    assert field in result, f"Missing field: {field}"
```
