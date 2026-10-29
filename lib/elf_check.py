"""elf_check.py: checks on a firmware ELF built by arduino-cli (no board needed).

Usage: elf_check.py FILE.elf [--machine ARM|Xtensa|RISC-V|AVR] [--symbol NAME]... [--no-symbol NAME]...
                    [--section NAME]... [--max-text BYTES] [--max-data BYTES] [--string TEXT]...
                    [--code-from ADDR]
Prints the machine, the alloc sections with sizes, then one ok/FAIL line per check.
Exit 0 when every check passes, 1 when one fails, 2 on a usage error.
--symbol matches a symbol name exactly or as a C++ mangled name containing it (e.g. setup1, xTaskCreate).
--code-from checks that every executable section starts at or above ADDR (e.g. after a bootloader).
--string looks for a byte string in the loaded sections (e.g. a version injected with --build-property).
Depends on: pyelftools (pixi env of arduino-box).
"""
import argparse
import sys

from elftools.elf.elffile import ELFFile
from elftools.elf.sections import SymbolTableSection

MACHINES = {"EM_ARM": "ARM", "EM_XTENSA": "Xtensa", "EM_RISCV": "RISC-V", "EM_AVR": "AVR"}


def main(argv):
    ap = argparse.ArgumentParser(prog="elf_check.py", description="checks on a built firmware ELF")
    ap.add_argument("elf")
    ap.add_argument("--machine")
    ap.add_argument("--symbol", action="append", default=[])
    ap.add_argument("--no-symbol", action="append", default=[])
    ap.add_argument("--section", action="append", default=[])
    ap.add_argument("--string", action="append", default=[])
    ap.add_argument("--max-text", type=int)
    ap.add_argument("--max-data", type=int)
    ap.add_argument("--code-from", type=lambda v: int(v, 0))
    a = ap.parse_args(argv)
    fails = 0

    def check(ok, what):
        nonlocal fails
        print(("ok    " if ok else "FAIL  ") + what)
        if not ok:
            fails += 1

    with open(a.elf, "rb") as f:
        elf = ELFFile(f)
        machine = MACHINES.get(elf["e_machine"], elf["e_machine"])
        print(f"machine {machine}, {elf.elfclass}-bit, entry 0x{elf['e_entry']:x}")
        names, text, data, blob, code_lo = set(), 0, 0, b"", None
        sections = {}
        for s in elf.iter_sections():
            sections[s.name] = s
            if isinstance(s, SymbolTableSection):
                names.update(sym.name for sym in s.iter_symbols() if sym.name)
            if s["sh_flags"] & 2 and s["sh_size"]:  # SHF_ALLOC
                print(f"  {s.name:<28} 0x{s['sh_addr']:08x} {s['sh_size']:>9}")
                if s["sh_flags"] & 4 and (code_lo is None or s["sh_addr"] < code_lo):
                    code_lo = s["sh_addr"]
                if s["sh_type"] != "SHT_NOBITS":
                    blob += s.data()
                    if s["sh_flags"] & 4 or s["sh_flags"] & 1 == 0:  # exec or read-only: flash
                        text += s["sh_size"]
                    else:
                        data += s["sh_size"]
                else:
                    data += s["sh_size"]

    def has_symbol(n):
        return n in names or any(n in m for m in names if m.startswith("_Z"))

    if a.machine:
        check(machine == a.machine, f"machine {machine} (wanted {a.machine})")
    for n in a.section:
        check(n in sections, f"section {n}")
    for n in a.symbol:
        check(has_symbol(n), f"symbol {n}")
    for n in a.no_symbol:
        check(not has_symbol(n), f"no symbol {n}")
    for t in a.string:
        check(t.encode() in blob, f"string {t!r} in loaded sections")
    if a.code_from is not None:
        check(code_lo is not None and code_lo >= a.code_from,
              f"code starts at 0x{code_lo or 0:x} (>= 0x{a.code_from:x})")
    if a.max_text is not None:
        check(text <= a.max_text, f"flash-type sections {text} <= {a.max_text} bytes")
    if a.max_data is not None:
        check(data <= a.max_data, f"RAM-type sections {data} <= {a.max_data} bytes")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
