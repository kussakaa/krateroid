const sdl = @import("zsdl");
const Pos = @Vector(2, i32);
const Size = @Vector(2, i32);

pub fn pollEvent() union(enum) {
    none,
    quit,
    key: union(enum) {
        pressed: sdl.Scancode,
        unpressed: sdl.Scancode,
    },
    mouse: union(enum) {
        pressed: u8,
        unpressed: u8,
        moved: Pos,
        scrolled: i32,
    },
    window: union(enum) {
        resized: Size,
    },
} {
    var event: sdl.Event = undefined;
    if (!sdl.pollEvent(&event)) return .none;
    return switch (event.type) {
        .quit => .quit,
        .keydown => .{ .key = .{ .pressed = event.key.keysym.scancode } },
        .keyup => .{ .key = .{ .unpressed = event.key.keysym.scancode } },
        .mousebuttondown => .{ .mouse = .{ .pressed = event.button.button } },
        .mousebuttonup => .{ .mouse = .{ .unpressed = event.button.button } },
        .mousemotion => .{ .mouse = .{ .moved = .{ event.motion.x, event.motion.y } } },
        .mousewheel => .{ .mouse = .{ .scrolled = event.wheel.y } },
        .windowevent => switch (event.window.event) {
            .size_changed => .{ .window = .{ .resized = .{ event.window.data1, event.window.data2 } } },
            else => .none,
        },
        else => .none,
    };
}
