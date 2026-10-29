// @NAME@: BLE UART peripheral on nRF52840 (arduino-box new ble_uart_nrf52 @NAME@).
#include <Adafruit_TinyUSB.h>  // USB CDC Serial on the Adafruit nRF52 core
#include <bluefruit.h>

static BLEUart bleuart;
static BLEDis bledis;

static void handleLine(const char *line) {
  if (strcmp(line, "ping") == 0) bleuart.println("pong");
  else bleuart.printf("@NAME@ got: %s\n", line);
}

void setup() {
  Serial.begin(115200);
  Bluefruit.begin();
  Bluefruit.setName("@NAME@");
  bledis.setManufacturer("Box");
  bledis.begin();
  bleuart.begin();
  Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  Bluefruit.Advertising.addService(bleuart);
  Bluefruit.ScanResponse.addName();
  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.start(0);
}

void loop() {
  static char line[64];
  static size_t len = 0;
  while (bleuart.available()) {
    char c = (char)bleuart.read();
    if (c == '\n' || len == sizeof(line) - 1) {
      line[len] = 0;
      handleLine(line);
      len = 0;
    } else if (c != '\r') {
      line[len++] = c;
    }
  }
  delay(5);
}
