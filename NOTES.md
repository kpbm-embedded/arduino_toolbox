# 32_13_arduino: notes

## 2026-10-25: created
- New ID in the Box tool style (launcher `arduino-box`, `lib/boxtool.bash` copied unchanged from
  32_10_qemu, md5 b938d4f9...; pixi binary copied from there too). No pixi env: arduino-cli is a
  static binary and the cores bring their own toolchains; pixi stays only because the launcher
  contract bootstraps it.
- Arduino CLI 1.5.1 for all five platforms, sha256 from the release's `1.5.1-checksums.txt`.
- Cores pinned in `config/cores.tsv` (newest stable each): arduino:avr 1.8.8, esp32:esp32 3.3.12
  (4.0.0-RC1 skipped), rp2040:rp2040 6.3.1, STMicroelectronics:stm32 3.0.0.
  Measured: avr 259 MB + 49 MB downloads (16 s), esp32 6.0 GB + 1.7 GB (391 s), rp2040 1.5 GB +
  433 MB (43 s), stm32 2.5 GB + 350 MB (148 s). Total 11 GB data + 2.6 GB archives.
- Config: `config/arduino-cli.yaml` generated from `.yaml.in` (absolute paths), `--config-file` on
  every call plus `ARDUINO_DIRECTORIES_*` env; XDG_* under cache/. `~/.arduino15` (an old
  inventory.yaml from 2026-10-23) was not touched; nothing new in ~/.cache.
- Compiles are capped at 4 jobs in `lib/arduino.bash` (boxtool allows 8; the brief says <= 4).
- Mistakes fixed on the way: `hook_doctor` ended early under `set -e` when no serial device
  existed (`stat` of /dev/ttyUSB0 failing inside `$(...)`): now `|| true`. The dry-run bootstrap
  printed nothing to match (no pixi.toml): it now prints the config line.
- Results: doctor 16 ok / 0 failed, examples test 3/3 (12 compiles: blink 79 s incl. first ESP32
  core build, i2c_scan 33 s, serial_echo 25 s), tests/test_smoke.sh 10/10, tests/test_dry_run.sh
  30/30 (incl. shellcheck).
- Needs the user: serial access (`uucp` group or udev/70-box-arduino.rules, sudo); STM32duino's
  own upload methods need STM32CubeProgrammer (proprietary, not downloaded).

## 2026-10-25: readability pass 2 (script_style.md, scripts/README)
- lib/boxtool.bash (reference `00_09_meta/05_policy/templates/tool/lib/boxtool.bash`, synced to all 24 copies):
  `where`/`status`/`doctor`/`bootstrap`/`relocate` reject extra arguments (exit 2); colour only on a terminal
  and never with `NO_COLOR`; help lists `NO_COLOR`.
- README: exit codes, `BOX_INTEGRATION` and `NO_COLOR` rows. Backups:
  `00_09_meta/02_logs/config_backups/2026_10_25_readability2_embedded_tools/`.

## 2026-10-29: more boards, examples, templates; git repo
- Core `adafruit:nrf52` 1.7.0 added (nice!nano / Pro Micro nRF52840 as `nicenano` = `adafruit:nrf52:pca10056`).
  New board aliases: `esp32c3`, `pico2`, `nicenano`, `weact_g431` (GENERIC_G431CBUX), `weact_h562` (WEACT_H562RG),
  `weact_h743` (GENERIC_H743VITX). `plan` knows `nrfutil` uploads and the RP2350 BOOTSEL drive.
- Libraries pinned in `config/libraries.tsv` (ArduinoJson 7.4.3, Bounce2 2.71.0, Adafruit NeoPixel 1.15.5), installed by
  `install`, shown by `libs`, checked by doctor. Bounce2's library.properties says `2.71`: versions are padded to 3 parts.
- pixi env added (`pixi.toml` + `pixi.lock`): g++ 14, make, adafruit-nrfutil, pyelftools. The nRF52 core calls
  `adafruit-nrfutil` from PATH after every link (DFU .zip) on Linux; without it every nRF52 build fails.
- `lib/elf_check.py` + `elf` command: machine, sections, symbols, strings, code start address and sizes of a built ELF.
- 12 new examples: multi_file, freertos_esp32, ble_uart_nrf52, usb_hid_rp2040, host_unit_test, json_config, size_budget,
  build_flags, dual_core_rp2040, stm32_hw_timer, neopixel_status, avr_low_power. No board here: compile + ELF/artifact
  checks, host unit tests with the pixi g++.
- 11 new templates: multi_file, library, host_tested, freertos_esp32, ble_uart_nrf52, usb_hid_rp2040, dual_core_rp2040,
  stm32_timer, serial_cli, wifi_esp32, low_power_avr. tests/test_smoke.sh instantiates and compiles all 12 (and fails
  when a template has no row there).
- Problems found: Adafruit nRF52 sketches need `#include <Adafruit_TinyUSB.h>` or `Serial` is undefined at link time
  (arduino-cli only discovers libraries from sketch includes). AVR builds use LTO, so class/function symbols are inlined
  away: the AVR checks are size and vectors only. `static` helpers are inlined too, so symbol checks use public names.
  `build.extra_flags` is used by the STM32/nRF52 boards; the version example uses `compiler.cpp.extra_flags`. Inside
  the pixi env `BUILD` is exported by the compiler activation, so the host_tested Makefile uses `HOST_OUT`.
- `.gitignore` made strict (install/, cache/, .pixi/, .bin/, native/, user/, build output, generated config); git repo
  created (`main`).
- Results: doctor 22 ok / 0 warn / 0 fail; examples 15/15; smoke 26/26 (12 templates); dry-run 45/45 (shellcheck, py_compile).

## 2026-10-29: Rust, Zig, BEAM (addendum)
- Checked what Arduino cores can take: C/C++ only, but a static library linked as a precompiled Arduino library
  (`precompiled=true`, `ldflags`, `src/<build.mcu>/lib<name>.a`) works on arduino-pico and STM32duino (both pass
  `compiler.libraries.ldflags` inside the link group).
- Added examples `rust_staticlib` (no_std crate, `cargo test` on the host) and `zig_staticlib` (`zig test` on the host),
  for pico (thumbv6m / cortex_m0plus) and blackpill (thumbv7em-hf / cortex_m4); templates `rust_staticlib` and
  `zig_staticlib` with a `build.sh`. Toolchains are reached, not installed: `$BOX_EMBEDDED_RUST` / `$BOX_MICROZIG`
  or the sibling folders 32_17_embedded_rust / 32_24_microzig; exit 3 (skip) when missing. `examples/common.sh`:
  `sibling_tool`, `precompiled_lib`.
- Problems found: with the C header next to the `.ino`, STM32duino found it through `-I<sketch>` and never picked the
  library, so the link failed with undefined references (headers now in `rust/include`, `zig/include`). arduino-cli
  looks for the STM32 archive in `cortex-m4/-mfpu=fpv4-sp-d16--mfloat-abi=hard` (the board's fpu property includes the
  flag), then `cortex-m4/`: archives go to `cortex-m4/`. Zig is built with `-fno-compiler-rt`; libgcc provides
  `__aeabi_lmul` / `__aeabi_uldivmod`.
- BEAM (AtomVM): not supported: it is a whole firmware (VM + .avm), nothing a sketch can link; see 32_29_atomvm.
- Results: examples 17/17; smoke 28/28 (14 templates); dry-run 45/45; doctor 22 ok.
