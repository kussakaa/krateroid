const linmath = @import("linmath.zig");

pub const Point = linmath.I32x2;
pub const Line = linmath.I32x2;
pub const Rect = linmath.I32x4;

pub const Alignment = enum {
    left_bottom, // стандарт
    left_top,
    right_bottom,
    right_top,
};
