# @NAME@

Line-based command shell on Serial with a command table (`help`, `led on|off`, `uptime`, `echo ...`); add a row to `kCommands` for a new command.

Made by `arduino-box new serial_cli @NAME@` (32_13_arduino). Default board: `nano` (`arduino:avr:nano`, also in `sketch.yaml`).

```sh
arduino-box compile . nano          # output on $OUT/build/sketches/@NAME@/nano
arduino-box plan nano .             # prints the upload commands (never uploads)
```

Same source for every board (`esp32s3`, `pico`, `blackpill`, `nicenano` needs `#include <Adafruit_TinyUSB.h>` first). Terminal: `arduino-box cli monitor -p /dev/ttyUSB0 -c baudrate=115200`.
