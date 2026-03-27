#!/usr/bin/env bash
# GitLab Merge Requests API functions
# Source this file after common.sh to use MR-related API calls.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# List merge requests for a project
# Usage: gitlab_list_merge_requests PROJECT_ID [STATE] [ORDER_BY]
gitlab_list_merge_requests() {
  local project_id
  project_id=$(urlencode "${1:?project_id is required}")
  local state="${2:-all}"
  local order_by="${3:-created_at}"
  gitlab_api GET "/projects/${project_id}/merge_requests?state=${state}&order_by=${order_by}"
}

# Get a single merge request
# Usage: gitlab_get_merge_request PROJECT_ID MR_IID
gitlab_get_merge_request() {
  local project_id
  project_id=$(urlencode "${1:?project_id is required}")
  local mr_iid="${2:?mr_iid is required}"
  gitlab_api GET "/projects/${project_id}/merge_requests/${mr_iid}"
}

# Create a merge request
# Usage: gitlab_create_merge_request PROJECT_ID SOURCE_BRANCH TARGET_BRANCH TITLE
gitlab_create_merge_request() {
  local project_id
  project_id=$(urlencode "${1:?project_id is required}")
  local source_branch="${2:?source_branch is required}"
  local target_branch="${3:?target_branch is required}"
  local title="${4:?title is required}"
  gitlab_api POST "/projects/${project_id}/merge_requests" \
    "$(printf '{"source_branch":"%s","target_branch":"%s","title":"%s"}' \
      "$source_branch" "$target_branch" "$title")"
}

# Update a merge request with arbitrary JSON data
# Usage: gitlab_update_merge_request PROJECT_ID MR_IID JSON_DATA
gitlab_update_merge_request() {
  local project_id
  project_id=$(urlencode "${1:?project_id is required}")
  local mr_iid="${2:?mr_iid is required}"
  local data="${3:?JSON data is required}"
  gitlab_api PUT "/projects/${project_id}/merge_requests/${mr_iid}" "$data"
}

# Delete a merge request
# Usage: gitlab_delete_merge_request PROJECT_ID MR_IID
gitlab_delete_merge_request() {
  local project_id
  project_id=$(urlencode "${1:?project_id is required}")
  local mr_iid="${2:?mr_iid is required}"
  gitlab_api DELETE "/projects/${project_id}/merge_requests/${mr_iid}"
}

# Merge a merge request
# Usage: gitlab_merge_merge_request PROJECT_ID MR_IID [MERGE_WHEN_PIPELINE_SUCCEEDS] [SQUASH]
gitlab_merge_merge_request() {
  local project_id
  project_id=$(urlencode "${1:?project_id is required}")
  local mr_iid="${2:?mr_iid is required}"
  local merge_when_pipeline_succeeds="${3:-false}"
  local squash="${4:-false}"
  gitlab_api PUT "/projects/${project_id}/merge_requests/${mr_iid}/merge" \
    "$(printf '{"merge_when_pipeline_succeeds":%s,"squash":%s}' \
      "$merge_when_pipeline_succeeds" "$squash")"
}

# Rebase a merge request
# Usage: gitlab_rebase_merge_request PROJECT_ID MR_IID
gitlab_rebase_merge_request() {
  local project_id
  project_id=$(urlencode "${1:?project_id is required}")
  local mr_iid="${2:?mr_iid is required}"
  gitlab_api PUT "/projects/${project_id}/merge_requests/${mr_iid}/rebase"
}

# List changes/diffs for a merge request
# Usage: gitlab_list_mr_changes PROJECT_ID MR_IID
gitlab_list_mr_changes() {
  local project_id
  project_id=$(urlencode "${1:?project_id is required}")
  local mr_iid="${2:?mr_iid is required}"
  gitlab_api GET "/projects/${project_id}/merge_requests/${mr_iid}/changes"
}

# List commits for a merge request
# Usage: gitlab_list_mr_commits PROJECT_ID MR_IID
gitlab_list_mr_commits() {
  local project_id
  project_id=$(urlencode "${1:?project_id is required}")
  local mr_iid="${2:?mr_iid is required}"
  gitlab_api GET "/projects/${project_id}/merge_requests/${mr_iid}/commits"
}

# Get approval state for a merge request
# Usage: gitlab_get_mr_approvals PROJECT_ID MR_IID
gitlab_get_mr_approvals() {
  local project_id
  project_id=$(urlencode "${1:?project_id is required}")
  local mr_iid="${2:?mr_iid is required}"
  gitlab_api GET "/projects/${project_id}/merge_requests/${mr_iid}/approvals"
}

# Approve a merge request
# Usage: gitlab_approve_merge_request PROJECT_ID MR_IID
gitlab_approve_merge_request() {
  local project_id
  project_id=$(urlencode "${1:?project_id is required}")
  local mr_iid="${2:?mr_iid is required}"
  gitlab_api POST "/projects/${project_id}/merge_requests/${mr_iid}/approve"
}

# Unapprove a merge request
# Usage: gitlab_unapprove_merge_request PROJECT_ID MR_IID
gitlab_unapprove_merge_request() {
  local project_id
  project_id=$(urlencode "${1:?project_id is required}")
  local mr_iid="${2:?mr_iid is required}"
  gitlab_api POST "/projects/${project_id}/merge_requests/${mr_iid}/unapprove"
}

# List notes (comments) on a merge request
# Usage: gitlab_list_mr_notes PROJECT_ID MR_IID
gitlab_list_mr_notes() {
  local project_id
  project_id=$(urlencode "${1:?project_id is required}")
  local mr_iid="${2:?mr_iid is required}"
  gitlab_api GET "/projects/${project_id}/merge_requests/${mr_iid}/notes"
}

# Create a note (comment) on a merge request
# Usage: gitlab_create_mr_note PROJECT_ID MR_IID BODY
gitlab_create_mr_note() {
  local project_id
  project_id=$(urlencode "${1:?project_id is required}")
  local mr_iid="${2:?mr_iid is required}"
  local body="${3:?body is required}"
  gitlab_api POST "/projects/${project_id}/merge_requests/${mr_iid}/notes" \
    "$(printf '{"body":"%s"}' "$body")"
}
