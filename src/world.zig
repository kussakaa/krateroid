const std = @import("std");
const log = std.log.scoped(.world);
const Allocator = std.mem.Allocator;
const Array = std.ArrayListUnmanaged;

const zm = @import("zmath");
const Vec = zm.Vec;
const Color = zm.Vec;

pub const shape = @import("world/shape.zig");
pub const entity = @import("world/entity.zig");
pub const terra = @import("world/terra.zig");

pub fn init(info: struct {
    allocator: Allocator = std.heap.page_allocator,
    terra: struct { seed: i32 = 6969 },
}) !void {
    try shape.init(.{
        .allocator = info.allocator,
    });
    try terra.init(.{
        .allocator = info.allocator,
        .seed = 6969,
    });
}

pub fn deinit() void {
    shape.deinit();
    terra.deinit();
}
