#!/usr/bin/env bash
# about: sketch logic (ring buffer, CRC-16/CCITT) unit-tested on the PC with g++ (pixi env), then compiled for Nano/Pico/BlackPill
# Usage (through ./arduino-box examples ...): example.sh build | test | run [boards ...]
#   test: host unit tests first (tests/test_logic.cpp, no Arduino headers), then the firmware builds.
#   arduino-cli ignores tests/ (it only compiles the sketch folder and src/).
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ALL_BOARDS=(nano pico blackpill)
host_test() {
  echo "== host unit tests (${CXX:-c++})"
  mkdir -p "${EX_OUT:?}"
  "${CXX:-c++}" -std=c++17 -Wall -Wextra -Werror -I "$EX_DIR/src" "$EX_DIR/tests/test_logic.cpp" "$EX_DIR/src/crc16.cpp" -o "$EX_OUT/test_logic"
  "$EX_OUT/test_logic"
}
if [[ "${1:-}" == test ]]; then host_test; fi
ex_main "$@"
