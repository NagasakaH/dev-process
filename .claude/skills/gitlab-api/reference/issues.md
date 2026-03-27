# Issues API Reference

GitLab REST API v4 reference for issues, issue links, notes, labels, and milestones.

**Base URL:** `https://gitlab.example.com/api/v4`

**Authentication:** Pass a `PRIVATE-TOKEN` header or `access_token` query parameter.

---

## Issues

### List issues (global)

```
GET /issues
```

Returns all issues the authenticated user has access to across all projects.

| Parameter | Type | Description |
|---|---|---|
| `state` | string | `opened`, `closed`, or `all` (default: `all`) |
| `labels` | string | Comma-separated list of label names |
| `milestone` | string | Milestone title |
| `scope` | string | `created_by_me`, `assigned_to_me`, or `all` |
| `assignee_id` | integer | ID of a user assigned to the issue |
| `author_id` | integer | ID of the issue author |
| `search` | string | Search against title and description |
| `order_by` | string | `created_at` or `updated_at` (default: `created_at`) |
| `sort` | string | `asc` or `desc` (default: `desc`) |
| `per_page` | integer | Number of results per page (default: 20, max: 100) |
| `page` | integer | Page number (default: 1) |

### List project issues

```
GET /projects/:id/issues
```

Returns issues for a specific project. Accepts the same parameters as the global endpoint.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |

### List group issues

```
GET /groups/:id/issues
```

Returns issues for a specific group. Accepts the same parameters as the global endpoint.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Group ID or URL-encoded path |

### Get single issue

```
GET /projects/:id/issues/:issue_iid
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `issue_iid` | integer | yes | Internal ID of the issue |

### Create issue

```
POST /projects/:id/issues
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `title` | string | yes | Title of the issue |
| `description` | string | no | Description of the issue (Markdown supported) |
| `labels` | string | no | Comma-separated label names |
| `assignee_ids` | array[integer] | no | IDs of users to assign |
| `milestone_id` | integer | no | Milestone ID to assign |
| `confidential` | boolean | no | Whether the issue is confidential |
| `due_date` | string | no | Due date in `YYYY-MM-DD` format |
| `weight` | integer | no | Weight of the issue (GitLab Premium) |

### Edit issue

```
PUT /projects/:id/issues/:issue_iid
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `issue_iid` | integer | yes | Internal ID of the issue |
| `title` | string | no | Updated title |
| `description` | string | no | Updated description |
| `state_event` | string | no | `close` or `reopen` |
| `labels` | string | no | Comma-separated label names (replaces existing) |
| `add_labels` | string | no | Comma-separated label names to add |
| `remove_labels` | string | no | Comma-separated label names to remove |
| `assignee_ids` | array[integer] | no | IDs of users to assign |
| `milestone_id` | integer | no | Milestone ID to assign |

### Delete issue

```
DELETE /projects/:id/issues/:issue_iid
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `issue_iid` | integer | yes | Internal ID of the issue |

### Move issue

```
POST /projects/:id/issues/:issue_iid/move
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Source project ID or URL-encoded path |
| `issue_iid` | integer | yes | Internal ID of the issue |
| `to_project_id` | integer | yes | ID of the destination project |

---

## Issue Links

### List issue links

```
GET /projects/:id/issues/:issue_iid/links
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `issue_iid` | integer | yes | Internal ID of the issue |

### Create issue link

```
POST /projects/:id/issues/:issue_iid/links
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `issue_iid` | integer | yes | Internal ID of the source issue |
| `target_project_id` | integer | yes | Project ID of the target issue |
| `target_issue_iid` | integer | yes | Internal ID of the target issue |
| `link_type` | string | no | `relates_to` (default), `blocks`, or `is_blocked_by` |

### Delete issue link

```
DELETE /projects/:id/issues/:issue_iid/links/:issue_link_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `issue_iid` | integer | yes | Internal ID of the issue |
| `issue_link_id` | integer | yes | ID of the issue link |

---

## Issue Notes (Comments)

### List issue notes

```
GET /projects/:id/issues/:issue_iid/notes
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `issue_iid` | integer | yes | Internal ID of the issue |
| `sort` | string | no | `asc` or `desc` (default: `desc`) |
| `order_by` | string | no | `created_at` or `updated_at` (default: `created_at`) |

### Create issue note

```
POST /projects/:id/issues/:issue_iid/notes
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `issue_iid` | integer | yes | Internal ID of the issue |
| `body` | string | yes | Content of the note (Markdown supported) |

---

## Labels

### List labels

```
GET /projects/:id/labels
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `search` | string | no | Keyword to filter labels |

### Create label

```
POST /projects/:id/labels
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `name` | string | yes | Name of the label |
| `color` | string | yes | Color of the label in hex format (e.g., `#FF0000`) |
| `description` | string | no | Description of the label |
| `priority` | integer | no | Priority of the label |

---

## Milestones

### List milestones

```
GET /projects/:id/milestones
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `state` | string | no | `active` or `closed` |
| `search` | string | no | Search against title and description |

### Create milestone

```
POST /projects/:id/milestones
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `title` | string | yes | Title of the milestone |
| `description` | string | no | Description of the milestone |
| `due_date` | string | no | Due date in `YYYY-MM-DD` format |
| `start_date` | string | no | Start date in `YYYY-MM-DD` format |

---

## Attaching Files to Issues

To embed images or other files in an issue description or comment, first upload the file to the project, then include the returned Markdown link in the `description` or note `body`.

### Workflow

1. Upload the file via `POST /projects/:id/uploads` (see [Projects API — Upload a File](projects.md#upload-a-file-to-a-project))
2. Extract the `markdown` field from the response (e.g., `![screenshot](/uploads/abc123/screenshot.png)`)
3. Include the markdown string in the `description` when creating/editing an issue, or in the `body` when creating a note

### Example

```bash
source scripts/common.sh
source scripts/projects.sh
source scripts/issues.sh

PROJECT="my-group/my-project"

# Upload the file
UPLOAD=$(gitlab_upload_project_file "$PROJECT" "/path/to/screenshot.png")
IMAGE_MD=$(echo "$UPLOAD" | jq -r '.markdown')

# Create issue with embedded image
DESCRIPTION=$(printf "## Bug Report\n\nSee screenshot below:\n\n%s" "$IMAGE_MD")
gitlab_create_issue "$PROJECT" "Visual glitch on dashboard" "$DESCRIPTION"

# Or add image as a comment on an existing issue
NOTE_BODY=$(printf "Adding screenshot:\n\n%s" "$IMAGE_MD")
gitlab_create_issue_note "$PROJECT" 42 "$NOTE_BODY"
```

> **Tip:** Multiple files can be uploaded and embedded. Each upload returns its own Markdown link.

---

## Common Parameters

These query parameters are shared across most list endpoints:

| Parameter | Type | Description |
|---|---|---|
| `state` | string | Filter by state (`opened`, `closed`, `all`) |
| `labels` | string | Comma-separated label names to filter by |
| `milestone` | string | Milestone title to filter by |
| `scope` | string | Scope: `created_by_me`, `assigned_to_me`, `all` |
| `assignee_id` | integer | Filter by assignee user ID |
| `author_id` | integer | Filter by author user ID |
| `search` | string | Search against title and description |
| `order_by` | string | Order by `created_at` or `updated_at` |
| `sort` | string | Sort direction: `asc` or `desc` |
| `per_page` | integer | Results per page (default: 20, max: 100) |
| `page` | integer | Page number for pagination |

## Response Codes

| Code | Description |
|---|---|
| `200` | Success (GET, PUT) |
| `201` | Created (POST) |
| `204` | No Content (DELETE) |
| `400` | Bad request |
| `401` | Unauthorized |
| `403` | Forbidden |
| `404` | Not found |
| `409` | Conflict (e.g., duplicate issue link) |

---

## Markdown Formatting

All `description` and `body` fields accept **GitLab Flavored Markdown (GLFM)**. Use GLFM formatting for rich content such as task lists, tables, code blocks, inline diffs, and GitLab-specific references.

See [GitLab Flavored Markdown Reference](gitlab-flavored-markdown.md) for the full syntax guide.
