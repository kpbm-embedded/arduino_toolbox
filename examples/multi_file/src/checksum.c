#include "checksum.h"

/* two's complement 8-bit sum: the sum of the data and the checksum is 0 */
uint8_t checksum8(const uint8_t *data, size_t len) {
  uint8_t sum = 0;
  for (size_t i = 0; i < len; i++) sum = (uint8_t)(sum + data[i]);
  return (uint8_t)(0u - sum);
}
