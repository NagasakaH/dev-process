#!/usr/bin/env bash
#
# GitLab Admin & System API functions
# Requires: common.sh (provides gitlab_api, GITLAB_URL, GITLAB_TOKEN)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# ---------------------------------------------------------------------------
# Metadata
# ---------------------------------------------------------------------------

# Get GitLab instance version
# Usage: gitlab_get_version
gitlab_get_version() {
    gitlab_api GET "/version"
}

# Get GitLab instance metadata
# Usage: gitlab_get_metadata
gitlab_get_metadata() {
    gitlab_api GET "/metadata"
}

# ---------------------------------------------------------------------------
# Features (Feature Flags) — admin only
# ---------------------------------------------------------------------------

# List all feature flags
# Usage: gitlab_list_features
gitlab_list_features() {
    gitlab_api GET "/features"
}

# Set or create a feature flag
# Usage: gitlab_set_feature <name> <value> [key] [user] [group] [project]
#   value: true, false, or integer percentage
gitlab_set_feature() {
    local name="$1"
    local value="$2"
    local key="${3:-}"
    local user="${4:-}"
    local group="${5:-}"
    local project="${6:-}"

    local data="{\"value\": \"${value}\""
    [[ -n "$key" ]] && data+=", \"key\": \"${key}\""
    [[ -n "$user" ]] && data+=", \"user\": \"${user}\""
    [[ -n "$group" ]] && data+=", \"group\": \"${group}\""
    [[ -n "$project" ]] && data+=", \"project\": \"${project}\""
    data+="}"

    gitlab_api POST "/features/$(urlencode "$name")" "$data"
}

# Delete a feature flag
# Usage: gitlab_delete_feature <name>
gitlab_delete_feature() {
    local name="$1"

    gitlab_api DELETE "/features/$(urlencode "$name")"
}

# ---------------------------------------------------------------------------
# Broadcast Messages
# ---------------------------------------------------------------------------

# List all broadcast messages
# Usage: gitlab_list_broadcast_messages
gitlab_list_broadcast_messages() {
    gitlab_api GET "/broadcast_messages"
}

# Create a broadcast message
# Usage: gitlab_create_broadcast_message <message> [starts_at] [ends_at] [color] [font]
gitlab_create_broadcast_message() {
    local message="$1"
    local starts_at="${2:-}"
    local ends_at="${3:-}"
    local color="${4:-}"
    local font="${5:-}"

    local data="{\"message\": \"${message}\""
    [[ -n "$starts_at" ]] && data+=", \"starts_at\": \"${starts_at}\""
    [[ -n "$ends_at" ]] && data+=", \"ends_at\": \"${ends_at}\""
    [[ -n "$color" ]] && data+=", \"color\": \"${color}\""
    [[ -n "$font" ]] && data+=", \"font\": \"${font}\""
    data+="}"

    gitlab_api POST "/broadcast_messages" "$data"
}

# Update a broadcast message
# Usage: gitlab_update_broadcast_message <id> <json_data>
gitlab_update_broadcast_message() {
    local id="$1"
    local json_data="$2"

    gitlab_api PUT "/broadcast_messages/${id}" "$json_data"
}

# Delete a broadcast message
# Usage: gitlab_delete_broadcast_message <id>
gitlab_delete_broadcast_message() {
    local id="$1"

    gitlab_api DELETE "/broadcast_messages/${id}"
}

# ---------------------------------------------------------------------------
# System Hooks — admin only
# ---------------------------------------------------------------------------

# List system hooks
# Usage: gitlab_list_system_hooks
gitlab_list_system_hooks() {
    gitlab_api GET "/hooks"
}

# Add a system hook
# Usage: gitlab_add_system_hook <url> [token] [push_events] [merge_requests_events]
gitlab_add_system_hook() {
    local url="$1"
    local token="${2:-}"
    local push_events="${3:-}"
    local merge_requests_events="${4:-}"

    local data="{\"url\": \"${url}\""
    [[ -n "$token" ]] && data+=", \"token\": \"${token}\""
    [[ -n "$push_events" ]] && data+=", \"push_events\": ${push_events}"
    [[ -n "$merge_requests_events" ]] && data+=", \"merge_requests_events\": ${merge_requests_events}"
    data+="}"

    gitlab_api POST "/hooks" "$data"
}

# Delete a system hook
# Usage: gitlab_delete_system_hook <hook_id>
gitlab_delete_system_hook() {
    local hook_id="$1"

    gitlab_api DELETE "/hooks/${hook_id}"
}

# ---------------------------------------------------------------------------
# Applications (OAuth)
# ---------------------------------------------------------------------------

# List all applications
# Usage: gitlab_list_applications
gitlab_list_applications() {
    gitlab_api GET "/applications"
}

# Create an application
# Usage: gitlab_create_application <name> <redirect_uri> <scopes>
gitlab_create_application() {
    local name="$1"
    local redirect_uri="$2"
    local scopes="$3"

    local data="{\"name\": \"${name}\", \"redirect_uri\": \"${redirect_uri}\", \"scopes\": \"${scopes}\"}"

    gitlab_api POST "/applications" "$data"
}

# Delete an application
# Usage: gitlab_delete_application <id>
gitlab_delete_application() {
    local id="$1"

    gitlab_api DELETE "/applications/${id}"
}

# ---------------------------------------------------------------------------
# Namespaces
# ---------------------------------------------------------------------------

# List namespaces
# Usage: gitlab_list_namespaces [search]
gitlab_list_namespaces() {
    local search="${1:-}"

    local query_string=""
    [[ -n "$search" ]] && query_string="?search=$(urlencode "$search")"

    gitlab_api GET "/namespaces${query_string}"
}

# Get a namespace by ID or path
# Usage: gitlab_get_namespace <namespace_id>
gitlab_get_namespace() {
    local namespace_id="$1"

    gitlab_api GET "/namespaces/$(urlencode "$namespace_id")"
}

# ---------------------------------------------------------------------------
# Application Settings — admin only
# ---------------------------------------------------------------------------

# Get current application settings
# Usage: gitlab_get_settings
gitlab_get_settings() {
    gitlab_api GET "/application/settings"
}

# Update application settings
# Usage: gitlab_update_settings <json_data>
gitlab_update_settings() {
    local json_data="$1"

    gitlab_api PUT "/application/settings" "$json_data"
}
