#!/usr/bin/env bash
# about: FreeRTOS on ESP32: producer/consumer tasks, queue, mutex, core pinning; ESP32-S3 (Xtensa) + ESP32-C3 (RISC-V)
# Usage (through ./arduino-box examples ...): example.sh build | test | run [esp32s3|esp32c3]
#   test compiles for both chips, then checks the ELF architecture and the FreeRTOS symbols that were linked.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ALL_BOARDS=(esp32s3 esp32c3)
ex_extra_test() {
  local board machine
  for board in "$@"; do
    case "$board" in esp32c3) machine=RISC-V ;; *) machine=Xtensa ;; esac
    ex_elf "$board" --machine "$machine" --symbol xTaskCreatePinnedToCore --symbol xQueueGenericSend \
      --symbol xQueueReceive --symbol xQueueCreateMutex --symbol producerTask --symbol consumerTask
  done
}
ex_main "$@"
