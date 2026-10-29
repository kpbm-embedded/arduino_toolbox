// @NAME@: STM32 HardwareTimer interrupt + PWM (arduino-box new stm32_timer @NAME@).
#include <Arduino.h>

static const uint32_t PWM_PIN = PA6;  // TIM3_CH1 on F4/G4/H5/H7
static HardwareTimer *timer;
static volatile uint32_t periods = 0;

static void onPeriod() { periods++; }

void setup() {
  Serial.begin(115200);
  TIM_TypeDef *instance = (TIM_TypeDef *)pinmap_peripheral(digitalPinToPinName(PWM_PIN), PinMap_PWM);
  uint32_t channel = STM_PIN_CHANNEL(pinmap_function(digitalPinToPinName(PWM_PIN), PinMap_PWM));
  timer = new HardwareTimer(instance);
  timer->setPWM(channel, PWM_PIN, 1000, 25, onPeriod);  // 1 kHz, 25 % duty, callback every period
}

void loop() {
  static uint32_t last = 0;
  if (millis() - last >= 1000) {
    last = millis();
    Serial.printf("@NAME@ periods %lu\n", (unsigned long)periods);
  }
}
