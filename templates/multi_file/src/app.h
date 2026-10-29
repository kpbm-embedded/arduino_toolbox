// @NAME@ application state machine: no Arduino calls, the .ino passes the time in.
#pragma once
#include <stdint.h>

class App {
 public:
  void begin(uint32_t now) { last_ = now; }
  bool update(uint32_t now);  // true when the LED state changed
  bool ledOn() const { return led_; }
  uint32_t ticks() const { return ticks_; }

 private:
  uint32_t last_ = 0, ticks_ = 0;
  bool led_ = false;
};
