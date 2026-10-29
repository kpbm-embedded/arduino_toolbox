// size_budget: a lookup-table sketch whose flash/RAM use is checked against budget.tsv by the
// example's test (the pattern for a CI size gate: compile with --format json, compare, fail).
#include <Arduino.h>

#ifndef TABLE_SIZE
#define TABLE_SIZE 256
#endif

// sine table in flash (PROGMEM is a no-op on the 32-bit cores)
static const uint8_t kSine[TABLE_SIZE] PROGMEM = {
#include "sine_table.h"
};
static uint8_t history[64];  // RAM

void setup() { Serial.begin(115200); }

void loop() {
  static uint16_t i = 0;
  uint8_t v = pgm_read_byte(&kSine[i % TABLE_SIZE]);
  history[i % sizeof(history)] = v;
  if (i % sizeof(history) == 0) {
    uint16_t sum = 0;
    for (uint8_t h : history) sum += h;
    Serial.println(sum / sizeof(history));
  }
  i++;
  delay(10);
}
