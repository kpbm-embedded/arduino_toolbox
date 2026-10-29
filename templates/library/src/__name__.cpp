#include "@NAME@.h"

@NAME@::@NAME@(uint8_t window) : samples_(new float[window ? window : 1]), window_(window ? window : 1) {}
@NAME@::~@NAME@() { delete[] samples_; }

float @NAME@::add(float sample) {
  if (count_ == window_) sum_ -= samples_[next_];
  else count_++;
  samples_[next_] = sample;
  sum_ += sample;
  next_ = (next_ + 1) % window_;
  return average();
}

void @NAME@::reset() { count_ = next_ = 0; sum_ = 0; }
