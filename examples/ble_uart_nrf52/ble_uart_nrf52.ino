// ble_uart_nrf52: BLE peripheral on nice!nano / Pro Micro nRF52840 (Adafruit nRF52 core, Bluefruit).
// Services: Nordic UART (BLEUart, echo + "bat" command), Device Information, Battery.
// Test with a phone (nRF Connect, Bluefruit Connect): connect to "box-nrf52", send text on NUS.
#include <Adafruit_TinyUSB.h>  // USB CDC Serial on the Adafruit nRF52 core
#include <bluefruit.h>

BLEDis bledis;
BLEUart bleuart;
BLEBas blebas;

static void startAdvertising() {
  Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  Bluefruit.Advertising.addTxPower();
  Bluefruit.Advertising.addService(bleuart);
  Bluefruit.ScanResponse.addName();
  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(32, 244);  // units of 0.625 ms: fast, then slow
  Bluefruit.Advertising.setFastTimeout(30);
  Bluefruit.Advertising.start(0);
}

static void onConnect(uint16_t conn) {
  char name[32] = {0};
  Bluefruit.Connection(conn)->getPeerName(name, sizeof(name));
  Serial.printf("connected to %s\n", name);
}

static void onDisconnect(uint16_t, uint8_t reason) { Serial.printf("disconnected, reason 0x%02x\n", reason); }

void setup() {
  Serial.begin(115200);
  Bluefruit.begin();
  Bluefruit.setTxPower(4);
  Bluefruit.setName("box-nrf52");
  Bluefruit.Periph.setConnectCallback(onConnect);
  Bluefruit.Periph.setDisconnectCallback(onDisconnect);
  bledis.setManufacturer("Box");
  bledis.setModel("nice!nano");
  bledis.begin();
  bleuart.begin();
  blebas.begin();
  blebas.write(100);
  startAdvertising();
}

void loop() {
  static char line[64];
  static size_t len = 0;
  while (bleuart.available()) {
    char c = (char)bleuart.read();
    if (c == '\n' || len == sizeof(line) - 1) {
      line[len] = 0;
      if (strcmp(line, "bat") == 0) bleuart.printf("battery %u%%\n", 100);
      else bleuart.printf("echo: %s\n", line);
      len = 0;
    } else if (c != '\r') {
      line[len++] = c;
    }
  }
  delay(5);
}
