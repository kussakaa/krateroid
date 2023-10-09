const c = @import("c.zig");
const std = @import("std");
const linmath = @import("linmath.zig");
const Mat = linmath.Mat;
const sdl = @import("sdl.zig");
const gui = @import("gui.zig");
const input = @import("input.zig");
const shape = @import("shape.zig");

const WINDOW_WIDTH = 1200;
const WINDOW_HEIGHT = 900;

pub fn main() !void {
    std.debug.print("\n", .{});

    try sdl.init();
    defer sdl.deinit();

    var window = try sdl.Window.init("krateroid", WINDOW_WIDTH, WINDOW_HEIGHT);
    defer window.deinit();

    c.glEnable(c.GL_DEPTH_TEST);
    c.glEnable(c.GL_CULL_FACE);
    c.glEnable(c.GL_BLEND);
    c.glEnable(c.GL_MULTISAMPLE);
    c.glCullFace(c.GL_FRONT);
    c.glFrontFace(c.GL_CW);
    c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_FILL);
    c.glLineWidth(1);
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);

    var input_state = input.State.init();

    var gui_state = try gui.State.init(std.heap.page_allocator, .{ WINDOW_WIDTH, WINDOW_HEIGHT });
    defer gui_state.deinit();

    _ = try gui_state.addControl(gui.Control{ .button = try gui.Button.init(
        gui_state,
        .{ .min = .{ -32, -25 }, .max = .{ 32, -9 } },
        .{ .horizontal = .center, .vertical = .center },
        std.unicode.utf8ToUtf16LeStringLiteral("играть"),
    ) });

    _ = try gui_state.addControl(gui.Control{ .button = try gui.Button.init(
        gui_state,
        .{ .min = .{ -32, -8 }, .max = .{ 32, 8 } },
        .{ .horizontal = .center, .vertical = .center },
        std.unicode.utf8ToUtf16LeStringLiteral("настройки"),
    ) });

    _ = try gui_state.addControl(gui.Control{ .button = try gui.Button.init(
        gui_state,
        .{ .min = .{ -32, 9 }, .max = .{ 32, 25 } },
        .{ .horizontal = .center, .vertical = .center },
        std.unicode.utf8ToUtf16LeStringLiteral("выход"),
    ) });

    _ = try gui_state.addControl(gui.Control{ .text = try gui.Text.init(
        gui_state,
        .{ 2, 1 },
        .{},
        .{ 1.0, 1.0, 1.0, 1.0 },
        std.unicode.utf8ToUtf16LeStringLiteral("krateroid prototype gui"),
    ) });

    var last_time = @as(i32, @intCast(c.SDL_GetTicks()));
    var run = true;

    var frame: u32 = 0;
    var fps: u32 = 0;
    var seconds: u32 = 0;

    while (run) {
        const current_time = @as(i32, @intCast(c.SDL_GetTicks()));
        const dt: f32 = @as(f32, @floatFromInt(current_time - last_time)) / 1000.0;
        _ = dt;
        last_time = current_time;

        if (@divTrunc(c.SDL_GetTicks(), 1000) > seconds) {
            seconds = @divTrunc(c.SDL_GetTicks(), 1000);
            fps = frame;
            frame = 0;
        }

        while (true) {
            const event = sdl.pollEvent();
            if (event == .none) break;
            input_state.process(event);
            //std.log.debug("event: {}", .{event.?});
            switch (event) {
                input.Event.quit => run = false,
                input.Event.window_size => |size| {
                    window.size = size;
                    gui_state.vpsize = size;
                    c.glViewport(0, 0, size[0], size[1]);
                },
                input.Event.keyboard_key_down => |key| {
                    switch (key) {
                        c.SDL_SCANCODE_W => gui_state.scale += 1,
                        c.SDL_SCANCODE_S => gui_state.scale -= 1,
                        else => {},
                    }
                },
                else => {},
            }

            const gui_event = gui.EventSystem.process(gui_state, input_state, event);
            if (gui_event != .none) std.log.debug("gui event: {}", .{gui_event});

            switch (gui_event) {
                .unpress => |id| switch (id) {
                    2 => run = false,
                    else => {},
                },
                else => {},
            }
        }

        gui.InputSystem.process(&gui_state, input_state);

        // Рисование
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glEnable(c.GL_DEPTH_TEST);
        // 3D

        c.glDisable(c.GL_DEPTH_TEST);

        gui.RenderSystem.draw(gui_state);

        frame += 1;

        window.swap();
    }
}
