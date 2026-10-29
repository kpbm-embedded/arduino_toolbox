// json_config: device settings as JSON (ArduinoJson 7, pinned). Type a JSON line on Serial to
// change them, e.g. {"name":"bench","period_ms":250,"led":true}; the sketch answers with the result.
#include "src/settings.h"

static Settings settings;

void setup() {
  Serial.begin(115200);
  parseSettings("{\"name\":\"default\",\"period_ms\":500,\"led\":true}", settings);
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  static char line[96];
  static size_t len = 0;
  static uint32_t last = 0;
  while (Serial.available()) {
    char c = (char)Serial.read();
    if (c == '\n' || len == sizeof(line) - 1) {
      line[len] = 0;
      len = 0;
      char out[96];
      if (parseSettings(line, settings)) {
        writeSettings(settings, out, sizeof(out));
        Serial.println(out);
      } else {
        Serial.println(F("{\"error\":\"bad json\"}"));
      }
    } else if (c != '\r') {
      line[len++] = c;
    }
  }
  if (settings.led && millis() - last >= settings.period_ms) {
    last = millis();
    digitalWrite(LED_BUILTIN, !digitalRead(LED_BUILTIN));
  }
}
