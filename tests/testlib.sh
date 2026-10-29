#!/usr/bin/env bash
# Shared helpers for tests/test_dry_run.sh and tests/test_smoke.sh (sourced, not run).
# Sets HERE (ID root) and LAUNCHER from TEST_LAUNCHER_NAME; counts results; `finish` prints the
# summary and returns 1 if anything failed. Depends on: timeout, grep; shellcheck (optional).
set -uo pipefail   # no -e: a failing check is counted, not fatal
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck disable=SC2034  # read by the test script that sources this file
LAUNCHER="$HERE/${TEST_LAUNCHER_NAME:?set TEST_LAUNCHER_NAME before sourcing testlib.sh}"
PASSED=0; FAILED=0

ok()  { printf 'ok    %s\n' "$*"; PASSED=$((PASSED + 1)); }
bad() { printf 'FAIL  %s\n' "$*"; FAILED=$((FAILED + 1)); }

check() { # name expected-regex cmd...: passes when cmd exits 0 and its output matches
  local name=$1 pattern=$2 output status
  shift 2
  output=$(timeout 300 "$@" 2>&1); status=$?
  if [[ "$status" -eq 0 ]] && grep -qE -- "$pattern" <<<"$output"; then ok "$name"
  else bad "$name (rc=$status)"; tail -5 <<<"$output" | sed 's/^/      /'; fi
}

check_exit() { # name expected-status cmd...: passes when cmd exits with that status
  local name=$1 wanted=$2 status
  shift 2
  timeout 300 "$@" >/dev/null 2>&1; status=$?
  if [[ "$status" -eq "$wanted" ]]; then ok "$name"; else bad "$name (rc=$status, wanted $wanted)"; fi
}

check_shellcheck() { # file... (relative to HERE)
  local output
  if ! command -v shellcheck >/dev/null; then printf 'skip  shellcheck (not installed)\n'; return 0; fi
  if output=$(cd "$HERE" && shellcheck -x "$@" 2>&1); then ok "shellcheck ($# files)"
  else bad "shellcheck"; head -30 <<<"$output"; fi
}

check_py_compile() { # file... (relative to HERE)
  local file
  for file in "$@"; do
    if (cd "$HERE" && python3 -m py_compile "$file" 2>&1); then ok "py_compile $file"; else bad "py_compile $file"; fi
  done
}

make_temp_dir() { # -> path of a temp dir that is moved to the Trash on exit (never rm)
  TEST_TMP=$(mktemp -d)
  trap 'if command -v trash-put >/dev/null; then trash-put "$TEST_TMP"; fi' EXIT
}

finish() { # suite-name
  echo "$1: $PASSED ok, $FAILED failed"
  [[ "$FAILED" -eq 0 ]]
}
