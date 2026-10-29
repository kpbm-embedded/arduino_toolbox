// C declarations of the Zig functions in fixed.zig (freestanding static library, C ABI).
#pragma once
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
uint16_t zig_isqrt(uint32_t value);
uint32_t zig_scale(uint32_t raw, uint32_t max_raw, uint32_t out_max);
#ifdef __cplusplus
}
#endif
