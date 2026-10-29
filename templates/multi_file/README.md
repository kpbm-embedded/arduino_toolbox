# @NAME@

Sketch split into a config header and a C++ module in `src/` (arduino-cli compiles `src/` recursively; include it as `"src/app.h"`).

Made by `arduino-box new multi_file @NAME@` (32_13_arduino). Default board: `pico` (`rp2040:rp2040:rpipico`, also in `sketch.yaml`).

```sh
arduino-box compile . pico          # output on $OUT/build/sketches/@NAME@/pico
arduino-box plan pico .             # prints the upload commands (never uploads)
```

Add modules as `src/<name>.h/.cpp`; keep hardware access in the .ino so modules stay testable on the PC (see the `host_tested` template).
