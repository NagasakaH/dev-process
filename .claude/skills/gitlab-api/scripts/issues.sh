#!/usr/bin/env bash
#
# GitLab Issues API functions
# Requires: common.sh (provides gitlab_api, GITLAB_URL, GITLAB_TOKEN)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# ---------------------------------------------------------------------------
# Issues
# ---------------------------------------------------------------------------

# List issues globally or for a specific project
# Usage: gitlab_list_issues [project_id] [state] [labels] [search]
gitlab_list_issues() {
    local project_id="${1:-}"
    local state="${2:-}"
    local labels="${3:-}"
    local search="${4:-}"

    local params=()
    [[ -n "$state" ]] && params+=("state=${state}")
    [[ -n "$labels" ]] && params+=("labels=${labels}")
    [[ -n "$search" ]] && params+=("search=$(urlencode "$search")")

    local query_string=""
    if [[ ${#params[@]} -gt 0 ]]; then
        query_string="?$(IFS='&'; echo "${params[*]}")"
    fi

    if [[ -n "$project_id" ]]; then
        gitlab_api GET "/projects/$(urlencode "$project_id")/issues${query_string}"
    else
        gitlab_api GET "/issues${query_string}"
    fi
}

# List issues for a specific project
# Usage: gitlab_list_project_issues <project_id> [state] [labels]
gitlab_list_project_issues() {
    local project_id="$1"
    local state="${2:-}"
    local labels="${3:-}"

    local params=()
    [[ -n "$state" ]] && params+=("state=${state}")
    [[ -n "$labels" ]] && params+=("labels=${labels}")

    local query_string=""
    if [[ ${#params[@]} -gt 0 ]]; then
        query_string="?$(IFS='&'; echo "${params[*]}")"
    fi

    gitlab_api GET "/projects/$(urlencode "$project_id")/issues${query_string}"
}

# List issues for a specific group
# Usage: gitlab_list_group_issues <group_id> [state] [labels]
gitlab_list_group_issues() {
    local group_id="$1"
    local state="${2:-}"
    local labels="${3:-}"

    local params=()
    [[ -n "$state" ]] && params+=("state=${state}")
    [[ -n "$labels" ]] && params+=("labels=${labels}")

    local query_string=""
    if [[ ${#params[@]} -gt 0 ]]; then
        query_string="?$(IFS='&'; echo "${params[*]}")"
    fi

    gitlab_api GET "/groups/$(urlencode "$group_id")/issues${query_string}"
}

# Get a single issue
# Usage: gitlab_get_issue <project_id> <issue_iid>
gitlab_get_issue() {
    local project_id="$1"
    local issue_iid="$2"

    gitlab_api GET "/projects/$(urlencode "$project_id")/issues/${issue_iid}"
}

# Create an issue
# Usage: gitlab_create_issue <project_id> <title> [description] [labels] [assignee_ids] [milestone_id]
gitlab_create_issue() {
    local project_id="$1"
    local title="$2"
    local description="${3:-}"
    local labels="${4:-}"
    local assignee_ids="${5:-}"
    local milestone_id="${6:-}"

    local data
    data=$(cat <<EOF
{
    "title": "${title}"
EOF
    )

    # Build JSON payload incrementally
    [[ -n "$description" ]] && data+=", \"description\": \"${description}\""
    [[ -n "$labels" ]] && data+=", \"labels\": \"${labels}\""
    [[ -n "$assignee_ids" ]] && data+=", \"assignee_ids\": ${assignee_ids}"
    [[ -n "$milestone_id" ]] && data+=", \"milestone_id\": ${milestone_id}"
    data+="}"

    gitlab_api POST "/projects/$(urlencode "$project_id")/issues" "$data"
}

# Edit an issue
# Usage: gitlab_edit_issue <project_id> <issue_iid> <json_data>
gitlab_edit_issue() {
    local project_id="$1"
    local issue_iid="$2"
    local json_data="$3"

    gitlab_api PUT "/projects/$(urlencode "$project_id")/issues/${issue_iid}" "$json_data"
}

# Delete an issue
# Usage: gitlab_delete_issue <project_id> <issue_iid>
gitlab_delete_issue() {
    local project_id="$1"
    local issue_iid="$2"

    gitlab_api DELETE "/projects/$(urlencode "$project_id")/issues/${issue_iid}"
}

# Move an issue to another project
# Usage: gitlab_move_issue <project_id> <issue_iid> <to_project_id>
gitlab_move_issue() {
    local project_id="$1"
    local issue_iid="$2"
    local to_project_id="$3"

    local data="{\"to_project_id\": ${to_project_id}}"

    gitlab_api POST "/projects/$(urlencode "$project_id")/issues/${issue_iid}/move" "$data"
}

# ---------------------------------------------------------------------------
# Issue Notes (Comments)
# ---------------------------------------------------------------------------

# List notes on an issue
# Usage: gitlab_list_issue_notes <project_id> <issue_iid>
gitlab_list_issue_notes() {
    local project_id="$1"
    local issue_iid="$2"

    gitlab_api GET "/projects/$(urlencode "$project_id")/issues/${issue_iid}/notes"
}

# Create a note on an issue
# Usage: gitlab_create_issue_note <project_id> <issue_iid> <body>
gitlab_create_issue_note() {
    local project_id="$1"
    local issue_iid="$2"
    local body="$3"

    local data="{\"body\": \"${body}\"}"

    gitlab_api POST "/projects/$(urlencode "$project_id")/issues/${issue_iid}/notes" "$data"
}

# ---------------------------------------------------------------------------
# Labels
# ---------------------------------------------------------------------------

# List project labels
# Usage: gitlab_list_labels <project_id>
gitlab_list_labels() {
    local project_id="$1"

    gitlab_api GET "/projects/$(urlencode "$project_id")/labels"
}

# Create a project label
# Usage: gitlab_create_label <project_id> <name> <color>
gitlab_create_label() {
    local project_id="$1"
    local name="$2"
    local color="$3"

    local data="{\"name\": \"${name}\", \"color\": \"${color}\"}"

    gitlab_api POST "/projects/$(urlencode "$project_id")/labels" "$data"
}

# ---------------------------------------------------------------------------
# Milestones
# ---------------------------------------------------------------------------

# List project milestones
# Usage: gitlab_list_milestones <project_id>
gitlab_list_milestones() {
    local project_id="$1"

    gitlab_api GET "/projects/$(urlencode "$project_id")/milestones"
}

# Create a project milestone
# Usage: gitlab_create_milestone <project_id> <title>
gitlab_create_milestone() {
    local project_id="$1"
    local title="$2"

    local data="{\"title\": \"${title}\"}"

    gitlab_api POST "/projects/$(urlencode "$project_id")/milestones" "$data"
}
