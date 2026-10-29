# @NAME@

BLE peripheral with the Nordic UART Service (Bluefruit) for nice!nano / Pro Micro nRF52840: text from the phone is handled by `handleLine()`.

Made by `arduino-box new ble_uart_nrf52 @NAME@` (32_13_arduino). Default board: `nicenano` (`adafruit:nrf52:pca10056`, also in `sketch.yaml`).

```sh
arduino-box compile . nicenano          # output on $OUT/build/sketches/@NAME@/nicenano
arduino-box plan nicenano .             # prints the upload commands (never uploads)
```

nice!nano uses the `pca10056` variant: Arduino pin N = P0.N, P1.x = 32+x. The build makes a DFU `.zip` with adafruit-nrfutil (pixi env). Test with nRF Connect or Bluefruit Connect.
