#!/usr/bin/env bash
# about: both cores on RP2040/RP2350 (setup1/loop1, inter-core FIFO, shared mutex) for Pico and Pico 2; ELF symbol checks
# Usage (through ./arduino-box examples ...): example.sh build | test | run [pico|pico2]
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ALL_BOARDS=(pico pico2)
ex_extra_test() {
  local board
  for board in "$@"; do ex_elf "$board" --machine ARM --symbol setup1 --symbol loop1 --symbol multicore_fifo_push_blocking_inline --symbol mutex_enter_blocking; done
}
ex_main "$@"
