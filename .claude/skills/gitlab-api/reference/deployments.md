# Deployments, Environments & Releases API Reference

GitLab REST API v4 reference for deployments, environments, releases, deploy keys, and deploy tokens.

**Base URL:** `https://gitlab.example.com/api/v4`

**Authentication:** Pass a `PRIVATE-TOKEN` header or `access_token` query parameter.

---

## Deployments

### List project deployments

```
GET /projects/:id/deployments
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `order_by` | string | no | `id`, `iid`, `created_at`, `updated_at`, or `ref` (default: `id`) |
| `sort` | string | no | `asc` or `desc` (default: `asc`) |
| `updated_after` | datetime | no | Return deployments updated after the specified date |
| `updated_before` | datetime | no | Return deployments updated before the specified date |
| `environment` | string | no | Name of the environment to filter by |
| `status` | string | no | `created`, `running`, `success`, `failed`, or `canceled` |
| `per_page` | integer | no | Number of results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

### Get a specific deployment

```
GET /projects/:id/deployments/:deployment_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `deployment_id` | integer | yes | ID of the deployment |

### Create a deployment

```
POST /projects/:id/deployments
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `environment` | string | yes | Name of the environment to deploy to |
| `sha` | string | yes | SHA of the commit being deployed |
| `ref` | string | yes | Name of the branch or tag being deployed |
| `tag` | boolean | yes | Whether the ref is a tag (`true`) or branch (`false`) |
| `status` | string | yes | `created`, `running`, `success`, `failed`, or `canceled` |

### Update a deployment

```
PUT /projects/:id/deployments/:deployment_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `deployment_id` | integer | yes | ID of the deployment |
| `status` | string | yes | New status: `created`, `running`, `success`, `failed`, or `canceled` |

---

## Environments

### List environments

```
GET /projects/:id/environments
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `name` | string | no | Return the environment with this name (exact match) |
| `search` | string | no | Return environments matching the search criteria |
| `states` | string | no | Filter by state: `available` or `stopped` |
| `per_page` | integer | no | Number of results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

### Get a specific environment

```
GET /projects/:id/environments/:environment_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `environment_id` | integer | yes | ID of the environment |

### Create an environment

```
POST /projects/:id/environments
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `name` | string | yes | Name of the environment |
| `external_url` | string | no | URL pointing to the environment |

### Edit an environment

```
PUT /projects/:id/environments/:environment_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `environment_id` | integer | yes | ID of the environment |
| `name` | string | no | Updated name of the environment |
| `external_url` | string | no | Updated external URL |

### Delete an environment

```
DELETE /projects/:id/environments/:environment_id
```

The environment must be stopped before it can be deleted.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `environment_id` | integer | yes | ID of the environment |

### Stop an environment

```
POST /projects/:id/environments/:environment_id/stop
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `environment_id` | integer | yes | ID of the environment |

---

## Releases

### List releases

```
GET /projects/:id/releases
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `order_by` | string | no | `released_at` or `created_at` (default: `released_at`) |
| `sort` | string | no | `asc` or `desc` (default: `desc`) |
| `per_page` | integer | no | Number of results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

### Get a release by tag name

```
GET /projects/:id/releases/:tag_name
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `tag_name` | string | yes | Git tag the release is associated with |

### Create a release

```
POST /projects/:id/releases
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `tag_name` | string | yes | Tag where the release is created from |
| `name` | string | no | Release name |
| `description` | string | no | Description (release notes, Markdown supported) |
| `ref` | string | no | Commit SHA, branch, or tag if the tag doesn't exist |
| `milestones` | array[string] | no | Milestone titles to associate |
| `released_at` | datetime | no | Date of the release (default: current time) |

### Update a release

```
PUT /projects/:id/releases/:tag_name
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `tag_name` | string | yes | Tag associated with the release |
| `name` | string | no | Updated release name |
| `description` | string | no | Updated description |
| `milestones` | array[string] | no | Updated milestone titles |
| `released_at` | datetime | no | Updated release date |

### Delete a release

```
DELETE /projects/:id/releases/:tag_name
```

Deletes the release. Does not delete the associated tag.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `tag_name` | string | yes | Tag associated with the release |

---

## Release Links

### List links of a release

```
GET /projects/:id/releases/:tag_name/assets/links
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `tag_name` | string | yes | Tag associated with the release |

### Create a release link

```
POST /projects/:id/releases/:tag_name/assets/links
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `tag_name` | string | yes | Tag associated with the release |
| `name` | string | yes | Name of the link |
| `url` | string | yes | URL of the link |
| `link_type` | string | no | `other` (default), `runbook`, `image`, or `package` |

---

## Deploy Keys

### List deploy keys

```
GET /projects/:id/deploy_keys
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `per_page` | integer | no | Number of results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

### Get a single deploy key

```
GET /projects/:id/deploy_keys/:key_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `key_id` | integer | yes | ID of the deploy key |

### Add a deploy key

```
POST /projects/:id/deploy_keys
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `title` | string | yes | Title of the deploy key |
| `key` | string | yes | New deploy key (public SSH key) |
| `can_push` | boolean | no | Whether the key has push access (default: `false`) |

### Delete a deploy key

```
DELETE /projects/:id/deploy_keys/:key_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `key_id` | integer | yes | ID of the deploy key |

### Enable a deploy key

```
POST /projects/:id/deploy_keys/:key_id/enable
```

Enables a deploy key for a project so it can be used. The key must already exist.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `key_id` | integer | yes | ID of the deploy key |

---

## Deploy Tokens

### List project deploy tokens

```
GET /projects/:id/deploy_tokens
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `per_page` | integer | no | Number of results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

### Create a project deploy token

```
POST /projects/:id/deploy_tokens
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `name` | string | yes | Name of the deploy token |
| `scopes` | array[string] | yes | Scopes: `read_repository`, `read_registry`, `write_registry`, `read_package_registry`, `write_package_registry` |
| `expires_at` | datetime | no | Expiration date in ISO 8601 format |
| `username` | string | no | Username for the deploy token (default: `gitlab+deploy-token-{n}`) |

### Delete a project deploy token

```
DELETE /projects/:id/deploy_tokens/:token_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `token_id` | integer | yes | ID of the deploy token |

---

## Common Parameters

These query parameters are shared across most list endpoints:

| Parameter | Type | Description |
|---|---|---|
| `order_by` | string | Field to order results by |
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
| `409` | Conflict |
