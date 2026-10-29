# @NAME@

Arduino sketch with a Rust part (`rust/`, `no_std` staticlib, C ABI), made by `arduino-box new rust_staticlib @NAME@`
(32_13_arduino). The Rust toolchain is not part of 32_13_arduino: `build.sh` reaches 32_17_embedded_rust
(`$BOX_EMBEDDED_RUST`, or the folder next to 32_13_arduino) and exits 3 when it is missing.

```sh
arduino-box run "$PWD/build.sh" pico                  # cargo build (thumbv6m) -> build/libraries/@NAME@_rs -> compile
arduino-box run "$PWD/build.sh" blackpill             # thumbv7em-none-eabihf, cortex-m4
"$BOX_EMBEDDED_RUST/rust-box" cargo test --manifest-path rust/Cargo.toml   # host tests of the Rust code
```

The header stays in `rust/include/`: a header next to the `.ino` would hide the library from arduino-cli's discovery
and the link fails with undefined references. Arduino looks for the archive in `src/<build.mcu>/`.
