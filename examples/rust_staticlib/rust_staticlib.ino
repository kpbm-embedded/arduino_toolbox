// rust_staticlib: functions written in Rust (rust/src/lib.rs, no_std, C ABI) called from a sketch.
// example.sh builds them with 32_17_embedded_rust's pinned toolchain into a precompiled Arduino
// library (precompiled=true, ldflags=-lbox_rust_dsp) and compiles with --library <that folder>.
#include <box_rust_dsp.h>

void setup() {
  Serial.begin(115200);
  static const uint8_t check[] = "123456789";
  Serial.print(F("rust_crc32 = 0x"));
  Serial.println(rust_crc32(check, sizeof(check) - 1), HEX);  // 0xCBF43926
}

void loop() {
  static int32_t avg = 0;
  avg = rust_ema_q16(avg, (int32_t)analogRead(A0) << 16, 6554);  // alpha 0.1
  Serial.println(avg >> 16);
  delay(100);
}
