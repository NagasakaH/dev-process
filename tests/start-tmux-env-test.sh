#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_SCRIPT="${REPO_ROOT}/.devcontainer/scripts/start-tmux.sh"

PASSED=0
FAILED=0
TOTAL=0

log_info() {
  echo "[INFO] $*"
}

log_error() {
  echo "[ERROR] $*" >&2
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if [[ "${haystack}" != *"${needle}"* ]]; then
    log_error "FAIL: ${message} (missing: ${needle})"
    return 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if [[ "${haystack}" == *"${needle}"* ]]; then
    log_error "FAIL: ${message} (unexpected: ${needle})"
    return 1
  fi
}

run_test() {
  local test_name="$1"

  TOTAL=$((TOTAL + 1))
  log_info "Running: ${test_name}"
  if "${test_name}"; then
    PASSED=$((PASSED + 1))
    log_info "PASS: ${test_name}"
  else
    FAILED=$((FAILED + 1))
    log_error "FAIL: ${test_name}"
  fi
}

write_fake_commands() {
  local bin_dir="$1"

  cat >"${bin_dir}/id" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  "-u") echo "0" ;;
  "vscode") exit 0 ;;
  "-u vscode") echo "1000" ;;
  "-g vscode") echo "1000" ;;
  *) /usr/bin/id "$@" ;;
esac
EOF

  cat >"${bin_dir}/su" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${FAKE_SU_LOG}"
exit 0
EOF

  for name in usermod groupmod chown chmod; do
    cat >"${bin_dir}/${name}" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  done

  chmod +x "${bin_dir}/id" "${bin_dir}/su" "${bin_dir}/usermod" "${bin_dir}/groupmod" "${bin_dir}/chown" "${bin_dir}/chmod"
}

test_root_user_switch_preserves_required_environment_names() {
  local temp_dir su_log su_args
  local status=0

  temp_dir="$(mktemp -d)"
  su_log="${temp_dir}/su.log"
  write_fake_commands "${temp_dir}"

  PATH="${temp_dir}:${PATH}" \
    FAKE_SU_LOG="${su_log}" \
    PROJECT_NAME="dev-process" \
    DOCKER_MODE="dood" \
    GITLAB_TOKEN="fake-token-value" \
    GITLAB_URL="https://gitlab.example.com" \
    GITHUB_TOKEN="fake-github-token-value" \
    "${TARGET_SCRIPT}" >/dev/null 2>&1 || status=1

  su_args="$(cat "${su_log}")"
  assert_contains "${su_args}" "--whitelist-environment=PROJECT_NAME,LC_ALL,LANG,DOCKER_MODE,GITLAB_TOKEN,GITLAB_URL,GITHUB_TOKEN" \
    "root user switch should preserve development environment variables by name" || status=1
  assert_not_contains "${su_args}" "fake-token-value" \
    "root user switch should not put the GitLab token value in su command arguments" || status=1
  assert_not_contains "${su_args}" "fake-github-token-value" \
    "root user switch should not put the GitHub token value in su command arguments" || status=1

  rm -rf "${temp_dir}"
  return "${status}"
}

print_summary() {
  echo "================================"
  echo "Total: ${TOTAL}, Passed: ${PASSED}, Failed: ${FAILED}"
  echo "================================"

  if [[ "${FAILED}" -ne 0 ]]; then
    exit 1
  fi
}

run_test test_root_user_switch_preserves_required_environment_names
print_summary
