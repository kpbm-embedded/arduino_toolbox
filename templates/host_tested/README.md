# @NAME@

Logic in `src/` without Arduino headers, unit-tested on the PC; the .ino only does I/O.

Made by `arduino-box new host_tested @NAME@` (32_13_arduino). Default board: `nano` (`arduino:avr:nano`, also in `sketch.yaml`).

```sh
arduino-box compile . nano          # output on $OUT/build/sketches/@NAME@/nano
arduino-box plan nano .             # prints the upload commands (never uploads)
```

Host tests: `arduino-box run make test` (g++ from the pixi env; `tests/` is ignored by arduino-cli; output in `build-host/`, gitignored).
