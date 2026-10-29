// @NAME@: FreeRTOS tasks on ESP32 (arduino-box new freertos_esp32 @NAME@).
// sensorTask -> queue -> reportTask; 'p' on Serial pauses/resumes the sensor via an event group.
#include <Arduino.h>

static QueueHandle_t readings;
static EventGroupHandle_t flags;
static const EventBits_t RUNNING = BIT0;

static void sensorTask(void *) {
  for (;;) {
    xEventGroupWaitBits(flags, RUNNING, pdFALSE, pdTRUE, portMAX_DELAY);
    int value = analogRead(1);
    xQueueSend(readings, &value, 0);
    vTaskDelay(pdMS_TO_TICKS(200));
  }
}

static void reportTask(void *) {
  int value;
  for (;;) {
    if (xQueueReceive(readings, &value, pdMS_TO_TICKS(1000)) == pdTRUE) {
      Serial.printf("@NAME@ value=%d stack_free=%u\n", value, (unsigned)uxTaskGetStackHighWaterMark(nullptr));
    }
  }
}

void setup() {
  Serial.begin(115200);
  readings = xQueueCreate(16, sizeof(int));
  flags = xEventGroupCreate();
  xEventGroupSetBits(flags, RUNNING);
  xTaskCreatePinnedToCore(sensorTask, "sensor", 4096, nullptr, 2, nullptr, 0);
  xTaskCreatePinnedToCore(reportTask, "report", 4096, nullptr, 1, nullptr, portNUM_PROCESSORS - 1);
}

void loop() {
  if (Serial.available() && Serial.read() == 'p') {
    if (xEventGroupGetBits(flags) & RUNNING) xEventGroupClearBits(flags, RUNNING);
    else xEventGroupSetBits(flags, RUNNING);
  }
  vTaskDelay(pdMS_TO_TICKS(50));
}
