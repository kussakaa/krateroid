const sdl = @import("zsdl");
const Pos = @Vector(2, i32);
const Size = @Vector(2, i32);

pub fn pollEvent() union(enum) {
    none,
    quit,
    key: union(enum) {
        press: sdl.Scancode,
        unpress: sdl.Scancode,
    },
    mouse: union(enum) {
        button: union(enum) {
            press: u8,
            unpress: u8,
        },
        pos: Pos,
        scroll: i32,
    },
    window: union(enum) {
        size: Size,
    },
} {
    var event: sdl.Event = undefined;
    if (!sdl.pollEvent(&event)) return .none;
    return switch (event.type) {
        .quit => .quit,
        .keydown => .{ .key = .{ .press = event.key.keysym.scancode } },
        .keyup => .{ .key = .{ .unpress = event.key.keysym.scancode } },
        .mousebuttondown => .{ .mouse = .{ .button = .{ .press = event.button.button } } },
        .mousebuttonup => .{ .mouse = .{ .button = .{ .unpress = event.button.button } } },
        .mousemotion => .{ .mouse = .{ .pos = .{ event.motion.x, event.motion.y } } },
        .mousewheel => .{ .mouse = .{ .scroll = event.wheel.y } },
        .windowevent => switch (event.window.event) {
            .size_changed => .{ .window = .{ .size = .{ event.window.data1, event.window.data2 } } },
            else => .none,
        },
        else => .none,
    };
}
