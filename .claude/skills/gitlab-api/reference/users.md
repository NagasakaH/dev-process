# Users API Reference

GitLab REST API v4 endpoints for managing users, members, access requests, access tokens, and SSH keys.

---

## Users

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/users` | List all users (filterable) |
| `GET` | `/users/:id` | Get a single user by ID |
| `GET` | `/user` | Get the currently authenticated user |
| `POST` | `/users` | Create a user *(admin only)* |
| `PUT` | `/users/:id` | Modify a user *(admin only)* |
| `DELETE` | `/users/:id` | Delete a user *(admin only)* |
| `GET` | `/users/:id/status` | Get the status of a user |
| `PUT` | `/user/status` | Set status of the current user |

### List Users

```
GET /users
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `search` | string | no | Search by name, username, or email |
| `username` | string | no | Filter by exact username |
| `active` | boolean | no | Filter by active state |
| `blocked` | boolean | no | Filter by blocked state |
| `external` | boolean | no | Filter by external users |
| `order_by` | string | no | Order by `id`, `name`, `username`, `created_at`, or `updated_at` |
| `sort` | string | no | Sort order: `asc` or `desc` |

### Get Single User

```
GET /users/:id
```

### Get Current User

```
GET /user
```

Returns the authenticated user. Requires authentication.

### Create User (Admin)

```
POST /users
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `email` | string | yes | Email address |
| `name` | string | yes | Full name |
| `username` | string | yes | Username |
| `password` | string | yes* | Password (*or `reset_password`) |
| `reset_password` | boolean | no | Send password reset link |
| `admin` | boolean | no | Set user as admin |
| `can_create_group` | boolean | no | Allow group creation |
| `skip_confirmation` | boolean | no | Skip email confirmation |

### Modify User (Admin)

```
PUT /users/:id
```

Accepts the same parameters as Create User.

### Delete User (Admin)

```
DELETE /users/:id
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `hard_delete` | boolean | no | Permanently remove the user and their contributions |

### User Status

```
GET /users/:id/status
```

### Set User Status

```
PUT /user/status
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `emoji` | string | no | Emoji name (e.g., `coffee`) |
| `message` | string | no | Status message (max 100 characters) |
| `clear_status_after` | string | no | Auto-clear: `30_minutes`, `3_hours`, `8_hours`, `1_day`, `3_days`, `7_days`, `30_days` |

---

## Members

Manage members of projects and groups.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/projects/:id/members` | List project members |
| `GET` | `/groups/:id/members` | List group members |
| `GET` | `/projects/:id/members/:user_id` | Get a project member |
| `GET` | `/groups/:id/members/:user_id` | Get a group member |
| `POST` | `/projects/:id/members` | Add a project member |
| `POST` | `/groups/:id/members` | Add a group member |
| `PUT` | `/projects/:id/members/:user_id` | Edit a project member |
| `PUT` | `/groups/:id/members/:user_id` | Edit a group member |
| `DELETE` | `/projects/:id/members/:user_id` | Remove a project member |
| `DELETE` | `/groups/:id/members/:user_id` | Remove a group member |

### List Project Members

```
GET /projects/:id/members
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | string | no | Search by name or username |

### List Group Members

```
GET /groups/:id/members
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | string | no | Search by name or username |

### Add Member

```
POST /projects/:id/members
POST /groups/:id/members
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `user_id` | integer | yes | User ID to add |
| `access_level` | integer | yes | Access level (see reference below) |
| `expires_at` | string | no | Expiration date (`YYYY-MM-DD`) |

### Edit Member

```
PUT /projects/:id/members/:user_id
PUT /groups/:id/members/:user_id
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `access_level` | integer | yes | New access level |
| `expires_at` | string | no | New expiration date |

### Remove Member

```
DELETE /projects/:id/members/:user_id
DELETE /groups/:id/members/:user_id
```

---

## Access Requests

Manage access requests for projects and groups.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/projects/:id/access_requests` | List access requests for a project |
| `GET` | `/groups/:id/access_requests` | List access requests for a group |
| `POST` | `/projects/:id/access_requests` | Request access to a project |
| `POST` | `/groups/:id/access_requests` | Request access to a group |
| `PUT` | `/projects/:id/access_requests/:user_id/approve` | Approve a project access request |
| `PUT` | `/groups/:id/access_requests/:user_id/approve` | Approve a group access request |
| `DELETE` | `/projects/:id/access_requests/:user_id` | Deny a project access request |
| `DELETE` | `/groups/:id/access_requests/:user_id` | Deny a group access request |

### List Access Requests

```
GET /projects/:id/access_requests
GET /groups/:id/access_requests
```

### Request Access

```
POST /projects/:id/access_requests
POST /groups/:id/access_requests
```

### Approve Access Request

```
PUT /projects/:id/access_requests/:user_id/approve
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `access_level` | integer | no | Access level to grant (default: 30/Developer) |

### Deny Access Request

```
DELETE /projects/:id/access_requests/:user_id
```

---

## Access Tokens

Manage project access tokens.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/projects/:id/access_tokens` | List project access tokens |
| `POST` | `/projects/:id/access_tokens` | Create a project access token |
| `DELETE` | `/projects/:id/access_tokens/:token_id` | Revoke a project access token |

### List Project Access Tokens

```
GET /projects/:id/access_tokens
```

### Create Project Access Token

```
POST /projects/:id/access_tokens
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | string | yes | Token name |
| `scopes` | array | yes | Scopes: `api`, `read_api`, `read_repository`, `write_repository`, `read_registry`, `write_registry` |
| `access_level` | integer | no | Access level (default: 40/Maintainer) |
| `expires_at` | string | yes | Expiration date (`YYYY-MM-DD`) |

### Revoke Project Access Token

```
DELETE /projects/:id/access_tokens/:token_id
```

---

## SSH Keys

Manage SSH keys for the authenticated user.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/user/keys` | List SSH keys of the current user |
| `GET` | `/user/keys/:key_id` | Get a single SSH key |
| `POST` | `/user/keys` | Add an SSH key |
| `DELETE` | `/user/keys/:key_id` | Delete an SSH key |

### List SSH Keys

```
GET /user/keys
```

### Get SSH Key

```
GET /user/keys/:key_id
```

### Add SSH Key

```
POST /user/keys
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `title` | string | yes | Key title |
| `key` | string | yes | Public SSH key |
| `expires_at` | string | no | Expiration date (`YYYY-MM-DD`) |
| `usage_type` | string | no | `auth`, `signing`, or `auth_and_signing` |

### Delete SSH Key

```
DELETE /user/keys/:key_id
```

---

## Access Levels Reference

| Value | Role |
|-------|------|
| 10 | Guest |
| 20 | Reporter |
| 30 | Developer |
| 40 | Maintainer |
| 50 | Owner |
