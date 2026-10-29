#!/usr/bin/env bash
# about: line echo at 115200 baud (Serial API only), compiled for all four boards
# Usage (through ./arduino-box examples ...): example.sh build | test | run [nano|esp32s3|pico|blackpill ...]
#   build/test compile into $OUT/build/sketches/serial_echo/<board>; run prints the upload plan (never uploads).
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ex_main "$@"
