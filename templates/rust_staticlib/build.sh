#!/usr/bin/env bash
# build.sh [board]: build rust/ (no_std staticlib) with 32_17_embedded_rust's pinned toolchain, wrap it as a
# precompiled Arduino library in build/libraries/@NAME@_rs, then compile the sketch with --library.
# Run through arduino-box so both launchers are found:  arduino-box run "$PWD/build.sh" pico
# Boards: pico (thumbv6m), blackpill | weact_g431 | nicenano (thumbv7em-hf, cortex-m4), weact_h743 (cortex-m7).
# Exit 3 when 32_17_embedded_rust is not found ($BOX_EMBEDDED_RUST or next to 32_13_arduino).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
board=${1:-pico}
case "$board" in
  pico) target=thumbv6m-none-eabi mcu=cortex-m0plus ;;
  blackpill|weact_g431|nicenano) target=thumbv7em-none-eabihf mcu=cortex-m4 ;;
  weact_h743) target=thumbv7em-none-eabihf mcu=cortex-m7 ;;
  *) echo "usage: build.sh [pico|blackpill|weact_g431|nicenano|weact_h743]" >&2; exit 2 ;;
esac
arduino_box=${ARDUINO_BOX_ROOT:+$ARDUINO_BOX_ROOT/arduino-box}
arduino_box=${arduino_box:-$(command -v arduino-box || true)}
[[ -n "$arduino_box" ]] || { echo "build.sh: run it with: arduino-box run \"\$PWD/build.sh\" $board" >&2; exit 2; }
rust_box=""
for d in "${BOX_EMBEDDED_RUST:-}" "$(dirname "$arduino_box")/../32_17_embedded_rust"; do
  if [[ -n "$d" && -x "$d/rust-box" ]]; then rust_box="$d/rust-box"; break; fi
done
[[ -n "$rust_box" ]] || { echo "skip: 32_17_embedded_rust not found (BOX_EMBEDDED_RUST)"; exit 3; }

out="$here/build"
lib="$out/libraries/@NAME@_rs"
RUST_BOX_TARGET_DIR="$out/cargo-target" "$rust_box" cargo build --release --target "$target" --manifest-path "$here/rust/Cargo.toml"
mkdir -p "$lib/src/$mcu"
cp "$here/rust/include/@NAME@_rs.h" "$lib/src/"
cp "$out/cargo-target/$target/release/lib@NAME@_rs.a" "$lib/src/$mcu/"
cat >"$lib/library.properties" <<PROPS
name=@NAME@_rs
version=0.1.0
author=you
maintainer=you
sentence=Rust part of @NAME@ (precompiled)
paragraph=built by build.sh
category=Other
url=https://example.com
architectures=*
precompiled=true
ldflags=-l@NAME@_rs
includes=@NAME@_rs.h
PROPS
"$arduino_box" compile "$here" "$board" --library "$lib"
