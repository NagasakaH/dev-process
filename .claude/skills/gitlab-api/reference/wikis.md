# Wikis API Reference

GitLab REST API v4 reference for project and group wiki pages.

**Base URL:** `https://gitlab.example.com/api/v4`

**Authentication:** Pass a `PRIVATE-TOKEN` header or `access_token` query parameter.

---

## Project Wikis

### List wiki pages

```
GET /projects/:id/wikis
```

Returns a list of all wiki pages for the given project.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `with_content` | boolean | no | Include page content in the response (default: `false`) |

### Get a wiki page

```
GET /projects/:id/wikis/:slug
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `slug` | string | yes | URL-encoded slug of the wiki page (e.g., `getting-started`) |
| `render_html` | boolean | no | Return the rendered HTML of the page content |
| `version` | string | no | Wiki page version SHA to retrieve |

### Create a wiki page

```
POST /projects/:id/wikis
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `title` | string | yes | Title of the wiki page |
| `content` | string | yes | Content of the wiki page |
| `format` | string | no | Content format: `markdown` (default), `rdoc`, `asciidoc`, or `org` |

### Edit a wiki page

```
PUT /projects/:id/wikis/:slug
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `slug` | string | yes | URL-encoded slug of the wiki page |
| `title` | string | no | New title of the wiki page |
| `content` | string | no | New content of the wiki page |
| `format` | string | no | Content format: `markdown`, `rdoc`, `asciidoc`, or `org` |

### Delete a wiki page

```
DELETE /projects/:id/wikis/:slug
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `slug` | string | yes | URL-encoded slug of the wiki page |

### Upload an attachment

```
POST /projects/:id/wikis/attachments
```

Uploads a file to the wiki repository. The response includes a `link` object with the URL to embed in wiki pages.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `file` | file | yes | Attachment to be uploaded (multipart form data) |
| `branch` | string | no | Branch name (default: wiki default branch) |

---

## Group Wikis

Group wikis use the same endpoints and parameters as project wikis, but under the `/groups/:id/wikis` path:

### List group wiki pages

```
GET /groups/:id/wikis
```

### Get a group wiki page

```
GET /groups/:id/wikis/:slug
```

### Create a group wiki page

```
POST /groups/:id/wikis
```

### Edit a group wiki page

```
PUT /groups/:id/wikis/:slug
```

### Delete a group wiki page

```
DELETE /groups/:id/wikis/:slug
```

### Upload attachment to group wiki

```
POST /groups/:id/wikis/attachments
```

All parameters are identical to the project wiki endpoints above, with `id` referring to the group ID or URL-encoded path.

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
