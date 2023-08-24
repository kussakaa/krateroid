const std = @import("std");

pub const Color = u32;

pub fn convert(comptime T: type, color: Color) T {
    switch (comptime T) {
        @Vector(4, u32) => {
            return @Vector(4, u32){
                (color >> 24) & 255,
                (color >> 16) & 255,
                (color >> 8) & 255,
                (color >> 0) & 255,
            };
        },
        @Vector(4, f32) => {
            return @Vector(4, f32){
                @as(f32, @floatFromInt((color >> 24) & 255)) / 255.0,
                @as(f32, @floatFromInt((color >> 16) & 255)) / 255.0,
                @as(f32, @floatFromInt((color >> 8) & 255)) / 255.0,
                @as(f32, @floatFromInt((color >> 0) & 255)) / 255.0,
            };
        },
        else => @compileError("[ERROR]:Invalid type for color converter!\n"),
    }
}

test "Color converter" {
    try std.testing.expectEqual(
        convert(@Vector(4, u32), 0x0064c8FF),
        @Vector(4, u32){ 0, 100, 200, 255 },
    );
}
