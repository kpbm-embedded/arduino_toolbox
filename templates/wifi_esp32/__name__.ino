// @NAME@: Wi-Fi station + JSON status endpoint (arduino-box new wifi_esp32 @NAME@).
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

#if __has_include("secrets.h")
#include "secrets.h"  // gitignored: copy secrets.example.h
#else
#define WIFI_SSID ""
#define WIFI_PASSWORD ""
#endif

static WebServer server(80);

static void handleStatus() {
  JsonDocument doc;
  doc["device"] = "@NAME@";
  doc["uptime_s"] = millis() / 1000;
  doc["rssi"] = WiFi.RSSI();
  doc["heap_free"] = ESP.getFreeHeap();
  String body;
  serializeJson(doc, body);
  server.send(200, "application/json", body);
}

void setup() {
  Serial.begin(115200);
  WiFi.mode(WIFI_STA);
  WiFi.setHostname("@NAME@");
  WiFi.setAutoReconnect(true);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  server.on("/status", handleStatus);
  server.begin();
}

void loop() {
  static uint32_t last = 0;
  static bool wasConnected = false;
  bool connected = WiFi.status() == WL_CONNECTED;
  if (connected != wasConnected) {
    wasConnected = connected;
    if (connected) Serial.printf("@NAME@ at http://%s/status\n", WiFi.localIP().toString().c_str());
    else Serial.println("@NAME@ Wi-Fi lost");
  }
  if (!connected && millis() - last > 10000) {
    last = millis();
    WiFi.reconnect();
  }
  server.handleClient();
  delay(2);
}
