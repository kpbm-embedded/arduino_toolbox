// @NAME@: multi-file sketch (arduino-box new multi_file @NAME@). Logic in src/app.*, settings in config.h.
#include "config.h"
#include "src/app.h"

static App app;

void setup() {
  Serial.begin(SERIAL_BAUD);
  pinMode(LED_BUILTIN, OUTPUT);
  app.begin(millis());
}

void loop() {
  if (app.update(millis())) digitalWrite(LED_BUILTIN, app.ledOn() ? HIGH : LOW);
  if (Serial.available() && Serial.read() == 's') Serial.println(app.ticks());
}
