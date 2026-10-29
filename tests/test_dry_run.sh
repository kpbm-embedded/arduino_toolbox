#!/usr/bin/env bash
# Every arduino-box command in --dry-run mode (no downloads, compiles, moves or uploads), help and
# exit codes, plus shellcheck and py_compile of every script. Usage: tests/test_dry_run.sh
# Depends on: tests/testlib.sh, an installed ID for the doctor/cores lines.
TEST_LAUNCHER_NAME=arduino-box
# shellcheck source-path=SCRIPTDIR source=testlib.sh
. "$(dirname "$0")/testlib.sh"
Q=$LAUNCHER

check help        'usage: \./arduino-box'                  "$Q" help
check help-flag   'environment'                            "$Q" --help
check help-short  'BOXT_OUT'                               "$Q" -h
check_exit unknown-cmd 2                                   "$Q" no-such-command
check_exit usage-compile 2                                 "$Q" compile
check_exit usage-plan 2                                    "$Q" plan nano
check_exit bad-board 2                                     "$Q" plan no-such-board blink
check where       '^arduino-cli '                          "$Q" where
check bootstrap   'arduino-cli config'                     "$Q" --dry-run bootstrap
check install     'core install esp32:esp32@'              "$Q" --dry-run install
check update      'curl https://api.github.com/repos/arduino/arduino-cli' "$Q" --dry-run update
check clean       'nothing to clean|dry run: re-run with --yes' "$Q" clean
check clean-all   'dry run: re-run with --yes'             "$Q" clean --all
check status      '^  arduino-cli '                        "$Q" status
check doctor      'doctor: [0-9]+ ok'                      bash -c "'$Q' doctor || true"
check shell       '\+ true'                                "$Q" --dry-run shell -- true
check run         '\+ arduino-cli version'                 "$Q" --dry-run run arduino-cli version
check test        'test_smoke\.sh'                         "$Q" --dry-run test
check new         '\+ copy .*templates/sketch'             "$Q" --dry-run new sketch demo --dir /nonexistent
check ex-list     'i2c_scan .*Wire'                        "$Q" examples list
check ex-run      'example\.sh run'                        "$Q" --dry-run examples run blink
check ex-build    'example\.sh build'                      "$Q" --dry-run examples build
check ex-test     'example\.sh test'                       "$Q" --dry-run examples test
check native      'arduino-cli @cli'                       "$Q" --dry-run native
check relocate    'pixi env already matches|re-creating'   "$Q" --dry-run relocate
check pack        '\+ tar .*-cf .*arduino-box_'            "$Q" --dry-run pack
check cores       'esp32:esp32 .*3\.3\.12'                 "$Q" --dry-run cores
check boards      'blackpill .*BLACKPILL_F411CE'           "$Q" boards
check compile     'compile --fqbn rp2040:rp2040:rpipico .*--jobs [1-4] ' "$Q" --dry-run compile blink pico
check compile-fqbn 'compile --fqbn arduino:avr:uno '       "$Q" --dry-run compile blink arduino:avr:uno
check list        '\+ arduino-cli board list'              "$Q" --dry-run list
check plan-nano   'PRINTED ONLY'                           "$Q" plan nano blink
check plan-pico   'RPI-RP2'                                "$Q" plan pico blink
check plan-bp     'dfu-util'                               "$Q" plan blackpill blink
check libs        'ArduinoJson +7\.4\.3'                   "$Q" libs
check install-libs 'lib install ArduinoJson@7\.4\.3'       "$Q" --dry-run install
check elf         'python3 -I .*elf_check\.py x\.elf'       "$Q" --dry-run elf x.elf
check_exit usage-elf 2                                     "$Q" elf
check plan-nrf    'adafruit-nrfutil dfu serial'            "$Q" plan nicenano blink
check plan-pico2  'RP2350'                                 "$Q" plan pico2 blink
check new-kinds   'freertos_esp32'                         bash -c "'$Q' new 2>&1 || true"
check cli         '\+ arduino-cli --config-file .* version' "$Q" --dry-run cli version
mapfile -t scripts < <(cd "$HERE" && ls arduino-box lib/*.bash tests/*.sh examples/common.sh examples/*/example.sh templates/*/build.sh)
check_shellcheck "${scripts[@]}"
check_py_compile lib/arduino_cores.py lib/elf_check.py
finish dry-run
