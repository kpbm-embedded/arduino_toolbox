// Host unit tests for src/logic.cpp: `make test`. Exit 1 on a failure.
#include <cstdio>

#include "logic.h"

static int failures = 0;
#define CHECK(cond)                                                              \
  do {                                                                           \
    if (cond) std::printf("ok    %s\n", #cond);                                  \
    else { std::printf("FAIL  %s (line %d)\n", #cond, __LINE__); failures++; }   \
  } while (0)

int main() {
  Debounce d(20);
  CHECK(!d.update(true, 0));                  // edge seen, not stable yet
  CHECK(!d.update(false, 5) && !d.pressed()); // bounce
  CHECK(!d.update(true, 10));
  CHECK(!d.update(true, 25));                 // 15 ms stable: not enough
  CHECK(d.update(true, 30) && d.pressed());   // 20 ms stable: pressed
  CHECK(!d.update(true, 100));                // no change
  CHECK(!d.update(false, 110) && d.update(false, 130) && !d.pressed());
  std::printf("@NAME@ host tests: %d failed\n", failures);
  return failures ? 1 : 0;
}
