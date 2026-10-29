#!/usr/bin/env bash
# Smoke test of the installed arduino-box: arduino-cli runs with this folder's directories, all
# pinned cores and libraries are installed, every template instantiates with `new` and compiles for
# its default board (host_tested also runs its host unit tests), `plan` only prints, and nothing
# was written to ~/.arduino15. Usage: tests/test_smoke.sh
# Depends on: tests/testlib.sh, ./arduino-box install done.
TEST_LAUNCHER_NAME=arduino-box
# shellcheck source-path=SCRIPTDIR source=testlib.sh
. "$(dirname "$0")/testlib.sh"
Q=$LAUNCHER
make_temp_dir
home_files_before=$(find "$HOME/.arduino15" -newer "$HERE/config/cores.tsv" 2>/dev/null | wc -l)

if version=$("$Q" cli version 2>&1) && grep -q 'Version: ' <<<"$version"; then ok "$version"; else bad "arduino-cli: $version"; fi
if data_dir=$("$Q" cli config get directories.data 2>&1) && [[ "$data_dir" == "$HERE/install/arduino15" ]]; then ok "data dir inside the ID"
else bad "data dir: $data_dir"; fi
core_list=$("$Q" cli core list 2>/dev/null)
while IFS=$'\t' read -r core version _; do
  if grep -qE "^$core +$version " <<<"$core_list"; then ok "core $core $version"; else bad "core $core $version not installed"; fi
done < <(grep -v '^#' "$HERE/config/cores.tsv")
libs=$("$Q" libs 2>/dev/null)
while IFS=$'\t' read -r lib version _; do
  if grep -qE "^$lib +$version +$version" <<<"$libs"; then ok "library $lib $version"; else bad "library $lib $version not installed"; fi
done < <(grep -v '^#' "$HERE/config/libraries.tsv")
sketch=smoke_sketch
if "$Q" new sketch "$sketch" --dir "$TEST_TMP" >/dev/null 2>&1; then
  for board in nano pico; do
    if output=$("$Q" compile "$TEST_TMP/$sketch" "$board" 2>&1) && grep -qE 'Sketch uses [0-9]+ bytes' <<<"$output"; then
      ok "template sketch compiles for $board"
    else bad "template for $board: $(tail -3 <<<"$output")"; fi
  done
else bad "new sketch"; fi
# every template: kind, board, how to build it (sketch = the folder; library = its examples/basic)
template_table="multi_file pico sketch
library nano library
host_tested nano sketch+host
freertos_esp32 esp32s3 sketch
ble_uart_nrf52 nicenano sketch
usb_hid_rp2040 pico sketch
dual_core_rp2040 pico2 sketch
stm32_timer weact_g431 sketch
serial_cli nano sketch
wifi_esp32 esp32c3 sketch
low_power_avr nano sketch"
for kind in $(cd "$HERE/templates" && ls); do
  [[ "$kind" == sketch ]] || grep -q "^$kind " <<<"$template_table" || bad "template $kind has no row in test_smoke.sh"
done
while read -r kind board how; do
  name="t_$kind"
  if ! "$Q" new "$kind" "$name" --dir "$TEST_TMP" >/dev/null 2>&1; then bad "new $kind"; continue; fi
  if grep -rq '@NAME' "$TEST_TMP/$name" || find "$TEST_TMP/$name" -name '*__name__*' | grep -q .; then bad "template $kind: placeholder left"; continue; fi
  compile_args=("$TEST_TMP/$name" "$board")
  if [[ "$how" == library ]]; then compile_args=("$TEST_TMP/$name/examples/basic" "$board" --library "$TEST_TMP/$name"); fi
  if output=$("$Q" compile "${compile_args[@]}" 2>&1) && grep -qE 'Sketch uses [0-9]+ bytes' <<<"$output"; then ok "template $kind compiles for $board"
  else bad "template $kind for $board: $(tail -3 <<<"$output")"; fi
  if [[ "$how" == sketch+host ]]; then
    if output=$("$Q" run make -C "$TEST_TMP/$name" test 2>&1) && grep -q 'host tests: 0 failed' <<<"$output"; then ok "template $kind host tests"
    else bad "template $kind host tests: $(tail -3 <<<"$output")"; fi
  fi
done <<<"$template_table"
if output=$("$Q" plan esp32s3 "$TEST_TMP/$sketch" 2>&1) && grep -q 'PRINTED ONLY' <<<"$output"; then ok "plan prints only"; else bad "plan"; fi
home_files_after=$(find "$HOME/.arduino15" -newer "$HERE/config/cores.tsv" 2>/dev/null | wc -l)
if [[ "$home_files_after" == "$home_files_before" ]]; then ok "nothing new in \$HOME/.arduino15"; else bad "\$HOME/.arduino15 changed"; fi
finish smoke
