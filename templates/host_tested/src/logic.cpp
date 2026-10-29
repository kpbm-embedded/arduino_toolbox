#include "logic.h"

bool Debounce::update(bool raw, uint32_t now) {
  if (raw != raw_) {
    raw_ = raw;
    since_ = now;
    return false;
  }
  if (raw_ != stable_ && now - since_ >= ms_) {
    stable_ = raw_;
    return true;
  }
  return false;
}
