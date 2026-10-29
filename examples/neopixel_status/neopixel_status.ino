// neopixel_status: one WS2812 shows the device state (boot = blue, ok = green breathing,
// error = red blink). Pin per board: ESP32-S3-DevKitC-1 GPIO48 (on board), ESP32-C3 boards GPIO8,
// Pico GP16 and nice!nano P0.06 (external LED; 3.3 V data usually works at short distance).
#if defined(ARDUINO_ARCH_NRF52)
#include <Adafruit_TinyUSB.h>  // USB CDC Serial on the Adafruit nRF52 core
#endif
#include <Adafruit_NeoPixel.h>

#if defined(CONFIG_IDF_TARGET_ESP32S3)
#define PIXEL_PIN 48
#elif defined(CONFIG_IDF_TARGET_ESP32C3)
#define PIXEL_PIN 8
#elif defined(ARDUINO_ARCH_RP2040)
#define PIXEL_PIN 16
#else
#define PIXEL_PIN 6
#endif

enum class State { Boot, Ok, Error };
static Adafruit_NeoPixel pixel(1, PIXEL_PIN, NEO_GRB + NEO_KHZ800);
static State state = State::Boot;

static void show(State s, uint32_t now) {
  uint8_t level = (uint8_t)((now / 8) % 256);
  if (level > 127) level = 255 - level;  // triangle 0..127..0
  switch (s) {
    case State::Boot: pixel.setPixelColor(0, pixel.Color(0, 0, 60)); break;
    case State::Ok: pixel.setPixelColor(0, pixel.Color(0, level / 2, 0)); break;
    case State::Error: pixel.setPixelColor(0, (now / 250) % 2 ? pixel.Color(80, 0, 0) : 0); break;
  }
  pixel.show();
}

void setup() {
  Serial.begin(115200);
  pixel.begin();
  show(State::Boot, 0);
  delay(500);
  state = State::Ok;
}

void loop() {
  if (Serial.available()) {
    char c = (char)Serial.read();
    if (c == 'e') state = State::Error;
    if (c == 'o') state = State::Ok;
  }
  show(state, millis());
  delay(20);
}
