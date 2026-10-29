// @NAME@: sketch calling Zig (zig/, built into a precompiled library by build.sh).
#include <@NAME@_zig.h>

static const int32_t kRaw[] = {0, 512, 1023};      // ADC
static const int32_t kTemp[] = {-400, 250, 1250};  // 0.1 degC (example calibration)

void setup() { Serial.begin(115200); }

void loop() {
  Serial.println(@NAME@_lerp(kRaw, kTemp, 3, analogRead(A0)));
  delay(500);
}
