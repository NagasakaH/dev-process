#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_SCRIPT="${REPO_ROOT}/scripts/dev-container.sh"

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

assert_equal() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [[ "${expected}" != "${actual}" ]]; then
    log_error "FAIL: ${message} (expected: ${expected}, actual: ${actual})"
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

write_fake_docker() {
  local docker_bin="$1"

  cat > "${docker_bin}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >> "${FAKE_DOCKER_LOG}"

case "${1:-}" in
  ps)
    echo "${FAKE_CONTAINER_NAME}"
    ;;
  exec)
    if [[ "${FAKE_TMUX_FAIL:-0}" == "1" && "$*" == *"tmux attach-session"* ]]; then
      exit 1
    fi
    ;;
  *)
    echo "unexpected docker invocation: $*" >&2
    exit 1
    ;;
esac
EOF

  chmod +x "${docker_bin}"
}

run_shell_command() {
  local log_file="$1"
  local tmux_fail="${2:-0}"
  local temp_dir
  local status=0

  temp_dir="$(mktemp -d)"
  write_fake_docker "${temp_dir}/docker"

  PATH="${temp_dir}:${PATH}" \
    FAKE_DOCKER_LOG="${log_file}" \
    FAKE_CONTAINER_NAME="dev-process-test" \
    FAKE_TMUX_FAIL="${tmux_fail}" \
    "${TARGET_SCRIPT}" shell >/dev/null 2>&1 || status=$?

  rm -rf "${temp_dir}"
  return "${status}"
}

test_shell_uses_vscode_for_tmux() {
  local temp_dir log_file log_output
  local status=0

  temp_dir="$(mktemp -d)"
  log_file="${temp_dir}/docker.log"

  run_shell_command "${log_file}"
  log_output="$(cat "${log_file}")"

  assert_contains "${log_output}" "exec -it --user vscode dev-process-test tmux attach-session -t dev-process" \
    "shell should try tmux as the vscode user" || status=1

  rm -rf "${temp_dir}"
  return "${status}"
}

test_shell_falls_back_to_vscode_bash() {
  local temp_dir log_file log_output bash_execs
  local status=0

  temp_dir="$(mktemp -d)"
  log_file="${temp_dir}/docker.log"

  run_shell_command "${log_file}" 1
  log_output="$(cat "${log_file}")"
  bash_execs="$(grep -c "exec -it --user vscode dev-process-test bash" "${log_file}" || true)"

  assert_contains "${log_output}" "exec -it --user vscode dev-process-test tmux attach-session -t dev-process" \
    "shell should still try tmux first as the vscode user" || status=1
  assert_equal "1" "${bash_execs}" "shell should fall back to a vscode bash session" || status=1

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

run_test test_shell_uses_vscode_for_tmux
run_test test_shell_falls_back_to_vscode_bash
print_summary
