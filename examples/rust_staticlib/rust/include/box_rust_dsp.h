// C declarations of the Rust functions in src/lib.rs (no_std staticlib, C ABI).
#pragma once
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
uint32_t rust_crc32(const uint8_t *data, size_t len);
int32_t rust_ema_q16(int32_t avg, int32_t sample, uint32_t alpha_q16);
#ifdef __cplusplus
}
#endif
