// zig_staticlib: functions written in Zig (zig/fixed.zig, freestanding, C ABI) called from a sketch.
// example.sh builds them with 32_24_microzig's pinned Zig into a precompiled Arduino library
// (precompiled=true, ldflags=-lbox_zig_dsp) and compiles with --library <that folder>.
#include <box_zig_dsp.h>

void setup() {
  Serial.begin(115200);
  Serial.print(F("zig_isqrt(1000000) = "));
  Serial.println(zig_isqrt(1000000UL));  // 1000
}

void loop() {
  uint32_t mv = zig_scale((uint32_t)analogRead(A0), 1023, 3300);  // 10-bit reading -> millivolts
  Serial.println(mv);
  delay(250);
}
