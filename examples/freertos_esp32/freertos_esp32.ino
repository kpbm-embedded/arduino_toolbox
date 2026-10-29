// freertos_esp32: the Arduino ESP32 core runs on FreeRTOS (setup/loop are the "loopTask").
// Two tasks talk through a queue; a mutex protects Serial. On the dual-core S3 the producer is
// pinned to core 0 and the consumer to core 1; the single-core C3 uses core 0 for both.
#include <Arduino.h>

struct Sample {
  uint32_t seq;
  uint32_t tick;
};

static QueueHandle_t samples;
static SemaphoreHandle_t serialLock;

static void logLine(const char *what, const Sample &s) {
  if (xSemaphoreTake(serialLock, pdMS_TO_TICKS(50)) == pdTRUE) {
    Serial.printf("[core %d] %s seq=%lu tick=%lu\n", xPortGetCoreID(), what, (unsigned long)s.seq, (unsigned long)s.tick);
    xSemaphoreGive(serialLock);
  }
}

void producerTask(void *) {
  Sample s{0, 0};
  for (;;) {
    s.seq++;
    s.tick = xTaskGetTickCount();
    if (xQueueSend(samples, &s, pdMS_TO_TICKS(10)) != pdTRUE) logLine("queue full", s);
    vTaskDelay(pdMS_TO_TICKS(100));
  }
}

void consumerTask(void *) {
  Sample s;
  for (;;) {
    if (xQueueReceive(samples, &s, portMAX_DELAY) == pdTRUE) logLine("got", s);
  }
}

void setup() {
  Serial.begin(115200);
  samples = xQueueCreate(8, sizeof(Sample));
  serialLock = xSemaphoreCreateMutex();
  const BaseType_t consumerCore = portNUM_PROCESSORS > 1 ? 1 : 0;
  xTaskCreatePinnedToCore(producerTask, "producer", 3072, nullptr, 2, nullptr, 0);
  xTaskCreatePinnedToCore(consumerTask, "consumer", 3072, nullptr, 1, nullptr, consumerCore);
}

void loop() {
  // the Arduino loop task is not needed: give its time away
  vTaskDelay(pdMS_TO_TICKS(1000));
}
