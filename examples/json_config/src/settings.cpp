#include "settings.h"

#include <ArduinoJson.h>
#include <string.h>

bool parseSettings(const char *json, Settings &s) {
  JsonDocument doc;
  if (deserializeJson(doc, json)) return false;
  uint32_t period = doc["period_ms"] | s.period_ms;
  if (period < 10 || period > 60000) return false;
  const char *name = doc["name"] | (const char *)s.name;
  if (name != s.name) {
    strncpy(s.name, name, sizeof(s.name) - 1);
    s.name[sizeof(s.name) - 1] = 0;
  }
  s.period_ms = period;
  s.led = doc["led"] | s.led;
  return true;
}

size_t writeSettings(const Settings &s, char *out, size_t size) {
  JsonDocument doc;
  doc["name"] = s.name;
  doc["period_ms"] = s.period_ms;
  doc["led"] = s.led;
  return serializeJson(doc, out, size);
}
