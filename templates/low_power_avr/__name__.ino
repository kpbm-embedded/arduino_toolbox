// @NAME@: AVR power-down sleep, wake on D2 (INT0) or watchdog (arduino-box new low_power_avr @NAME@).
#include <avr/power.h>
#include <avr/sleep.h>
#include <avr/wdt.h>

static volatile uint8_t wakeReason = 0;  // 1 = button, 2 = watchdog

ISR(WDT_vect) { wakeReason = 2; }
static void onButton() { wakeReason = 1; }

static void sleepNow() {
  ADCSRA &= ~_BV(ADEN);
  cli();
  MCUSR &= ~_BV(WDRF);
  WDTCSR = _BV(WDCE) | _BV(WDE);
  WDTCSR = _BV(WDIE) | _BV(WDP3) | _BV(WDP0);  // 8 s interrupt
  set_sleep_mode(SLEEP_MODE_PWR_DOWN);
  sleep_enable();
  sleep_bod_disable();
  sei();
  sleep_cpu();
  sleep_disable();
  wdt_disable();
  ADCSRA |= _BV(ADEN);
}

void setup() {
  Serial.begin(115200);
  pinMode(2, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(2), onButton, FALLING);
}

void loop() {
  Serial.flush();
  sleepNow();
  Serial.println(wakeReason == 1 ? F("@NAME@ woke: button") : F("@NAME@ woke: watchdog"));
}
