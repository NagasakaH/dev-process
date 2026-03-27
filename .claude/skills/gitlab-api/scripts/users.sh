#!/usr/bin/env bash
#
# GitLab Users API functions
# Covers: Users, Members, Access Requests, Access Tokens, SSH Keys

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# =============================================================================
# Users
# =============================================================================

# List users with optional filters
# Usage: gitlab_list_users [search] [username] [active]
gitlab_list_users() {
    local search="${1:-}"
    local username="${2:-}"
    local active="${3:-}"
    local params=""

    [[ -n "$search" ]] && params="${params}&search=$(urlencode "$search")"
    [[ -n "$username" ]] && params="${params}&username=$(urlencode "$username")"
    [[ -n "$active" ]] && params="${params}&active=${active}"

    gitlab_api GET "/users?per_page=20${params}"
}

# Get a single user by ID
# Usage: gitlab_get_user <user_id>
gitlab_get_user() {
    local user_id="$1"
    [[ -z "$user_id" ]] && { echo "Error: user_id is required" >&2; return 1; }

    gitlab_api GET "/users/${user_id}"
}

# Get the currently authenticated user
# Usage: gitlab_get_current_user
gitlab_get_current_user() {
    gitlab_api GET "/user"
}

# Get a user's status
# Usage: gitlab_get_user_status <user_id>
gitlab_get_user_status() {
    local user_id="$1"
    [[ -z "$user_id" ]] && { echo "Error: user_id is required" >&2; return 1; }

    gitlab_api GET "/users/${user_id}/status"
}

# Set the current user's status
# Usage: gitlab_set_user_status <emoji> <message>
gitlab_set_user_status() {
    local emoji="$1"
    local message="$2"

    local payload
    payload=$(jq -n \
        --arg emoji "$emoji" \
        --arg message "$message" \
        '{emoji: $emoji, message: $message}')

    gitlab_api PUT "/user/status" "$payload"
}

# =============================================================================
# Members
# =============================================================================

# List project members
# Usage: gitlab_list_project_members <project_id>
gitlab_list_project_members() {
    local project_id="$1"
    [[ -z "$project_id" ]] && { echo "Error: project_id is required" >&2; return 1; }

    gitlab_api GET "/projects/$(urlencode "$project_id")/members?per_page=20"
}

# List group members
# Usage: gitlab_list_group_members <group_id>
gitlab_list_group_members() {
    local group_id="$1"
    [[ -z "$group_id" ]] && { echo "Error: group_id is required" >&2; return 1; }

    gitlab_api GET "/groups/$(urlencode "$group_id")/members?per_page=20"
}

# Add a member to a project
# Usage: gitlab_add_project_member <project_id> <user_id> <access_level>
gitlab_add_project_member() {
    local project_id="$1"
    local user_id="$2"
    local access_level="$3"
    [[ -z "$project_id" || -z "$user_id" || -z "$access_level" ]] && {
        echo "Error: project_id, user_id, and access_level are required" >&2; return 1
    }

    local payload
    payload=$(jq -n \
        --argjson user_id "$user_id" \
        --argjson access_level "$access_level" \
        '{user_id: $user_id, access_level: $access_level}')

    gitlab_api POST "/projects/$(urlencode "$project_id")/members" "$payload"
}

# Add a member to a group
# Usage: gitlab_add_group_member <group_id> <user_id> <access_level>
gitlab_add_group_member() {
    local group_id="$1"
    local user_id="$2"
    local access_level="$3"
    [[ -z "$group_id" || -z "$user_id" || -z "$access_level" ]] && {
        echo "Error: group_id, user_id, and access_level are required" >&2; return 1
    }

    local payload
    payload=$(jq -n \
        --argjson user_id "$user_id" \
        --argjson access_level "$access_level" \
        '{user_id: $user_id, access_level: $access_level}')

    gitlab_api POST "/groups/$(urlencode "$group_id")/members" "$payload"
}

# Edit a project member's access level
# Usage: gitlab_edit_project_member <project_id> <user_id> <access_level>
gitlab_edit_project_member() {
    local project_id="$1"
    local user_id="$2"
    local access_level="$3"
    [[ -z "$project_id" || -z "$user_id" || -z "$access_level" ]] && {
        echo "Error: project_id, user_id, and access_level are required" >&2; return 1
    }

    local payload
    payload=$(jq -n \
        --argjson access_level "$access_level" \
        '{access_level: $access_level}')

    gitlab_api PUT "/projects/$(urlencode "$project_id")/members/${user_id}" "$payload"
}

# Remove a member from a project
# Usage: gitlab_remove_project_member <project_id> <user_id>
gitlab_remove_project_member() {
    local project_id="$1"
    local user_id="$2"
    [[ -z "$project_id" || -z "$user_id" ]] && {
        echo "Error: project_id and user_id are required" >&2; return 1
    }

    gitlab_api DELETE "/projects/$(urlencode "$project_id")/members/${user_id}"
}

# Remove a member from a group
# Usage: gitlab_remove_group_member <group_id> <user_id>
gitlab_remove_group_member() {
    local group_id="$1"
    local user_id="$2"
    [[ -z "$group_id" || -z "$user_id" ]] && {
        echo "Error: group_id and user_id are required" >&2; return 1
    }

    gitlab_api DELETE "/groups/$(urlencode "$group_id")/members/${user_id}"
}

# =============================================================================
# Access Tokens
# =============================================================================

# List project access tokens
# Usage: gitlab_list_access_tokens <project_id>
gitlab_list_access_tokens() {
    local project_id="$1"
    [[ -z "$project_id" ]] && { echo "Error: project_id is required" >&2; return 1; }

    gitlab_api GET "/projects/$(urlencode "$project_id")/access_tokens"
}

# Create a project access token
# Usage: gitlab_create_access_token <project_id> <name> <scopes> <expires_at>
gitlab_create_access_token() {
    local project_id="$1"
    local name="$2"
    local scopes="$3"
    local expires_at="$4"
    [[ -z "$project_id" || -z "$name" || -z "$scopes" || -z "$expires_at" ]] && {
        echo "Error: project_id, name, scopes, and expires_at are required" >&2; return 1
    }

    local payload
    payload=$(jq -n \
        --arg name "$name" \
        --argjson scopes "$scopes" \
        --arg expires_at "$expires_at" \
        '{name: $name, scopes: $scopes, expires_at: $expires_at}')

    gitlab_api POST "/projects/$(urlencode "$project_id")/access_tokens" "$payload"
}

# Revoke a project access token
# Usage: gitlab_revoke_access_token <project_id> <token_id>
gitlab_revoke_access_token() {
    local project_id="$1"
    local token_id="$2"
    [[ -z "$project_id" || -z "$token_id" ]] && {
        echo "Error: project_id and token_id are required" >&2; return 1
    }

    gitlab_api DELETE "/projects/$(urlencode "$project_id")/access_tokens/${token_id}"
}

# =============================================================================
# SSH Keys
# =============================================================================

# List SSH keys for the current user
# Usage: gitlab_list_ssh_keys
gitlab_list_ssh_keys() {
    gitlab_api GET "/user/keys"
}

# Add an SSH key for the current user
# Usage: gitlab_add_ssh_key <title> <key>
gitlab_add_ssh_key() {
    local title="$1"
    local key="$2"
    [[ -z "$title" || -z "$key" ]] && {
        echo "Error: title and key are required" >&2; return 1
    }

    local payload
    payload=$(jq -n \
        --arg title "$title" \
        --arg key "$key" \
        '{title: $title, key: $key}')

    gitlab_api POST "/user/keys" "$payload"
}

# Delete an SSH key for the current user
# Usage: gitlab_delete_ssh_key <key_id>
gitlab_delete_ssh_key() {
    local key_id="$1"
    [[ -z "$key_id" ]] && { echo "Error: key_id is required" >&2; return 1; }

    gitlab_api DELETE "/user/keys/${key_id}"
}
