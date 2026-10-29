#!/usr/bin/env bash
# Shared by examples/*/example.sh (sourced): compile one sketch for the owned boards (ALL_BOARDS,
# which an example may set after sourcing), check the artifacts and ELF (ex_elf), or print the upload plans. Runs inside ./arduino-box examples
# (EX_DIR, BOXT_ROOT, BOXT_BUILD set). Depends on ./arduino-box compile and plan.
set -euo pipefail
BOX="${BOXT_ROOT:?run through ./arduino-box examples}/arduino-box"
SKETCH=$(basename "${EX_DIR:?}")
ALL_BOARDS=(nano esp32s3 pico blackpill)

artifact() { # board -> the main firmware file arduino-cli writes for it
  local build_path="${BOXT_BUILD:?}/sketches/$SKETCH/$1"
  case "$1" in
    nano) echo "$build_path/$SKETCH.ino.hex" ;;
    esp32s3) echo "$build_path/$SKETCH.ino.merged.bin" ;;
    pico) echo "$build_path/$SKETCH.ino.uf2" ;;
    blackpill|weact_*) echo "$build_path/$SKETCH.ino.bin" ;;
    esp32c3) echo "$build_path/$SKETCH.ino.merged.bin" ;;
    pico2) echo "$build_path/$SKETCH.ino.uf2" ;;
    nicenano) echo "$build_path/$SKETCH.ino.zip" ;;
    *) echo "$build_path/$SKETCH.ino.bin" ;;
  esac
}
elf_of() { echo "${BOXT_BUILD:?}/sketches/$SKETCH/$1/$SKETCH.ino.elf"; }   # board -> built ELF
ex_elf() { # board elf_check-args...: section/symbol/arch checks on the board's ELF (lib/elf_check.py)
  local board=$1; shift
  echo "== elf checks $SKETCH/$board"
  python3 -I "$BOXT_ROOT/lib/elf_check.py" "$(elf_of "$board")" "$@"
}
ex_build() { # [boards...]
  local board
  if [[ $# -eq 0 ]]; then set -- "${ALL_BOARDS[@]}"; fi
  for board in "$@"; do
    echo "== $SKETCH for $board"
    "$BOX" compile "$EX_DIR" "$board"
  done
}
ex_test() { # [boards...]
  local board file failures=0
  if [[ $# -eq 0 ]]; then set -- "${ALL_BOARDS[@]}"; fi
  ex_build "$@"
  for board in "$@"; do
    file=$(artifact "$board")
    if [[ -s "$file" ]]; then echo "ok    $SKETCH/$board: $(basename "$file") $(stat -c %s "$file") bytes"
    else echo "FAIL  $SKETCH/$board: $file missing"; failures=$((failures + 1)); fi
  done
  [[ "$failures" == 0 ]] || return 1
  echo "PASS $SKETCH ($# boards)"
}
ex_run() { # [boards...]: print the upload plans (never uploads)
  local board
  if [[ $# -eq 0 ]]; then set -- "${ALL_BOARDS[@]}"; fi
  for board in "$@"; do "$BOX" plan "$board" "$EX_DIR"; echo; done
}
ex_main() { # build|test|run [boards...]; an example may define ex_extra_test (run after ex_test)
  local action=${1:-run}
  if [[ $# -gt 0 ]]; then shift; fi
  case "$action" in
    build) ex_build "$@" ;;
    test)
      if [[ $# -eq 0 ]]; then set -- "${ALL_BOARDS[@]}"; fi
      ex_test "$@"
      if declare -F ex_extra_test >/dev/null; then ex_extra_test "$@"; fi ;;
    run) ex_run "$@" ;;
    *) echo "usage: example.sh build|test|run [${ALL_BOARDS[*]}]" >&2; exit 2 ;;
  esac
}
