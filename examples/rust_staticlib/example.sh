#!/usr/bin/env bash
# about: Rust no_std staticlib (32_17_embedded_rust toolchain) as a precompiled Arduino library on Pico + BlackPill; host test + ELF checks
# Usage (through ./arduino-box examples ...): example.sh build | test | run [pico|blackpill]
#   Reaches rust-box via $BOX_EMBEDDED_RUST or the sibling folder ../32_17_embedded_rust (exit 3 = skip when missing).
#   Targets: pico -> thumbv6m-none-eabi (src/cortex-m0plus), blackpill -> thumbv7em-none-eabihf (src/cortex-m4: STM32duino's fpu folder name would be "-mfpu=fpv4-sp-d16--mfloat-abi=hard").
#   The header lives in rust/include (not next to the .ino): a header in the sketch folder hides the library from discovery.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ALL_BOARDS=(pico blackpill)
RUST_BOX=$(sibling_tool BOX_EMBEDDED_RUST 32_17_embedded_rust rust-box)
[[ -n "$RUST_BOX" ]] || { echo "skip: 32_17_embedded_rust not found (BOX_EMBEDDED_RUST)"; exit 3; }
LIB=""
rust_lib() { # build the static libraries once per run, then the precompiled library folder
  local target dir archives="${EX_OUT:?}/archives"
  for pair in "thumbv6m-none-eabi cortex-m0plus" "thumbv7em-none-eabihf cortex-m4"; do
    read -r target dir <<<"$pair"
    echo "== cargo build --release --target $target (rust-box)"
    RUST_BOX_TARGET_DIR="$EX_OUT/cargo-target" "$RUST_BOX" cargo build --release --target "$target" \
      --manifest-path "$EX_DIR/rust/Cargo.toml"
    mkdir -p "$archives/$dir"
    cp "$EX_OUT/cargo-target/$target/release/libbox_rust_dsp.a" "$archives/$dir/"
  done
  LIB=$(precompiled_lib box_rust_dsp "$EX_DIR/rust/include/box_rust_dsp.h" "$archives" | tail -1)
}
ex_build() { # [boards...]
  local board
  if [[ $# -eq 0 ]]; then set -- "${ALL_BOARDS[@]}"; fi
  [[ -n "$LIB" ]] || rust_lib
  for board in "$@"; do
    echo "== $SKETCH for $board (--library $LIB)"
    "$BOX" compile "$EX_DIR" "$board" --library "$LIB"
  done
}
ex_extra_test() {
  local board
  for board in "$@"; do ex_elf "$board" --machine ARM --symbol rust_crc32 --symbol rust_ema_q16; done
  echo "== cargo test on the host (same crate, rust-box toolchain)"
  RUST_BOX_TARGET_DIR="$EX_OUT/cargo-target" "$RUST_BOX" cargo test --manifest-path "$EX_DIR/rust/Cargo.toml" --lib
}
ex_main "$@"
