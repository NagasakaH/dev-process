#!/usr/bin/env bash
#
# GitLab Groups API functions
# Requires: common.sh (provides gitlab_api, GITLAB_URL, GITLAB_TOKEN)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# ---------------------------------------------------------------------------
# Groups
# ---------------------------------------------------------------------------

# List groups visible to the authenticated user
# Usage: gitlab_list_groups [search] [order_by]
gitlab_list_groups() {
    local search="${1:-}"
    local order_by="${2:-}"

    local params=()
    [[ -n "$search" ]] && params+=("search=$(urlencode "$search")")
    [[ -n "$order_by" ]] && params+=("order_by=${order_by}")

    local query_string=""
    if [[ ${#params[@]} -gt 0 ]]; then
        query_string="?$(IFS='&'; echo "${params[*]}")"
    fi

    gitlab_api GET "/groups${query_string}"
}

# Get a single group
# Usage: gitlab_get_group <group_id>
gitlab_get_group() {
    local group_id="$1"

    gitlab_api GET "/groups/$(urlencode "$group_id")"
}

# Create a new group
# Usage: gitlab_create_group <name> <path> [visibility] [description] [parent_id]
gitlab_create_group() {
    local name="$1"
    local path="$2"
    local visibility="${3:-}"
    local description="${4:-}"
    local parent_id="${5:-}"

    local data
    data=$(cat <<EOF
{
    "name": "${name}",
    "path": "${path}"
EOF
    )

    [[ -n "$visibility" ]] && data+=", \"visibility\": \"${visibility}\""
    [[ -n "$description" ]] && data+=", \"description\": \"${description}\""
    [[ -n "$parent_id" ]] && data+=", \"parent_id\": ${parent_id}"
    data+="}"

    gitlab_api POST "/groups" "$data"
}

# Update an existing group
# Usage: gitlab_update_group <group_id> <json_data>
gitlab_update_group() {
    local group_id="$1"
    local json_data="$2"

    gitlab_api PUT "/groups/$(urlencode "$group_id")" "$json_data"
}

# Delete a group
# Usage: gitlab_delete_group <group_id>
gitlab_delete_group() {
    local group_id="$1"

    gitlab_api DELETE "/groups/$(urlencode "$group_id")"
}

# ---------------------------------------------------------------------------
# Subgroups
# ---------------------------------------------------------------------------

# List direct subgroups of a group
# Usage: gitlab_list_subgroups <group_id>
gitlab_list_subgroups() {
    local group_id="$1"

    gitlab_api GET "/groups/$(urlencode "$group_id")/subgroups"
}

# ---------------------------------------------------------------------------
# Group Projects
# ---------------------------------------------------------------------------

# List projects belonging to a group
# Usage: gitlab_list_group_projects <group_id>
gitlab_list_group_projects() {
    local group_id="$1"

    gitlab_api GET "/groups/$(urlencode "$group_id")/projects"
}

# ---------------------------------------------------------------------------
# Group Sharing
# ---------------------------------------------------------------------------

# Share a group with another group
# Usage: gitlab_share_group_with_group <group_id> <share_group_id> <group_access>
gitlab_share_group_with_group() {
    local group_id="$1"
    local share_group_id="$2"
    local group_access="$3"

    local data="{\"group_id\": ${share_group_id}, \"group_access\": ${group_access}}"

    gitlab_api POST "/groups/$(urlencode "$group_id")/share" "$data"
}
