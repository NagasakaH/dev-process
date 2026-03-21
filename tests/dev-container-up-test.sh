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

write_fake_docker() {
  local docker_bin="$1"

  cat > "${docker_bin}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >> "${FAKE_DOCKER_LOG}"

cmd="${1:-}"
shift || true

case "${cmd}" in
  version)
    echo "${FAKE_DOCKER_VERSION:-24.0.0}"
    ;;
  ps)
    if [[ -f "${FAKE_DOCKER_STATE}" ]]; then
      cat "${FAKE_DOCKER_STATE}"
    fi
    ;;
  run)
    container_name=""
    prev=""
    for arg in "$@"; do
      if [[ "${prev}" == "--name" ]]; then
        container_name="${arg}"
        break
      fi
      prev="${arg}"
    done

    if [[ -z "${container_name}" ]]; then
      echo "missing --name in docker run" >&2
      exit 1
    fi

    printf '%s' "${container_name}" > "${FAKE_DOCKER_STATE}"
    echo "fake-container-id"
    ;;
  exec)
    if [[ "$*" == *"tmux attach-session"* && "${FAKE_TMUX_FAIL:-0}" == "1" ]]; then
      exit 1
    fi
    ;;
  rm | stop)
    rm -f "${FAKE_DOCKER_STATE}"
    ;;
  *)
    echo "unexpected docker invocation: ${cmd} $*" >&2
    exit 1
    ;;
esac
EOF

  chmod +x "${docker_bin}"
}

run_up_command() {
  local log_file="$1"
  local tmux_fail="${2:-0}"
  local temp_dir
  local state_file
  local status=0

  temp_dir="$(mktemp -d)"
  state_file="${temp_dir}/container-name"
  write_fake_docker "${temp_dir}/docker"

  PATH="${temp_dir}:${PATH}" \
    FAKE_DOCKER_LOG="${log_file}" \
    FAKE_DOCKER_STATE="${state_file}" \
    FAKE_TMUX_FAIL="${tmux_fail}" \
    "${TARGET_SCRIPT}" up >/dev/null 2>&1 || status=$?

  rm -rf "${temp_dir}"
  return "${status}"
}

test_up_runs_container_detached_then_enters_tmux() {
  local temp_dir log_file log_output
  local status=0

  temp_dir="$(mktemp -d)"
  log_file="${temp_dir}/docker.log"

  run_up_command "${log_file}"
  log_output="$(cat "${log_file}")"

  assert_contains "${log_output}" "run -d --name" \
    "up should start the container detached" || status=1
  assert_not_contains "${log_output}" "run -it --name" \
    "up should not keep container lifetime tied to docker run tty" || status=1
  assert_contains "${log_output}" "exec -it -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 --user vscode" \
    "up should enter the running container via docker exec" || status=1
  assert_contains "${log_output}" "tmux attach-session -t dev-process" \
    "up should attach to the tmux session after the container starts" || status=1
  assert_contains "${log_output}" ".devcontainer/scripts/start-tmux.sh:/usr/local/bin/start-tmux:ro" \
    "up should mount the local start-tmux script so the latest lifecycle fix is used without rebuilding the image" || status=1
  assert_contains "${log_output}" "-e LANG=C.UTF-8" \
    "up should set a UTF-8 locale for the container" || status=1
  assert_contains "${log_output}" "-e LC_ALL=C.UTF-8" \
    "up should set LC_ALL to UTF-8 for the container" || status=1

  rm -rf "${temp_dir}"
  return "${status}"
}

test_up_falls_back_to_bash_if_tmux_entry_fails() {
  local temp_dir log_file log_output
  local status=0

  temp_dir="$(mktemp -d)"
  log_file="${temp_dir}/docker.log"

  run_up_command "${log_file}" 1
  log_output="$(cat "${log_file}")"

  assert_contains "${log_output}" "run -d --name" \
    "up should still start detached when tmux entry fails" || status=1
  assert_contains "${log_output}" "exec -it -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 --user vscode" \
    "up should try entering the running container" || status=1
  assert_contains "${log_output}" "tmux attach-session -t dev-process" \
    "up should try tmux before falling back" || status=1
  assert_contains "${log_output}" "exec -it -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 --user vscode" \
    "up should use docker exec for the fallback shell too" || status=1
  assert_contains "${log_output}" "bash" \
    "up should fall back to a bash shell when tmux entry fails" || status=1
  assert_contains "${log_output}" ".devcontainer/scripts/start-tmux.sh:/usr/local/bin/start-tmux:ro" \
    "up should still mount the local start-tmux script when tmux entry fails" || status=1
  assert_contains "${log_output}" "-e LANG=C.UTF-8" \
    "up should keep the UTF-8 locale env when tmux entry fails" || status=1
  assert_contains "${log_output}" "-e LC_ALL=C.UTF-8" \
    "up should keep LC_ALL set to UTF-8 when tmux entry fails" || status=1

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

run_test test_up_runs_container_detached_then_enters_tmux
run_test test_up_falls_back_to_bash_if_tmux_entry_fails
print_summary
