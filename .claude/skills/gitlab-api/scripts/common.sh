#!/usr/bin/env bash
# Common utilities for GitLab API skill
# Source this file before using any category-specific scripts.

set -euo pipefail

# ---------------------------------------------------------------------------
# Token and URL Resolution
# Priority: Environment variable > $HOME/.config/skills/gitlab/.env > $HOME/.config/skills/.env
# ---------------------------------------------------------------------------

_load_env_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    while IFS='=' read -r key value; do
      # Skip comments and empty lines
      [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
      # Trim whitespace
      key=$(echo "$key" | xargs)
      value=$(echo "$value" | xargs)
      # Remove surrounding quotes from value
      value="${value%\"}"
      value="${value#\"}"
      value="${value%\'}"
      value="${value#\'}"
      echo "$key=$value"
    done < "$file"
  fi
}

_resolve_config() {
  local var_name="$1"
  local current_value="${!var_name:-}"

  # If already set in environment, use it
  if [[ -n "$current_value" ]]; then
    echo "$current_value"
    return
  fi

  # Check $HOME/.config/skills/gitlab/.env
  local gitlab_env="$HOME/.config/skills/gitlab/.env"
  if [[ -f "$gitlab_env" ]]; then
    local val
    val=$(_load_env_file "$gitlab_env" | grep "^${var_name}=" | head -1 | cut -d'=' -f2-)
    if [[ -n "$val" ]]; then
      echo "$val"
      return
    fi
  fi

  # Check $HOME/.config/skills/.env
  local skills_env="$HOME/.config/skills/.env"
  if [[ -f "$skills_env" ]]; then
    local val
    val=$(_load_env_file "$skills_env" | grep "^${var_name}=" | head -1 | cut -d'=' -f2-)
    if [[ -n "$val" ]]; then
      echo "$val"
      return
    fi
  fi

  echo ""
}

# Resolve GITLAB_TOKEN and GITLAB_URL
GITLAB_TOKEN="${GITLAB_TOKEN:-$(_resolve_config GITLAB_TOKEN)}"
GITLAB_URL="${GITLAB_URL:-$(_resolve_config GITLAB_URL)}"

# Default URL if not set
GITLAB_URL="${GITLAB_URL:-https://gitlab.com}"

# Remove trailing slash from URL
GITLAB_URL="${GITLAB_URL%/}"

# Validate token
if [[ -z "$GITLAB_TOKEN" ]]; then
  echo "ERROR: GITLAB_TOKEN is not set." >&2
  echo "Set it via:" >&2
  echo "  1. export GITLAB_TOKEN=glpat-xxx" >&2
  echo "  2. Add to \$HOME/.config/skills/gitlab/.env" >&2
  echo "  3. Add to \$HOME/.config/skills/.env" >&2
  exit 1
fi

# Export for child processes
export GITLAB_TOKEN
export GITLAB_URL

# ---------------------------------------------------------------------------
# API Base URL
# ---------------------------------------------------------------------------

GITLAB_API_BASE="${GITLAB_URL}/api/v4"

# ---------------------------------------------------------------------------
# Helper Functions
# ---------------------------------------------------------------------------

# URL-encode a string (useful for project paths like "namespace/project")
urlencode() {
  local string="$1"
  python3 -c "import urllib.parse; print(urllib.parse.quote('$string', safe=''))" 2>/dev/null \
    || printf '%s' "$string" | curl -Gso /dev/null -w '%{url_effective}' --data-urlencode @- '' | cut -c3-
}

# Core API call function
# Usage: gitlab_api METHOD ENDPOINT [DATA] [EXTRA_CURL_ARGS...]
# Example: gitlab_api GET "/projects"
# Example: gitlab_api POST "/projects" '{"name":"test"}'
gitlab_api() {
  local method="${1:?Method required (GET/POST/PUT/DELETE/PATCH)}"
  local endpoint="${2:?Endpoint required (e.g. /projects)}"
  local data="${3:-}"
  shift 2
  [[ -n "$data" ]] && shift || true

  local url="${GITLAB_API_BASE}${endpoint}"
  local -a curl_args=(
    -s
    -w "\n%{http_code}"
    -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}"
    -H "Content-Type: application/json"
    -X "$method"
  )

  if [[ -n "$data" && "$data" != "" ]]; then
    curl_args+=(-d "$data")
  fi

  # Append any extra curl arguments
  curl_args+=("$@")
  curl_args+=("$url")

  local response
  response=$(curl "${curl_args[@]}")

  local http_code
  http_code=$(echo "$response" | tail -1)
  local body
  body=$(echo "$response" | sed '$d')

  # Check for HTTP errors
  if [[ "$http_code" -ge 400 ]]; then
    echo "ERROR: HTTP ${http_code} from ${method} ${endpoint}" >&2
    echo "$body" >&2
    return 1
  fi

  echo "$body"
}

# Upload a file via multipart form
# Usage: gitlab_upload ENDPOINT FILE_PATH [FORM_FIELD_NAME]
gitlab_upload() {
  local endpoint="${1:?Endpoint required}"
  local file_path="${2:?File path required}"
  local field_name="${3:-file}"

  local url="${GITLAB_API_BASE}${endpoint}"

  local response
  response=$(curl -s -w "\n%{http_code}" \
    -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    -F "${field_name}=@${file_path}" \
    "$url")

  local http_code
  http_code=$(echo "$response" | tail -1)
  local body
  body=$(echo "$response" | sed '$d')

  if [[ "$http_code" -ge 400 ]]; then
    echo "ERROR: HTTP ${http_code} from upload to ${endpoint}" >&2
    echo "$body" >&2
    return 1
  fi

  echo "$body"
}

# Paginate through all results
# Usage: gitlab_paginate ENDPOINT [PER_PAGE]
gitlab_paginate() {
  local endpoint="${1:?Endpoint required}"
  local per_page="${2:-100}"
  local page=1
  local all_results="[]"

  while true; do
    local separator="?"
    [[ "$endpoint" == *"?"* ]] && separator="&"
    local result
    result=$(gitlab_api GET "${endpoint}${separator}per_page=${per_page}&page=${page}")

    if [[ -z "$result" || "$result" == "[]" ]]; then
      break
    fi

    all_results=$(echo "$all_results" "$result" | jq -s 'add')
    local count
    count=$(echo "$result" | jq 'length')
    if [[ "$count" -lt "$per_page" ]]; then
      break
    fi
    page=$((page + 1))
  done

  echo "$all_results"
}

# Pretty print JSON response
pp() {
  echo "$1" | jq '.' 2>/dev/null || echo "$1"
}
