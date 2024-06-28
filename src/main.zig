const std = @import("std");
const log = std.log.scoped(.MAIN);

const World = @import("World.zig");
const Gfx = @import("Gfx.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator: std.mem.Allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var world = try World.init(allocator, .{
        .width = 4,
    });
    defer world.deinit();

    var gfx = try Gfx.init(allocator, .{
        .window = .{ .title = "krateroid", .size = .{ 1200, 900 } },
        .input = .{},
        .camera = .{ .ratio = 1.0, .scale = 1.0 },
    });
    defer gfx.deinit();

    gfx.window.handle.setUserPointer(&gfx.input);

    while (gfx.update() and gfx.draw()) {}
}
