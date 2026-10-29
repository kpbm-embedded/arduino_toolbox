#!/usr/bin/env bash
# about: Zig static library (32_24_microzig's Zig) as a precompiled Arduino library on Pico + BlackPill; zig test + ELF checks
# Usage (through ./arduino-box examples ...): example.sh build | test | run [pico|blackpill]
#   Reaches microzig-box via $BOX_MICROZIG or the sibling folder ../32_24_microzig (exit 3 = skip when missing).
#   pico -> thumb-freestanding-eabi cortex_m0plus (src/cortex-m0plus), blackpill -> thumb-freestanding-eabihf cortex_m4 (src/cortex-m4).
#   -fno-compiler-rt: 64-bit multiply/divide helpers come from the core's libgcc at link time.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ALL_BOARDS=(pico blackpill)
ZIG_BOX=$(sibling_tool BOX_MICROZIG 32_24_microzig microzig-box)
[[ -n "$ZIG_BOX" ]] || { echo "skip: 32_24_microzig not found (BOX_MICROZIG)"; exit 3; }
LIB=""
zig_lib() {
  local target cpu dir archives="${EX_OUT:?}/archives"
  for triple in "thumb-freestanding-eabi cortex_m0plus cortex-m0plus" "thumb-freestanding-eabihf cortex_m4 cortex-m4"; do
    read -r target cpu dir <<<"$triple"
    echo "== zig build-lib -target $target -mcpu $cpu (microzig-box)"
    mkdir -p "$archives/$dir"
    "$ZIG_BOX" zig build-lib -static -target "$target" -mcpu "$cpu" -O ReleaseSmall -fno-compiler-rt \
      "$EX_DIR/zig/fixed.zig" -femit-bin="$archives/$dir/libbox_zig_dsp.a"
  done
  LIB=$(precompiled_lib box_zig_dsp "$EX_DIR/zig/include/box_zig_dsp.h" "$archives" | tail -1)
}
ex_build() { # [boards...]
  local board
  if [[ $# -eq 0 ]]; then set -- "${ALL_BOARDS[@]}"; fi
  [[ -n "$LIB" ]] || zig_lib
  for board in "$@"; do
    echo "== $SKETCH for $board (--library $LIB)"
    "$BOX" compile "$EX_DIR" "$board" --library "$LIB"
  done
}
ex_extra_test() {
  local board
  for board in "$@"; do ex_elf "$board" --machine ARM --symbol zig_isqrt --symbol zig_scale; done
  echo "== zig test on the host (microzig-box)"
  "$ZIG_BOX" zig test "$EX_DIR/zig/fixed.zig"
}
ex_main "$@"
