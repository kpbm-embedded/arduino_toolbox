// Settings <-> JSON with ArduinoJson; no Arduino headers needed, so it also builds on the host.
#pragma once
#include <stddef.h>
#include <stdint.h>

struct Settings {
  char name[16] = "unset";
  uint32_t period_ms = 1000;
  bool led = false;
};

// Missing keys keep their current value; returns false on invalid JSON or a period outside 10..60000.
bool parseSettings(const char *json, Settings &s);
size_t writeSettings(const Settings &s, char *out, size_t size);
