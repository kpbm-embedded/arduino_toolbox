#!/usr/bin/env bash
# about: version/build-id injected with --build-property compiler.cpp.extra_flags; string checked in the ELF (Nano, Pico, WeAct H743)
# Usage (through ./arduino-box examples ...): example.sh build | test | run [boards ...]
#   FW_MAJOR/FW_MINOR/FW_PATCH/FW_BUILD come from the command line (no source edit); test checks "fw 2.7.13+<id>" in the image.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ALL_BOARDS=(nano pico weact_h743)
BUILD_ID=${BUILD_ID:-4242}
FLAGS="-DFW_MAJOR=2 -DFW_MINOR=7 -DFW_PATCH=13 -DFW_BUILD=$BUILD_ID"
ex_build() { # [boards...]
  local board
  if [[ $# -eq 0 ]]; then set -- "${ALL_BOARDS[@]}"; fi
  for board in "$@"; do
    echo "== $SKETCH for $board ($FLAGS)"
    "$BOX" compile "$EX_DIR" "$board" --build-property "compiler.cpp.extra_flags=$FLAGS"
  done
}
ex_extra_test() {
  local board
  for board in "$@"; do ex_elf "$board" --string "fw 2.7.13+$BUILD_ID"; done
}
ex_main "$@"
