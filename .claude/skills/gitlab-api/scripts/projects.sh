#!/usr/bin/env bash
# GitLab Projects API functions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# ---------------------------------------------------------------------------
# List projects accessible by the authenticated user.
# Usage: gitlab_list_projects [visibility] [search] [order_by]
#   $1 - visibility: "public", "internal", or "private" (optional)
#   $2 - search: filter by name/path (optional)
#   $3 - order_by: "id", "name", "created_at", "updated_at", "last_activity_at" (optional)
# ---------------------------------------------------------------------------
gitlab_list_projects() {
  local visibility="${1:-}"
  local search="${2:-}"
  local order_by="${3:-}"
  local params=""

  [[ -n "$visibility" ]] && params="${params}&visibility=${visibility}"
  [[ -n "$search" ]] && params="${params}&search=$(urlencode "$search")"
  [[ -n "$order_by" ]] && params="${params}&order_by=${order_by}"

  # Strip leading '&' and prepend '?'
  params="${params#&}"
  [[ -n "$params" ]] && params="?${params}"

  gitlab_api GET "/projects${params}"
}

# ---------------------------------------------------------------------------
# Get a single project by ID or path.
# Usage: gitlab_get_project <project_id>
#   $1 - project_id: numeric ID or "namespace/project" path (required)
# ---------------------------------------------------------------------------
gitlab_get_project() {
  local project_id="${1:?project_id is required}"
  local encoded_id
  encoded_id="$(urlencode "$project_id")"

  gitlab_api GET "/projects/${encoded_id}"
}

# ---------------------------------------------------------------------------
# Create a new project.
# Usage: gitlab_create_project <name> [visibility] [description] [namespace_id]
#   $1 - name: project name (required)
#   $2 - visibility: "private", "internal", or "public" (optional, default: "private")
#   $3 - description: short description (optional)
#   $4 - namespace_id: target namespace/group ID (optional)
# ---------------------------------------------------------------------------
gitlab_create_project() {
  local name="${1:?name is required}"
  local visibility="${2:-}"
  local description="${3:-}"
  local namespace_id="${4:-}"

  local json
  json=$(jq -n \
    --arg name "$name" \
    --arg visibility "$visibility" \
    --arg description "$description" \
    --arg namespace_id "$namespace_id" \
    '{name: $name}
     + (if $visibility   != "" then {visibility: $visibility}          else {} end)
     + (if $description  != "" then {description: $description}        else {} end)
     + (if $namespace_id != "" then {namespace_id: ($namespace_id | tonumber)} else {} end)')

  gitlab_api POST "/projects" "$json"
}

# ---------------------------------------------------------------------------
# Edit an existing project.
# Usage: gitlab_edit_project <project_id> <json_data>
#   $1 - project_id: numeric ID or "namespace/project" path (required)
#   $2 - json_data: JSON string with fields to update (required)
# ---------------------------------------------------------------------------
gitlab_edit_project() {
  local project_id="${1:?project_id is required}"
  local json_data="${2:?json_data is required}"
  local encoded_id
  encoded_id="$(urlencode "$project_id")"

  gitlab_api PUT "/projects/${encoded_id}" "$json_data"
}

# ---------------------------------------------------------------------------
# Delete a project. This action is irreversible.
# Usage: gitlab_delete_project <project_id>
#   $1 - project_id: numeric ID or "namespace/project" path (required)
# ---------------------------------------------------------------------------
gitlab_delete_project() {
  local project_id="${1:?project_id is required}"
  local encoded_id
  encoded_id="$(urlencode "$project_id")"

  gitlab_api DELETE "/projects/${encoded_id}"
}

# ---------------------------------------------------------------------------
# Fork a project into the authenticated user's namespace.
# Usage: gitlab_fork_project <project_id>
#   $1 - project_id: numeric ID or "namespace/project" path (required)
# ---------------------------------------------------------------------------
gitlab_fork_project() {
  local project_id="${1:?project_id is required}"
  local encoded_id
  encoded_id="$(urlencode "$project_id")"

  gitlab_api POST "/projects/${encoded_id}/fork"
}

# ---------------------------------------------------------------------------
# List forks of a project.
# Usage: gitlab_list_forks <project_id>
#   $1 - project_id: numeric ID or "namespace/project" path (required)
# ---------------------------------------------------------------------------
gitlab_list_forks() {
  local project_id="${1:?project_id is required}"
  local encoded_id
  encoded_id="$(urlencode "$project_id")"

  gitlab_api GET "/projects/${encoded_id}/forks"
}

# ---------------------------------------------------------------------------
# Star a project.
# Usage: gitlab_star_project <project_id>
#   $1 - project_id: numeric ID or "namespace/project" path (required)
# ---------------------------------------------------------------------------
gitlab_star_project() {
  local project_id="${1:?project_id is required}"
  local encoded_id
  encoded_id="$(urlencode "$project_id")"

  gitlab_api POST "/projects/${encoded_id}/star"
}

# ---------------------------------------------------------------------------
# Unstar a project.
# Usage: gitlab_unstar_project <project_id>
#   $1 - project_id: numeric ID or "namespace/project" path (required)
# ---------------------------------------------------------------------------
gitlab_unstar_project() {
  local project_id="${1:?project_id is required}"
  local encoded_id
  encoded_id="$(urlencode "$project_id")"

  gitlab_api POST "/projects/${encoded_id}/unstar"
}

# ---------------------------------------------------------------------------
# Archive a project (makes it read-only).
# Usage: gitlab_archive_project <project_id>
#   $1 - project_id: numeric ID or "namespace/project" path (required)
# ---------------------------------------------------------------------------
gitlab_archive_project() {
  local project_id="${1:?project_id is required}"
  local encoded_id
  encoded_id="$(urlencode "$project_id")"

  gitlab_api POST "/projects/${encoded_id}/archive"
}

# ---------------------------------------------------------------------------
# Unarchive a project.
# Usage: gitlab_unarchive_project <project_id>
#   $1 - project_id: numeric ID or "namespace/project" path (required)
# ---------------------------------------------------------------------------
gitlab_unarchive_project() {
  local project_id="${1:?project_id is required}"
  local encoded_id
  encoded_id="$(urlencode "$project_id")"

  gitlab_api POST "/projects/${encoded_id}/unarchive"
}

# ---------------------------------------------------------------------------
# Get languages used in a project (with percentage breakdown).
# Usage: gitlab_get_project_languages <project_id>
#   $1 - project_id: numeric ID or "namespace/project" path (required)
# ---------------------------------------------------------------------------
gitlab_get_project_languages() {
  local project_id="${1:?project_id is required}"
  local encoded_id
  encoded_id="$(urlencode "$project_id")"

  gitlab_api GET "/projects/${encoded_id}/languages"
}

# ---------------------------------------------------------------------------
# List webhooks for a project.
# Usage: gitlab_list_project_hooks <project_id>
#   $1 - project_id: numeric ID or "namespace/project" path (required)
# ---------------------------------------------------------------------------
gitlab_list_project_hooks() {
  local project_id="${1:?project_id is required}"
  local encoded_id
  encoded_id="$(urlencode "$project_id")"

  gitlab_api GET "/projects/${encoded_id}/hooks"
}

# ---------------------------------------------------------------------------
# Create a webhook for a project.
# Usage: gitlab_create_project_hook <project_id> <url> [push_events] [merge_requests_events] [token]
#   $1 - project_id: numeric ID or "namespace/project" path (required)
#   $2 - url: webhook URL (required)
#   $3 - push_events: "true" or "false" (optional, default: "true")
#   $4 - merge_requests_events: "true" or "false" (optional)
#   $5 - token: secret token for webhook validation (optional)
# ---------------------------------------------------------------------------
gitlab_create_project_hook() {
  local project_id="${1:?project_id is required}"
  local url="${2:?url is required}"
  local push_events="${3:-true}"
  local merge_requests_events="${4:-}"
  local token="${5:-}"
  local encoded_id
  encoded_id="$(urlencode "$project_id")"

  local json
  json=$(jq -n \
    --arg url "$url" \
    --arg push_events "$push_events" \
    --arg mr_events "$merge_requests_events" \
    --arg token "$token" \
    '{url: $url, push_events: ($push_events == "true")}
     + (if $mr_events != "" then {merge_requests_events: ($mr_events == "true")} else {} end)
     + (if $token     != "" then {token: $token}                                  else {} end)')

  gitlab_api POST "/projects/${encoded_id}/hooks" "$json"
}

# ---------------------------------------------------------------------------
# Delete a webhook from a project.
# Usage: gitlab_delete_project_hook <project_id> <hook_id>
#   $1 - project_id: numeric ID or "namespace/project" path (required)
#   $2 - hook_id: webhook ID (required)
# ---------------------------------------------------------------------------
gitlab_delete_project_hook() {
  local project_id="${1:?project_id is required}"
  local hook_id="${2:?hook_id is required}"
  local encoded_id
  encoded_id="$(urlencode "$project_id")"

  gitlab_api DELETE "/projects/${encoded_id}/hooks/${hook_id}"
}

# ---------------------------------------------------------------------------
# Upload a file to a project.
# The response includes a "markdown" field that can be embedded in issue
# descriptions, merge request descriptions, or comments.
# Usage: gitlab_upload_project_file <project_id> <file_path>
#   $1 - project_id: numeric ID or "namespace/project" path (required)
#   $2 - file_path: local path to the file to upload (required)
# Returns JSON with: alt, url, full_path, markdown
# ---------------------------------------------------------------------------
gitlab_upload_project_file() {
  local project_id="${1:?project_id is required}"
  local file_path="${2:?file_path is required}"
  local encoded_id
  encoded_id="$(urlencode "$project_id")"

  gitlab_upload "/projects/${encoded_id}/uploads" "$file_path" "file"
}
