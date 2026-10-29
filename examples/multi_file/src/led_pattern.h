// Non-blocking LED blink pattern (C++ class in src/).
#pragma once
#include <Arduino.h>

class LedPattern {
 public:
  LedPattern(uint8_t pin, const uint16_t *steps, size_t count) : pin_(pin), steps_(steps), count_(count) {}
  void begin();
  void update(uint32_t now_ms);

 private:
  uint8_t pin_;
  const uint16_t *steps_;
  size_t count_;
  size_t index_ = 0;
  uint32_t since_ = 0;
};
