#!/usr/bin/env bash
#
# GitLab CI/CD API functions
# Requires: common.sh (provides gitlab_api, GITLAB_URL, GITLAB_TOKEN)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# ---------------------------------------------------------------------------
# Pipelines
# ---------------------------------------------------------------------------

# List pipelines for a project
# Usage: gitlab_list_pipelines <project_id> [status] [ref] [order_by]
gitlab_list_pipelines() {
    local project_id="$1"
    local status="${2:-}"
    local ref="${3:-}"
    local order_by="${4:-}"

    local params=()
    [[ -n "$status" ]] && params+=("status=${status}")
    [[ -n "$ref" ]] && params+=("ref=${ref}")
    [[ -n "$order_by" ]] && params+=("order_by=${order_by}")

    local query_string=""
    if [[ ${#params[@]} -gt 0 ]]; then
        query_string="?$(IFS='&'; echo "${params[*]}")"
    fi

    gitlab_api GET "/projects/$(urlencode "$project_id")/pipelines${query_string}"
}

# Get a single pipeline
# Usage: gitlab_get_pipeline <project_id> <pipeline_id>
gitlab_get_pipeline() {
    local project_id="$1"
    local pipeline_id="$2"

    gitlab_api GET "/projects/$(urlencode "$project_id")/pipelines/${pipeline_id}"
}

# Create a new pipeline
# Usage: gitlab_create_pipeline <project_id> <ref> [variables_json]
# variables_json: JSON array, e.g. '[{"key":"VAR","value":"val"}]'
gitlab_create_pipeline() {
    local project_id="$1"
    local ref="$2"
    local variables="${3:-}"

    local data="{\"ref\": \"${ref}\""
    [[ -n "$variables" ]] && data+=", \"variables\": ${variables}"
    data+="}"

    gitlab_api POST "/projects/$(urlencode "$project_id")/pipeline" "$data"
}

# Cancel a pipeline
# Usage: gitlab_cancel_pipeline <project_id> <pipeline_id>
gitlab_cancel_pipeline() {
    local project_id="$1"
    local pipeline_id="$2"

    gitlab_api POST "/projects/$(urlencode "$project_id")/pipelines/${pipeline_id}/cancel"
}

# Retry a pipeline
# Usage: gitlab_retry_pipeline <project_id> <pipeline_id>
gitlab_retry_pipeline() {
    local project_id="$1"
    local pipeline_id="$2"

    gitlab_api POST "/projects/$(urlencode "$project_id")/pipelines/${pipeline_id}/retry"
}

# Delete a pipeline
# Usage: gitlab_delete_pipeline <project_id> <pipeline_id>
gitlab_delete_pipeline() {
    local project_id="$1"
    local pipeline_id="$2"

    gitlab_api DELETE "/projects/$(urlencode "$project_id")/pipelines/${pipeline_id}"
}

# ---------------------------------------------------------------------------
# Jobs
# ---------------------------------------------------------------------------

# List jobs for a pipeline
# Usage: gitlab_list_pipeline_jobs <project_id> <pipeline_id>
gitlab_list_pipeline_jobs() {
    local project_id="$1"
    local pipeline_id="$2"

    gitlab_api GET "/projects/$(urlencode "$project_id")/pipelines/${pipeline_id}/jobs"
}

# Get a single job
# Usage: gitlab_get_job <project_id> <job_id>
gitlab_get_job() {
    local project_id="$1"
    local job_id="$2"

    gitlab_api GET "/projects/$(urlencode "$project_id")/jobs/${job_id}"
}

# Cancel a job
# Usage: gitlab_cancel_job <project_id> <job_id>
gitlab_cancel_job() {
    local project_id="$1"
    local job_id="$2"

    gitlab_api POST "/projects/$(urlencode "$project_id")/jobs/${job_id}/cancel"
}

# Retry a job
# Usage: gitlab_retry_job <project_id> <job_id>
gitlab_retry_job() {
    local project_id="$1"
    local job_id="$2"

    gitlab_api POST "/projects/$(urlencode "$project_id")/jobs/${job_id}/retry"
}

# Play a manual job
# Usage: gitlab_play_job <project_id> <job_id>
gitlab_play_job() {
    local project_id="$1"
    local job_id="$2"

    gitlab_api POST "/projects/$(urlencode "$project_id")/jobs/${job_id}/play"
}

# Get job log (trace)
# Usage: gitlab_get_job_log <project_id> <job_id>
gitlab_get_job_log() {
    local project_id="$1"
    local job_id="$2"

    gitlab_api GET "/projects/$(urlencode "$project_id")/jobs/${job_id}/trace"
}

# Download job artifacts to a file
# Usage: gitlab_download_artifacts <project_id> <job_id> <output_file>
gitlab_download_artifacts() {
    local project_id="$1"
    local job_id="$2"
    local output_file="$3"

    local url="${GITLAB_API_BASE}/projects/$(urlencode "$project_id")/jobs/${job_id}/artifacts"

    curl -s \
        -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        -o "$output_file" \
        -w "%{http_code}" \
        "$url" | {
        read -r http_code
        if [[ "$http_code" -ge 400 ]]; then
            echo "ERROR: HTTP ${http_code} downloading artifacts for job ${job_id}" >&2
            return 1
        fi
        echo "Artifacts saved to ${output_file}"
    }
}

# ---------------------------------------------------------------------------
# Runners
# ---------------------------------------------------------------------------

# List runners accessible to the authenticated user
# Usage: gitlab_list_runners [scope]
# scope: active, paused, online, specific, shared
gitlab_list_runners() {
    local scope="${1:-}"

    local query_string=""
    [[ -n "$scope" ]] && query_string="?scope=${scope}"

    gitlab_api GET "/runners${query_string}"
}

# Get details of a runner
# Usage: gitlab_get_runner <runner_id>
gitlab_get_runner() {
    local runner_id="$1"

    gitlab_api GET "/runners/${runner_id}"
}

# List runners for a project
# Usage: gitlab_list_project_runners <project_id>
gitlab_list_project_runners() {
    local project_id="$1"

    gitlab_api GET "/projects/$(urlencode "$project_id")/runners"
}

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------

# List project-level CI/CD variables
# Usage: gitlab_list_project_variables <project_id>
gitlab_list_project_variables() {
    local project_id="$1"

    gitlab_api GET "/projects/$(urlencode "$project_id")/variables"
}

# Get a single project variable
# Usage: gitlab_get_project_variable <project_id> <key>
gitlab_get_project_variable() {
    local project_id="$1"
    local key="$2"

    gitlab_api GET "/projects/$(urlencode "$project_id")/variables/${key}"
}

# Create a project variable
# Usage: gitlab_create_project_variable <project_id> <key> <value> [protected] [masked]
gitlab_create_project_variable() {
    local project_id="$1"
    local key="$2"
    local value="$3"
    local protected="${4:-}"
    local masked="${5:-}"

    local data="{\"key\": \"${key}\", \"value\": \"${value}\""
    [[ -n "$protected" ]] && data+=", \"protected\": ${protected}"
    [[ -n "$masked" ]] && data+=", \"masked\": ${masked}"
    data+="}"

    gitlab_api POST "/projects/$(urlencode "$project_id")/variables" "$data"
}

# Update a project variable
# Usage: gitlab_update_project_variable <project_id> <key> <value>
gitlab_update_project_variable() {
    local project_id="$1"
    local key="$2"
    local value="$3"

    local data="{\"value\": \"${value}\"}"

    gitlab_api PUT "/projects/$(urlencode "$project_id")/variables/${key}" "$data"
}

# Delete a project variable
# Usage: gitlab_delete_project_variable <project_id> <key>
gitlab_delete_project_variable() {
    local project_id="$1"
    local key="$2"

    gitlab_api DELETE "/projects/$(urlencode "$project_id")/variables/${key}"
}

# ---------------------------------------------------------------------------
# Pipeline Schedules
# ---------------------------------------------------------------------------

# List pipeline schedules
# Usage: gitlab_list_pipeline_schedules <project_id>
gitlab_list_pipeline_schedules() {
    local project_id="$1"

    gitlab_api GET "/projects/$(urlencode "$project_id")/pipeline_schedules"
}

# Create a pipeline schedule
# Usage: gitlab_create_pipeline_schedule <project_id> <description> <ref> <cron>
gitlab_create_pipeline_schedule() {
    local project_id="$1"
    local description="$2"
    local ref="$3"
    local cron="$4"

    local data="{\"description\": \"${description}\", \"ref\": \"${ref}\", \"cron\": \"${cron}\"}"

    gitlab_api POST "/projects/$(urlencode "$project_id")/pipeline_schedules" "$data"
}

# ---------------------------------------------------------------------------
# Pipeline Triggers
# ---------------------------------------------------------------------------

# Trigger a pipeline via trigger token
# Usage: gitlab_trigger_pipeline <project_id> <ref> <token> [variables_json]
# variables_json: JSON object, e.g. '{"VAR":"val"}'
gitlab_trigger_pipeline() {
    local project_id="$1"
    local ref="$2"
    local token="$3"
    local variables="${4:-}"

    local data="{\"ref\": \"${ref}\", \"token\": \"${token}\""
    [[ -n "$variables" ]] && data+=", \"variables\": ${variables}"
    data+="}"

    gitlab_api POST "/projects/$(urlencode "$project_id")/trigger/pipeline" "$data"
}

# ---------------------------------------------------------------------------
# CI Lint
# ---------------------------------------------------------------------------

# Validate CI/CD configuration content
# Usage: gitlab_lint_ci <project_id> <content>
gitlab_lint_ci() {
    local project_id="$1"
    local content="$2"

    # Escape the YAML content for JSON embedding
    local escaped_content
    escaped_content=$(printf '%s' "$content" | jq -Rs '.')

    local data="{\"content\": ${escaped_content}}"

    gitlab_api POST "/projects/$(urlencode "$project_id")/ci/lint" "$data"
}
