# @NAME@

ATmega328P power-down sleep, woken by a falling edge on D2 (INT0) or the watchdog (8 s); `sleepNow()` turns off ADC and BOD.

Made by `arduino-box new low_power_avr @NAME@` (32_13_arduino). Default board: `nano` (`arduino:avr:nano`, also in `sketch.yaml`).

```sh
arduino-box compile . nano          # output on $OUT/build/sketches/@NAME@/nano
arduino-box plan nano .             # prints the upload commands (never uploads)
```

The Nano board itself draws mA (regulator, USB chip, power LED); for uA measure a bare ATmega328P or remove the LED.
