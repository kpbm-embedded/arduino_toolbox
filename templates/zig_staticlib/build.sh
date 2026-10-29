#!/usr/bin/env bash
# build.sh [board]: build zig/@NAME@.zig with 32_24_microzig's pinned Zig, wrap it as a precompiled Arduino
# library in build/libraries/@NAME@_zig, then compile the sketch with --library.
# Run through arduino-box so both launchers are found:  arduino-box run "$PWD/build.sh" pico
# Boards: pico (cortex_m0plus), blackpill | weact_g431 | nicenano (cortex_m4, hard float), weact_h743 (cortex_m7).
# Exit 3 when 32_24_microzig is not found ($BOX_MICROZIG or next to 32_13_arduino).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
board=${1:-pico}
case "$board" in
  pico) target=thumb-freestanding-eabi cpu=cortex_m0plus mcu=cortex-m0plus ;;
  blackpill|weact_g431|nicenano) target=thumb-freestanding-eabihf cpu=cortex_m4 mcu=cortex-m4 ;;
  weact_h743) target=thumb-freestanding-eabihf cpu=cortex_m7 mcu=cortex-m7 ;;
  *) echo "usage: build.sh [pico|blackpill|weact_g431|nicenano|weact_h743]" >&2; exit 2 ;;
esac
arduino_box=${ARDUINO_BOX_ROOT:+$ARDUINO_BOX_ROOT/arduino-box}
arduino_box=${arduino_box:-$(command -v arduino-box || true)}
[[ -n "$arduino_box" ]] || { echo "build.sh: run it with: arduino-box run \"\$PWD/build.sh\" $board" >&2; exit 2; }
zig_box=""
for d in "${BOX_MICROZIG:-}" "$(dirname "$arduino_box")/../32_24_microzig"; do
  if [[ -n "$d" && -x "$d/microzig-box" ]]; then zig_box="$d/microzig-box"; break; fi
done
[[ -n "$zig_box" ]] || { echo "skip: 32_24_microzig not found (BOX_MICROZIG)"; exit 3; }

lib="$here/build/libraries/@NAME@_zig"
mkdir -p "$lib/src/$mcu"
# -fno-compiler-rt: 64-bit math helpers come from the core's libgcc at link time
"$zig_box" zig build-lib -static -target "$target" -mcpu "$cpu" -O ReleaseSmall -fno-compiler-rt \
  "$here/zig/@NAME@.zig" -femit-bin="$lib/src/$mcu/lib@NAME@_zig.a"
cp "$here/zig/include/@NAME@_zig.h" "$lib/src/"
cat >"$lib/library.properties" <<PROPS
name=@NAME@_zig
version=0.1.0
author=you
maintainer=you
sentence=Zig part of @NAME@ (precompiled)
paragraph=built by build.sh
category=Other
url=https://example.com
architectures=*
precompiled=true
ldflags=-l@NAME@_zig
includes=@NAME@_zig.h
PROPS
"$arduino_box" compile "$here" "$board" --library "$lib"
