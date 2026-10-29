#include "app.h"
#include "../config.h"

bool App::update(uint32_t now) {
  if (now - last_ < @NAME_UPPER@_PERIOD_MS) return false;
  last_ = now;
  ticks_++;
  led_ = !led_;
  return true;
}
