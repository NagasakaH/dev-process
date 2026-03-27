# Repositories API Reference

GitLab REST API v4 endpoints for managing repository content: files, branches, tags, and commits.

**Base URL:** `GITLAB_URL/api/v4`

**Authentication:** `PRIVATE-TOKEN: <token>` header

---

## Repository

### List repository tree

```
GET /projects/:id/repository/tree
```

| Parameter   | Type    | Required | Description                              |
|-------------|---------|----------|------------------------------------------|
| `id`        | string  | Yes      | Project ID or URL-encoded path           |
| `path`      | string  | No       | Path inside the repository               |
| `ref`       | string  | No       | Branch, tag, or commit SHA (default: default branch) |
| `recursive` | boolean | No       | List files recursively                   |
| `per_page`  | integer | No       | Results per page (default 20, max 100)   |
| `page`      | integer | No       | Page number                              |

**Response:** Array of tree entries with `id`, `name`, `type` (blob/tree), `path`, `mode`.

### Compare branches, tags, or commits

```
GET /projects/:id/repository/compare
```

| Parameter  | Type   | Required | Description                    |
|------------|--------|----------|--------------------------------|
| `id`       | string | Yes      | Project ID or URL-encoded path |
| `from`     | string | Yes      | Branch, tag, or commit SHA     |
| `to`       | string | Yes      | Branch, tag, or commit SHA     |
| `straight` | boolean| No       | Use straight comparison        |

**Response:** Object with `commit`, `commits`, `diffs`, `compare_timeout`, `compare_same_ref`.

---

## Repository Files

### Get file from repository

```
GET /projects/:id/repository/files/:file_path
```

| Parameter   | Type   | Required | Description                                |
|-------------|--------|----------|--------------------------------------------|
| `id`        | string | Yes      | Project ID or URL-encoded path             |
| `file_path` | string | Yes      | URL-encoded full path to file (e.g. `lib%2Fclass%2Erb`) |
| `ref`       | string | Yes      | Branch, tag, or commit SHA                 |

**Response:** Object with `file_name`, `file_path`, `size`, `encoding`, `content` (Base64), `content_sha256`, `ref`, `blob_id`, `commit_id`, `last_commit_id`.

### Get raw file from repository

```
GET /projects/:id/repository/files/:file_path/raw
```

| Parameter   | Type   | Required | Description                    |
|-------------|--------|----------|--------------------------------|
| `id`        | string | Yes      | Project ID or URL-encoded path |
| `file_path` | string | Yes      | URL-encoded full path to file  |
| `ref`       | string | No       | Branch, tag, or commit SHA     |

**Response:** Raw file content (not JSON).

### Create new file in repository

```
POST /projects/:id/repository/files/:file_path
```

| Parameter        | Type   | Required | Description                    |
|------------------|--------|----------|--------------------------------|
| `id`             | string | Yes      | Project ID or URL-encoded path |
| `file_path`      | string | Yes      | URL-encoded full path to file  |
| `branch`         | string | Yes      | Target branch name             |
| `content`        | string | Yes      | File content                   |
| `commit_message` | string | Yes      | Commit message                 |
| `encoding`       | string | No       | `text` or `base64` (default: `text`) |
| `author_email`   | string | No       | Commit author email            |
| `author_name`    | string | No       | Commit author name             |

**Response:** Object with `file_path`, `branch`.

### Update existing file in repository

```
PUT /projects/:id/repository/files/:file_path
```

| Parameter        | Type   | Required | Description                    |
|------------------|--------|----------|--------------------------------|
| `id`             | string | Yes      | Project ID or URL-encoded path |
| `file_path`      | string | Yes      | URL-encoded full path to file  |
| `branch`         | string | Yes      | Target branch name             |
| `content`        | string | Yes      | New file content               |
| `commit_message` | string | Yes      | Commit message                 |
| `encoding`       | string | No       | `text` or `base64` (default: `text`) |

**Response:** Object with `file_path`, `branch`.

### Delete file from repository

```
DELETE /projects/:id/repository/files/:file_path
```

| Parameter        | Type   | Required | Description                    |
|------------------|--------|----------|--------------------------------|
| `id`             | string | Yes      | Project ID or URL-encoded path |
| `file_path`      | string | Yes      | URL-encoded full path to file  |
| `branch`         | string | Yes      | Target branch name             |
| `commit_message` | string | Yes      | Commit message                 |

**Response:** Empty on success (204).

---

## Branches

### List branches

```
GET /projects/:id/repository/branches
```

| Parameter | Type   | Required | Description                    |
|-----------|--------|----------|--------------------------------|
| `id`      | string | Yes      | Project ID or URL-encoded path |
| `search`  | string | No       | Return branches matching search|
| `per_page`| integer| No       | Results per page (max 100)     |
| `page`    | integer| No       | Page number                    |

**Response:** Array of branch objects with `name`, `merged`, `protected`, `default`, `commit`.

### Get single branch

```
GET /projects/:id/repository/branches/:branch
```

| Parameter | Type   | Required | Description                    |
|-----------|--------|----------|--------------------------------|
| `id`      | string | Yes      | Project ID or URL-encoded path |
| `branch`  | string | Yes      | URL-encoded branch name        |

**Response:** Branch object with `name`, `merged`, `protected`, `default`, `commit`.

### Create branch

```
POST /projects/:id/repository/branches
```

| Parameter | Type   | Required | Description                                  |
|-----------|--------|----------|----------------------------------------------|
| `id`      | string | Yes      | Project ID or URL-encoded path               |
| `branch`  | string | Yes      | Name of the new branch                       |
| `ref`     | string | Yes      | Branch name or commit SHA to branch from     |

**Response:** Branch object.

### Delete branch

```
DELETE /projects/:id/repository/branches/:branch
```

| Parameter | Type   | Required | Description                    |
|-----------|--------|----------|--------------------------------|
| `id`      | string | Yes      | Project ID or URL-encoded path |
| `branch`  | string | Yes      | URL-encoded branch name        |

**Response:** Empty on success (204).

### Protect a branch

```
POST /projects/:id/protected_branches
```

| Parameter              | Type   | Required | Description                                      |
|------------------------|--------|----------|--------------------------------------------------|
| `id`                   | string | Yes      | Project ID or URL-encoded path                   |
| `name`                 | string | Yes      | Branch name or wildcard pattern                  |
| `push_access_level`    | string | No       | Access level for push (e.g. `0`, `30`, `40`)     |
| `merge_access_level`   | string | No       | Access level for merge                           |
| `allow_force_push`     | boolean| No       | Allow force push to branch                       |

**Response:** Protected branch object with `name`, `push_access_levels`, `merge_access_levels`.

---

## Tags

### List tags

```
GET /projects/:id/repository/tags
```

| Parameter | Type   | Required | Description                    |
|-----------|--------|----------|--------------------------------|
| `id`      | string | Yes      | Project ID or URL-encoded path |
| `search`  | string | No       | Return tags matching search    |
| `order_by`| string | No       | `name` or `updated` (default: `updated`) |
| `sort`    | string | No       | `asc` or `desc` (default: `desc`) |
| `per_page`| integer| No       | Results per page (max 100)     |
| `page`    | integer| No       | Page number                    |

**Response:** Array of tag objects with `name`, `message`, `target`, `commit`, `release`, `protected`.

### Create a tag

```
POST /projects/:id/repository/tags
```

| Parameter | Type   | Required | Description                                |
|-----------|--------|-----------|--------------------------------------------|
| `id`      | string | Yes      | Project ID or URL-encoded path             |
| `tag_name`| string | Yes      | Name of the tag                            |
| `ref`     | string | Yes      | Branch name or commit SHA to tag           |
| `message` | string | No       | Annotation message (creates annotated tag) |

**Response:** Tag object.

### Delete a tag

```
DELETE /projects/:id/repository/tags/:tag_name
```

| Parameter  | Type   | Required | Description                    |
|------------|--------|----------|--------------------------------|
| `id`       | string | Yes      | Project ID or URL-encoded path |
| `tag_name` | string | Yes      | URL-encoded tag name           |

**Response:** Empty on success (204).

---

## Commits

### List commits

```
GET /projects/:id/repository/commits
```

| Parameter  | Type   | Required | Description                                  |
|------------|--------|----------|----------------------------------------------|
| `id`       | string | Yes      | Project ID or URL-encoded path               |
| `ref_name` | string | No       | Branch, tag, or commit range (default: default branch) |
| `since`    | string | No       | ISO 8601 date — commits after this date      |
| `until`    | string | No       | ISO 8601 date — commits before this date     |
| `path`     | string | No       | File path to filter commits                  |
| `per_page` | integer| No       | Results per page (max 100)                   |
| `page`     | integer| No       | Page number                                  |

**Response:** Array of commit objects with `id`, `short_id`, `title`, `author_name`, `author_email`, `authored_date`, `committer_name`, `committer_email`, `committed_date`, `message`, `parent_ids`.

### Get single commit

```
GET /projects/:id/repository/commits/:sha
```

| Parameter | Type   | Required | Description                    |
|-----------|--------|----------|--------------------------------|
| `id`      | string | Yes      | Project ID or URL-encoded path |
| `sha`     | string | Yes      | Commit SHA                     |

**Response:** Commit object with full details including `stats` (additions, deletions, total).

### Create a commit

```
POST /projects/:id/repository/commits
```

| Parameter        | Type   | Required | Description                              |
|------------------|--------|----------|------------------------------------------|
| `id`             | string | Yes      | Project ID or URL-encoded path           |
| `branch`         | string | Yes      | Target branch name                       |
| `commit_message` | string | Yes      | Commit message                           |
| `actions`        | array  | Yes      | Array of action objects (see below)      |
| `start_branch`   | string | No       | Branch to start new branch from          |
| `author_email`   | string | No       | Commit author email                      |
| `author_name`    | string | No       | Commit author name                       |

**Action object fields:**

| Field           | Type   | Required | Description                                        |
|-----------------|--------|----------|----------------------------------------------------|
| `action`        | string | Yes      | `create`, `delete`, `move`, `update`, `chmod`      |
| `file_path`     | string | Yes      | Full path to file                                  |
| `content`       | string | No       | File content (required for create/update)          |
| `encoding`      | string | No       | `text` or `base64` (default: `text`)               |
| `previous_path` | string | No       | Original path (for `move` action)                  |

**Response:** Commit object.

### Get diff of a commit

```
GET /projects/:id/repository/commits/:sha/diff
```

| Parameter | Type   | Required | Description                    |
|-----------|--------|----------|--------------------------------|
| `id`      | string | Yes      | Project ID or URL-encoded path |
| `sha`     | string | Yes      | Commit SHA                     |
| `per_page`| integer| No       | Results per page (max 100)     |
| `page`    | integer| No       | Page number                    |

**Response:** Array of diff objects with `old_path`, `new_path`, `a_mode`, `b_mode`, `diff`, `new_file`, `renamed_file`, `deleted_file`.
