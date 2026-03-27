#!/usr/bin/env bash
#
# GitLab Container Registry API functions
# Requires: common.sh (provides gitlab_api, urlencode, GITLAB_URL, GITLAB_TOKEN)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# ---------------------------------------------------------------------------
# Registry Repositories
# ---------------------------------------------------------------------------

# List registry repositories for a project
# Usage: gitlab_list_registry_repos <project_id>
gitlab_list_registry_repos() {
    local project_id="$1"

    gitlab_api GET "/projects/$(urlencode "$project_id")/registry/repositories"
}

# Delete a registry repository
# Usage: gitlab_delete_registry_repo <project_id> <repository_id>
gitlab_delete_registry_repo() {
    local project_id="$1"
    local repository_id="$2"

    gitlab_api DELETE "/projects/$(urlencode "$project_id")/registry/repositories/${repository_id}"
}

# ---------------------------------------------------------------------------
# Registry Tags
# ---------------------------------------------------------------------------

# List tags for a registry repository
# Usage: gitlab_list_registry_tags <project_id> <repository_id>
gitlab_list_registry_tags() {
    local project_id="$1"
    local repository_id="$2"

    gitlab_api GET "/projects/$(urlencode "$project_id")/registry/repositories/${repository_id}/tags"
}

# Get details of a specific registry tag
# Usage: gitlab_get_registry_tag <project_id> <repository_id> <tag_name>
gitlab_get_registry_tag() {
    local project_id="$1"
    local repository_id="$2"
    local tag_name="$3"

    gitlab_api GET "/projects/$(urlencode "$project_id")/registry/repositories/${repository_id}/tags/$(urlencode "$tag_name")"
}

# Delete a specific registry tag
# Usage: gitlab_delete_registry_tag <project_id> <repository_id> <tag_name>
gitlab_delete_registry_tag() {
    local project_id="$1"
    local repository_id="$2"
    local tag_name="$3"

    gitlab_api DELETE "/projects/$(urlencode "$project_id")/registry/repositories/${repository_id}/tags/$(urlencode "$tag_name")"
}

# Bulk delete registry tags by regex and retention criteria
# Usage: gitlab_bulk_delete_registry_tags <project_id> <repository_id> [name_regex] [keep_n] [older_than]
gitlab_bulk_delete_registry_tags() {
    local project_id="$1"
    local repository_id="$2"
    local name_regex="${3:-.*}"
    local keep_n="${4:-}"
    local older_than="${5:-}"

    local data="{\"name_regex_delete\": \"${name_regex}\""
    [[ -n "$keep_n" ]] && data+=", \"keep_n\": ${keep_n}"
    [[ -n "$older_than" ]] && data+=", \"older_than\": \"${older_than}\""
    data+="}"

    gitlab_api DELETE "/projects/$(urlencode "$project_id")/registry/repositories/${repository_id}/tags" "$data"
}

# ---------------------------------------------------------------------------
# Group-Level Registry Repositories
# ---------------------------------------------------------------------------

# List registry repositories for a group
# Usage: gitlab_list_group_registry_repos <group_id>
gitlab_list_group_registry_repos() {
    local group_id="$1"

    gitlab_api GET "/groups/$(urlencode "$group_id")/registry/repositories"
}
