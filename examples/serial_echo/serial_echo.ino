// serial_echo: line-based echo at 115200 baud. Each received line comes back as
// "echo[<n>]: <line>"; "help" prints the board name. Uses only the core Serial API.
#ifndef ARDUINO_BOARD
#define ARDUINO_BOARD "unknown"
#endif

static char buf[96];
static size_t len = 0;
static unsigned long count = 0;

void setup() {
  Serial.begin(115200);
  unsigned long t0 = millis();
  while (!Serial && millis() - t0 < 2000) { }   // native-USB boards: wait briefly for the host
  Serial.println("serial_echo ready (type a line)");
}

static void handle(const char *line) {
  count++;
  if (strcmp(line, "help") == 0) {
    Serial.print("board: ");
    Serial.println(ARDUINO_BOARD);
    return;
  }
  Serial.print("echo[");
  Serial.print(count);
  Serial.print("]: ");
  Serial.println(line);
}

void loop() {
  while (Serial.available() > 0) {
    int c = Serial.read();
    if (c == '\r') continue;
    if (c == '\n' || len == sizeof(buf) - 1) {
      buf[len] = '\0';
      handle(buf);
      len = 0;
    } else {
      buf[len++] = (char)c;
    }
  }
}
