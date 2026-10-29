#!/usr/bin/env bash
# about: Nano power-down sleep woken by the watchdog every 8 s, wear-levelled EEPROM boot counter; size and vector checks
# Usage (through ./arduino-box examples ...): example.sh build | test | run [nano]
#   test checks the image fits the Nano (30720 B flash, 2048 B RAM) and the WDT interrupt vector (__vector_6) is linked.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ALL_BOARDS=(nano)
ex_extra_test() { ex_elf nano --machine AVR --symbol __vector_6 --max-text 30720 --max-data 2048; }
ex_main "$@"
