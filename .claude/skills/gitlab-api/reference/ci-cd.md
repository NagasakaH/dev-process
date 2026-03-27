# CI/CD API Reference

GitLab REST API v4 reference for pipelines, jobs, runners, variables, pipeline schedules, and triggers.

**Base URL:** `https://gitlab.example.com/api/v4`

**Authentication:** Pass a `PRIVATE-TOKEN` header or `access_token` query parameter.

---

## Pipelines

### List pipelines

```
GET /projects/:id/pipelines
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `status` | string | no | `created`, `waiting_for_resource`, `preparing`, `pending`, `running`, `success`, `failed`, `canceled`, `skipped`, `manual`, `scheduled` |
| `ref` | string | no | Branch or tag name |
| `sha` | string | no | Commit SHA |
| `yaml_errors` | boolean | no | Filter pipelines with/without YAML errors |
| `username` | string | no | Filter by username of the trigger author |
| `order_by` | string | no | `id`, `status`, `ref`, `updated_at`, or `user_id` (default: `id`) |
| `sort` | string | no | `asc` or `desc` (default: `desc`) |
| `per_page` | integer | no | Results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

### Get a pipeline

```
GET /projects/:id/pipelines/:pipeline_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `pipeline_id` | integer | yes | ID of the pipeline |

### Create a pipeline

```
POST /projects/:id/pipeline
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `ref` | string | yes | Branch or tag to run the pipeline for |
| `variables` | array | no | Array of variables `[{"key":"VAR","value":"val","variable_type":"env_var"}]` |

### Delete a pipeline

```
DELETE /projects/:id/pipelines/:pipeline_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `pipeline_id` | integer | yes | ID of the pipeline |

### Cancel a pipeline

```
POST /projects/:id/pipelines/:pipeline_id/cancel
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `pipeline_id` | integer | yes | ID of the pipeline |

### Retry a pipeline

```
POST /projects/:id/pipelines/:pipeline_id/retry
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `pipeline_id` | integer | yes | ID of the pipeline |

---

## Jobs

### List pipeline jobs

```
GET /projects/:id/pipelines/:pipeline_id/jobs
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `pipeline_id` | integer | yes | ID of the pipeline |
| `scope` | string/array | no | Filter by status: `created`, `pending`, `running`, `failed`, `success`, `canceled`, `skipped`, `manual` |
| `per_page` | integer | no | Results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

### Get a single job

```
GET /projects/:id/jobs/:job_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `job_id` | integer | yes | ID of the job |

### Cancel a job

```
POST /projects/:id/jobs/:job_id/cancel
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `job_id` | integer | yes | ID of the job |

### Retry a job

```
POST /projects/:id/jobs/:job_id/retry
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `job_id` | integer | yes | ID of the job |

### Play a manual job

```
POST /projects/:id/jobs/:job_id/play
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `job_id` | integer | yes | ID of the job |
| `job_variables_attributes` | array | no | Array of variables `[{"key":"VAR","value":"val"}]` |

### Get job log (trace)

```
GET /projects/:id/jobs/:job_id/trace
```

Returns the raw job log as plain text.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `job_id` | integer | yes | ID of the job |

### Download job artifacts

```
GET /projects/:id/jobs/:job_id/artifacts
```

Returns the artifacts archive as a binary file.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `job_id` | integer | yes | ID of the job |

---

## Runners

### List owned runners

```
GET /runners
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `scope` | string | no | `active`, `paused`, `online`, `specific`, `shared` |
| `type` | string | no | `instance_type`, `group_type`, `project_type` |
| `status` | string | no | `online`, `offline`, `stale`, `never_contacted` |
| `tag_list` | string | no | Comma-separated list of runner tags |
| `per_page` | integer | no | Results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

### Get a runner

```
GET /runners/:id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer | yes | ID of the runner |

### List project runners

```
GET /projects/:id/runners
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `scope` | string | no | `active`, `paused`, `online`, `specific`, `shared` |
| `tag_list` | string | no | Comma-separated list of runner tags |

### Enable a project runner

```
POST /projects/:id/runners
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `runner_id` | integer | yes | ID of the runner to enable |

### Disable a project runner

```
DELETE /projects/:id/runners/:runner_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `runner_id` | integer | yes | ID of the runner to disable |

---

## Variables

### List project variables

```
GET /projects/:id/variables
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `per_page` | integer | no | Results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

### Get a project variable

```
GET /projects/:id/variables/:key
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `key` | string | yes | Key of the variable |

### Create a project variable

```
POST /projects/:id/variables
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `key` | string | yes | Key of the variable (max 255 characters) |
| `value` | string | yes | Value of the variable (max 10000 characters) |
| `variable_type` | string | no | `env_var` (default) or `file` |
| `protected` | boolean | no | Whether the variable is only available on protected branches/tags |
| `masked` | boolean | no | Whether the variable is masked in job logs |
| `environment_scope` | string | no | Environment scope (default: `*`) |

### Update a project variable

```
PUT /projects/:id/variables/:key
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `key` | string | yes | Key of the variable |
| `value` | string | yes | New value of the variable |
| `variable_type` | string | no | `env_var` or `file` |
| `protected` | boolean | no | Whether the variable is protected |
| `masked` | boolean | no | Whether the variable is masked |

### Delete a project variable

```
DELETE /projects/:id/variables/:key
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `key` | string | yes | Key of the variable |

### Group variables

Group variables follow the same pattern, replacing the project path with a group path:

```
GET    /groups/:id/variables
GET    /groups/:id/variables/:key
POST   /groups/:id/variables
PUT    /groups/:id/variables/:key
DELETE /groups/:id/variables/:key
```

Parameters are identical to project variables, substituting group ID for project ID.

---

## Pipeline Schedules

### List pipeline schedules

```
GET /projects/:id/pipeline_schedules
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `scope` | string | no | `active` or `inactive` |

### Create a pipeline schedule

```
POST /projects/:id/pipeline_schedules
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `description` | string | yes | Description of the schedule |
| `ref` | string | yes | Branch or tag name |
| `cron` | string | yes | Cron expression (e.g., `0 1 * * *`) |
| `cron_timezone` | string | no | Timezone (default: `UTC`) |
| `active` | boolean | no | Whether the schedule is active (default: `true`) |

### Edit a pipeline schedule

```
PUT /projects/:id/pipeline_schedules/:schedule_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `schedule_id` | integer | yes | ID of the pipeline schedule |
| `description` | string | no | Updated description |
| `ref` | string | no | Updated branch or tag name |
| `cron` | string | no | Updated cron expression |
| `cron_timezone` | string | no | Updated timezone |
| `active` | boolean | no | Whether the schedule is active |

### Delete a pipeline schedule

```
DELETE /projects/:id/pipeline_schedules/:schedule_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `schedule_id` | integer | yes | ID of the pipeline schedule |

### Take ownership of a pipeline schedule

```
POST /projects/:id/pipeline_schedules/:schedule_id/take_ownership
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `schedule_id` | integer | yes | ID of the pipeline schedule |

### Play a pipeline schedule

```
POST /projects/:id/pipeline_schedules/:schedule_id/play
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `schedule_id` | integer | yes | ID of the pipeline schedule |

---

## Pipeline Triggers

### List triggers

```
GET /projects/:id/triggers
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |

### Create a trigger

```
POST /projects/:id/triggers
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `description` | string | yes | Description of the trigger |

### Trigger a pipeline

```
POST /projects/:id/trigger/pipeline
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `ref` | string | yes | Branch or tag to run the pipeline for |
| `token` | string | yes | Trigger token |
| `variables` | object | no | Key-value pairs of pipeline variables |

---

## CI Lint

### Validate CI/CD configuration

```
POST /projects/:id/ci/lint
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `content` | string | yes | CI/CD YAML configuration content |
| `dry_run` | boolean | no | Run pipeline creation simulation (default: `false`) |
| `include_jobs` | boolean | no | Include list of jobs in the response (default: `false`) |

---

## Common Parameters

These query parameters are shared across most list endpoints:

| Parameter | Type | Description |
|---|---|---|
| `per_page` | integer | Results per page (default: 20, max: 100) |
| `page` | integer | Page number for pagination |
| `order_by` | string | Field to order results by |
| `sort` | string | Sort direction: `asc` or `desc` |

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
