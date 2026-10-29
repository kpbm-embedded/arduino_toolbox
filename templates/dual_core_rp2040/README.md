# @NAME@

Core 1 samples the ADC into a buffer, core 0 reports; the cores talk through the hardware FIFO (`rp2040.fifo`).

Made by `arduino-box new dual_core_rp2040 @NAME@` (32_13_arduino). Default board: `pico2` (`rp2040:rp2040:rpipico2`, also in `sketch.yaml`).

```sh
arduino-box compile . pico2          # output on $OUT/build/sketches/@NAME@/pico2
arduino-box plan pico2 .             # prints the upload commands (never uploads)
```

Also builds for `pico` (RP2040). Anything core 1 shares with core 0 needs the FIFO, a `mutex_t` or atomics.
