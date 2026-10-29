// Host unit tests for src/ (built and run by example.sh test with the pixi g++). Exit 1 on a failure.
#include <cstdio>
#include <cstring>

#include "crc16.h"
#include "ring_buffer.h"

static int failures = 0;
#define CHECK(cond)                                              \
  do {                                                           \
    if (cond) std::printf("ok    %s\n", #cond);                  \
    else { std::printf("FAIL  %s (line %d)\n", #cond, __LINE__); failures++; } \
  } while (0)

int main() {
  const char *check = "123456789";  // the CRC catalogue check string
  CHECK(crc16_ccitt(reinterpret_cast<const uint8_t *>(check), std::strlen(check)) == 0x29B1);
  CHECK(crc16_ccitt(nullptr, 0) == 0xFFFF);

  RingBuffer<int, 3> rb;
  int v = 0;
  CHECK(rb.empty() && !rb.pop(v));
  CHECK(rb.push(1) && rb.push(2) && rb.push(3));
  CHECK(rb.full() && !rb.push(4));
  CHECK(rb.contains(2) && !rb.contains(9));
  CHECK(rb.pop(v) && v == 1);
  CHECK(rb.push(4) && rb.size() == 3);  // wraps around
  CHECK(rb.pop(v) && v == 2 && rb.pop(v) && v == 3 && rb.pop(v) && v == 4 && rb.empty());
  std::printf("host tests: %d failed\n", failures);
  return failures ? 1 : 0;
}
