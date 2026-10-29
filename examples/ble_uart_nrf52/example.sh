#!/usr/bin/env bash
# about: BLE UART (Nordic UART Service) + Device Info + battery on nice!nano nRF52840 (Bluefruit, S140); DFU .zip + ELF checks
# Usage (through ./arduino-box examples ...): example.sh build | test | run [nicenano]
#   No radio test here (no board): test checks the DFU package (adafruit-nrfutil from the pixi env) and the linked BLE code.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ALL_BOARDS=(nicenano)
ex_extra_test() {
  local hex
  hex="${BOXT_BUILD:?}/sketches/$SKETCH/nicenano/$SKETCH.ino.hex"
  [[ -s "$hex" ]] || { echo "FAIL  $hex missing"; return 1; }
  # the application must start after the S140 6.1.1 SoftDevice (0x26000) and fit below the bootloader
  ex_elf nicenano --machine ARM --code-from 0x26000 --symbol _ZN7BLEUart5beginEv --symbol _ZN6BLEBas5writeEh \
    --symbol _ZN6BLEDis5beginEv --string box-nrf52 --max-text 815104
}
ex_main "$@"
