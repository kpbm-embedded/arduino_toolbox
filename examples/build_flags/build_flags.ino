// build_flags: the version is not in the source; the build passes it:
//   arduino-box compile . pico --build-property "compiler.cpp.extra_flags=-DFW_MAJOR=2 -DFW_MINOR=7 -DFW_PATCH=13 -DFW_BUILD=4242"
// compiler.cpp.extra_flags is an empty hook in every core's platform.txt (build.extra_flags is not:
// boards use it, so overriding it breaks them).
#include <Arduino.h>

#ifndef FW_MAJOR
#error "build with --build-property compiler.cpp.extra_flags=-DFW_MAJOR=.. -DFW_MINOR=.. -DFW_PATCH=.. -DFW_BUILD=.."
#endif
#define STR_(x) #x
#define STR(x) STR_(x)

// used: kept in the image, so the test finds it with elf_check.py --string
const char kVersion[] = "fw " STR(FW_MAJOR) "." STR(FW_MINOR) "." STR(FW_PATCH) "+" STR(FW_BUILD);

void setup() {
  Serial.begin(115200);
  Serial.println(kVersion);
  Serial.println(F("built " __DATE__ " " __TIME__));
}

void loop() {
  if (Serial.read() == 'v') Serial.println(kVersion);
}
