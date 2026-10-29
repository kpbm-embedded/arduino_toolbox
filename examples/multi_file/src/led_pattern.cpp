#include "led_pattern.h"

void LedPattern::begin() {
  pinMode(pin_, OUTPUT);
  digitalWrite(pin_, HIGH);
}

void LedPattern::update(uint32_t now_ms) {
  if (now_ms - since_ < steps_[index_]) return;
  since_ = now_ms;
  index_ = (index_ + 1) % count_;
  digitalWrite(pin_, (index_ % 2 == 0) ? HIGH : LOW);
}
