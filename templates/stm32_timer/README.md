# @NAME@

STM32duino HardwareTimer: a periodic interrupt and a PWM output from one timer (TIM3 CH1 on PA6 here).

Made by `arduino-box new stm32_timer @NAME@` (32_13_arduino). Default board: `weact_g431` (`STMicroelectronics:stm32:GenG4:pnum=GENERIC_G431CBUX`, also in `sketch.yaml`).

```sh
arduino-box compile . weact_g431          # output on $OUT/build/sketches/@NAME@/weact_g431
arduino-box plan weact_g431 .             # prints the upload commands (never uploads)
```

Also builds for `blackpill`, `weact_h562`, `weact_h743`. Check the timer/pin pair in the variant's `PeripheralPins.c` when changing the pin.
