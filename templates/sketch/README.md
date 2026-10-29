# @NAME@

Arduino sketch from the `sketch` template of 32_13_arduino (`arduino-box new sketch @NAME@`).
The folder name and the `.ino` name must match (Arduino rule).

```sh
arduino-box compile . nano          # or esp32s3 | pico | blackpill | <FQBN>; output on $OUT/build/sketches/@NAME@/<board>
arduino-box plan nano .             # prints the upload commands (never uploads)
arduino-box cli lib install "<Library>@<version>"   # libraries go to the box's user/libraries
```

`sketch.yaml` sets `default_fqbn` for a plain `arduino-cli compile`.
