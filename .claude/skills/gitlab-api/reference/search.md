# Search API Reference

GitLab REST API v4 reference for global, group, and project search.

**Base URL:** `https://gitlab.example.com/api/v4`

**Authentication:** Pass a `PRIVATE-TOKEN` header or `access_token` query parameter.

---

## Global Search

### Search across all projects

```
GET /search?scope=:scope&search=:query
```

Returns results matching the search query across all projects the authenticated user has access to.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `scope` | string | yes | Search scope (see Scopes below) |
| `search` | string | yes | Search query |
| `state` | string | no | Filter by state (`opened`, `closed`) — applies to issues and merge requests |
| `confidential` | boolean | no | Filter by confidentiality — applies to issues |
| `order_by` | string | no | Order by `created_at` or `updated_at` (default: `created_at`) |
| `sort` | string | no | Sort direction: `asc` or `desc` (default: `desc`) |
| `per_page` | integer | no | Results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

---

## Group Search

### Search within a group

```
GET /groups/:id/search?scope=:scope&search=:query
```

Returns results matching the search query within the specified group.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Group ID or URL-encoded path |
| `scope` | string | yes | Search scope (see Scopes below) |
| `search` | string | yes | Search query |
| `state` | string | no | Filter by state (`opened`, `closed`) |
| `confidential` | boolean | no | Filter by confidentiality |
| `order_by` | string | no | Order by `created_at` or `updated_at` |
| `sort` | string | no | Sort direction: `asc` or `desc` |
| `per_page` | integer | no | Results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

---

## Project Search

### Search within a project

```
GET /projects/:id/search?scope=:scope&search=:query
```

Returns results matching the search query within the specified project.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `scope` | string | yes | Search scope (see Scopes below) |
| `search` | string | yes | Search query |
| `state` | string | no | Filter by state (`opened`, `closed`) |
| `confidential` | boolean | no | Filter by confidentiality |
| `order_by` | string | no | Order by `created_at` or `updated_at` |
| `sort` | string | no | Sort direction: `asc` or `desc` |
| `per_page` | integer | no | Results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

---

## Scopes

Available search scopes vary by context:

| Scope | Global | Group | Project | Description |
|---|---|---|---|---|
| `projects` | ✓ | ✓ | — | Search project names and descriptions |
| `issues` | ✓ | ✓ | ✓ | Search issue titles and descriptions |
| `merge_requests` | ✓ | ✓ | ✓ | Search merge request titles and descriptions |
| `milestones` | ✓ | ✓ | ✓ | Search milestone titles and descriptions |
| `snippet_titles` | ✓ | — | ✓ | Search snippet titles |
| `wiki_blobs` | ✓ | — | ✓ | Search wiki content |
| `commits` | ✓ | — | ✓ | Search commit messages |
| `blobs` | ✓ | — | ✓ | Search file contents in repositories |
| `notes` | ✓ | ✓ | ✓ | Search comments and notes |
| `users` | ✓ | ✓ | ✓ | Search user names and usernames |

---

## Example: Searching Code in Blobs

Searching for code in the `blobs` scope returns file matches with repository content:

```
GET /projects/42/search?scope=blobs&search=def+initialize
```

Response:

```json
[
  {
    "basename": "config",
    "data": "class Config\n  def initialize\n    @settings = {}\n  end\nend",
    "path": "lib/config.rb",
    "filename": "lib/config.rb",
    "id": null,
    "ref": "main",
    "startline": 1,
    "project_id": 42
  }
]
```

Each blob result includes `path`, `data` (the matching content), `project_id`, `ref` (branch), and `startline`.

---

## Response Codes

| Code | Description |
|---|---|
| `200` | Success |
| `400` | Bad request (invalid scope or missing parameters) |
| `401` | Unauthorized |
| `403` | Forbidden |
| `404` | Not found |
