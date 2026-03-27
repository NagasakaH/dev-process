# Groups API Reference

GitLab REST API v4 reference for groups, subgroups, and group-level operations.

**Base URL:** `https://gitlab.example.com/api/v4`

**Authentication:** Pass a `PRIVATE-TOKEN` header or `access_token` query parameter.

> **Note:** The `:id` parameter can be the group ID (integer) or the URL-encoded group path (e.g., `my-group%2Fmy-subgroup`).

---

## Groups

### List groups

```
GET /groups
```

Returns a list of visible groups for the authenticated user. Administrators see all groups.

| Parameter | Type | Description |
|---|---|---|
| `skip_groups` | array[integer] | IDs of groups to exclude |
| `all_available` | boolean | Show all groups accessible to the current user (default: `false`) |
| `search` | string | Search against group name or path |
| `order_by` | string | `name`, `path`, `id`, or `similarity` (default: `name`) |
| `sort` | string | `asc` or `desc` (default: `asc`) |
| `statistics` | boolean | Include group statistics (default: `false`) |
| `with_custom_attributes` | boolean | Include custom attributes (admin only) |
| `owned` | boolean | Limit to groups explicitly owned by the current user |
| `min_access_level` | integer | Limit to groups where the user has at least this access level |
| `top_level_only` | boolean | Limit to top-level groups only (default: `false`) |
| `per_page` | integer | Number of results per page (default: 20, max: 100) |
| `page` | integer | Page number (default: 1) |

### List subgroups

```
GET /groups/:id/subgroups
```

Returns a list of direct subgroups of a group.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Group ID or URL-encoded path |
| `skip_groups` | array[integer] | no | IDs of groups to exclude |
| `all_available` | boolean | no | Show all groups accessible to the current user |
| `search` | string | no | Search against group name or path |
| `order_by` | string | no | `name`, `path`, `id`, or `similarity` (default: `name`) |
| `sort` | string | no | `asc` or `desc` (default: `asc`) |
| `statistics` | boolean | no | Include group statistics |
| `owned` | boolean | no | Limit to explicitly owned groups |
| `min_access_level` | integer | no | Minimum access level filter |
| `per_page` | integer | no | Number of results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

### List descendant groups

```
GET /groups/:id/descendant_groups
```

Returns a list of all descendant groups (subgroups at any depth) of a group.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Group ID or URL-encoded path |
| `skip_groups` | array[integer] | no | IDs of groups to exclude |
| `all_available` | boolean | no | Show all groups accessible to the current user |
| `search` | string | no | Search against group name or path |
| `order_by` | string | no | `name`, `path`, `id`, or `similarity` (default: `name`) |
| `sort` | string | no | `asc` or `desc` (default: `asc`) |
| `statistics` | boolean | no | Include group statistics |
| `owned` | boolean | no | Limit to explicitly owned groups |
| `min_access_level` | integer | no | Minimum access level filter |
| `per_page` | integer | no | Number of results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

### Get single group

```
GET /groups/:id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Group ID or URL-encoded path |
| `with_custom_attributes` | boolean | no | Include custom attributes (admin only) |
| `with_projects` | boolean | no | Include details of projects in the group (default: `true`) |
| `statistics` | boolean | no | Include group statistics |

### Create group

```
POST /groups
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Name of the group |
| `path` | string | yes | URL-friendly path for the group |
| `description` | string | no | Description of the group |
| `visibility` | string | no | `private`, `internal`, or `public` (default: `private`) |
| `parent_id` | integer | no | ID of the parent group for creating a subgroup |
| `membership_lock` | boolean | no | Prevent adding members directly to projects in this group |
| `share_with_group_lock` | boolean | no | Prevent sharing projects in this group with other groups |
| `require_two_factor_authentication` | boolean | no | Require 2FA for all group members |
| `two_factor_grace_period` | integer | no | Hours before 2FA is enforced |
| `project_creation_level` | string | no | `noone`, `maintainer`, or `developer` |
| `subgroup_creation_level` | string | no | `owner` or `maintainer` |
| `default_branch_protection` | integer | no | 0 (no protection), 1 (partial), 2 (full), 3 (full with push access) |
| `request_access_enabled` | boolean | no | Allow users to request access (default: `true`) |
| `lfs_enabled` | boolean | no | Enable Git LFS for group projects |

### Update group

```
PUT /groups/:id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Group ID or URL-encoded path |
| `name` | string | no | Updated name of the group |
| `path` | string | no | Updated path of the group |
| `description` | string | no | Updated description |
| `visibility` | string | no | `private`, `internal`, or `public` |
| `membership_lock` | boolean | no | Prevent adding members directly to projects |
| `share_with_group_lock` | boolean | no | Prevent sharing projects with other groups |
| `require_two_factor_authentication` | boolean | no | Require 2FA for all group members |
| `project_creation_level` | string | no | `noone`, `maintainer`, or `developer` |
| `subgroup_creation_level` | string | no | `owner` or `maintainer` |
| `default_branch_protection` | integer | no | 0, 1, 2, or 3 |
| `request_access_enabled` | boolean | no | Allow users to request access |
| `lfs_enabled` | boolean | no | Enable Git LFS for group projects |

### Delete group

```
DELETE /groups/:id
```

Schedules the group and all associated resources (projects, subgroups) for deletion. Actual deletion occurs after a configured delay (default: 7 days on premium tiers, immediate on free tier).

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Group ID or URL-encoded path |
| `permanently_remove` | boolean | no | Immediately delete the group (admin only) |
| `full_path` | string | no | Full path of the group to confirm permanent removal |

---

## Group Projects

### List group projects

```
GET /groups/:id/projects
```

Returns a list of projects belonging to the group.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Group ID or URL-encoded path |
| `archived` | boolean | no | Filter by archived status |
| `visibility` | string | no | Filter by `public`, `internal`, or `private` |
| `order_by` | string | no | `id`, `name`, `path`, `created_at`, `updated_at`, `last_activity_at`, or `similarity` |
| `sort` | string | no | `asc` or `desc` (default: `desc`) |
| `search` | string | no | Search against project name |
| `simple` | boolean | no | Return limited fields only |
| `owned` | boolean | no | Limit to projects owned by the current user |
| `starred` | boolean | no | Limit to projects starred by the current user |
| `with_issues_enabled` | boolean | no | Limit to projects with issues enabled |
| `with_merge_requests_enabled` | boolean | no | Limit to projects with merge requests enabled |
| `with_shared` | boolean | no | Include projects shared with the group (default: `true`) |
| `include_subgroups` | boolean | no | Include projects in subgroups (default: `false`) |
| `min_access_level` | integer | no | Minimum access level filter |
| `per_page` | integer | no | Number of results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

---

## Group Sharing

### Share group with group

```
POST /groups/:id/share
```

Share a group with another group so that all members of the shared-with group gain access.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Group ID or URL-encoded path of the group to share |
| `group_id` | integer | yes | ID of the group to share with |
| `group_access` | integer | yes | Access level to grant (10=Guest, 20=Reporter, 30=Developer, 40=Maintainer) |
| `expires_at` | string | no | Expiry date in ISO 8601 format (`YYYY-MM-DD`) |

### Unshare group from group

```
DELETE /groups/:id/share/:share_group_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Group ID or URL-encoded path |
| `share_group_id` | integer | yes | ID of the shared group to remove |

---

## Transfer Project to Group

### Transfer project

```
POST /groups/:id/projects/:project_id
```

Transfer a project to a group namespace.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Group ID or URL-encoded path |
| `project_id` | integer/string | yes | Project ID or URL-encoded path |

---

## Common Parameters

These query parameters are shared across most list endpoints:

| Parameter | Type | Description |
|---|---|---|
| `search` | string | Search against group name or path |
| `order_by` | string | Field to order by (varies by endpoint) |
| `sort` | string | Sort direction: `asc` or `desc` |
| `statistics` | boolean | Include group statistics |
| `with_projects` | boolean | Include project details (default: `true`) |
| `per_page` | integer | Results per page (default: 20, max: 100) |
| `page` | integer | Page number for pagination |

## Response Codes

| Code | Description |
|---|---|
| `200` | Success (GET, PUT) |
| `201` | Created (POST) |
| `202` | Accepted (DELETE – scheduled for deletion) |
| `204` | No Content (DELETE – immediately removed) |
| `400` | Bad request |
| `401` | Unauthorized |
| `403` | Forbidden |
| `404` | Not found |
| `409` | Conflict (e.g., path already taken) |
