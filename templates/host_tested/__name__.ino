// @NAME@: logic in src/logic.* (host-tested with `make test`), I/O here.
#include "src/logic.h"

static Debounce button(20);

void setup() {
  pinMode(2, INPUT_PULLUP);
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  if (button.update(digitalRead(2) == LOW, millis()) && button.pressed()) {
    digitalWrite(LED_BUILTIN, !digitalRead(LED_BUILTIN));
  }
}
