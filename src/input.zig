const c = @import("c.zig");

const Pos = @Vector(2, i32);
const Size = @Vector(2, i32);

pub fn pollEvent() union(enum) {
    none,
    quit,
    key: union(enum) {
        press: u32,
        unpress: u32,
    },
    mouse: union(enum) {
        button: union(enum) {
            press: u32,
            unpress: u32,
        },
        pos: Pos,
        scroll: i32,
    },
    window: union(enum) {
        size: Size,
    },
} {
    var sdl_event: c.SDL_Event = undefined;
    if (c.SDL_PollEvent(&sdl_event) <= 0) return .none;
    return switch (sdl_event.type) {
        c.SDL_QUIT => .quit,
        c.SDL_KEYDOWN => .{ .key = .{ .press = sdl_event.key.keysym.scancode } },
        c.SDL_KEYUP => .{ .key = .{ .unpress = sdl_event.key.keysym.scancode } },
        c.SDL_MOUSEBUTTONDOWN => .{ .mouse = .{ .button = .{ .press = sdl_event.button.button } } },
        c.SDL_MOUSEBUTTONUP => .{ .mouse = .{ .button = .{ .unpress = sdl_event.button.button } } },
        c.SDL_MOUSEMOTION => .{ .mouse = .{ .pos = .{ sdl_event.motion.x, sdl_event.motion.y } } },
        c.SDL_MOUSEWHEEL => .{ .mouse = .{ .scroll = sdl_event.wheel.y } },
        c.SDL_WINDOWEVENT => switch (sdl_event.window.event) {
            c.SDL_WINDOWEVENT_SIZE_CHANGED => .{ .window = .{ .size = .{ sdl_event.window.data1, sdl_event.window.data2 } } },
            else => .none,
        },
        else => .none,
    };
}
