#!/usr/bin/env bash
# arduino-box tool part: hooks and commands for lib/boxtool.bash (sourced below), run by the
# ./arduino-box launcher (never directly). Official arduino-cli static binary (pinned release
# tarball) with its data/downloads/user directories inside this folder, pinned board cores
# (config/cores.tsv), owned boards (config/boards.tsv), build cache/output on $OUT (idisk03).
# Depends on: lib/boxtool.bash, lib/arduino_cores.py (python3), coreutils, awk, column.
# SAFETY: nothing here uploads to or erases a board. `list` only enumerates ports; `plan` only
# prints upload commands. `cli` passes whatever *you* type to arduino-cli.
set -euo pipefail

# shellcheck disable=SC2034  # TOOL_* are read by lib/boxtool.bash (cmd_help, cmd_install)
{
  TOOL_TITLE="32_13_arduino: Arduino CLI $(sed -n 's/^arduino-cli\t\([^\t]*\)\t.*/\1/p' "${BOXT_ROOT:?run through ./arduino-box}/config/pins.tsv" | head -1) with AVR, ESP32, RP2040, STM32 and nRF52 cores"
  TOOL_INSTALL_WHAT="the pinned cores (config/cores.tsv), libraries (config/libraries.tsv) + native wrappers"
  TOOL_HELP_USE="  cores                   pinned cores vs installed, with data + download sizes
  boards [filter]         owned boards -> FQBN (config/boards.tsv)
  compile <sketch> <board|fqbn> [args]   compile into \$OUT/build/sketches/<sketch>/<board>
  list                    read-only: serial ports / boards seen by arduino-cli (board list)
  plan <board> <sketch>   PRINT the upload commands for a compiled sketch (runs nothing)
  libs                    pinned libraries (config/libraries.tsv) vs installed
  elf <file.elf> [checks] sections/symbols/arch of a built ELF (lib/elf_check.py; --help)
  cli [args]              arduino-cli with this folder's config (pass-through)"
}
# shellcheck source-path=SCRIPTDIR source=boxtool.bash
. "$BOXT_ROOT/lib/boxtool.bash"

# Shared machine: these compilers run at most 4 jobs (boxtool allows 8); BOXT_JOBS can lower it.
if [[ "$JOBS" -gt 4 ]]; then JOBS=4; fi

ARDUINO_CLI="$INST/arduino-cli/arduino-cli"
if [[ -x "$ARDUINO_CLI.exe" ]]; then ARDUINO_CLI="$ARDUINO_CLI.exe"; fi
CLI_CONFIG="$CONFIG/arduino-cli.yaml"
CORES_TSV="$CONFIG/cores.tsv"
LIBS_TSV="$CONFIG/libraries.tsv"
BOARDS_TSV="$CONFIG/boards.tsv"
DATA_DIR="$INST/arduino15"
DOWNLOADS_DIR="$ROOT/cache/arduino-downloads"
SKETCHBOOK_DIR="$ROOT/user"
BUILD_CACHE_DIR="$BUILD/arduino-cache"
CORES_PY="$ROOT/lib/arduino_cores.py"

# config/arduino-cli.yaml from the template (absolute paths; rewritten after a move or $OUT change)
write_cli_config() {
  local wanted
  wanted=$(sed -e "s#@ROOT@#$ROOT#g" -e "s#@OUT@#$OUT#g" "$CONFIG/arduino-cli.yaml.in")
  if [[ ! -r "$CLI_CONFIG" || "$(cat "$CLI_CONFIG")" != "$wanted" ]]; then
    if [[ "$DRY" == 1 ]]; then echo "+ write $CLI_CONFIG"; return 0; fi
    printf '%s\n' "$wanted" >"$CLI_CONFIG.part" && mv "$CLI_CONFIG.part" "$CLI_CONFIG"
  fi
}

hook_env() {
  write_cli_config
  # Also as environment (arduino-cli maps ARDUINO_<SECTION>_<KEY>), so tools started by a core
  # and a bare arduino-cli in `shell` see the same directories. Nothing goes to ~/.arduino15.
  export ARDUINO_CONFIG_FILE="$CLI_CONFIG" ARDUINO_DIRECTORIES_DATA="$DATA_DIR" \
         ARDUINO_DIRECTORIES_DOWNLOADS="$DOWNLOADS_DIR" ARDUINO_DIRECTORIES_USER="$SKETCHBOOK_DIR" \
         ARDUINO_BUILD_CACHE_PATH="$BUILD_CACHE_DIR" ARDUINO_UPDATER_ENABLE_NOTIFICATION=false
  # Core tools (esptool, pico python helpers, ...) must not write to ~/.cache or ~/.config.
  export XDG_CACHE_HOME="$ROOT/cache/xdg-cache" XDG_CONFIG_HOME="$ROOT/cache/xdg-config" XDG_DATA_HOME="$ROOT/cache/xdg-data"
  if [[ "$DRY" != 1 ]]; then
    mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$SKETCHBOOK_DIR/libraries" 2>/dev/null || true
  fi
  PATH="$(dirname "$ARDUINO_CLI"):$PATH"
  export PATH ARDUINO_BOX_ROOT="$ROOT" ARDUINO_BOX_BOARDS="$BOARDS_TSV" ARDUINO_BOX_CLI="$ARDUINO_CLI"
}

arduino_cli() { "$ARDUINO_CLI" --config-file "$CLI_CONFIG" "$@"; }

# ---------- cores ----------
core_rows() { # non-comment lines of config/cores.tsv: core version index upstream
  if [[ -r "$CORES_TSV" ]]; then awk -F'\t' '!/^#/ && NF>=3' "$CORES_TSV"; fi
}
core_installed_version() { # core -> installed version or empty
  [[ -d "$DATA_DIR/packages" ]] || return 0
  arduino_cli core list --json 2>/dev/null | python3 -I "$CORES_PY" installed-version --core "$1" 2>/dev/null || true
}
core_package_dir() { printf '%s/packages/%s' "$DATA_DIR" "${1%%:*}"; }
core_download_size() { # core -> human size of its package's archives in cache/arduino-downloads
  local bytes
  bytes=$(python3 -I "$CORES_PY" download-size --data "$DATA_DIR" --package "${1%%:*}" \
          --downloads "$DOWNLOADS_DIR/packages" 2>/dev/null || echo 0)
  if [[ -z "$bytes" || "$bytes" == 0 ]]; then echo "-"
  else numfmt --to=iec --suffix=B "$bytes" 2>/dev/null || echo "$bytes"; fi
}

install_cores() {
  local core version
  cachedir_tag "$DOWNLOADS_DIR" "$INST"
  info "arduino-cli core update-index"
  run timeout "$NET_TIMEOUT" "$ARDUINO_CLI" --config-file "$CLI_CONFIG" core update-index
  while IFS=$'\t' read -r core version _; do
    if [[ "$DRY" != 1 && "$(core_installed_version "$core")" == "$version" ]]; then
      info "core $core@$version already installed"; continue
    fi
    wait_for_ram
    info "core install $core@$version"
    run timeout "$NET_TIMEOUT" "$ARDUINO_CLI" --config-file "$CLI_CONFIG" core install "$core@$version" --no-overwrite
  done < <(core_rows)
}

# ---------- libraries ----------
lib_rows() { # non-comment lines of config/libraries.tsv: name version used_by
  if [[ -r "$LIBS_TSV" ]]; then awk -F'\t' '!/^#/ && NF>=2' "$LIBS_TSV"; fi
}
lib_installed_version() { # name -> installed version in user/libraries or empty
  local props
  for props in "$SKETCHBOOK_DIR"/libraries/*/library.properties; do
    [[ -r "$props" ]] || continue
    if [[ "$(sed -n 's/^name=//p' "$props" | tr -d '\r')" == "$1" ]]; then
      # library.properties may say 2.71 where the index says 2.71.0: pad to three parts
      sed -n 's/^version=//p' "$props" | tr -d '\r' | awk -F. '{v=$0; for (i=NF; i<3; i++) v=v ".0"; print v}'; return 0
    fi
  done
}
install_libraries() {
  local name version
  [[ -n "$(lib_rows)" ]] || return 0
  info "arduino-cli lib update-index"
  run timeout "$NET_TIMEOUT" "$ARDUINO_CLI" --config-file "$CLI_CONFIG" lib update-index
  while IFS=$'\t' read -r name version _; do
    if [[ "$DRY" != 1 && "$(lib_installed_version "$name")" == "$version" ]]; then
      info "library $name@$version already installed"; continue
    fi
    info "lib install $name@$version"
    run timeout "$NET_TIMEOUT" "$ARDUINO_CLI" --config-file "$CLI_CONFIG" lib install "$name@$version" --no-deps
  done < <(lib_rows)
}

hook_bootstrap() {
  cachedir_tag "$ROOT/cache" "$DOWNLOADS_DIR"
  write_cli_config
  info "arduino-cli config: config/arduino-cli.yaml (data install/arduino15, downloads cache/arduino-downloads)"
}
hook_install() { # demos-flag (unused: there are no demo downloads)
  activate
  install_cores
  install_libraries
  cmd_native
}
hook_relocate() { write_cli_config; }

hook_status() {
  local core installed=0
  while IFS=$'\t' read -r core _; do
    if [[ -d "$(core_package_dir "$core")" ]]; then installed=$((installed + 1)); fi
  done < <(core_rows)
  printf '  %-22s %s of %s pinned in install/arduino15 (%s); ./%s cores\n' cores "$installed" \
    "$(core_rows | wc -l)" "$(human_size "$DATA_DIR")" "$NAME"
}

doctor_serial_group() { # ok/warn line about access to /dev/ttyUSB*/ttyACM*
  local group
  group=$(stat -c %G /dev/ttyUSB0 /dev/ttyACM0 2>/dev/null | head -1 || true)
  if [[ -z "$group" ]]; then d_ok "no serial board connected (list/plan need none)"
  elif id -nG | tr ' ' '\n' | grep -x "$group" >/dev/null; then d_ok "serial ports: user is in group $group"
  else d_warn "serial ports owned by group $group; you are not in it (README 'udev and groups')"; fi
}

hook_doctor() {
  local value core wanted installed
  if value=$("$ARDUINO_CLI" version 2>/dev/null | head -1); then d_ok "$value"
  else d_fail "arduino-cli not runnable ($ARDUINO_CLI): ./$NAME bootstrap"; fi
  if [[ -r "$CLI_CONFIG" ]] && grep -q "$ROOT/install/arduino15" "$CLI_CONFIG"; then d_ok "config/arduino-cli.yaml points inside this folder"
  else d_fail "config/arduino-cli.yaml stale: ./$NAME relocate"; fi
  value=$(arduino_cli config get directories.data 2>/dev/null || true)
  if [[ "$value" == "$DATA_DIR" ]]; then d_ok "data dir: install/arduino15"; else d_fail "data dir is '$value' (expected $DATA_DIR)"; fi
  value=$(arduino_cli config get directories.downloads 2>/dev/null || true)
  if [[ "$value" == "$DOWNLOADS_DIR" ]]; then d_ok "downloads dir: cache/arduino-downloads"; else d_fail "downloads dir is '$value'"; fi
  while IFS=$'\t' read -r core wanted _; do
    installed=$(core_installed_version "$core")
    if [[ "$installed" == "$wanted" ]]; then d_ok "core $core $installed"
    elif [[ -n "$installed" ]]; then d_fail "core $core $installed installed, $wanted pinned: ./$NAME install"
    else d_fail "core $core $wanted not installed: ./$NAME install"; fi
  done < <(core_rows)
  while IFS=$'\t' read -r core wanted _; do
    installed=$(lib_installed_version "$core")
    if [[ "$installed" == "$wanted" ]]; then d_ok "library $core $installed"
    else d_fail "library $core $wanted not installed (${installed:-none}): ./$NAME install"; fi
  done < <(lib_rows)
  if [[ -x "$ENV_DIR/bin/adafruit-nrfutil" ]]; then d_ok "pixi env: adafruit-nrfutil, g++, pyelftools"
  else d_fail "pixi env missing (nRF52 builds and host tests need it): ./$NAME bootstrap"; fi
  if [[ -r "$BOARDS_TSV" ]]; then d_ok "boards table: $(board_rows | wc -l) boards"; else d_fail "config/boards.tsv missing"; fi
  if have python3; then d_ok "python3 (host; core versions and sizes)"; else d_warn "python3 missing: cores and doctor's core checks need it"; fi
  doctor_serial_group
}

hook_native_bins() {
  echo "arduino-cli @cli"
}

# ---------- boards / sketches ----------
board_rows() { # non-comment lines of config/boards.tsv: board fqbn upload notes
  if [[ -r "$BOARDS_TSV" ]]; then awk -F'\t' '!/^#/ && NF>=3' "$BOARDS_TSV"; fi
}
board_fqbn() { # board alias or full FQBN -> FQBN (exit 1 if neither)
  local fqbn
  fqbn=$(board_rows | awk -F'\t' -v b="$1" '$1==b {print $2}')
  if [[ -n "$fqbn" ]]; then printf '%s' "$fqbn"
  elif [[ "$1" == *:*:* ]]; then printf '%s' "$1"
  else return 1; fi
}
board_folder_name() { # board alias or FQBN -> folder-safe name
  if board_rows | awk -F'\t' -v b="$1" '$1==b {f=1} END {exit !f}'; then printf '%s' "$1"
  else printf '%s' "$1" | tr ':=,' '___'; fi
}
sketch_dir() { # sketch folder, .ino file or example name -> absolute folder (exit 1 if none)
  local sketch=$1
  if [[ -f "$sketch" ]]; then sketch=$(dirname "$sketch"); fi
  if [[ ! -d "$sketch" && -d "$ROOT/examples/$sketch" ]]; then sketch="$ROOT/examples/$sketch"; fi
  [[ -d "$sketch" ]] || return 1
  (cd "$sketch" && pwd -P)
}
sketch_build_dir() { # sketch-dir board -> build path on $OUT
  printf '%s/sketches/%s/%s' "$BUILD" "$(basename "$1")" "$(board_folder_name "$2")"
}

# ---------- commands ----------
tool_cmd_cores() {
  activate
  local core version installed
  printf '%-26s %-10s %-12s %-8s %s\n' core pinned installed data downloads
  while IFS=$'\t' read -r core version _; do
    if [[ "$DRY" == 1 ]]; then printf '%-26s %-10s %s\n' "$core" "$version" "+ arduino-cli core list"; continue; fi
    installed=$(core_installed_version "$core")
    printf '%-26s %-10s %-12s %-8s %s\n' "$core" "$version" "${installed:--}" \
      "$(human_size "$(core_package_dir "$core")")" "$(core_download_size "$core")"
  done < <(core_rows)
  if [[ "$DRY" != 1 ]]; then
    printf 'total: data %s (install/arduino15) | downloads %s (cache/arduino-downloads) | build cache %s\n' \
      "$(human_size "$DATA_DIR")" "$(human_size "$DOWNLOADS_DIR")" "$(human_size "$BUILD_CACHE_DIR")"
  fi
}

tool_cmd_boards() {
  local filter=${1:-}
  { printf 'board\tfqbn\tupload\tnotes\n'; board_rows | grep -i -- "$filter" || true; } | column -t -s $'\t'
}

# compile <sketch> <board|fqbn> [extra arduino-cli compile args]
tool_cmd_compile() {
  local sketch=${1:-} board=${2:-}
  [[ -n "$sketch" && -n "$board" ]] || usage_error "usage: ./$NAME compile <sketch-dir|.ino|example> <board|fqbn> [args] (boards: ./$NAME boards)"
  shift 2
  local sketch_path fqbn build_path
  sketch_path=$(sketch_dir "$sketch") || usage_error "no sketch folder: $sketch"
  fqbn=$(board_fqbn "$board") || usage_error "unknown board '$board' (./$NAME boards, or give a full FQBN)"
  activate
  build_path=$(sketch_build_dir "$sketch_path" "$board")
  if [[ "$DRY" != 1 ]]; then mkdir -p "$build_path"; cachedir_tag "$BUILD"; fi
  wait_for_ram
  run "$ARDUINO_CLI" --config-file "$CLI_CONFIG" compile --fqbn "$fqbn" --build-path "$build_path" \
    --jobs "$JOBS" --warnings default "$@" "$sketch_path"
}

tool_cmd_list() {
  activate
  if [[ "$DRY" == 1 ]]; then printf '+ arduino-cli board list\n+ lsusb\n'; return 0; fi
  echo "== arduino-cli board list (read-only port discovery)"
  timeout 60 "$ARDUINO_CLI" --config-file "$CLI_CONFIG" board list 2>&1 || true
  if have lsusb; then
    echo "== lsusb (Arduino/CH340/CP210x/FTDI/Espressif/RP2040/STM32 DFU)"
    lsusb | grep -iE '2341:|2a03:|1a86:|10c4:ea60|0403:6001|303a:|2e8a:|0483:df11' || echo "(none)"
  fi
}

# plan <board> <sketch>: print, never run.
tool_cmd_plan() {
  local board=${1:-} sketch=${2:-}
  [[ -n "$board" && -n "$sketch" ]] || usage_error "usage: ./$NAME plan <board> <sketch-dir|example> (boards: ./$NAME boards)"
  local row fqbn upload notes sketch_path build_path base
  row=$(board_rows | awk -F'\t' -v b="$board" '$1==b')
  [[ -n "$row" ]] || usage_error "unknown board '$board' (./$NAME boards)"
  fqbn=$(cut -f2 <<<"$row"); upload=$(cut -f3 <<<"$row"); notes=$(cut -f4 <<<"$row")
  sketch_path=$(sketch_dir "$sketch") || usage_error "no sketch folder: $sketch"
  build_path=$(sketch_build_dir "$sketch_path" "$board"); base=$(basename "$sketch_path")
  echo "# upload plan for $board ($fqbn): PRINTED ONLY, nothing was run."
  echo "# notes: ${notes:--}"
  if [[ ! -d "$build_path" ]]; then echo "# not compiled yet: ./$NAME compile $sketch_path $board"; fi
  echo "# find the port first (read-only): ./$NAME list"
  case "$upload" in
    serial)
      echo "./$NAME cli upload --fqbn $fqbn --port /dev/ttyUSB0 --input-dir $build_path $sketch_path    # adjust the port"
      if [[ "$board" == esp32s3 ]]; then
        echo "# esptool directly: $DATA_DIR/packages/esp32/tools/esptool_py/*/esptool --chip esp32s3 --port /dev/ttyUSB0 write_flash 0x0 $build_path/$base.ino.merged.bin"
      fi ;;
    uf2)
      local drive=RPI-RP2; [[ "$fqbn" == *rpipico2* ]] && drive=RP2350
      echo "# BOOTSEL drive (no tool): cp $build_path/$base.ino.uf2 /run/media/\$USER/$drive/"
      echo "./$NAME cli upload --fqbn $fqbn --port /dev/ttyACM0 --input-dir $build_path $sketch_path    # running sketch with USB serial" ;;
    dfu)
      echo "# DFU (dfu-util is not bundled; host package or probe tools): dfu-util -a 0 -s 0x08000000:leave -D $build_path/$base.ino.bin"
      echo "# SWD (ST-Link/CMSIS-DAP + OpenOCD/probe-rs): flash $build_path/$base.ino.elf (chip: see notes)"
      echo "./$NAME cli upload --fqbn $fqbn:upload_method=dfuMethod --input-dir $build_path $sketch_path    # needs STM32CubeProgrammer on PATH (proprietary)" ;;
    nrfutil)
      echo "# serial DFU (Adafruit bootloader; double-tap reset first): adafruit-nrfutil dfu serial --package $build_path/$base.ino.zip -p /dev/ttyACM0 -b 115200 --singlebank"
      echo "# UF2 drive: python3 $DATA_DIR/packages/adafruit/hardware/nrf52/*/tools/uf2conv/uf2conv.py -f 0xADA52840 -c -o $base.uf2 $build_path/$base.ino.hex, then copy to the NICENANO drive"
      echo "./$NAME cli upload --fqbn $fqbn --port /dev/ttyACM0 --input-dir $build_path $sketch_path    # uses adafruit-nrfutil from the pixi env" ;;
    *) echo "# upload method '$upload' in config/boards.tsv is not known to plan" ;;
  esac
}

tool_cmd_libs() {
  local name version installed
  printf '%-22s %-10s %-10s %s\n' library pinned installed used_by
  while IFS=$'\t' read -r name version used; do
    installed=$(lib_installed_version "$name")
    printf '%-22s %-10s %-10s %s\n' "$name" "$version" "${installed:--}" "${used:-}"
  done < <(lib_rows)
}

# elf <file.elf> [--section S] [--symbol S] [--machine M] [--max-flash N]: checks on a built ELF
tool_cmd_elf() {
  [[ $# -gt 0 ]] || usage_error "usage: ./$NAME elf <file.elf> [--machine ARM|Xtensa|RISC-V|AVR] [--symbol NAME]... [--section NAME]... [--max-text BYTES]"
  activate
  run python3 -I "$ROOT/lib/elf_check.py" "$@"
}

tool_cmd_cli() {
  activate
  if [[ "$DRY" == 1 ]]; then printf '+ arduino-cli --config-file %s %s\n' "$CLI_CONFIG" "$*"; return 0; fi
  exec "$ARDUINO_CLI" --config-file "$CLI_CONFIG" "$@"
}

hook_help() { # printed after boxtool's help: tool-specific examples and environment
  cat <<EOF

tool examples
  ./$NAME compile blink pico                 compile examples/blink for the Pico
  ./$NAME compile ~/fw/my_sketch arduino:avr:uno   any sketch, any FQBN
  ./$NAME plan nano blink                    print the upload commands (never uploads)
  ./$NAME new sketch my_fw --dir ~/fw        sketch from templates/sketch
  ./$NAME new freertos_esp32 tasks           any kind in templates/ (./$NAME new lists them)
  ./$NAME elf fw.ino.elf --machine ARM --symbol setup   section/symbol checks on a build
tool environment
  BOXT_JOBS          capped at 4 here (shared machine)
  ARDUINO_*          set by arduino-box from config/arduino-cli.yaml; not read from your shell
EOF
}

# ---------- dispatch: boxtool commands, tool_cmd_<name>, unknown -> usage error (exit 2) ----------
boxt_main "$@"
