const c = @import("c.zig");
const std = @import("std");
const linmath = @import("linmath.zig");
const Mat = linmath.Mat;
const sdl = @import("sdl.zig");
const gui = @import("gui.zig");
const Event = @import("events.zig").Event;
const shape = @import("shape.zig");
const world = @import("world.zig");

const page_allocator = std.heap.page_allocator;

const WINDOW_WIDTH = 1200;
const WINDOW_HEIGHT = 900;

pub fn main() !void {
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

    var gui_render_system = try gui.RenderSystem.init(std.heap.page_allocator);
    defer gui_render_system.deinit();

    var gui_controls = gui.Controls.init(std.heap.page_allocator);
    defer gui_controls.deinit();
    try gui_controls.append(gui.Control.init(std.heap.page_allocator));
    defer gui_controls.items[0].?.deinit();
    try gui_controls.items[0].?.append(gui.Component{ .color_panel = .{
        .rect = .{ 50, 50, 100, 100 },
        .color = .{ 1.0, 0.0, 0.0, 1.0 },
    } });

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
            if (event == null) break;
            switch (event.?) {
                Event.quit => run = false,
                Event.window_size => |size| {
                    window.size = size;
                    gui_render_system.vpsize = size;
                    c.glViewport(0, 0, size[0], size[1]);
                },
                else => {},
            }
        }

        // Рисование
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glEnable(c.GL_DEPTH_TEST);
        // 3D

        c.glDisable(c.GL_DEPTH_TEST);

        gui_render_system.draw(gui_controls);

        frame += 1;

        window.swap();
    }
}
