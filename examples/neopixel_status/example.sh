#!/usr/bin/env bash
# about: WS2812 status LED with the pinned Adafruit NeoPixel library on ESP32-S3 (GPIO48), ESP32-C3 (GPIO8), Pico, nice!nano
# Usage (through ./arduino-box examples ...): example.sh build | test | run [boards ...]
#   One source, per-board pin in the sketch; test checks the library code was linked into every image.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ALL_BOARDS=(esp32s3 esp32c3 pico nicenano)
ex_extra_test() {
  local board
  for board in "$@"; do ex_elf "$board" --symbol Adafruit_NeoPixel4show --symbol Adafruit_NeoPixel13setPixelColor; done
}
ex_main "$@"
