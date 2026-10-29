// Host unit tests for src/settings.cpp with the pinned ArduinoJson. Exit 1 on a failure.
#include <cstdio>
#include <cstring>

#include "settings.h"

static int failures = 0;
#define CHECK(cond)                                              \
  do {                                                           \
    if (cond) std::printf("ok    %s\n", #cond);                  \
    else { std::printf("FAIL  %s (line %d)\n", #cond, __LINE__); failures++; } \
  } while (0)

int main() {
  Settings s;
  CHECK(parseSettings("{\"name\":\"bench\",\"period_ms\":250,\"led\":true}", s));
  CHECK(std::strcmp(s.name, "bench") == 0 && s.period_ms == 250 && s.led);
  CHECK(parseSettings("{\"led\":false}", s) && s.period_ms == 250 && !s.led);  // partial update
  CHECK(!parseSettings("{\"period_ms\":5}", s) && s.period_ms == 250);        // out of range: unchanged
  CHECK(!parseSettings("{not json", s));
  CHECK(parseSettings("{\"name\":\"a-very-long-device-name\"}", s) && std::strlen(s.name) == 15);
  char out[96];
  size_t n = writeSettings(s, out, sizeof(out));
  CHECK(n > 0 && std::strstr(out, "\"period_ms\":250") != nullptr);
  std::printf("host tests: %d failed\n", failures);
  return failures ? 1 : 0;
}
