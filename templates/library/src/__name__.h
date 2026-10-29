// @NAME@: Arduino library (1.5 format: library.properties + src/). Moving average over N samples.
#pragma once
#include <Arduino.h>

class @NAME@ {
 public:
  explicit @NAME@(uint8_t window = 8);
  ~@NAME@();
  float add(float sample);  // returns the current average
  float average() const { return count_ ? sum_ / count_ : 0.0f; }
  void reset();

 private:
  float *samples_;
  uint8_t window_, count_ = 0, next_ = 0;
  float sum_ = 0;
};
