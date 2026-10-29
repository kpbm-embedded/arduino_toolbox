// usb_hid_rp2040: the Pico appears as a USB keyboard + mouse (arduino-pico's Keyboard/Mouse
// libraries on its TinyUSB stack). A button on GP15 (to GND) types a line; holding it moves the
// mouse in a small square. Bounce2 (pinned in config/libraries.tsv) debounces the button.
#include <Keyboard.h>
#include <Mouse.h>
#include <Bounce2.h>

static const uint8_t BUTTON_PIN = 15;
static Bounce2::Button button;
static const char kText[] = "box-hid: hello from the Pico\n";

void setup() {
  button.attach(BUTTON_PIN, INPUT_PULLUP);
  button.interval(10);
  button.setPressedState(LOW);
  pinMode(LED_BUILTIN, OUTPUT);
  Keyboard.begin();
  Mouse.begin();
}

void loop() {
  static uint32_t lastMove = 0;
  static uint8_t side = 0;
  button.update();
  if (button.pressed()) {
    digitalWrite(LED_BUILTIN, HIGH);
    Keyboard.print(kText);
  }
  if (button.isPressed() && millis() - lastMove > 250) {
    static const int8_t dx[] = {20, 0, -20, 0}, dy[] = {0, 20, 0, -20};
    Mouse.move(dx[side], dy[side]);
    side = (side + 1) % 4;
    lastMove = millis();
  }
  if (button.released()) digitalWrite(LED_BUILTIN, LOW);
}
