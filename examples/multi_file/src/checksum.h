// Plain C module in src/ (extern "C" so C++ callers link to it).
#pragma once
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
uint8_t checksum8(const uint8_t *data, size_t len);
#ifdef __cplusplus
}
#endif
