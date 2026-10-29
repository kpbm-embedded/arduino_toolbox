#!/usr/bin/env bash
# about: USB HID keyboard + mouse on Pico / Pico 2 (arduino-pico TinyUSB), debounced button (pinned Bounce2); UF2 + ELF checks
# Usage (through ./arduino-box examples ...): example.sh build | test | run [pico|pico2]
#   No USB host test here (no board): test checks the UF2 and that the HID code and library were linked.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ALL_BOARDS=(pico pico2)
ex_extra_test() {
  local board
  for board in "$@"; do
    ex_elf "$board" --machine ARM --symbol Keyboard --symbol Mouse --symbol Debouncer6update --string "box-hid"
  done
}
ex_main "$@"
