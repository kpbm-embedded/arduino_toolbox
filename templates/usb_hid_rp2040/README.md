# @NAME@

USB HID macro pad on the Pico: buttons on GP2..GP5 send key combinations (arduino-pico Keyboard + the pinned Bounce2).

Made by `arduino-box new usb_hid_rp2040 @NAME@` (32_13_arduino). Default board: `pico` (`rp2040:rp2040:rpipico`, also in `sketch.yaml`).

```sh
arduino-box compile . pico          # output on $OUT/build/sketches/@NAME@/pico
arduino-box plan pico .             # prints the upload commands (never uploads)
```

Also builds for `pico2`. Edit the `kKeys` table; `KEY_LEFT_CTRL` etc. come from `Keyboard.h`.
