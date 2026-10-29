// i2c_scan: probes 7-bit addresses 0x08..0x77 on the default Wire bus every 5 s and prints
// the ones that ACK. Default pins: Nano A4/A5, ESP32-S3 GPIO8/GPIO9, Pico GP4/GP5 (Wire),
// BlackPill PB7/PB6.
#include <Wire.h>

void setup() {
  Serial.begin(115200);
  Wire.begin();
  Serial.println("i2c_scan ready");
}

void loop() {
  int found = 0;
  for (uint8_t addr = 0x08; addr < 0x78; addr++) {
    Wire.beginTransmission(addr);
    if (Wire.endTransmission() == 0) {
      Serial.print("found 0x");
      if (addr < 16) Serial.print('0');
      Serial.println(addr, HEX);
      found++;
    }
  }
  Serial.print("scan done: ");
  Serial.print(found);
  Serial.println(" device(s)");
  delay(5000);
}
