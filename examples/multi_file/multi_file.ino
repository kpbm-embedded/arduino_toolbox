// multi_file: a sketch split into several files. arduino-cli builds the .ino (all .ino files are
// concatenated), the .cpp/.c next to it, and everything below src/ (included with "src/...").
#include "config.h"
#include "src/led_pattern.h"
#include "src/checksum.h"

static LedPattern pattern(LED_BUILTIN, PATTERN_SOS, sizeof(PATTERN_SOS) / sizeof(PATTERN_SOS[0]));

void setup() {
  Serial.begin(SERIAL_BAUD);
  pattern.begin();
  static const uint8_t banner[] = "multi_file";
  Serial.print(F("banner checksum 0x"));
  Serial.println(checksum8(banner, sizeof(banner) - 1), HEX);
}

void loop() {
  pattern.update(millis());
}
