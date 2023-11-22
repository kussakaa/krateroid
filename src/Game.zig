const std = @import("std");
const Allocator = std.mem.Allocator;

const Core = @import("Core.zig");
const Drawer = @import("Drawer.zig");
const Gui = @import("Gui.zig");

const Game = @This();

allocator: Allocator,
core: Core,
drawer: Drawer,
gui: Gui,

pub const InitInfo = struct {
    allocator: Allocator,
    core: Core.InitInfo,
};

pub fn init(info: InitInfo) !Game {
    const allocator = info.allocator;

    return Game{
        .allocator = allocator,
        .core = try Core.init(info.core),
        .drawer = try Drawer.init(.{ .allocator = allocator }),
        .gui = try Gui.init(.{ .allocator = allocator }),
    };
}

pub fn deinit(self: Game) void {
    self.core.deinit();
    self.drawer.deinit();
    self.gui.deinit();
}

pub fn draw(self: Game) !void {
    _ = self;
}
