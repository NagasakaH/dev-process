#!/usr/bin/env bash
#
# GitLab Search API functions
# Requires: common.sh (provides gitlab_api, GITLAB_URL, GITLAB_TOKEN)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# ---------------------------------------------------------------------------
# Global Search
# ---------------------------------------------------------------------------

# Search across all projects the authenticated user has access to
# Usage: gitlab_search_global <scope> <search_query>
# Scopes: projects, issues, merge_requests, milestones, snippet_titles,
#         wiki_blobs, commits, blobs, notes, users
gitlab_search_global() {
    local scope="$1"
    local search_query="$2"

    gitlab_api GET "/search?scope=${scope}&search=$(urlencode "$search_query")"
}

# ---------------------------------------------------------------------------
# Group Search
# ---------------------------------------------------------------------------

# Search within a specific group
# Usage: gitlab_search_group <group_id> <scope> <search_query>
gitlab_search_group() {
    local group_id="$1"
    local scope="$2"
    local search_query="$3"

    gitlab_api GET "/groups/$(urlencode "$group_id")/search?scope=${scope}&search=$(urlencode "$search_query")"
}

# ---------------------------------------------------------------------------
# Project Search
# ---------------------------------------------------------------------------

# Search within a specific project
# Usage: gitlab_search_project <project_id> <scope> <search_query>
gitlab_search_project() {
    local project_id="$1"
    local scope="$2"
    local search_query="$3"

    gitlab_api GET "/projects/$(urlencode "$project_id")/search?scope=${scope}&search=$(urlencode "$search_query")"
}
