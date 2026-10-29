// CRC-16/CCITT-FALSE (poly 0x1021, init 0xFFFF); no Arduino headers.
#pragma once
#include <stddef.h>
#include <stdint.h>

uint16_t crc16_ccitt(const uint8_t *data, size_t len);
