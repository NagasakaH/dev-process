# Projects API Reference

GitLab REST API v4 endpoints for managing projects (repositories). Projects are the core resource in GitLab — they contain code, issues, merge requests, CI/CD pipelines, and more.

**Base URL:** `GET /api/v4/projects`

---

## Endpoints

### List All Projects

```
GET /projects
```

Returns a list of all projects accessible by the authenticated user. Supports filtering, sorting, and pagination.

| Parameter | Type | Description |
|---|---|---|
| `search` | string | Filter by name or path (fuzzy match) |
| `visibility` | string | `public`, `internal`, or `private` |
| `owned` | boolean | Limit to projects owned by the current user |
| `membership` | boolean | Limit to projects the current user is a member of |
| `starred` | boolean | Limit to projects starred by the current user |
| `archived` | boolean | Limit to archived projects (`true`) or non-archived (`false`) |
| `order_by` | string | `id`, `name`, `path`, `created_at`, `updated_at`, `last_activity_at`, `similarity` |
| `sort` | string | `asc` or `desc` (default: `desc`) |
| `per_page` | integer | Results per page (default: 20, max: 100) |
| `page` | integer | Page number (default: 1) |
| `with_issues_enabled` | boolean | Limit to projects with issues enabled |
| `with_merge_requests_enabled` | boolean | Limit to projects with MRs enabled |
| `min_access_level` | integer | Minimum access level (10=Guest, 20=Reporter, 30=Developer, 40=Maintainer, 50=Owner) |
| `topic` | string | Filter by topic/tag |
| `simple` | boolean | Return limited fields for each project |

---

### List User Projects

```
GET /users/:user_id/projects
```

Returns projects owned by the specified user. Supports the same filtering and pagination parameters as "List All Projects".

| Parameter | Type | Description |
|---|---|---|
| `user_id` | integer or string | **Required.** The ID or username of the user |

---

### Get Single Project

```
GET /projects/:id
```

Returns detailed information about a specific project.

| Parameter | Type | Description |
|---|---|---|
| `id` | integer or string | **Required.** Project ID or URL-encoded path (e.g. `namespace%2Fproject`) |
| `statistics` | boolean | Include project statistics (commits, storage, etc.) |
| `license` | boolean | Include the project license data |
| `with_custom_attributes` | boolean | Include custom attributes |

---

### Create Project

```
POST /projects
```

Creates a new project owned by the authenticated user.

| Parameter | Type | Description |
|---|---|---|
| `name` | string | **Required.** Project name |
| `path` | string | Repository slug (auto-generated from name if omitted) |
| `namespace_id` | integer | Namespace (group/user) to create the project in |
| `description` | string | Short project description |
| `visibility` | string | `private`, `internal`, or `public` (default: `private`) |
| `initialize_with_readme` | boolean | Create an initial README |
| `default_branch` | string | Default branch name (default: `main`) |
| `import_url` | string | URL to import repository from |
| `auto_devops_enabled` | boolean | Enable Auto DevOps |
| `build_timeout` | integer | CI/CD job timeout in seconds |
| `ci_config_path` | string | Path to the CI/CD configuration file |
| `issues_enabled` | boolean | Enable issues |
| `merge_requests_enabled` | boolean | Enable merge requests |
| `wiki_enabled` | boolean | Enable wiki |
| `snippets_enabled` | boolean | Enable snippets |
| `container_registry_enabled` | boolean | Enable container registry |
| `shared_runners_enabled` | boolean | Enable shared runners |

---

### Edit Project

```
PUT /projects/:id
```

Updates an existing project. Only parameters that are passed will be updated.

| Parameter | Type | Description |
|---|---|---|
| `id` | integer or string | **Required.** Project ID or URL-encoded path |
| `name` | string | Project name |
| `description` | string | Project description |
| `visibility` | string | `private`, `internal`, or `public` |
| `default_branch` | string | Default branch |
| `issues_enabled` | boolean | Enable/disable issues |
| `merge_requests_enabled` | boolean | Enable/disable merge requests |
| `wiki_enabled` | boolean | Enable/disable wiki |
| `archived` | boolean | Archive/unarchive the project |

---

### Delete Project

```
DELETE /projects/:id
```

Deletes a project including all associated resources (repository, issues, merge requests, etc.). This action is **irreversible**.

| Parameter | Type | Description |
|---|---|---|
| `id` | integer or string | **Required.** Project ID or URL-encoded path |

---

### Fork Project

```
POST /projects/:id/fork
```

Forks a project into the authenticated user's namespace (or a specified namespace).

| Parameter | Type | Description |
|---|---|---|
| `id` | integer or string | **Required.** Project ID or URL-encoded path |
| `namespace` | integer or string | Target namespace ID or path |
| `name` | string | Name for the forked project |
| `path` | string | Path for the forked project |
| `visibility` | string | Visibility level of the fork |

---

### List Forks

```
GET /projects/:id/forks
```

Returns a list of forks of the specified project. Supports the same filtering and pagination parameters as "List All Projects".

| Parameter | Type | Description |
|---|---|---|
| `id` | integer or string | **Required.** Project ID or URL-encoded path |

---

### Star Project

```
POST /projects/:id/star
```

Stars the specified project for the authenticated user. Returns `304 Not Modified` if already starred.

| Parameter | Type | Description |
|---|---|---|
| `id` | integer or string | **Required.** Project ID or URL-encoded path |

---

### Unstar Project

```
POST /projects/:id/unstar
```

Unstars the specified project for the authenticated user. Returns `304 Not Modified` if not starred.

| Parameter | Type | Description |
|---|---|---|
| `id` | integer or string | **Required.** Project ID or URL-encoded path |

---

### Archive Project

```
POST /projects/:id/archive
```

Archives the project. Archived projects are read-only and hidden from the default project list.

| Parameter | Type | Description |
|---|---|---|
| `id` | integer or string | **Required.** Project ID or URL-encoded path |

---

### Unarchive Project

```
POST /projects/:id/unarchive
```

Unarchives the project, making it active again.

| Parameter | Type | Description |
|---|---|---|
| `id` | integer or string | **Required.** Project ID or URL-encoded path |

---

### Get Project Languages

```
GET /projects/:id/languages
```

Returns the programming languages used in the project with their percentage share.

| Parameter | Type | Description |
|---|---|---|
| `id` | integer or string | **Required.** Project ID or URL-encoded path |

---

### Transfer Project

```
PUT /projects/:id/transfer
```

Transfers a project to a different namespace. Requires owner-level access.

| Parameter | Type | Description |
|---|---|---|
| `id` | integer or string | **Required.** Project ID or URL-encoded path |
| `namespace` | integer or string | **Required.** Target namespace ID or path |

---

### Share Project with Group

```
POST /projects/:id/share
```

Shares the project with a group, granting group members access at the specified level.

| Parameter | Type | Description |
|---|---|---|
| `id` | integer or string | **Required.** Project ID or URL-encoded path |
| `group_id` | integer | **Required.** ID of the group to share with |
| `group_access` | integer | **Required.** Access level (10=Guest, 20=Reporter, 30=Developer, 40=Maintainer) |
| `expires_at` | string | Expiration date (ISO 8601 format: `YYYY-MM-DD`) |

---

## Project Hooks (Webhooks)

### List Project Hooks

```
GET /projects/:id/hooks
```

Returns a list of webhooks configured for the project.

| Parameter | Type | Description |
|---|---|---|
| `id` | integer or string | **Required.** Project ID or URL-encoded path |

### Get a Project Hook

```
GET /projects/:id/hooks/:hook_id
```

| Parameter | Type | Description |
|---|---|---|
| `id` | integer or string | **Required.** Project ID or URL-encoded path |
| `hook_id` | integer | **Required.** Hook ID |

### Add Project Hook

```
POST /projects/:id/hooks
```

| Parameter | Type | Description |
|---|---|---|
| `id` | integer or string | **Required.** Project ID or URL-encoded path |
| `url` | string | **Required.** Webhook URL |
| `push_events` | boolean | Trigger on push events (default: `true`) |
| `issues_events` | boolean | Trigger on issue events |
| `merge_requests_events` | boolean | Trigger on merge request events |
| `tag_push_events` | boolean | Trigger on tag push events |
| `note_events` | boolean | Trigger on comment events |
| `pipeline_events` | boolean | Trigger on pipeline events |
| `job_events` | boolean | Trigger on job events |
| `releases_events` | boolean | Trigger on release events |
| `confidential_issues_events` | boolean | Trigger on confidential issue events |
| `token` | string | Secret token for webhook validation |
| `enable_ssl_verification` | boolean | Enable SSL verification (default: `true`) |

### Edit Project Hook

```
PUT /projects/:id/hooks/:hook_id
```

Same parameters as "Add Project Hook", plus the `hook_id` path parameter.

### Delete Project Hook

```
DELETE /projects/:id/hooks/:hook_id
```

| Parameter | Type | Description |
|---|---|---|
| `id` | integer or string | **Required.** Project ID or URL-encoded path |
| `hook_id` | integer | **Required.** Hook ID |

---

## Upload a File to a Project

```
POST /projects/:id/uploads
```

Uploads a file to the specified project. The response contains a Markdown-formatted link that can be used in issue descriptions, merge request descriptions, comments (notes), and any other Markdown field.

This endpoint uses **multipart form data** (not JSON).

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer or string | yes | Project ID or URL-encoded path |
| `file` | file | yes | The file to upload (multipart form field) |

### Response

```json
{
  "id": 968485269,
  "alt": "my-image",
  "url": "/uploads/abc123def456/my-image.png",
  "full_path": "/-/project/12345/uploads/abc123def456/my-image.png",
  "markdown": "![my-image](/uploads/abc123def456/my-image.png)"
}
```

### Usage Pattern: Attaching Files to Issues or Merge Requests

To attach an image or file to an issue or merge request description:

1. **Upload the file** to the project using this endpoint
2. **Extract the `markdown` field** from the response
3. **Include the markdown** in the `description` field when creating/editing an issue or merge request

```bash
# Step 1: Upload file
UPLOAD_RESULT=$(gitlab_upload_project_file "my-group/my-project" "/path/to/screenshot.png")

# Step 2: Extract markdown link
IMAGE_MD=$(echo "$UPLOAD_RESULT" | jq -r '.markdown')

# Step 3: Use in issue or MR description
gitlab_create_issue "my-group/my-project" "Bug report" "Found a bug:\n\n${IMAGE_MD}"
```

> **Note:** Uploaded files are scoped to the project. The returned relative URL (`/uploads/...`) is resolved by GitLab when rendered in Markdown.

---

## Common Query Parameters

These parameters are supported across most list endpoints:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `per_page` | integer | 20 | Number of results per page (max 100) |
| `page` | integer | 1 | Page number for pagination |
| `order_by` | string | `created_at` | Field to order results by |
| `sort` | string | `desc` | Sort direction: `asc` or `desc` |
| `search` | string | — | Search by name or path |
| `visibility` | string | — | Filter by visibility: `public`, `internal`, `private` |

---

## Example Responses

### Single Project (abbreviated)

```json
{
  "id": 42,
  "name": "my-project",
  "name_with_namespace": "My Group / my-project",
  "path": "my-project",
  "path_with_namespace": "my-group/my-project",
  "description": "An example project",
  "visibility": "private",
  "default_branch": "main",
  "web_url": "https://gitlab.com/my-group/my-project",
  "ssh_url_to_repo": "git@gitlab.com:my-group/my-project.git",
  "http_url_to_repo": "https://gitlab.com/my-group/my-project.git",
  "created_at": "2024-01-15T10:30:00.000Z",
  "last_activity_at": "2024-06-20T14:22:00.000Z",
  "star_count": 12,
  "forks_count": 3,
  "open_issues_count": 8,
  "archived": false,
  "namespace": {
    "id": 10,
    "name": "My Group",
    "path": "my-group",
    "kind": "group"
  },
  "permissions": {
    "project_access": {
      "access_level": 40,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 30,
      "notification_level": 3
    }
  }
}
```

### Project Languages

```json
{
  "Python": 58.42,
  "Shell": 22.15,
  "JavaScript": 12.30,
  "Dockerfile": 4.08,
  "Makefile": 3.05
}
```

### Project Hook

```json
{
  "id": 1,
  "url": "https://example.com/webhook",
  "project_id": 42,
  "push_events": true,
  "issues_events": false,
  "merge_requests_events": true,
  "tag_push_events": false,
  "note_events": false,
  "pipeline_events": true,
  "job_events": false,
  "releases_events": false,
  "enable_ssl_verification": true,
  "created_at": "2024-01-20T08:00:00.000Z"
}
```

### List Projects (abbreviated)

```json
[
  {
    "id": 42,
    "name": "my-project",
    "path_with_namespace": "my-group/my-project",
    "visibility": "private",
    "default_branch": "main",
    "web_url": "https://gitlab.com/my-group/my-project",
    "star_count": 12,
    "forks_count": 3,
    "last_activity_at": "2024-06-20T14:22:00.000Z"
  },
  {
    "id": 43,
    "name": "another-project",
    "path_with_namespace": "my-group/another-project",
    "visibility": "public",
    "default_branch": "main",
    "web_url": "https://gitlab.com/my-group/another-project",
    "star_count": 130,
    "forks_count": 28,
    "last_activity_at": "2024-06-19T09:10:00.000Z"
  }
]
```

---

## Notes

- Project IDs can be numeric (`42`) or URL-encoded namespace paths (`my-group%2Fmy-project`).
- All endpoints require authentication via `PRIVATE-TOKEN` header or OAuth token.
- Rate limits apply. Default: 2000 requests per minute for authenticated users.
- Pagination headers (`X-Total`, `X-Total-Pages`, `X-Per-Page`, `X-Page`, `X-Next-Page`, `X-Prev-Page`) are included in list responses.
- See the [official GitLab documentation](https://docs.gitlab.com/ee/api/projects.html) for the complete API reference.

---

## Markdown Formatting

All `description` fields accept **GitLab Flavored Markdown (GLFM)**. Use GLFM formatting for rich content such as task lists, tables, code blocks, and GitLab-specific references.

See [GitLab Flavored Markdown Reference](gitlab-flavored-markdown.md) for the full syntax guide.
