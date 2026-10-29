// @NAME@ logic: time-based debouncer (no Arduino headers: compiled by the host tests too).
#pragma once
#include <stdint.h>

class Debounce {
 public:
  explicit Debounce(uint32_t ms) : ms_(ms) {}
  bool update(bool raw, uint32_t now);  // true when the stable state changed
  bool pressed() const { return stable_; }

 private:
  uint32_t ms_, since_ = 0;
  bool raw_ = false, stable_ = false;
};
