# Admin & System API Reference

GitLab REST API v4 reference for instance-level administration: metadata, feature flags, broadcast messages, system hooks, applications, namespaces, and settings.

**Base URL:** `https://gitlab.example.com/api/v4`

**Authentication:** Pass a `PRIVATE-TOKEN` header or `access_token` query parameter.

> **Note:** Most endpoints in this document require **administrator** access. Non-admin users will receive a `403 Forbidden` response.

---

## Metadata

### Get version

```
GET /version
```

Returns the version and revision of the GitLab instance.

| Parameter | Type | Required | Description |
|---|---|---|---|
| *(none)* | | | |

### Get metadata

```
GET /metadata
```

Returns metadata about the GitLab instance (version, revision, enterprise status).

| Parameter | Type | Required | Description |
|---|---|---|---|
| *(none)* | | | |

---

## Features (Feature Flags)

Admin-only endpoints for managing instance-level feature flags.

### List all features

```
GET /features
```

Returns a list of all persisted feature flags with their gate values.

| Parameter | Type | Required | Description |
|---|---|---|---|
| *(none)* | | | |

### Set or create a feature

```
POST /features/:name
```

Set the gate value for a feature flag. Creates the flag if it does not exist.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Name of the feature flag |
| `value` | string/boolean/integer | yes | `true`, `false`, or integer percentage of time |
| `key` | string | no | `percentage_of_actors` or `percentage_of_time` (when value is an integer) |
| `feature_group` | string | no | Flipper group name |
| `user` | string | no | GitLab username to enable for |
| `group` | string | no | GitLab group path to enable for |
| `namespace` | string | no | GitLab group or user namespace to enable for |
| `project` | string | no | Project path to enable for |
| `repository` | string | no | Project path (for gitaly actor type) |
| `force` | boolean | no | Skip feature flag validation checks |

### Delete a feature

```
DELETE /features/:name
```

Removes a feature flag gate. The flag returns to its default state.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Name of the feature flag |

---

## Broadcast Messages

Manage instance-wide broadcast banners and notifications.

### List broadcast messages

```
GET /broadcast_messages
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| *(none)* | | | |

### Get a broadcast message

```
GET /broadcast_messages/:id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer | yes | ID of the broadcast message |

### Create a broadcast message

```
POST /broadcast_messages
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `message` | string | yes | Message content (Markdown supported) |
| `starts_at` | datetime | no | Start time (ISO 8601, default: current time) |
| `ends_at` | datetime | no | End time (ISO 8601, default: one hour from `starts_at`) |
| `color` | string | no | Background color hex code (e.g., `#E75E40`) |
| `font` | string | no | Foreground color hex code (e.g., `#FFFFFF`) |
| `target_access_levels` | array[integer] | no | Access levels to target |
| `target_path` | string | no | Path matching pattern for targeting |
| `broadcast_type` | string | no | `banner` (default) or `notification` |
| `dismissable` | boolean | no | Whether the message can be dismissed |

### Update a broadcast message

```
PUT /broadcast_messages/:id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer | yes | ID of the broadcast message |
| `message` | string | no | Updated message content |
| `starts_at` | datetime | no | Updated start time |
| `ends_at` | datetime | no | Updated end time |
| `color` | string | no | Updated background color |
| `font` | string | no | Updated foreground color |
| `target_access_levels` | array[integer] | no | Updated access levels |
| `target_path` | string | no | Updated path pattern |
| `broadcast_type` | string | no | Updated type: `banner` or `notification` |
| `dismissable` | boolean | no | Updated dismissable flag |

### Delete a broadcast message

```
DELETE /broadcast_messages/:id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer | yes | ID of the broadcast message |

---

## System Hooks

Admin-only endpoints for managing system-wide webhooks.

### List system hooks

```
GET /hooks
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| *(none)* | | | |

### Add system hook

```
POST /hooks
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `url` | string | yes | Hook URL |
| `token` | string | no | Secret token to validate payloads |
| `push_events` | boolean | no | Trigger on push events (default: `true`) |
| `tag_push_events` | boolean | no | Trigger on tag push events (default: `false`) |
| `merge_requests_events` | boolean | no | Trigger on merge request events (default: `false`) |
| `repository_update_events` | boolean | no | Trigger on repository update events (default: `true`) |
| `enable_ssl_verification` | boolean | no | Enable SSL verification (default: `true`) |

### Get system hook

```
GET /hooks/:id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer | yes | ID of the system hook |

### Test system hook

```
POST /hooks/:id
```

Triggers a test event for the specified system hook. Returns `200` with event data on success.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer | yes | ID of the system hook |

### Delete system hook

```
DELETE /hooks/:id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer | yes | ID of the system hook |

---

## Applications (OAuth)

Manage instance-level OAuth applications.

### List all applications

```
GET /applications
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| *(none)* | | | |

### Create an application

```
POST /applications
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Name of the application |
| `redirect_uri` | string | yes | Redirect URI (one per line for multiple) |
| `scopes` | string | yes | Space-separated list of scopes (e.g., `api read_user`) |
| `confidential` | boolean | no | Whether the app is confidential (default: `true`) |

### Delete an application

```
DELETE /applications/:id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer | yes | ID of the application |

---

## Namespaces

### List namespaces

```
GET /namespaces
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `search` | string | no | Filter by name or path |
| `owned_only` | boolean | no | Only return namespaces owned by the current user |
| `per_page` | integer | no | Number of results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

### Get namespace by ID

```
GET /namespaces/:id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Namespace ID or URL-encoded path |

### Search namespaces

```
GET /namespaces?search=term
```

Equivalent to listing with the `search` parameter. Returns namespaces matching the given term by name or path.

---

## Application Settings

Admin-only endpoints for managing instance-wide application settings.

### Get current settings

```
GET /application/settings
```

Returns the current application settings for the GitLab instance.

| Parameter | Type | Required | Description |
|---|---|---|---|
| *(none)* | | | |

### Update settings

```
PUT /application/settings
```

Modify one or more application settings. Only include the settings you want to change.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `default_branch_protection` | integer | no | Branch protection level (0=none, 1=partial, 2=full) |
| `default_project_visibility` | string | no | `private`, `internal`, or `public` |
| `default_group_visibility` | string | no | `private`, `internal`, or `public` |
| `restricted_visibility_levels` | array[string] | no | Visibility levels to restrict |
| `signup_enabled` | boolean | no | Enable user sign-up |
| `require_admin_approval_after_user_signup` | boolean | no | Require admin approval for new sign-ups |
| `user_default_external` | boolean | no | New users are external by default |
| `max_attachment_size` | integer | no | Max attachment size in MB |
| `session_expire_delay` | integer | no | Session expiry in minutes |
| `home_page_url` | string | no | Custom home page URL |
| `after_sign_out_path` | string | no | Redirect path after sign-out |
| `password_authentication_enabled_for_web` | boolean | no | Allow password auth for web |
| `password_authentication_enabled_for_git` | boolean | no | Allow password auth for Git |

> Refer to the [GitLab docs](https://docs.gitlab.com/api/settings/) for the full list of available settings.

---

## Response Codes

| Code | Description |
|---|---|
| `200` | Success (GET, PUT) |
| `201` | Created (POST) |
| `204` | No Content (DELETE) |
| `400` | Bad request |
| `401` | Unauthorized |
| `403` | Forbidden (admin access required) |
| `404` | Not found |
