//! box_zig_dsp: small freestanding Zig functions with a C ABI, called from an Arduino sketch
//! through box_zig_dsp.h. No allocator, no std I/O; built by examples/zig_staticlib with the
//! pinned Zig of 32_24_microzig (microzig-box zig build-lib).

/// Integer square root (floor) of a 32-bit value, bit by bit.
export fn zig_isqrt(value: u32) u16 {
    var op: u32 = value;
    var res: u32 = 0;
    var one: u32 = 1 << 30;
    while (one > op) one >>= 2;
    while (one != 0) {
        if (op >= res + one) {
            op -= res + one;
            res = (res >> 1) + one;
        } else {
            res >>= 1;
        }
        one >>= 2;
    }
    return @intCast(res);
}

/// Clamp-and-scale an ADC reading (0..max_raw) to 0..out_max, saturating out-of-range input.
export fn zig_scale(raw: u32, max_raw: u32, out_max: u32) u32 {
    if (max_raw == 0) return 0;
    const r: u64 = @min(raw, max_raw);
    return @intCast(r * out_max / max_raw);
}

const std = @import("std");

test "isqrt" {
    try std.testing.expectEqual(@as(u16, 0), zig_isqrt(0));
    try std.testing.expectEqual(@as(u16, 3), zig_isqrt(15));
    try std.testing.expectEqual(@as(u16, 4), zig_isqrt(16));
    try std.testing.expectEqual(@as(u16, 65535), zig_isqrt(0xFFFF_FFFF));
}

test "scale saturates" {
    try std.testing.expectEqual(@as(u32, 1650), zig_scale(2048, 4096, 3300));
    try std.testing.expectEqual(@as(u32, 3300), zig_scale(9999, 4095, 3300));
    try std.testing.expectEqual(@as(u32, 0), zig_scale(5, 0, 3300));
}
