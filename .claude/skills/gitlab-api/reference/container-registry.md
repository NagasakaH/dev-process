# Container Registry API Reference

GitLab REST API v4 reference for container registry repositories and tags.

**Base URL:** `https://gitlab.example.com/api/v4`

**Authentication:** Pass a `PRIVATE-TOKEN` header or `access_token` query parameter.

---

## Registry Repositories

### List registry repositories

```
GET /projects/:id/registry/repositories
```

Returns a list of registry repositories in a project.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `tags` | boolean | no | If `true`, include tags in the response |
| `tags_count` | boolean | no | If `true`, include tags count in the response |
| `per_page` | integer | no | Number of results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

### Get repository details

```
GET /registry/repositories/:repository_id
```

Returns details of a single registry repository (accessible by any authenticated user with the right permissions, regardless of project).

| Parameter | Type | Required | Description |
|---|---|---|---|
| `repository_id` | integer | yes | ID of the registry repository |
| `tags` | boolean | no | If `true`, include tags in the response |
| `tags_count` | boolean | no | If `true`, include tags count in the response |
| `size` | boolean | no | If `true`, include size in the response (may be slow) |

### Delete repository

```
DELETE /projects/:id/registry/repositories/:repository_id
```

Deletes a repository from the registry. This deletes all tags within the repository.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `repository_id` | integer | yes | ID of the registry repository |

---

## Registry Tags

### List repository tags

```
GET /projects/:id/registry/repositories/:repository_id/tags
```

Returns a list of tags for a given registry repository.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `repository_id` | integer | yes | ID of the registry repository |
| `per_page` | integer | no | Number of results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

### Get tag details

```
GET /projects/:id/registry/repositories/:repository_id/tags/:tag_name
```

Returns details of a specific registry repository tag.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `repository_id` | integer | yes | ID of the registry repository |
| `tag_name` | string | yes | Name of the tag |

### Delete tag

```
DELETE /projects/:id/registry/repositories/:repository_id/tags/:tag_name
```

Deletes a registry repository tag.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `repository_id` | integer | yes | ID of the registry repository |
| `tag_name` | string | yes | Name of the tag |

### Bulk delete tags

```
DELETE /projects/:id/registry/repositories/:repository_id/tags
```

Deletes registry repository tags in bulk based on given criteria.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `repository_id` | integer | yes | ID of the registry repository |
| `name_regex` | string | no | Regex pattern of tags to delete (e.g., `.*` to delete all, `v1\\..*` for v1 tags). **Deprecated:** use `name_regex_delete` instead. |
| `name_regex_delete` | string | yes | Regex pattern of tags to delete (e.g., `.*`) |
| `name_regex_keep` | string | no | Regex pattern of tags to keep (overrides `name_regex_delete`) |
| `keep_n` | integer | no | Number of most recent tags to keep (per image name) |
| `older_than` | string | no | Delete tags older than this value (e.g., `7d`, `1month`, `2h`) |

---

## Group-Level Container Repositories

### List group registry repositories

```
GET /groups/:id/registry/repositories
```

Returns a list of registry repositories within a group.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Group ID or URL-encoded path |
| `tags` | boolean | no | If `true`, include tags in the response |
| `tags_count` | boolean | no | If `true`, include tags count in the response |
| `per_page` | integer | no | Number of results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

---

## Response Codes

| Code | Description |
|---|---|
| `200` | Success (GET, PUT) |
| `202` | Accepted (bulk delete scheduled) |
| `204` | No Content (DELETE) |
| `400` | Bad request (e.g., invalid regex) |
| `401` | Unauthorized |
| `403` | Forbidden |
| `404` | Not found |
