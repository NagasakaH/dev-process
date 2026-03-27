#!/usr/bin/env bash
#
# GitLab Snippets API functions
# Requires: common.sh (provides gitlab_api, GITLAB_URL, GITLAB_TOKEN)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# ---------------------------------------------------------------------------
# Personal Snippets
# ---------------------------------------------------------------------------

# List the authenticated user's snippets
# Usage: gitlab_list_snippets
gitlab_list_snippets() {
    gitlab_api GET "/snippets"
}

# List all public snippets
# Usage: gitlab_list_public_snippets
gitlab_list_public_snippets() {
    gitlab_api GET "/snippets/public"
}

# Get a single snippet
# Usage: gitlab_get_snippet <snippet_id>
gitlab_get_snippet() {
    local snippet_id="$1"

    gitlab_api GET "/snippets/${snippet_id}"
}

# Get raw content of a snippet
# Usage: gitlab_get_snippet_raw <snippet_id>
gitlab_get_snippet_raw() {
    local snippet_id="$1"

    gitlab_api GET "/snippets/${snippet_id}/raw"
}

# Create a personal snippet
# Usage: gitlab_create_snippet <title> <file_name> <content> <visibility>
# Visibility: private, internal, public
gitlab_create_snippet() {
    local title="$1"
    local file_name="$2"
    local content="$3"
    local visibility="$4"

    local data
    data=$(cat <<EOF
{
    "title": "${title}",
    "file_name": "${file_name}",
    "content": "${content}",
    "visibility": "${visibility}"
}
EOF
    )

    gitlab_api POST "/snippets" "$data"
}

# Update a personal snippet
# Usage: gitlab_update_snippet <snippet_id> <json_data>
gitlab_update_snippet() {
    local snippet_id="$1"
    local json_data="$2"

    gitlab_api PUT "/snippets/${snippet_id}" "$json_data"
}

# Delete a personal snippet
# Usage: gitlab_delete_snippet <snippet_id>
gitlab_delete_snippet() {
    local snippet_id="$1"

    gitlab_api DELETE "/snippets/${snippet_id}"
}

# ---------------------------------------------------------------------------
# Project Snippets
# ---------------------------------------------------------------------------

# List snippets for a project
# Usage: gitlab_list_project_snippets <project_id>
gitlab_list_project_snippets() {
    local project_id="$1"

    gitlab_api GET "/projects/$(urlencode "$project_id")/snippets"
}

# Get a single project snippet
# Usage: gitlab_get_project_snippet <project_id> <snippet_id>
gitlab_get_project_snippet() {
    local project_id="$1"
    local snippet_id="$2"

    gitlab_api GET "/projects/$(urlencode "$project_id")/snippets/${snippet_id}"
}

# Get raw content of a project snippet
# Usage: gitlab_get_project_snippet_raw <project_id> <snippet_id>
gitlab_get_project_snippet_raw() {
    local project_id="$1"
    local snippet_id="$2"

    gitlab_api GET "/projects/$(urlencode "$project_id")/snippets/${snippet_id}/raw"
}

# Create a project snippet
# Usage: gitlab_create_project_snippet <project_id> <title> <file_name> <content> <visibility>
# Visibility: private, internal, public
gitlab_create_project_snippet() {
    local project_id="$1"
    local title="$2"
    local file_name="$3"
    local content="$4"
    local visibility="$5"

    local data
    data=$(cat <<EOF
{
    "title": "${title}",
    "file_name": "${file_name}",
    "content": "${content}",
    "visibility": "${visibility}"
}
EOF
    )

    gitlab_api POST "/projects/$(urlencode "$project_id")/snippets" "$data"
}

# Delete a project snippet
# Usage: gitlab_delete_project_snippet <project_id> <snippet_id>
gitlab_delete_project_snippet() {
    local project_id="$1"
    local snippet_id="$2"

    gitlab_api DELETE "/projects/$(urlencode "$project_id")/snippets/${snippet_id}"
}
