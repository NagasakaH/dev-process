# Merge Requests API Reference

GitLab REST API v4 endpoints for managing merge requests, approvals, and related resources.

Base: `GET /api/v4`

---

## List Merge Requests

### Global (across all projects)

```
GET /merge_requests
```

### Project-scoped

```
GET /projects/:id/merge_requests
```

**Parameters:**

| Parameter     | Type   | Description                                                        |
| ------------- | ------ | ------------------------------------------------------------------ |
| `state`       | string | Filter by state: `opened`, `closed`, `merged`, `all` (default: `all`) |
| `order_by`    | string | Order by `created_at` or `updated_at` (default: `created_at`)     |
| `sort`        | string | Sort order: `asc` or `desc` (default: `desc`)                     |
| `scope`       | string | Scope: `created_by_me`, `assigned_to_me`, `all`                   |
| `labels`      | string | Comma-separated label names                                       |
| `milestone`   | string | Milestone title; `None` for no milestone, `Any` for any milestone |
| `author_id`   | int    | Filter by author user ID                                          |
| `assignee_id` | int    | Filter by assignee user ID; `None` or `Any`                       |
| `search`      | string | Search in title and description                                   |
| `source_branch` | string | Filter by source branch                                         |
| `target_branch` | string | Filter by target branch                                         |
| `wip`         | string | Filter by WIP status: `yes` or `no`                               |
| `per_page`    | int    | Number of results per page (default: 20, max: 100)                |
| `page`        | int    | Page number for pagination                                        |

---

## Get Single Merge Request

```
GET /projects/:id/merge_requests/:merge_request_iid
```

**Parameters:**

| Parameter              | Type    | Description                                              |
| ---------------------- | ------- | -------------------------------------------------------- |
| `id`                   | int/str | Project ID or URL-encoded path                           |
| `merge_request_iid`    | int     | Internal ID of the merge request                         |
| `include_diverged_commits_count` | bool | Include diverged commits count (default: false) |
| `include_rebase_in_progress`     | bool | Include rebase-in-progress status                |
| `render_html`          | bool    | Return description and title rendered as HTML            |

---

## Create Merge Request

```
POST /projects/:id/merge_requests
```

**Required Parameters:**

| Parameter        | Type   | Description              |
| ---------------- | ------ | ------------------------ |
| `source_branch`  | string | Source branch name        |
| `target_branch`  | string | Target branch name        |
| `title`          | string | Title of the merge request |

**Optional Parameters:**

| Parameter                        | Type    | Description                                        |
| -------------------------------- | ------- | -------------------------------------------------- |
| `description`                    | string  | Description of the MR                              |
| `assignee_id`                    | int     | Assignee user ID                                   |
| `assignee_ids`                   | array   | Assignee user IDs (multiple assignees)             |
| `reviewer_ids`                   | array   | Reviewer user IDs                                  |
| `labels`                         | string  | Comma-separated label names                        |
| `milestone_id`                   | int     | Milestone ID                                       |
| `remove_source_branch`           | bool    | Remove source branch after merge                   |
| `squash`                         | bool    | Squash commits on merge                            |
| `allow_collaboration`            | bool    | Allow commits from upstream members                |
| `target_project_id`              | int     | Target project ID (for cross-project MRs)          |

---

## Update Merge Request

```
PUT /projects/:id/merge_requests/:merge_request_iid
```

Accepts the same optional parameters as Create, plus:

| Parameter        | Type   | Description                                        |
| ---------------- | ------ | -------------------------------------------------- |
| `state_event`    | string | `close` or `reopen` the merge request              |
| `title`          | string | Updated title                                      |
| `target_branch`  | string | Updated target branch                              |
| `discussion_locked` | bool | Lock discussion on the MR                        |

---

## Delete Merge Request

```
DELETE /projects/:id/merge_requests/:merge_request_iid
```

Requires at least Maintainer role in the project.

---

## Merge a Merge Request

```
PUT /projects/:id/merge_requests/:merge_request_iid/merge
```

**Parameters:**

| Parameter                        | Type   | Description                                        |
| -------------------------------- | ------ | -------------------------------------------------- |
| `merge_commit_message`           | string | Custom merge commit message                        |
| `squash_commit_message`          | string | Custom squash commit message                       |
| `squash`                         | bool   | Squash commits on merge                            |
| `should_remove_source_branch`    | bool   | Remove source branch after merge                   |
| `merge_when_pipeline_succeeds`   | bool   | Merge when pipeline succeeds                       |
| `sha`                            | string | HEAD SHA must match this for merge to proceed      |

---

## Rebase a Merge Request

```
PUT /projects/:id/merge_requests/:merge_request_iid/rebase
```

**Parameters:**

| Parameter    | Type | Description                                 |
| ------------ | ---- | ------------------------------------------- |
| `skip_ci`    | bool | Skip CI pipeline for the rebase (optional)  |

---

## List Merge Request Changes / Diffs

```
GET /projects/:id/merge_requests/:merge_request_iid/changes
```

Returns the merge request including its files and changes (diffs).

**Parameters:**

| Parameter          | Type | Description                                  |
| ------------------ | ---- | -------------------------------------------- |
| `access_raw_diffs` | bool | Return raw diff data without highlighting    |
| `unidiff`          | bool | Return diffs in unified diff format          |

---

## List Merge Request Commits

```
GET /projects/:id/merge_requests/:merge_request_iid/commits
```

Returns a list of commits associated with the merge request.

---

## Merge Request Approvals

### Get Approval State

```
GET /projects/:id/merge_requests/:merge_request_iid/approvals
```

Returns approval status including required approvals, approved-by list, and approval rules.

### Approve a Merge Request

```
POST /projects/:id/merge_requests/:merge_request_iid/approve
```

**Parameters:**

| Parameter | Type   | Description                                 |
| --------- | ------ | ------------------------------------------- |
| `sha`     | string | HEAD SHA; approve only if it matches        |

### Unapprove a Merge Request

```
POST /projects/:id/merge_requests/:merge_request_iid/unapprove
```

---

## Merge Request Notes (Comments)

### List Notes

```
GET /projects/:id/merge_requests/:merge_request_iid/notes
```

**Parameters:**

| Parameter  | Type   | Description                                           |
| ---------- | ------ | ----------------------------------------------------- |
| `sort`     | string | Sort order: `asc` or `desc` (default: `desc`)        |
| `order_by` | string | Order by `created_at` or `updated_at`                 |
| `per_page` | int    | Results per page (default: 20, max: 100)              |
| `page`     | int    | Page number                                           |

### Create a Note

```
POST /projects/:id/merge_requests/:merge_request_iid/notes
```

**Parameters:**

| Parameter  | Type   | Description                        |
| ---------- | ------ | ---------------------------------- |
| `body`     | string | **Required.** Content of the note  |

---

## Attaching Files to Merge Requests

To embed images or other files in a merge request description or comment, first upload the file to the project, then include the returned Markdown link in the `description` or note `body`.

### Workflow

1. Upload the file via `POST /projects/:id/uploads` (see [Projects API — Upload a File](projects.md#upload-a-file-to-a-project))
2. Extract the `markdown` field from the response (e.g., `![screenshot](/uploads/abc123/screenshot.png)`)
3. Include the markdown string in the `description` when creating/updating a merge request, or in the `body` when creating a note

### Example

```bash
source scripts/common.sh
source scripts/projects.sh
source scripts/merge-requests.sh

PROJECT="my-group/my-project"

# Upload the file
UPLOAD=$(gitlab_upload_project_file "$PROJECT" "/path/to/design-mockup.png")
IMAGE_MD=$(echo "$UPLOAD" | jq -r '.markdown')

# Create MR with embedded image
DESCRIPTION=$(printf "## UI Redesign\n\nMockup:\n\n%s" "$IMAGE_MD")
JSON=$(jq -n \
  --arg title "feat: redesign dashboard" \
  --arg desc "$DESCRIPTION" \
  --arg src "feature/redesign" \
  --arg tgt "main" \
  '{title: $title, description: $desc, source_branch: $src, target_branch: $tgt}')
gitlab_api POST "/projects/$(urlencode "$PROJECT")/merge_requests" "$JSON"

# Or add image as a comment on an existing MR
NOTE_BODY=$(printf "Updated mockup:\n\n%s" "$IMAGE_MD")
gitlab_create_mr_note "$PROJECT" 15 "$NOTE_BODY"
```

> **Tip:** Multiple files can be uploaded and embedded. Each upload returns its own Markdown link.

---

## Common Query Parameters

These parameters are shared across list endpoints:

| Parameter     | Type   | Description                                                       |
| ------------- | ------ | ----------------------------------------------------------------- |
| `state`       | string | `opened`, `closed`, `merged`, `all`                               |
| `order_by`    | string | `created_at`, `updated_at`                                        |
| `sort`        | string | `asc`, `desc`                                                     |
| `scope`       | string | `created_by_me`, `assigned_to_me`, `all`                          |
| `labels`      | string | Comma-separated label names                                       |
| `milestone`   | string | Milestone title; `None` or `Any`                                  |
| `author_id`   | int    | Filter by author user ID                                          |
| `assignee_id` | int    | Filter by assignee user ID; `None` or `Any`                       |
| `per_page`    | int    | Results per page (max: 100)                                       |
| `page`        | int    | Page number for pagination                                        |

---

## Markdown Formatting

All `description` and `body` fields accept **GitLab Flavored Markdown (GLFM)**. Use GLFM formatting for rich content such as task lists, tables, code blocks, inline diffs, and GitLab-specific references (e.g., `#123` for issues, `!456` for merge requests).

See [GitLab Flavored Markdown Reference](gitlab-flavored-markdown.md) for the full syntax guide.
