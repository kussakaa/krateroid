const c = @import("c.zig");
const std = @import("std");
const linmath = @import("linmath.zig");
const Vec = linmath.Vec;
const Color = linmath.F32x4;
const Mat = linmath.Mat;
const sdl = @import("sdl.zig");
const mesh = @import("mesh.zig");
const shader = @import("shader.zig");
const shader_sources = @import("shader_sources.zig");
const gui = @import("gui.zig");
const Renderer = @import("renderer.zig").Renderer;
const Event = @import("events.zig").Event;

pub fn main() !void {
    try sdl.init();
    defer sdl.quit();

    var window = try sdl.Window.init("krateroid", 800, 600);
    defer window.destroy();

    c.glEnable(c.GL_DEPTH_TEST);
    c.glEnable(c.GL_CULL_FACE);
    c.glCullFace(c.GL_FRONT);
    c.glFrontFace(c.GL_CW);
    c.glEnable(c.GL_BLEND);
    c.glBlendFunc(c.GL_SRC_ALPHA, c.GL_ONE_MINUS_SRC_ALPHA);
    c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
    c.glClearColor(0.0, 0.0, 0.0, 1.0);

    var renderer = try Renderer.init();
    defer renderer.destroy();

    var gui_main_menu = gui.Gui.init();

    try gui_main_menu.addButton(gui.Button{
        .rect = gui.Rect{ -80, 40, 80, 100 },
        .alignment = gui.Alignment.center_center,
    });
    try gui_main_menu.addButton(gui.Button{
        .rect = gui.Rect{ -80, -30, 80, 30 },
        .alignment = gui.Alignment.center_center,
    });
    try gui_main_menu.addButton(gui.Button{
        .rect = gui.Rect{ -80, -100, 80, -40 },
        .alignment = gui.Alignment.center_center,
    });

    var last_time: f32 = @intToFloat(f32, c.SDL_GetTicks());
    var run = true;

    while (run) {
        const current_time: f32 = @intToFloat(f32, c.SDL_GetTicks());
        const dt: f32 = (current_time - last_time) / 1000.0;
        _ = dt;
        last_time = current_time;

        while (true) {
            const event = sdl.pollEvent();
            if (event == null) break;
            switch (event.?) {
                Event.quit => run = false,
                Event.key_down => |key| {
                    switch (key) {
                        c.SDLK_ESCAPE => {
                            gui_main_menu.enable = !gui_main_menu.enable;
                        },
                        else => {},
                    }
                },
                Event.window_size => |size| {
                    window.size = size;
                    c.glViewport(0, 0, size[0], size[1]);
                },
                else => {},
            }
            const gui_event = gui_main_menu.pollEvent(event.?);
            switch (gui_event) {
                gui.GuiEvent.button_up => |id| {
                    switch (id) {
                        0 => gui_main_menu.enable = false,
                        2 => run = false,
                        else => {},
                    }
                },
                else => {},
            }
        }

        const vpsize = window.size;
        renderer.vpsize = vpsize;

        // Рисование
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
        c.glClearColor(0.0, 0.0, 0.0, 1.0);
        c.glEnable(c.GL_DEPTH_TEST);
        // 3D

        // ...

        c.glDisable(c.GL_DEPTH_TEST);
        // 2D

        renderer.color = Color{ 1.0, 1.0, 1.0, 1.0 };
        if (gui_main_menu.enable) renderer.draw(gui_main_menu);
        renderer.draw(gui.Label{ .str = &[_]u16{ 's', 'e', 't', 't', 'i', 'n', 'g', 's' }, .pos = linmath.I32x2{ -52, -8 }, .alignment = gui.Alignment.center_center });

        window.swap();
    }
}
