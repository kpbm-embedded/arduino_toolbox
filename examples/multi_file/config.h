// Settings shared by the sketch files (included as "config.h").
#pragma once
#include <Arduino.h>

#define SERIAL_BAUD 115200
// on/off durations in ms: ... --- ...
static const uint16_t PATTERN_SOS[] = {150, 150, 150, 150, 150, 450,
                                       450, 150, 450, 150, 450, 450,
                                       150, 150, 150, 150, 150, 1500};
#ifndef LED_BUILTIN
#define LED_BUILTIN 2
#endif
