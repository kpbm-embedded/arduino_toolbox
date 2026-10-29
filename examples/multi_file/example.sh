#!/usr/bin/env bash
# about: multi-file sketch (.ino + config.h + src/ module, C and C++), Nano/Pico/BlackPill/WeAct G431; ELF symbol check
# Usage (through ./arduino-box examples ...): example.sh build | test | run [boards ...]
#   arduino-cli compiles every .cpp/.c in the sketch folder and, recursively, in src/; src/ needs relative includes.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ALL_BOARDS=(nano pico blackpill weact_g431)
ex_extra_test() {
  local board
  for board in "$@"; do
    # AVR builds use LTO: the small functions are inlined into main, so only the image is checked there
    if [[ "$board" == nano ]]; then ex_elf nano --machine AVR --symbol main --max-text 30720 --max-data 2048
    else ex_elf "$board" --machine ARM --symbol LedPattern6update --symbol checksum8 --symbol setup --symbol loop; fi
  done
}
ex_main "$@"
