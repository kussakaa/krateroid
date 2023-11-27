const std = @import("std");
const Allocator = std.mem.Allocator;

const Window = @import("Game/Window.zig");
const Input = @import("Game/Input.zig");
const Drawer = @import("Game/Drawer.zig");
const Gui = @import("Game/Gui.zig");

const Game = @This();
allocator: Allocator,
window: Window,
input: Input,
drawer: Drawer,
gui: Gui,

pub const InitInfo = struct {
    allocator: Allocator,
    window: Window.InitInfo,
};

pub fn init(info: InitInfo) !Game {
    const allocator = info.allocator;
    return .{
        .allocator = allocator,
        .window = try Window.init(info.window),
        .input = .{},
        .drawer = try Drawer.init(.{ .allocator = allocator }),
        .gui = try Gui.init(.{ .allocator = allocator }),
    };
}

pub fn deinit(game: Game) void {
    game.window.deinit();
    game.drawer.deinit();
    game.gui.deinit();
}

pub fn draw(game: *Game) !void {
    try game.drawer.draw(game.window, game.gui);
    game.window.swap();
}
