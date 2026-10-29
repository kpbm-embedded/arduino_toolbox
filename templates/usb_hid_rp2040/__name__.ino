// @NAME@: USB HID macro pad (arduino-box new usb_hid_rp2040 @NAME@). Buttons to GND on GP2..GP5.
#include <Keyboard.h>
#include <Bounce2.h>

struct Macro {
  uint8_t pin;
  uint8_t modifier;  // 0 = none
  char key;
};
static const Macro kKeys[] = {
    {2, KEY_LEFT_CTRL, 'c'}, {3, KEY_LEFT_CTRL, 'v'}, {4, KEY_LEFT_CTRL, 'z'}, {5, 0, ' '}};
static const size_t kCount = sizeof(kKeys) / sizeof(kKeys[0]);
static Bounce2::Button buttons[kCount];

void setup() {
  for (size_t i = 0; i < kCount; i++) {
    buttons[i].attach(kKeys[i].pin, INPUT_PULLUP);
    buttons[i].interval(10);
    buttons[i].setPressedState(LOW);
  }
  Keyboard.begin();
}

void loop() {
  for (size_t i = 0; i < kCount; i++) {
    buttons[i].update();
    if (!buttons[i].pressed()) continue;
    if (kKeys[i].modifier) Keyboard.press(kKeys[i].modifier);
    Keyboard.press(kKeys[i].key);
    delay(10);
    Keyboard.releaseAll();
  }
}
