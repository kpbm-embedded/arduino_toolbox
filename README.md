# 32_13_arduino - Arduino CLI with pinned board cores

The official Arduino CLI (static Go binary) with five pinned board cores for your boards: Arduino Nano (AVR),
ESP32-S3 / ESP32-C3, Raspberry Pi Pico / Pico 2 (RP2040/RP2350), BlackPill STM32F411CE and WeAct G431/H562/H743
(STM32duino), nice!nano / Pro Micro nRF52840 (Adafruit nRF52). Use it to compile, check and (by printed plan)
upload Arduino sketches without the IDE and without touching `~/.arduino15`. Cores, tools, indexes, downloads,
pinned libraries and the sketchbook live in this folder; build output goes to idisk03. No sudo, no system packages.
The launcher never shadows `arduino-cli`.

Status: **ready** (doctor 22 ok, examples 17/17, templates 14/14 compile, smoke 28/28, dry-run 45/45, 2026-10-29). Launcher: `./arduino-box`.

## What's included

| Component | Version | Notes |
|---|---|---|
| Arduino CLI | 1.5.1 (2026-06-05) | sha256 from the release `1.5.1-checksums.txt`; 1.5.2 is only an rc |
| `arduino:avr` (Nano) | 1.8.8 | built-in index |
| `esp32:esp32` (ESP32-S3) | 3.3.12 | 4.0.0 is an RC; index `https://espressif.github.io/arduino-esp32/package_esp32_index.json` |
| `rp2040:rp2040` (Pico, arduino-pico) | 6.3.1 | index `https://github.com/earlephilhower/arduino-pico/releases/download/global/package_rp2040_index.json` |
| `STMicroelectronics:stm32` (STM32duino) | 3.0.0 | index `https://github.com/stm32duino/BoardManagerFiles/raw/main/package_stmicroelectronics_index.json` |
| `adafruit:nrf52` (nice!nano, Bluefruit) | 1.7.0 | index `https://adafruit.github.io/arduino-board-index/package_adafruit_index.json` |
| Libraries (`config/libraries.tsv`) | ArduinoJson 7.4.3, Bounce2 2.71.0, Adafruit NeoPixel 1.15.5 | `arduino-cli lib install name@version` into `user/libraries`; checked against the signed library index |
| pixi | 0.81.0 | sha256 pinned in the launcher |
| pixi env (`pixi.toml` + `pixi.lock`) | python 3.12, g++ 14 (clang++ 19 on macOS), make, adafruit-nrfutil 0.5.3.post16, pyelftools 0.33 | host unit tests, the nRF52 core's DFU packaging (it calls `adafruit-nrfutil` from PATH), `lib/elf_check.py` |

Core archives are verified by arduino-cli against the checksums in each package index. Changing a core version is a
deliberate edit of `config/cores.tsv` followed by `./arduino-box install`.

| Core | Data (`install/arduino15/packages/<pkg>`) | Downloads | Install time |
|---|---|---|---|
| arduino:avr 1.8.8 | 259 MB | 49 MB | 16 s |
| esp32:esp32 3.3.12 | 6.0 GB (all ESP32 variants + Xtensa and RISC-V GCC) | 1.7 GB | 391 s |
| rp2040:rp2040 6.3.1 | 1.5 GB | 433 MB | 43 s |
| STMicroelectronics:stm32 3.0.0 | 2.5 GB | 350 MB | 148 s |
| adafruit:nrf52 1.7.0 | 0.5 GB (incl. its own arm-none-eabi-gcc 9) | 0.1 GB | about 60 s |
| builtin tools (ctags, discoveries, serial-monitor) | 17 MB | 9 MB | |

## Quick start

```sh
cd "$BOX_ARDUINO"                          # or: cd $BOX/30_39_tools/32_embedded/32_13_arduino
./arduino-box install && ./arduino-box doctor    # CLI + pixi env + 5 cores + libraries (installed here), then health checks
./arduino-box boards                       # your boards -> FQBN
./arduino-box compile blink pico           # sketch dir or .ino + board alias or full FQBN
./arduino-box plan nano blink              # PRINTS the upload commands; arduino-box never uploads
```

With the Box shell set up once (`box shell install --apply`), the `arduino-box` shim works from any folder,
and `box test|doctor|status arduino` run this launcher (`box clean arduino` is a dry run until `--apply`).
Standalone (no Box, or `BOX_INTEGRATION=0`), `./arduino-box` keeps its output in this folder.

## Commands

Global option: `--dry-run` / `-n` prints what a command would do. Exit codes: 0 ok, 1 failure, 2 usage error (unknown command or option, or arguments given to `where`, `status`, `doctor`, `bootstrap` or `relocate`), 3 not applicable. `help` ends with this tool's own examples and variables (`tool examples`, `tool environment`).

| Command | What it does | Example |
|---|---|---|
| `install [--no-demos]` | bootstrap + demo downloads + the pinned cores (`config/cores.tsv`) + native wrappers | `./arduino-box install` |
| `bootstrap` | pinned pixi + env + core downloads (sha-checked) | `./arduino-box bootstrap` |
| `update [--check\|--env]` | `--check` (default): pins vs newest upstream; `--env`: re-solve the pixi env (rewrites `pixi.lock`) | `./arduino-box update --check` |
| `clean [--all] [--yes]` | move build/log output (`--all`: + install/, .pixi, native/, downloads) to the Trash; dry run unless `--yes` | `./arduino-box --dry-run clean --all` |
| `status`, `where`, `doctor` | versions and sizes, paths, health checks (exit 1 on failure) | `./arduino-box doctor` |
| `shell [-- cmd ...]` | bash (or a command) with the tools on PATH | `./arduino-box shell` |
| `run <cmd> [args]` | one command inside the environment | `./arduino-box run arduino-cli version` |
| `cores` | pinned cores vs installed, with data and download sizes | `./arduino-box cores` |
| `boards [filter]` | owned boards -> FQBN (`config/boards.tsv`) | `./arduino-box boards pico` |
| `compile <sketch> <board\|fqbn> [args]` | compile into `$BOXT_OUT/build/sketches/<sketch>/<board>`; `-j` up to 4 | `./arduino-box compile blink pico` |
| `list` | read-only: serial ports / boards seen by `arduino-cli board list` (+ lsusb filter) | `./arduino-box list` |
| `plan <board> <sketch>` | PRINT the upload commands for a compiled sketch, runs nothing | `./arduino-box plan nano blink` |
| `libs` | pinned libraries (`config/libraries.tsv`) vs installed | `./arduino-box libs` |
| `elf <file.elf> [checks]` | machine, sections and sizes of a built ELF; `--machine`, `--symbol`, `--no-symbol`, `--section`, `--string`, `--code-from`, `--max-text`, `--max-data` (exit 1 when a check fails) | `./arduino-box elf fw.ino.elf --machine ARM --symbol setup1` |
| `cli [args]` | arduino-cli with this folder's config (pass-through) | `./arduino-box cli lib install "Adafruit NeoPixel@1.12.3"` |
| `new <kind> <name> [--dir D] [--force]` | project from `templates/` (12 kinds, table below) | `./arduino-box new freertos_esp32 my_fw --dir ~/fw` |
| `test [--all]` | `tests/test_smoke.sh`; `--all` adds the dry-run test and examples test | `./arduino-box test` |
| `examples list \| run <ex> [args] \| build [ex...] \| test [ex...]` | list, run, build or test the examples | `./arduino-box examples test` |
| `native [--print]` | write `native/{native.zsh,native.bash,bin/}` | `./arduino-box native` |
| `relocate` | after moving the folder: re-create the pixi env, rewrite `native/` | `./arduino-box relocate` |
| `pack [--with-cache] [--out F]` | tarball of this folder (minus envs/build) for another machine | `./arduino-box pack --out /tmp/p.tgz` |
| `help`, `-h`, `--help` | the command list | `./arduino-box help` |

Libraries installed with `cli lib install` go to `user/libraries`. Any sketch and any FQBN work:
`./arduino-box compile ~/fw/my_sketch arduino:avr:uno`.

### Uploading (printed only)

`plan <board> <sketch>` prints the commands; run them yourself after checking the port with `list`:

- Nano: `arduino-box cli upload --fqbn arduino:avr:nano --port /dev/ttyUSB0 --input-dir ...` (clones with the old bootloader: `arduino:avr:nano:cpu=atmega328old`).
- ESP32-S3: `cli upload` (esptool from the core) or esptool directly with the merged image at 0x0.
- Pico: copy the `.uf2` to the RPI-RP2 drive (BOOTSEL), or `cli upload` to a running sketch's port.
- Pico 2: same as the Pico; the BOOTSEL drive is `RP2350`.
- nice!nano: `adafruit-nrfutil dfu serial --package <sketch>.ino.zip` after a double-tap reset, or a `.uf2` (made with the core's `uf2conv.py`) copied to the `NICENANO` drive.
- BlackPill and WeAct STM32: `dfu-util` (not bundled here; see `32_15_flashers`) or SWD with an ST-Link/CMSIS-DAP probe. STM32duino's own upload methods need STM32CubeProgrammer, which is proprietary and not bundled.

## Examples and templates

`./arduino-box examples list`, `examples test` (every build and check below), `examples run blink` (prints the upload plans).
No board is attached here: every test is a compile plus checks on the artifact (file exists, ELF machine, symbols,
sections, strings, flash/RAM sizes) or a host unit test on the PC. Radio, USB and sleep behaviour are not tested.

| Example | Boards | What it shows | Test |
|---|---|---|---|
| `blink` | nano, esp32s3, pico, blackpill | `LED_BUILTIN` toggle + uptime on Serial (non-blocking `millis()`) | artifacts |
| `serial_echo` | all four | line echo at 115200; `help` prints `ARDUINO_BOARD`; waits briefly for native-USB hosts | artifacts |
| `i2c_scan` | all four | `Wire` scan 0x08..0x77 (default SDA/SCL per board in the source) | artifacts |
| `multi_file` | nano, pico, blackpill, weact_g431 | `.ino` + `config.h` + `src/` C++ class and C module | ELF symbols (AVR: LTO inlines, size only) |
| `freertos_esp32` | esp32s3, esp32c3 | FreeRTOS tasks, queue, mutex, core pinning | ELF machine Xtensa/RISC-V, FreeRTOS symbols |
| `ble_uart_nrf52` | nicenano | Bluefruit Nordic UART Service, Device Info, Battery | DFU `.zip`, code above the S140 SoftDevice (0x26000), BLE symbols |
| `usb_hid_rp2040` | pico, pico2 | USB keyboard + mouse, debounced button (Bounce2) | UF2, HID + library symbols |
| `host_unit_test` | nano, pico, blackpill | ring buffer + CRC-16 in `src/`, tested on the PC (`tests/`, g++) | host tests (9 checks) + builds |
| `json_config` | nano, esp32s3, pico | settings as JSON with the pinned ArduinoJson; parser tested on the PC | host tests (7 checks) + ELF symbols |
| `size_budget` | nano, blackpill, esp32c3, pico | CI size gate: `--format json` sizes vs `budget.tsv` | within budget + a 1-byte budget must fail |
| `build_flags` | nano, pico, weact_h743 | version passed with `--build-property compiler.cpp.extra_flags=...` | version string in the ELF |
| `dual_core_rp2040` | pico, pico2 | `setup1`/`loop1`, inter-core FIFO, `mutex_t` | ELF symbols |
| `stm32_hw_timer` | blackpill, weact_g431, weact_h562, weact_h743 | HardwareTimer 1 kHz interrupt, chip UID, HAL tick | code at 0x08000000, timer/IRQ symbols |
| `neopixel_status` | esp32s3, esp32c3, pico, nicenano | WS2812 status LED (Adafruit NeoPixel), pin per board | library symbols |
| `avr_low_power` | nano | power-down sleep, watchdog wake, wear-levelled EEPROM counter | WDT vector, fits 30720/2048 B |
| `rust_staticlib` | pico, blackpill | `no_std` Rust (CRC-32, fixed-point EMA) built by 32_17_embedded_rust, linked as a precompiled library | `cargo test` on the host + Rust symbols in both ELFs |
| `zig_staticlib` | pico, blackpill | freestanding Zig (isqrt, ADC scaling) built by 32_24_microzig, linked as a precompiled library | `zig test` on the host + Zig symbols in both ELFs |

Artifacts checked: `.hex` (Nano), `.merged.bin` (ESP32), `.uf2` (Pico, Pico 2), `.bin` (STM32), `.zip` (nRF52 DFU).

Templates (`./arduino-box new <kind> <name> [--dir D]`; the name must be a C identifier for `library`). Each has a
`README.md` and a `sketch.yaml` with its default board; `tests/test_smoke.sh` instantiates and compiles every one.

| Template | Default board | What you get |
|---|---|---|
| `sketch` | nano | `<name>.ino` (blink + Serial), `sketch.yaml`, README |
| `multi_file` | pico | `.ino` + `config.h` + `src/app.{h,cpp}` (time passed in, no Arduino calls in the module) |
| `library` | nano (builds `examples/basic` with `--library`) | Arduino library 1.5 layout: `library.properties`, `src/<name>.{h,cpp}`, `examples/basic`, `keywords.txt` |
| `host_tested` | nano | debouncer in `src/` + `tests/` + `Makefile`: `arduino-box run make test` runs the host tests |
| `freertos_esp32` | esp32s3 | sensor/report tasks, queue, event group; also esp32c3 |
| `ble_uart_nrf52` | nicenano | BLE UART peripheral with a line handler |
| `usb_hid_rp2040` | pico | USB HID macro pad (key table, Bounce2); also pico2 |
| `dual_core_rp2040` | pico2 | core 1 samples the ADC, core 0 reports through the FIFO |
| `stm32_timer` | weact_g431 | HardwareTimer PWM + period interrupt from the pin's timer; also blackpill, weact_h562/h743 |
| `serial_cli` | nano | command table shell on Serial (`help`, `led`, `uptime`, `echo`) |
| `wifi_esp32` | esp32c3 | Wi-Fi station with reconnect + `GET /status` JSON (ArduinoJson); `secrets.h` gitignored |
| `low_power_avr` | nano | power-down sleep, wake on INT0 or watchdog |
| `rust_staticlib` | pico (`build.sh` also: blackpill, weact_g431, nicenano, weact_h743) | sketch + `rust/` staticlib; `arduino-box run "$PWD/build.sh" pico` builds the Rust part with 32_17_embedded_rust and compiles |
| `zig_staticlib` | blackpill (same boards) | sketch + `zig/` library (table interpolation); `build.sh` builds it with 32_24_microzig and compiles |

### Rust, Zig and BEAM

The Arduino cores compile C/C++ only. What works for real is linking a Rust or Zig static library into a sketch
as a *precompiled library* (`precompiled=true`, `ldflags=-l<name>`, archive in `src/<build.mcu>/`): the examples and
templates above. The toolchains are not installed here; they are reached in 32_17_embedded_rust (`$BOX_EMBEDDED_RUST`)
and 32_24_microzig (`$BOX_MICROZIG`), else the sibling folders; without them the Rust/Zig examples exit 3 (skip)
and the smoke test prints `skip`. Limits found: the C header must not sit next to the `.ino` (it then hides the
library and the link fails); STM32duino's FPU folder name is `-mfpu=fpv4-sp-d16--mfloat-abi=hard`, so the archives
go into plain `src/cortex-m4/`.
- Rust: supported as a linked static library (above); a Rust `main`, embassy or esp-hal firmware does not fit an Arduino core: use 32_17_embedded_rust / 32_22_rust_next.
- Zig: supported as a linked static library (above); MicroZig firmware has its own HAL and startup: use 32_24_microzig.
- BEAM: not supported: AtomVM is a whole firmware image (VM + packed .avm), not something an Arduino sketch can link or host; use 32_29_atomvm.

## Configuration and environment variables

| Variable | Default | Meaning |
|---|---|---|
| `BOXT_OUT` | same ID path on idisk03, else the ID folder | output root (`build/`, `log/`); also settable in `config/local.env` |
| `BOXT_JOBS` | 8 (maximum) here the launcher caps it at 4 | parallel jobs |
| `BOXT_MIN_FREE_GB` | 8 | pause builds while less RAM is free |
| `BOXT_RAM_WAIT_MAX` | 3600 | give up waiting for RAM after this many seconds |
| `BOXT_NET_TIMEOUT` | 3600 | seconds for one download |
| `BOXT_PLATFORM` | detected (`linux-x64`) | override the platform |
| `GITHUB_TOKEN` | unset | optional; lifts the GitHub API limit for `update --check` |
| `BOX_INTEGRATION` | 1 | `0` = standalone: ignore `$BOX`/`$BOX_V3`, keep output in this folder |
| `NO_COLOR` | unset | set to print plain text (colour is only used on a terminal anyway) |
| `ARDUINO_*` | set by `arduino-box` | derived from `config/arduino-cli.yaml`; not read from your shell |
| `BOX_NATIVE_OFF_ARDUINO` | unset | `1` skips native mode for one shell (old name `ARDUINO_BOX_NATIVE_OFF` still honoured) |
| `BOX_ARDUINO` | set by `box_env.sh` | path of this ID, used by the native snippet |

`config/arduino-cli.yaml` is generated from `config/arduino-cli.yaml.in` (rewritten after a move or `BOXT_OUT` change);
every call passes `--config-file`. Tool helpers are kept out of the home folder with `XDG_*` under `cache/`.

| Setting | Path |
|---|---|
| `directories.data` (cores, tools, indexes) | `install/arduino15` |
| `directories.downloads` (archives, offline reinstall) | `cache/arduino-downloads` |
| `directories.user` (sketchbook, libraries) | `user/` |
| `build_cache.path` | `$BOX_V3/30_39_tools/32_embedded/32_13_arduino/build/arduino-cache` |
| sketch build output | `.../build/sketches/<sketch>/<board>` |
| `board_manager.additional_urls` | ESP32, arduino-pico, STM32duino, Adafruit indexes |

## Where files go

| What | Where |
|---|---|
| Source, launcher, examples, templates, `config/` | this ID |
| Tools | `install/arduino-cli-1.5.1` (36 MB), `install/arduino15` (12 GB: cores, toolchains, indexes), `.pixi/` (0.9 GB env), `.bin/` (77 MB pixi) |
| Cache | `cache/` (2.6 GB: CLI tarball and core/tool archives; `CACHEDIR.TAG`) |
| Sketchbook | `user/` (`user/libraries`: the pinned libraries; regenerated by `install`, not in git) |
| Build output and logs | `$BOX_V3/30_39_tools/32_embedded/32_13_arduino/{build,log}` (about 0.2 GB after the examples) |

ID total about 14 GB on idisk01. `clean --all --yes` trashes `install/` and `cache/downloads` but keeps `cache/arduino-downloads`,
so `./arduino-box install` reinstalls the cores without downloading them.

## Native mode

`./arduino-box native` writes `native/native.{zsh,bash}` and `native/bin/arduino-cli`, a wrapper that runs
`arduino-box cli` (so the pinned config is always used). Load it in every shell (zsh, bash, fish) with `box native
enable arduino --apply`: it runs `./arduino-box native` when the files are missing and rebuilds `box_env.d/native.*`
(without `--apply` it only shows the plan; `box native disable arduino --apply` undoes it). `BOX_NATIVE_OFF_ARDUINO=1`
skips it for one shell (the old `ARDUINO_BOX_NATIVE_OFF` still works for now). Without Box, source `native/native.zsh`
or `native/native.bash` from your shell rc.

## Tests

```sh
./arduino-box test --all       # smoke + dry-run + examples
tests/test_smoke.sh            # cli + dirs + cores + libraries + every template built (+ host tests) + plan + ~/.arduino15 untouched
tests/test_dry_run.sh          # every command in --dry-run + shellcheck + py_compile
```

Last known (2026-10-29): doctor 22 ok / 0 warn / 0 fail; examples 17/17 (51 builds + 2 C++ host test programs,
cargo test, zig test); smoke 28/28 (14 templates); dry-run 45/45. A fresh clone passed bootstrap, install, doctor and `test --all`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Permission denied` on the serial port | join the group (`sudo usermod -aG uucp "$USER"`, log in again) or install the udev rules (below) |
| Nano upload fails on a clone | use `arduino:avr:nano:cpu=atmega328old` (old bootloader) |
| STM32duino upload asks for STM32CubeProgrammer | proprietary, not bundled: use dfu-util or SWD as printed by `plan` |
| Config paths wrong after moving the folder or changing `BOXT_OUT` | `./arduino-box relocate` rewrites `config/arduino-cli.yaml` and `native/` |
| Core reinstall downloads again after `clean --all` | keep `cache/arduino-downloads`; plain `clean --all` does |

## Limitations / needs you

- **Serial access (sudo, once):** `sudo usermod -aG uucp "$USER"` (this OS uses `uucp`; `dialout` on Debian), log out and in. Or install the uaccess rules shipped here:

```sh
sudo install -m 644 udev/70-box-arduino.rules /etc/udev/rules.d/
sudo udevadm control --reload && sudo udevadm trigger
```

- **No board attached:** BLE, USB HID, Wi-Fi, sleep current and timer behaviour are only compiled and checked in the ELF, never run.
- **nice!nano:** compiled with the Adafruit `pca10056` (nRF52840 DK) variant, the usual choice for this board; its pin names are the DK's (pin N = P0.N).
- **Size:** 14 GB, mostly the ESP32 core (6.0 GB data + 1.7 GB downloads) and STM32 (2.5 + 0.35 GB). Your decision whether to trim.
- **STM32 uploads** via STM32duino need the proprietary STM32CubeProgrammer (not downloaded).
- **Hardware:** nothing was uploaded; uploads are only printed. Not verified here: real boards.
- Other OSes: the CLI is pinned for macOS, Linux arm64 and Windows (Git Bash/MSYS2) in `config/pins.tsv`; untested.
- Licences: Arduino CLI GPL-3.0; the cores LGPL-2.1; toolchains GPL with exceptions; ESP-IDF libs Apache-2.0; Adafruit nRF52 core LGPL/BSD, Nordic SoftDevice under Nordic's licence (downloaded with the core, not in git); ArduinoJson MIT, Bounce2 MIT, Adafruit NeoPixel LGPL-3.0.

## Scripts

Each script has a `[scripts.*]` descriptor in `.box.toml` (`box scripts show 32_13`; `box scripts check 32_13` must stay clean).

| File | Purpose |
|---|---|
| `arduino-box` | launcher (POSIX sh): bootstraps the pinned pixi, keeps caches in this folder, then runs `lib/` |
| `lib/boxtool.bash` | shared launcher framework (boxtool 3: bootstrap, pinned downloads, pixi env, every common command); byte-identical copy of `$BOX/00_09_meta/05_policy/templates/tool/lib/boxtool.bash` (edit there, then sync) |
| `lib/arduino.bash`, `lib/arduino_cores.py` | this tool's hooks and extra commands; core pin/size helper |
| `lib/elf_check.py` | `elf` command and example checks: machine, sections, symbols, strings, sizes of a built ELF (pyelftools) |
| `pixi.toml`, `pixi.lock` | host-side env: g++, make, adafruit-nrfutil, pyelftools |
| `examples/common.sh`, `examples/*/example.sh` | shared example code (compile, artifact and ELF checks, sibling tools, precompiled libraries) and the 17 examples |
| `tests/test_smoke.sh`, `tests/test_dry_run.sh`, `tests/testlib.sh` | smoke test, dry-run/shellcheck test, shared test helpers |
| `native/` | written by `./arduino-box native`; regenerate, do not edit |

## Links

- Arduino CLI: <https://github.com/arduino/arduino-cli/releases/tag/v1.5.1>; AVR core: <https://github.com/arduino/ArduinoCore-avr>
- ESP32 core: <https://github.com/espressif/arduino-esp32>; Pico core: <https://github.com/earlephilhower/arduino-pico>; STM32 core: <https://github.com/stm32duino/Arduino_Core_STM32>
- pixi: <https://github.com/prefix-dev/pixi>
- History: `NOTES.md`. Report: `$BOX/00_09_meta/02_logs/2026_10_25_embedded_tools2_report.md`.
- Sibling tools: `32_14_platformio` (same boards, PlatformIO), `32_15_flashers` (uploading).
