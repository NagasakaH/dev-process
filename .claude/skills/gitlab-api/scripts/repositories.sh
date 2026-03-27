#!/usr/bin/env bash
# Repository operations: files, branches, tags, commits
# Source common.sh before using these functions.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# ---------------------------------------------------------------------------
# Repository Tree
# ---------------------------------------------------------------------------

# List repository tree
# Usage: gitlab_list_repo_tree PROJECT_ID [PATH] [REF] [RECURSIVE]
gitlab_list_repo_tree() {
  local project_id
  project_id=$(urlencode "${1:?Project ID required}")
  local path="${2:-}"
  local ref="${3:-}"
  local recursive="${4:-}"

  local query=""
  [[ -n "$path" ]] && query="${query}&path=${path}"
  [[ -n "$ref" ]] && query="${query}&ref=${ref}"
  [[ -n "$recursive" ]] && query="${query}&recursive=${recursive}"
  query="${query#&}"

  local endpoint="/projects/${project_id}/repository/tree"
  [[ -n "$query" ]] && endpoint="${endpoint}?${query}"

  gitlab_api GET "$endpoint"
}

# ---------------------------------------------------------------------------
# Repository Files
# ---------------------------------------------------------------------------

# Get file metadata and Base64 content
# Usage: gitlab_get_file PROJECT_ID FILE_PATH REF
gitlab_get_file() {
  local project_id
  project_id=$(urlencode "${1:?Project ID required}")
  local file_path
  file_path=$(urlencode "${2:?File path required}")
  local ref="${3:?Ref required}"

  gitlab_api GET "/projects/${project_id}/repository/files/${file_path}?ref=${ref}"
}

# Get raw file content
# Usage: gitlab_get_file_raw PROJECT_ID FILE_PATH REF
gitlab_get_file_raw() {
  local project_id
  project_id=$(urlencode "${1:?Project ID required}")
  local file_path
  file_path=$(urlencode "${2:?File path required}")
  local ref="${3:?Ref required}"

  gitlab_api GET "/projects/${project_id}/repository/files/${file_path}/raw?ref=${ref}"
}

# Create a new file in the repository
# Usage: gitlab_create_file PROJECT_ID FILE_PATH BRANCH CONTENT COMMIT_MESSAGE
gitlab_create_file() {
  local project_id
  project_id=$(urlencode "${1:?Project ID required}")
  local file_path
  file_path=$(urlencode "${2:?File path required}")
  local branch="${3:?Branch required}"
  local content="${4:?Content required}"
  local commit_message="${5:?Commit message required}"

  local data
  data=$(jq -n \
    --arg branch "$branch" \
    --arg content "$content" \
    --arg commit_message "$commit_message" \
    '{branch: $branch, content: $content, commit_message: $commit_message}')

  gitlab_api POST "/projects/${project_id}/repository/files/${file_path}" "$data"
}

# Update an existing file in the repository
# Usage: gitlab_update_file PROJECT_ID FILE_PATH BRANCH CONTENT COMMIT_MESSAGE
gitlab_update_file() {
  local project_id
  project_id=$(urlencode "${1:?Project ID required}")
  local file_path
  file_path=$(urlencode "${2:?File path required}")
  local branch="${3:?Branch required}"
  local content="${4:?Content required}"
  local commit_message="${5:?Commit message required}"

  local data
  data=$(jq -n \
    --arg branch "$branch" \
    --arg content "$content" \
    --arg commit_message "$commit_message" \
    '{branch: $branch, content: $content, commit_message: $commit_message}')

  gitlab_api PUT "/projects/${project_id}/repository/files/${file_path}" "$data"
}

# Delete a file from the repository
# Usage: gitlab_delete_file PROJECT_ID FILE_PATH BRANCH COMMIT_MESSAGE
gitlab_delete_file() {
  local project_id
  project_id=$(urlencode "${1:?Project ID required}")
  local file_path
  file_path=$(urlencode "${2:?File path required}")
  local branch="${3:?Branch required}"
  local commit_message="${4:?Commit message required}"

  local data
  data=$(jq -n \
    --arg branch "$branch" \
    --arg commit_message "$commit_message" \
    '{branch: $branch, commit_message: $commit_message}')

  gitlab_api DELETE "/projects/${project_id}/repository/files/${file_path}" "$data"
}

# ---------------------------------------------------------------------------
# Compare
# ---------------------------------------------------------------------------

# Compare branches, tags, or commits
# Usage: gitlab_compare PROJECT_ID FROM TO
gitlab_compare() {
  local project_id
  project_id=$(urlencode "${1:?Project ID required}")
  local from="${2:?From ref required}"
  local to="${3:?To ref required}"

  gitlab_api GET "/projects/${project_id}/repository/compare?from=${from}&to=${to}"
}

# ---------------------------------------------------------------------------
# Branches
# ---------------------------------------------------------------------------

# List branches
# Usage: gitlab_list_branches PROJECT_ID
gitlab_list_branches() {
  local project_id
  project_id=$(urlencode "${1:?Project ID required}")

  gitlab_api GET "/projects/${project_id}/repository/branches"
}

# Get single branch
# Usage: gitlab_get_branch PROJECT_ID BRANCH_NAME
gitlab_get_branch() {
  local project_id
  project_id=$(urlencode "${1:?Project ID required}")
  local branch_name
  branch_name=$(urlencode "${2:?Branch name required}")

  gitlab_api GET "/projects/${project_id}/repository/branches/${branch_name}"
}

# Create a new branch
# Usage: gitlab_create_branch PROJECT_ID BRANCH_NAME REF
gitlab_create_branch() {
  local project_id
  project_id=$(urlencode "${1:?Project ID required}")
  local branch_name="${2:?Branch name required}"
  local ref="${3:?Ref required}"

  local data
  data=$(jq -n \
    --arg branch "$branch_name" \
    --arg ref "$ref" \
    '{branch: $branch, ref: $ref}')

  gitlab_api POST "/projects/${project_id}/repository/branches" "$data"
}

# Delete a branch
# Usage: gitlab_delete_branch PROJECT_ID BRANCH_NAME
gitlab_delete_branch() {
  local project_id
  project_id=$(urlencode "${1:?Project ID required}")
  local branch_name
  branch_name=$(urlencode "${2:?Branch name required}")

  gitlab_api DELETE "/projects/${project_id}/repository/branches/${branch_name}"
}

# ---------------------------------------------------------------------------
# Tags
# ---------------------------------------------------------------------------

# List tags
# Usage: gitlab_list_tags PROJECT_ID
gitlab_list_tags() {
  local project_id
  project_id=$(urlencode "${1:?Project ID required}")

  gitlab_api GET "/projects/${project_id}/repository/tags"
}

# Create a tag
# Usage: gitlab_create_tag PROJECT_ID TAG_NAME REF [MESSAGE]
gitlab_create_tag() {
  local project_id
  project_id=$(urlencode "${1:?Project ID required}")
  local tag_name="${2:?Tag name required}"
  local ref="${3:?Ref required}"
  local message="${4:-}"

  local data
  if [[ -n "$message" ]]; then
    data=$(jq -n \
      --arg tag_name "$tag_name" \
      --arg ref "$ref" \
      --arg message "$message" \
      '{tag_name: $tag_name, ref: $ref, message: $message}')
  else
    data=$(jq -n \
      --arg tag_name "$tag_name" \
      --arg ref "$ref" \
      '{tag_name: $tag_name, ref: $ref}')
  fi

  gitlab_api POST "/projects/${project_id}/repository/tags" "$data"
}

# Delete a tag
# Usage: gitlab_delete_tag PROJECT_ID TAG_NAME
gitlab_delete_tag() {
  local project_id
  project_id=$(urlencode "${1:?Project ID required}")
  local tag_name
  tag_name=$(urlencode "${2:?Tag name required}")

  gitlab_api DELETE "/projects/${project_id}/repository/tags/${tag_name}"
}

# ---------------------------------------------------------------------------
# Commits
# ---------------------------------------------------------------------------

# List commits
# Usage: gitlab_list_commits PROJECT_ID [REF_NAME]
gitlab_list_commits() {
  local project_id
  project_id=$(urlencode "${1:?Project ID required}")
  local ref_name="${2:-}"

  local endpoint="/projects/${project_id}/repository/commits"
  [[ -n "$ref_name" ]] && endpoint="${endpoint}?ref_name=${ref_name}"

  gitlab_api GET "$endpoint"
}

# Get single commit
# Usage: gitlab_get_commit PROJECT_ID SHA
gitlab_get_commit() {
  local project_id
  project_id=$(urlencode "${1:?Project ID required}")
  local sha="${2:?SHA required}"

  gitlab_api GET "/projects/${project_id}/repository/commits/${sha}"
}

# Get commit diff
# Usage: gitlab_get_commit_diff PROJECT_ID SHA
gitlab_get_commit_diff() {
  local project_id
  project_id=$(urlencode "${1:?Project ID required}")
  local sha="${2:?SHA required}"

  gitlab_api GET "/projects/${project_id}/repository/commits/${sha}/diff"
}
