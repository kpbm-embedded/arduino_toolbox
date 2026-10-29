// blink: toggles LED_BUILTIN every 500 ms and prints the uptime on Serial.
// Boards: Nano (D13), ESP32-S3-DevKitC-1 (RGB LED on GPIO48 via LED_BUILTIN/RGB_BUILTIN),
// Pico (GP25), BlackPill F411CE (PC13, active low).
#ifndef LED_BUILTIN
#define LED_BUILTIN 13
#endif

static unsigned long last = 0;
static bool on = false;

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.begin(115200);
}

void loop() {
  unsigned long now = millis();
  if (now - last >= 500) {
    last = now;
    on = !on;
    digitalWrite(LED_BUILTIN, on ? HIGH : LOW);
    Serial.print("blink ");
    Serial.println(now);
  }
}
