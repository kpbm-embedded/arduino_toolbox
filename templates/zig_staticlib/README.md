# @NAME@

Arduino sketch with a Zig part (`zig/@NAME@.zig`, freestanding, C ABI), made by `arduino-box new zig_staticlib @NAME@`
(32_13_arduino). Zig is not part of 32_13_arduino: `build.sh` reaches 32_24_microzig (`$BOX_MICROZIG`, or the
folder next to 32_13_arduino) and exits 3 when it is missing.

```sh
arduino-box run "$PWD/build.sh" pico                  # zig build-lib (cortex_m0plus) -> build/libraries/@NAME@_zig -> compile
arduino-box run "$PWD/build.sh" blackpill             # cortex_m4, hard float
"$BOX_MICROZIG/microzig-box" zig test zig/@NAME@.zig   # host tests of the Zig code
```

The header stays in `zig/include/`: a header next to the `.ino` would hide the library from arduino-cli's discovery
and the link fails with undefined references. Arduino looks for the archive in `src/<build.mcu>/`.
