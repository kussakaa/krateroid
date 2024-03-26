const std = @import("std");
const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;

const zm = @import("zmath");
const Vec = zm.Vec;
const Mat = zm.Mat;
const Color = zm.Vec;

pub const Line = @import("shape/Line.zig");

var _allocator: Allocator = undefined;
pub var lines: Array(Line) = undefined;

pub fn init(info: struct {
    allocator: Allocator,
}) !void {
    _allocator = info.allocator;
}

pub fn deinit() void {
    lines.deinit(_allocator);
}

pub fn initLine(info: struct {
    p1: Vec,
    p2: Vec,
    color: Color = .{ 1.0, 1.0, 1.0, 1.0 },
    show: bool = true,
}) !Line.Id {
    try lines.append(_allocator, .{
        .id = lines.items.len,
        .p1 = info.p1,
        .p2 = info.p2,
        .color = info.color,
        .show = info.show,
    });
    return lines.items.len - 1;
}
