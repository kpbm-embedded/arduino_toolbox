// host_unit_test: frames from Serial are queued in a ring buffer and answered with their CRC-16.
// The logic lives in src/ without Arduino headers, so tests/test_logic.cpp runs it on the PC.
#include "src/ring_buffer.h"
#include "src/crc16.h"

static RingBuffer<uint8_t, 64> rx;

void setup() { Serial.begin(115200); }

void loop() {
  while (Serial.available() && !rx.full()) rx.push((uint8_t)Serial.read());
  if (rx.contains('\n')) {
    uint8_t frame[64];
    size_t n = 0;
    uint8_t b;
    while (rx.pop(b) && b != '\n') frame[n++] = b;
    Serial.print(F("crc16 0x"));
    Serial.println(crc16_ccitt(frame, n), HEX);
  }
}
