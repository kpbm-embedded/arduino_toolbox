#!/usr/bin/env bash
# about: CI size gate: arduino-cli --format json section sizes vs budget.tsv (flash/RAM per board), plus a must-fail check
# Usage (through ./arduino-box examples ...): example.sh build | test | run [boards ...]
#   test compiles with --format json, compares text/data with budget.tsv and fails when a board is over budget;
#   a 1-byte budget must be reported as over (proves the gate is not a no-op).
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ALL_BOARDS=(nano blackpill esp32c3 pico)
gate() { # board flash-budget ram-budget -> exit 0 within budget, 1 over
  local json="${EX_OUT:?}/$1.json"
  python3 -I - "$json" "$1" "$2" "$3" <<'PY'
import json, sys
path, board, flash_max, ram_max = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
res = json.load(open(path))
sizes = {s["name"]: s for s in res["builder_result"]["executable_sections_size"]}
flash, ram = sizes["text"]["size"], sizes["data"]["size"]
over = flash > flash_max or ram > ram_max
print(f"{'OVER ' if over else 'ok   '} {board}: flash {flash}/{flash_max} B, RAM {ram}/{ram_max} B "
      f"(board max {sizes['text'].get('max_size', '?')}/{sizes['data'].get('max_size', '?')})")
sys.exit(1 if over else 0)
PY
}
ex_test() { # [boards...]: compile with JSON output, then the budget gate
  local board flash ram rc=0
  if [[ $# -eq 0 ]]; then set -- "${ALL_BOARDS[@]}"; fi
  mkdir -p "${EX_OUT:?}"
  for board in "$@"; do
    echo "== $SKETCH for $board (--format json)"
    "$BOX" compile "$EX_DIR" "$board" --format json >"$EX_OUT/$board.json"
    read -r flash ram < <(awk -F'\t' -v b="$board" '$1==b {print $2, $3}' "$EX_DIR/budget.tsv")
    [[ -n "$flash" ]] || { echo "FAIL  no budget for $board in budget.tsv"; rc=1; continue; }
    gate "$board" "$flash" "$ram" || rc=1
  done
  if gate "$1" 1 1 >/dev/null; then echo "FAIL  a 1-byte budget passed the gate"; rc=1
  else echo "ok    a 1-byte budget is reported as over"; fi
  [[ "$rc" == 0 ]] && echo "PASS $SKETCH ($# boards within budget)"
  return "$rc"
}
ex_main "$@"
