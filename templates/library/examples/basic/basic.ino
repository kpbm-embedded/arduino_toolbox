// basic: example of the @NAME@ library (shown in the IDE under File > Examples once installed).
#include <@NAME@.h>

@NAME@ avg(16);

void setup() { Serial.begin(115200); }

void loop() {
  Serial.println(avg.add(analogRead(A0)));
  delay(100);
}
