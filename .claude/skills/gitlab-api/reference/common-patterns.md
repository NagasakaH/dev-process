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
