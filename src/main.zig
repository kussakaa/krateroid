const std = @import("std");
const log = @import("log");

const World = @import("World.zig");
const Gfx = @import("Gfx.zig");
const Drawer = @import("Drawer.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const world = try World.init(allocator, .{
        .map = .{
            .size = .{ 4, 4 },
        },
    });
    defer world.deinit();

    const gfx = try Gfx.init(allocator, .{
        .window = .{ .title = "krateroid", .size = .{ 1200, 900 } },
        .input = .{},
    });
    defer gfx.deinit();

    var drawer = try Drawer.init(.{
        .gfx = gfx,
        .camera = .{},
    });
    defer drawer.deinit();

    log.succes(.init, "MAIN", .{});

    while (world.update() and gfx.update() and drawer.draw()) continue;
}
