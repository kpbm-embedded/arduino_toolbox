// Fixed-size ring buffer (header-only, no Arduino headers: unit-tested on the host).
#pragma once
#include <stddef.h>

template <typename T, size_t N>
class RingBuffer {
 public:
  bool empty() const { return count_ == 0; }
  bool full() const { return count_ == N; }
  size_t size() const { return count_; }
  bool push(const T &v) {
    if (full()) return false;
    buf_[head_] = v;
    head_ = (head_ + 1) % N;
    count_++;
    return true;
  }
  bool pop(T &v) {
    if (empty()) return false;
    v = buf_[tail_];
    tail_ = (tail_ + 1) % N;
    count_--;
    return true;
  }
  bool contains(const T &v) const {
    for (size_t i = 0; i < count_; i++)
      if (buf_[(tail_ + i) % N] == v) return true;
    return false;
  }

 private:
  T buf_[N] = {};
  size_t head_ = 0, tail_ = 0, count_ = 0;
};
