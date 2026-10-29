# @NAME@

Wi-Fi station with reconnect and a small HTTP server: `GET /status` answers JSON (pinned ArduinoJson).

Made by `arduino-box new wifi_esp32 @NAME@` (32_13_arduino). Default board: `esp32c3` (`esp32:esp32:esp32c3`, also in `sketch.yaml`).

```sh
arduino-box compile . esp32c3          # output on $OUT/build/sketches/@NAME@/esp32c3
arduino-box plan esp32c3 .             # prints the upload commands (never uploads)
```

Credentials: copy `secrets.example.h` to `secrets.h` (gitignored) and fill it in; without it the sketch builds with empty credentials and only retries. Also builds for `esp32s3`.
