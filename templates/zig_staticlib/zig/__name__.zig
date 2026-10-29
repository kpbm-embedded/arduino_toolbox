//! @NAME@ Zig part (freestanding, C ABI). Declare every export in include/@NAME@_zig.h.
//! Host tests: "$BOX_MICROZIG/microzig-box" zig test zig/@NAME@.zig

/// Linear interpolation in a sorted table of (x, y) points; clamps outside the table.
export fn @NAME@_lerp(xs: [*]const i32, ys: [*]const i32, n: usize, x: i32) i32 {
    if (n == 0) return 0;
    if (x <= xs[0]) return ys[0];
    var i: usize = 1;
    while (i < n) : (i += 1) {
        if (x <= xs[i]) {
            const dx: i64 = xs[i] - xs[i - 1];
            const dy: i64 = ys[i] - ys[i - 1];
            return @intCast(ys[i - 1] + @divTrunc(dy * (x - xs[i - 1]), dx));
        }
    }
    return ys[n - 1];
}

test "lerp" {
    const std = @import("std");
    const xs = [_]i32{ 0, 100, 200 };
    const ys = [_]i32{ 0, 1000, 1500 };
    try std.testing.expectEqual(@as(i32, 500), @NAME@_lerp(&xs, &ys, 3, 50));
    try std.testing.expectEqual(@as(i32, 1250), @NAME@_lerp(&xs, &ys, 3, 150));
    try std.testing.expectEqual(@as(i32, 1500), @NAME@_lerp(&xs, &ys, 3, 999));
}
