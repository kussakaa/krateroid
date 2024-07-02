const std = @import("std");
const log = @import("log");

const World = @import("World.zig");
const Gfx = @import("Gfx.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var world = try World.init(allocator, .{
        .map = .{
            .size = .{ 4, 4 },
        },
    });
    defer world.deinit();

    var gfx = try Gfx.init(allocator, .{
        .window = .{ .title = "krateroid", .size = .{ 1200, 900 } },
        .input = .{},
        .camera = .{ .ratio = 1.0, .scale = 1.0 },
    });
    defer gfx.deinit();

    log.succes(.init, "MAIN", .{});

    while (world.update() and gfx.update() and gfx.draw()) {}
}
