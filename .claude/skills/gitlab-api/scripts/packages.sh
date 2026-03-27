#!/usr/bin/env bash
#
# GitLab Packages API functions
# Requires: common.sh (provides gitlab_api, urlencode, GITLAB_URL, GITLAB_TOKEN)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# ---------------------------------------------------------------------------
# Package Registry
# ---------------------------------------------------------------------------

# List packages for a project
# Usage: gitlab_list_packages <project_id> [package_type] [package_name]
gitlab_list_packages() {
    local project_id="$1"
    local package_type="${2:-}"
    local package_name="${3:-}"

    local params=()
    [[ -n "$package_type" ]] && params+=("package_type=${package_type}")
    [[ -n "$package_name" ]] && params+=("package_name=$(urlencode "$package_name")")

    local query_string=""
    if [[ ${#params[@]} -gt 0 ]]; then
        query_string="?$(IFS='&'; echo "${params[*]}")"
    fi

    gitlab_api GET "/projects/$(urlencode "$project_id")/packages${query_string}"
}

# List packages for a group
# Usage: gitlab_list_group_packages <group_id> [package_type] [package_name]
gitlab_list_group_packages() {
    local group_id="$1"
    local package_type="${2:-}"
    local package_name="${3:-}"

    local params=()
    [[ -n "$package_type" ]] && params+=("package_type=${package_type}")
    [[ -n "$package_name" ]] && params+=("package_name=$(urlencode "$package_name")")

    local query_string=""
    if [[ ${#params[@]} -gt 0 ]]; then
        query_string="?$(IFS='&'; echo "${params[*]}")"
    fi

    gitlab_api GET "/groups/$(urlencode "$group_id")/packages${query_string}"
}

# Get a single package
# Usage: gitlab_get_package <project_id> <package_id>
gitlab_get_package() {
    local project_id="$1"
    local package_id="$2"

    gitlab_api GET "/projects/$(urlencode "$project_id")/packages/${package_id}"
}

# Delete a package
# Usage: gitlab_delete_package <project_id> <package_id>
gitlab_delete_package() {
    local project_id="$1"
    local package_id="$2"

    gitlab_api DELETE "/projects/$(urlencode "$project_id")/packages/${package_id}"
}

# List files for a package
# Usage: gitlab_list_package_files <project_id> <package_id>
gitlab_list_package_files() {
    local project_id="$1"
    local package_id="$2"

    gitlab_api GET "/projects/$(urlencode "$project_id")/packages/${package_id}/package_files"
}

# ---------------------------------------------------------------------------
# Generic Packages
# ---------------------------------------------------------------------------

# Upload a file to the generic package registry
# Usage: gitlab_upload_generic_package <project_id> <package_name> <version> <file_name> <file_path>
gitlab_upload_generic_package() {
    local project_id="$1"
    local package_name="$2"
    local version="$3"
    local file_name="$4"
    local file_path="$5"

    if [[ ! -f "$file_path" ]]; then
        echo "ERROR: File not found: ${file_path}" >&2
        return 1
    fi

    local url="${GITLAB_API_BASE}/projects/$(urlencode "$project_id")/packages/generic/$(urlencode "$package_name")/$(urlencode "$version")/$(urlencode "$file_name")"

    local response
    response=$(curl -s -w "\n%{http_code}" \
        -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        -H "Content-Type: application/octet-stream" \
        -X PUT \
        --upload-file "$file_path" \
        "$url")

    local http_code
    http_code=$(echo "$response" | tail -1)
    local body
    body=$(echo "$response" | sed '$d')

    if [[ "$http_code" -ge 400 ]]; then
        echo "ERROR: HTTP ${http_code} uploading generic package" >&2
        echo "$body" >&2
        return 1
    fi

    echo "$body"
}

# Download a file from the generic package registry
# Usage: gitlab_download_generic_package <project_id> <package_name> <version> <file_name> [output_path]
gitlab_download_generic_package() {
    local project_id="$1"
    local package_name="$2"
    local version="$3"
    local file_name="$4"
    local output_path="${5:-$file_name}"

    local url="${GITLAB_API_BASE}/projects/$(urlencode "$project_id")/packages/generic/$(urlencode "$package_name")/$(urlencode "$version")/$(urlencode "$file_name")"

    local http_code
    http_code=$(curl -s -w "%{http_code}" \
        -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        -o "$output_path" \
        "$url")

    if [[ "$http_code" -ge 400 ]]; then
        echo "ERROR: HTTP ${http_code} downloading generic package" >&2
        [[ -f "$output_path" ]] && cat "$output_path" >&2
        return 1
    fi

    echo "$output_path"
}
