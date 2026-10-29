// dual_core_rp2040: arduino-pico runs setup()/loop() on core 0 and setup1()/loop1() on core 1.
// Core 1 does the "work" (sums blocks of numbers) and sends results through the hardware FIFO;
// core 0 prints them. A mutex guards a shared counter.
#include <Arduino.h>
#include <pico/mutex.h>

static mutex_t statsLock;
static volatile uint32_t blocksDone = 0;

void setup() {
  Serial.begin(115200);
  mutex_init(&statsLock);
}

void loop() {
  uint32_t result;
  if (rp2040.fifo.pop_nb(&result)) {
    mutex_enter_blocking(&statsLock);
    uint32_t done = blocksDone;
    mutex_exit(&statsLock);
    Serial.printf("core0: block %lu sum %lu\n", (unsigned long)done, (unsigned long)result);
  }
}

void setup1() { delay(100); }

void loop1() {
  static uint32_t base = 0;
  uint32_t sum = 0;
  for (uint32_t i = 0; i < 1000; i++) sum += base + i;
  base += 1000;
  mutex_enter_blocking(&statsLock);
  blocksDone++;
  mutex_exit(&statsLock);
  rp2040.fifo.push(sum);
  delay(200);
}
