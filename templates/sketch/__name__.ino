// @NAME@: Arduino sketch made by ./arduino-box new sketch @NAME@
// Compile: ./arduino-box compile . nano   (or esp32s3 | pico | blackpill | a full FQBN)
// Upload:  ./arduino-box plan nano .      (prints the commands; arduino-box never uploads)

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.begin(115200);
  Serial.println("@NAME@ started");
}

void loop() {
  digitalWrite(LED_BUILTIN, HIGH);
  delay(250);
  digitalWrite(LED_BUILTIN, LOW);
  delay(750);
}
