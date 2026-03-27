#!/usr/bin/env bash
#
# GitLab Deployments, Environments, Releases, Deploy Keys & Deploy Tokens API functions
# Requires: common.sh (provides gitlab_api, urlencode, GITLAB_URL, GITLAB_TOKEN)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# ---------------------------------------------------------------------------
# Deployments
# ---------------------------------------------------------------------------

# List deployments for a project
# Usage: gitlab_list_deployments <project_id>
gitlab_list_deployments() {
    local project_id="$1"

    gitlab_api GET "/projects/$(urlencode "$project_id")/deployments"
}

# Get a specific deployment
# Usage: gitlab_get_deployment <project_id> <deployment_id>
gitlab_get_deployment() {
    local project_id="$1"
    local deployment_id="$2"

    gitlab_api GET "/projects/$(urlencode "$project_id")/deployments/${deployment_id}"
}

# ---------------------------------------------------------------------------
# Environments
# ---------------------------------------------------------------------------

# List environments for a project
# Usage: gitlab_list_environments <project_id>
gitlab_list_environments() {
    local project_id="$1"

    gitlab_api GET "/projects/$(urlencode "$project_id")/environments"
}

# Create an environment
# Usage: gitlab_create_environment <project_id> <name> [external_url]
gitlab_create_environment() {
    local project_id="$1"
    local name="$2"
    local external_url="${3:-}"

    local data
    data=$(cat <<EOF
{
    "name": "${name}"
EOF
    )

    [[ -n "$external_url" ]] && data+=", \"external_url\": \"${external_url}\""
    data+="}"

    gitlab_api POST "/projects/$(urlencode "$project_id")/environments" "$data"
}

# Stop an environment
# Usage: gitlab_stop_environment <project_id> <environment_id>
gitlab_stop_environment() {
    local project_id="$1"
    local environment_id="$2"

    gitlab_api POST "/projects/$(urlencode "$project_id")/environments/${environment_id}/stop"
}

# Delete an environment
# Usage: gitlab_delete_environment <project_id> <environment_id>
gitlab_delete_environment() {
    local project_id="$1"
    local environment_id="$2"

    gitlab_api DELETE "/projects/$(urlencode "$project_id")/environments/${environment_id}"
}

# ---------------------------------------------------------------------------
# Releases
# ---------------------------------------------------------------------------

# List releases for a project
# Usage: gitlab_list_releases <project_id>
gitlab_list_releases() {
    local project_id="$1"

    gitlab_api GET "/projects/$(urlencode "$project_id")/releases"
}

# Get a specific release by tag name
# Usage: gitlab_get_release <project_id> <tag_name>
gitlab_get_release() {
    local project_id="$1"
    local tag_name="$2"

    gitlab_api GET "/projects/$(urlencode "$project_id")/releases/$(urlencode "$tag_name")"
}

# Create a release
# Usage: gitlab_create_release <project_id> <tag_name> <name> <description>
gitlab_create_release() {
    local project_id="$1"
    local tag_name="$2"
    local name="$3"
    local description="$4"

    local data
    data=$(cat <<EOF
{
    "tag_name": "${tag_name}",
    "name": "${name}",
    "description": "${description}"
}
EOF
    )

    gitlab_api POST "/projects/$(urlencode "$project_id")/releases" "$data"
}

# Update a release
# Usage: gitlab_update_release <project_id> <tag_name> <json_data>
gitlab_update_release() {
    local project_id="$1"
    local tag_name="$2"
    local json_data="$3"

    gitlab_api PUT "/projects/$(urlencode "$project_id")/releases/$(urlencode "$tag_name")" "$json_data"
}

# Delete a release
# Usage: gitlab_delete_release <project_id> <tag_name>
gitlab_delete_release() {
    local project_id="$1"
    local tag_name="$2"

    gitlab_api DELETE "/projects/$(urlencode "$project_id")/releases/$(urlencode "$tag_name")"
}

# ---------------------------------------------------------------------------
# Release Links
# ---------------------------------------------------------------------------

# List links of a release
# Usage: gitlab_list_release_links <project_id> <tag_name>
gitlab_list_release_links() {
    local project_id="$1"
    local tag_name="$2"

    gitlab_api GET "/projects/$(urlencode "$project_id")/releases/$(urlencode "$tag_name")/assets/links"
}

# Create a release link
# Usage: gitlab_create_release_link <project_id> <tag_name> <name> <url>
gitlab_create_release_link() {
    local project_id="$1"
    local tag_name="$2"
    local name="$3"
    local url="$4"

    local data="{\"name\": \"${name}\", \"url\": \"${url}\"}"

    gitlab_api POST "/projects/$(urlencode "$project_id")/releases/$(urlencode "$tag_name")/assets/links" "$data"
}

# ---------------------------------------------------------------------------
# Deploy Keys
# ---------------------------------------------------------------------------

# List deploy keys for a project
# Usage: gitlab_list_deploy_keys <project_id>
gitlab_list_deploy_keys() {
    local project_id="$1"

    gitlab_api GET "/projects/$(urlencode "$project_id")/deploy_keys"
}

# Add a deploy key to a project
# Usage: gitlab_add_deploy_key <project_id> <title> <key> [can_push]
gitlab_add_deploy_key() {
    local project_id="$1"
    local title="$2"
    local key="$3"
    local can_push="${4:-}"

    local data
    data=$(cat <<EOF
{
    "title": "${title}",
    "key": "${key}"
EOF
    )

    [[ -n "$can_push" ]] && data+=", \"can_push\": ${can_push}"
    data+="}"

    gitlab_api POST "/projects/$(urlencode "$project_id")/deploy_keys" "$data"
}

# Delete a deploy key from a project
# Usage: gitlab_delete_deploy_key <project_id> <key_id>
gitlab_delete_deploy_key() {
    local project_id="$1"
    local key_id="$2"

    gitlab_api DELETE "/projects/$(urlencode "$project_id")/deploy_keys/${key_id}"
}

# ---------------------------------------------------------------------------
# Deploy Tokens
# ---------------------------------------------------------------------------

# List deploy tokens for a project
# Usage: gitlab_list_deploy_tokens <project_id>
gitlab_list_deploy_tokens() {
    local project_id="$1"

    gitlab_api GET "/projects/$(urlencode "$project_id")/deploy_tokens"
}

# Create a deploy token for a project
# Usage: gitlab_create_deploy_token <project_id> <name> <scopes> [expires_at]
gitlab_create_deploy_token() {
    local project_id="$1"
    local name="$2"
    local scopes="$3"
    local expires_at="${4:-}"

    local data
    data=$(cat <<EOF
{
    "name": "${name}",
    "scopes": ${scopes}
EOF
    )

    [[ -n "$expires_at" ]] && data+=", \"expires_at\": \"${expires_at}\""
    data+="}"

    gitlab_api POST "/projects/$(urlencode "$project_id")/deploy_tokens" "$data"
}

# Delete a deploy token from a project
# Usage: gitlab_delete_deploy_token <project_id> <token_id>
gitlab_delete_deploy_token() {
    local project_id="$1"
    local token_id="$2"

    gitlab_api DELETE "/projects/$(urlencode "$project_id")/deploy_tokens/${token_id}"
}
