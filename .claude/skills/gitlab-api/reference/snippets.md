# Snippets API Reference

GitLab REST API v4 reference for personal and project snippets.

**Base URL:** `https://gitlab.example.com/api/v4`

**Authentication:** Pass a `PRIVATE-TOKEN` header or `access_token` query parameter.

---

## Personal Snippets

### List authenticated user's snippets

```
GET /snippets
```

Returns a list of snippets owned by the authenticated user.

| Parameter | Type | Description |
|---|---|---|
| `per_page` | integer | Results per page (default: 20, max: 100) |
| `page` | integer | Page number (default: 1) |

### List public snippets

```
GET /snippets/public
```

Returns a list of all public snippets.

| Parameter | Type | Description |
|---|---|---|
| `per_page` | integer | Results per page (default: 20, max: 100) |
| `page` | integer | Page number (default: 1) |

### Get a single snippet

```
GET /snippets/:id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer | yes | ID of the snippet |

### Get raw snippet content

```
GET /snippets/:id/raw
```

Returns the raw file content of the snippet.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer | yes | ID of the snippet |

### Create a snippet

```
POST /snippets
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `title` | string | yes | Title of the snippet |
| `file_name` | string | yes | Name of the snippet file |
| `content` | string | yes | Content of the snippet |
| `visibility` | string | yes | `private`, `internal`, or `public` |
| `description` | string | no | Description of the snippet |
| `files` | array | no | Array of file objects for multi-file snippets (see below) |

### Update a snippet

```
PUT /snippets/:id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer | yes | ID of the snippet |
| `title` | string | no | Updated title |
| `file_name` | string | no | Updated file name |
| `content` | string | no | Updated content |
| `visibility` | string | no | Updated visibility: `private`, `internal`, or `public` |
| `description` | string | no | Updated description |

### Delete a snippet

```
DELETE /snippets/:id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer | yes | ID of the snippet |

---

## Project Snippets

### List project snippets

```
GET /projects/:id/snippets
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `per_page` | integer | no | Results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

### Get a single project snippet

```
GET /projects/:id/snippets/:snippet_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `snippet_id` | integer | yes | ID of the project snippet |

### Get raw project snippet content

```
GET /projects/:id/snippets/:snippet_id/raw
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `snippet_id` | integer | yes | ID of the project snippet |

### Create a project snippet

```
POST /projects/:id/snippets
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `title` | string | yes | Title of the snippet |
| `file_name` | string | yes | Name of the snippet file |
| `content` | string | yes | Content of the snippet |
| `visibility` | string | yes | `private`, `internal`, or `public` |
| `description` | string | no | Description of the snippet |

### Update a project snippet

```
PUT /projects/:id/snippets/:snippet_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `snippet_id` | integer | yes | ID of the project snippet |
| `title` | string | no | Updated title |
| `file_name` | string | no | Updated file name |
| `content` | string | no | Updated content |
| `visibility` | string | no | Updated visibility |
| `description` | string | no | Updated description |

### Delete a project snippet

```
DELETE /projects/:id/snippets/:snippet_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `snippet_id` | integer | yes | ID of the project snippet |

---

## Multi-File Snippets

Snippets support multiple files via the `files` attribute. When creating or updating a snippet with multiple files, use an array of file objects instead of `file_name` and `content`:

```json
{
  "title": "My multi-file snippet",
  "visibility": "public",
  "files": [
    {
      "file_path": "script.sh",
      "content": "#!/bin/bash\necho hello"
    },
    {
      "file_path": "README.md",
      "content": "# Example\nA multi-file snippet."
    }
  ]
}
```

Each file object in the `files` array has:

| Field | Type | Description |
|---|---|---|
| `file_path` | string | Path/name of the file within the snippet |
| `content` | string | Content of the file |
| `action` | string | For updates: `create`, `update`, `delete`, or `move` |
| `previous_path` | string | For `move` action: the previous file path |

---

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
