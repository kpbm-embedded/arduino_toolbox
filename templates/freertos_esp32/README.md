# @NAME@

Two FreeRTOS tasks (sensor -> queue -> reporter) with an event group for a 'pause' flag, on the ESP32 Arduino core (FreeRTOS underneath).

Made by `arduino-box new freertos_esp32 @NAME@` (32_13_arduino). Default board: `esp32s3` (`esp32:esp32:esp32s3`, also in `sketch.yaml`).

```sh
arduino-box compile . esp32s3          # output on $OUT/build/sketches/@NAME@/esp32s3
arduino-box plan esp32s3 .             # prints the upload commands (never uploads)
```

Also builds for `esp32c3` (single core: both tasks run on core 0). Stack sizes are in bytes on ESP32 (not words); check `uxTaskGetStackHighWaterMark` output on Serial.
