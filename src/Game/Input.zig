const std = @import("std");
const c = @import("../c.zig");

const Point = @Vector(2, i32);

const Input = @This();
pub const Event = union(enum) {
    none,
    quit,
    keyboard: Keyboard,
    mouse: Mouse,
    window: Window,

    const Keyboard = union(enum) {
        down: u32,
        up: u32,
    };

    const Mouse = union(enum) {
        button: Button,
        motion: Point,

        const Button = union(enum) {
            down: u32,
            up: u32,
        };
    };

    pub const Window = union(enum) {
        size: Point,
    };
};

pub fn pollevents(self: Input) Event {
    _ = self;
    var sdl_event: c.SDL_Event = undefined;
    if (c.SDL_PollEvent(&sdl_event) <= 0) return .none;
    return switch (sdl_event.type) {
        c.SDL_QUIT => Event.quit,
        c.SDL_KEYDOWN => Event{ .keyboard = .{ .down = sdl_event.key.keysym.scancode } },
        c.SDL_KEYUP => Event{ .keyboard = .{ .up = sdl_event.key.keysym.scancode } },
        c.SDL_MOUSEBUTTONDOWN => Event{ .mouse = .{ .button = .{ .down = sdl_event.button.button } } },
        c.SDL_MOUSEBUTTONUP => Event{ .mouse = .{ .button = .{ .up = sdl_event.button.button } } },
        c.SDL_MOUSEMOTION => Event{ .mouse = .{ .motion = Point{ sdl_event.motion.x, sdl_event.motion.y } } },
        c.SDL_WINDOWEVENT => switch (sdl_event.window.event) {
            c.SDL_WINDOWEVENT_SIZE_CHANGED => Event{ .window = .{ .size = .{ sdl_event.window.data1, sdl_event.window.data2 } } },
            else => .none,
        },
        else => .none,
    };
}
