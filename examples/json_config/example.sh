#!/usr/bin/env bash
# about: JSON settings with the pinned ArduinoJson (config/libraries.tsv): host test of the parser, builds for Nano/ESP32-S3/Pico
# Usage (through ./arduino-box examples ...): example.sh build | test | run [boards ...]
#   test: tests/test_config.cpp against user/libraries/ArduinoJson on the PC, then the firmware builds + ELF checks.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ALL_BOARDS=(nano esp32s3 pico)
host_test() {
  local aj="$BOXT_ROOT/user/libraries/ArduinoJson/src"
  [[ -r "$aj/ArduinoJson.h" ]] || { echo "FAIL  ArduinoJson not installed: ./arduino-box install"; return 1; }
  echo "== host unit tests with ArduinoJson ($(sed -n 's/^version=//p' "$aj/../library.properties"))"
  mkdir -p "${EX_OUT:?}"
  "${CXX:-c++}" -std=c++17 -Wall -Wextra -Werror -I "$aj" -I "$EX_DIR/src" "$EX_DIR/tests/test_config.cpp" "$EX_DIR/src/settings.cpp" -o "$EX_OUT/test_config"
  "$EX_OUT/test_config"
}
ex_extra_test() {
  local board
  for board in "$@"; do
    [[ "$board" == nano ]] && continue   # LTO inlines the parser on AVR
    ex_elf "$board" --symbol parseSettings --symbol writeSettings
  done
}
if [[ "${1:-}" == test ]]; then host_test; fi
ex_main "$@"
