#!/usr/bin/env bash
# about: LED_BUILTIN toggle + uptime on Serial, compiled for Nano, ESP32-S3, Pico, BlackPill F411
# Usage (through ./arduino-box examples ...): example.sh build | test | run [nano|esp32s3|pico|blackpill ...]
#   build/test compile into $OUT/build/sketches/blink/<board>; run prints the upload plan (never uploads).
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ex_main "$@"
