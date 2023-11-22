const std = @import("std");
const log = std.log.scoped(.GameCore);
const c = @import("c.zig");

const Input = @import("Core/Input.zig");
const Window = @import("Core/Window.zig");
const Core = @This();

input: Input,
window: Window,

pub const InitInfo = struct {
    window: Window.InitInfo,
};

pub fn init(info: InitInfo) !Core {
    if (c.SDL_Init(c.SDL_INIT_EVERYTHING) < 0) {
        log.err("failed init SDL: {s}", .{c.SDL_GetError()});
        return error.Core_SDL_Init;
    } else {}
    const window = try Window.init(info.window);

    log.debug("init", .{});

    return .{
        .input = .{},
        .window = window,
    };
}

pub fn deinit(self: Core) void {
    self.window.deinit();
    c.SDL_Quit();
    log.debug("deinit", .{});
}
