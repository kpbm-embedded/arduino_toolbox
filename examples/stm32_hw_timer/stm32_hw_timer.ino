// stm32_hw_timer: STM32duino HardwareTimer on TIM2 at 1 kHz; the interrupt counts ticks and
// toggles the LED every 500 ms. Prints the 96-bit chip UID and compares the timer with HAL_GetTick().
// Same source for F411 (BlackPill), G431, H562 and H743 (WeAct boards).
#include <Arduino.h>

#ifndef LED_BUILTIN
#define LED_BUILTIN PC13
#endif

static HardwareTimer *timer;
static volatile uint32_t ticks = 0;

void onTick() {
  ticks++;
  if (ticks % 500 == 0) digitalWriteFast(digitalPinToPinName(LED_BUILTIN), ticks % 1000 == 0);
}

void setup() {
  Serial.begin(115200);
  pinMode(LED_BUILTIN, OUTPUT);
  timer = new HardwareTimer(TIM2);
  timer->setOverflow(1000, HERTZ_FORMAT);
  timer->attachInterrupt(onTick);
  timer->resume();
  Serial.printf("UID %08lx-%08lx-%08lx, SystemCoreClock %lu Hz\n", (unsigned long)HAL_GetUIDw2(),
                (unsigned long)HAL_GetUIDw1(), (unsigned long)HAL_GetUIDw0(), (unsigned long)SystemCoreClock);
}

void loop() {
  static uint32_t last = 0;
  if (millis() - last >= 1000) {
    last = millis();
    noInterrupts();
    uint32_t t = ticks;
    interrupts();
    Serial.printf("timer ticks %lu, HAL_GetTick %lu\n", (unsigned long)t, (unsigned long)HAL_GetTick());
  }
}
