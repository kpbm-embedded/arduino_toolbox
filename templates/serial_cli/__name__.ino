// @NAME@: serial command shell (arduino-box new serial_cli @NAME@).
#include <Arduino.h>

typedef void (*Handler)(const char *args);
struct Command {
  const char *name;
  Handler run;
  const char *help;
};

static void cmdHelp(const char *);
static void cmdLed(const char *args) {
  bool on = strcmp(args, "on") == 0;
  digitalWrite(LED_BUILTIN, on ? HIGH : LOW);
  Serial.println(on ? F("led on") : F("led off"));
}
static void cmdUptime(const char *) {
  Serial.print(millis() / 1000);
  Serial.println(F(" s"));
}
static void cmdEcho(const char *args) { Serial.println(args); }

static const Command kCommands[] = {
    {"help", cmdHelp, "list commands"},
    {"led", cmdLed, "led on|off"},
    {"uptime", cmdUptime, "seconds since reset"},
    {"echo", cmdEcho, "echo <text>"},
};

static void cmdHelp(const char *) {
  for (const Command &c : kCommands) {
    Serial.print(c.name);
    Serial.print(F("\t"));
    Serial.println(c.help);
  }
}

static void dispatch(char *line) {
  char *args = strchr(line, ' ');
  if (args) *args++ = 0;
  else args = line + strlen(line);
  for (const Command &c : kCommands) {
    if (strcmp(line, c.name) == 0) {
      c.run(args);
      return;
    }
  }
  if (*line) Serial.println(F("unknown command (help)"));
}

void setup() {
  Serial.begin(115200);
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.println(F("@NAME@ ready, type help"));
}

void loop() {
  static char line[64];
  static uint8_t len = 0;
  while (Serial.available()) {
    char c = (char)Serial.read();
    if (c == '\r') continue;
    if (c == '\n' || len == sizeof(line) - 1) {
      line[len] = 0;
      dispatch(line);
      len = 0;
    } else {
      line[len++] = c;
    }
  }
}
