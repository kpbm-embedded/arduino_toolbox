// avr_low_power: ATmega328P (Nano) sleeps in power-down (~ a few uA for the chip; the Nano's
// regulator, USB chip and LED draw more), the watchdog interrupt wakes it every 8 s. A boot
// counter is kept in EEPROM with simple wear levelling (16 slots, the highest sequence wins).
#include <avr/interrupt.h>
#include <avr/power.h>
#include <avr/sleep.h>
#include <avr/wdt.h>
#include <EEPROM.h>

static const uint8_t SLOTS = 16;
static volatile bool woke = false;

ISR(WDT_vect) { woke = true; }

static uint8_t newestSlot(uint32_t &seq) {
  uint8_t best = 0;
  seq = 0;
  for (uint8_t i = 0; i < SLOTS; i++) {
    uint32_t v;
    EEPROM.get(i * sizeof(uint32_t), v);
    if (v != 0xFFFFFFFFUL && v >= seq) { seq = v; best = i; }
  }
  return best;
}

static uint32_t countBoot() {
  uint32_t seq;
  uint8_t slot = newestSlot(seq);
  seq = (seq == 0xFFFFFFFFUL) ? 1 : seq + 1;
  EEPROM.put(((slot + 1) % SLOTS) * sizeof(uint32_t), seq);  // next slot: spreads the writes
  return seq;
}

static void watchdog8s() {
  cli();
  MCUSR &= ~_BV(WDRF);
  WDTCSR = _BV(WDCE) | _BV(WDE);
  WDTCSR = _BV(WDIE) | _BV(WDP3) | _BV(WDP0);  // interrupt only, 8 s
  sei();
}

void setup() {
  Serial.begin(115200);
  Serial.print(F("boot #"));
  Serial.println(countBoot());
  Serial.flush();
  power_adc_disable();
  watchdog8s();
}

void loop() {
  set_sleep_mode(SLEEP_MODE_PWR_DOWN);
  sleep_enable();
  sleep_bod_disable();
  sleep_cpu();
  sleep_disable();
  if (woke) {
    woke = false;
    Serial.println(F("wdt wake"));
    Serial.flush();
  }
}
