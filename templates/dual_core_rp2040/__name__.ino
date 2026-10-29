// @NAME@: dual core on RP2040/RP2350 (arduino-box new dual_core_rp2040 @NAME@).
#include <Arduino.h>

void setup() { Serial.begin(115200); }

void loop() {  // core 0: report
  uint32_t avg;
  if (rp2040.fifo.pop_nb(&avg)) Serial.printf("@NAME@ core1 average %lu\n", (unsigned long)avg);
}

void setup1() { analogReadResolution(12); }

void loop1() {  // core 1: sample 64 values, push the average
  uint32_t sum = 0;
  for (int i = 0; i < 64; i++) {
    sum += analogRead(A0);
    delayMicroseconds(500);
  }
  rp2040.fifo.push(sum / 64);
}
