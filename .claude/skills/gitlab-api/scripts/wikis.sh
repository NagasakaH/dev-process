#!/usr/bin/env bash
#
# GitLab Wikis API functions
# Requires: common.sh (provides gitlab_api, gitlab_upload, GITLAB_URL, GITLAB_TOKEN)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# ---------------------------------------------------------------------------
# Project Wikis
# ---------------------------------------------------------------------------

# List all wiki pages for a project
# Usage: gitlab_list_wiki_pages <project_id>
gitlab_list_wiki_pages() {
    local project_id="$1"

    gitlab_api GET "/projects/$(urlencode "$project_id")/wikis"
}

# Get a single wiki page by slug
# Usage: gitlab_get_wiki_page <project_id> <slug>
gitlab_get_wiki_page() {
    local project_id="$1"
    local slug="$2"

    gitlab_api GET "/projects/$(urlencode "$project_id")/wikis/$(urlencode "$slug")"
}

# Create a new wiki page
# Usage: gitlab_create_wiki_page <project_id> <title> <content> [format]
# Formats: markdown (default), rdoc, asciidoc, org
gitlab_create_wiki_page() {
    local project_id="$1"
    local title="$2"
    local content="$3"
    local format="${4:-}"

    local data
    data=$(cat <<EOF
{
    "title": "${title}",
    "content": "${content}"
EOF
    )

    [[ -n "$format" ]] && data+=", \"format\": \"${format}\""
    data+="}"

    gitlab_api POST "/projects/$(urlencode "$project_id")/wikis" "$data"
}

# Edit an existing wiki page
# Usage: gitlab_edit_wiki_page <project_id> <slug> <content> [title] [format]
gitlab_edit_wiki_page() {
    local project_id="$1"
    local slug="$2"
    local content="$3"
    local title="${4:-}"
    local format="${5:-}"

    local data
    data=$(cat <<EOF
{
    "content": "${content}"
EOF
    )

    [[ -n "$title" ]] && data+=", \"title\": \"${title}\""
    [[ -n "$format" ]] && data+=", \"format\": \"${format}\""
    data+="}"

    gitlab_api PUT "/projects/$(urlencode "$project_id")/wikis/$(urlencode "$slug")" "$data"
}

# Delete a wiki page
# Usage: gitlab_delete_wiki_page <project_id> <slug>
gitlab_delete_wiki_page() {
    local project_id="$1"
    local slug="$2"

    gitlab_api DELETE "/projects/$(urlencode "$project_id")/wikis/$(urlencode "$slug")"
}

# Upload an attachment to a project wiki
# Usage: gitlab_upload_wiki_attachment <project_id> <file_path>
gitlab_upload_wiki_attachment() {
    local project_id="$1"
    local file_path="$2"

    gitlab_upload "projects/$(urlencode "$project_id")/wikis/attachments" "$file_path" "file"
}
