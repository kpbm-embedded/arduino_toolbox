#!/usr/bin/env bash
# about: STM32duino HardwareTimer 1 kHz interrupt, chip UID and HAL tick on BlackPill F411 + WeAct G431/H562/H743; ELF checks
# Usage (through ./arduino-box examples ...): example.sh build | test | run [blackpill|weact_g431|weact_h562|weact_h743]
#   test checks each image: ARM, starts at flash 0x08000000, HardwareTimer and the TIM IRQ handler linked.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ALL_BOARDS=(blackpill weact_g431 weact_h562 weact_h743)
ex_extra_test() {
  local board
  for board in "$@"; do
    ex_elf "$board" --machine ARM --code-from 0x08000000 --symbol HardwareTimer6resume \
      --symbol HAL_TIM_Base_Start --symbol TIM2_IRQHandler --symbol onTick
  done
}
ex_main "$@"
