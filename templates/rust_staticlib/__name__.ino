// @NAME@: sketch calling Rust (rust/, built into a precompiled library by build.sh).
#include <@NAME@_rs.h>

void setup() {
  Serial.begin(115200);
  Serial.println(@NAME@_add_sat(30000, 10000));  // 32767
}

void loop() {}
