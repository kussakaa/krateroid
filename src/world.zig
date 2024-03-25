const std = @import("std");
const log = std.log.scoped(.world);
const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;

const zm = @import("zmath");
const Vec = zm.Vec;
const Color = zm.Vec;

pub const terra = @import("world/terra.zig");
pub const Line = @import("world/Line.zig");

var _allocator: Allocator = undefined;

pub var lines: Array(Line) = undefined;

pub fn init(info: struct {
    allocator: Allocator = std.heap.page_allocator,
    terra: struct { seed: i32 = 6969 },
}) !void {
    _allocator = info.allocator;
    try terra.init(.{
        .allocator = _allocator,
        .seed = 6969,
    });
}

pub fn deinit() void {
    lines.deinit(_allocator);
    terra.deinit();
}

pub const line = struct {
    pub fn init(info: struct {
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
};
